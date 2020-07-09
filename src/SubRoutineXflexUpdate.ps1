$Global:srcPath = split-path -path $MyInvocation.MyCommand.Definition 
$Global:mainPath = split-path -path $srcPath
$Global:resourcespath = join-path -path "$mainPath" -ChildPath "resources"
$Global:errorVariable = "Stop"
$Global:logFile = "$resourcespath\processing.log"
$Global:XflexInterfaceLog = "$resourcespath\XflexInterface.log"

#Statistics
$Global:APICalls = 0

#Requirementcheck PartnerCenter Module
if (!(Get-Module -ListAvailable -Name PartnerCenter)) {
    try {
        Install-Module -Name PartnerCenter
    } catch {
        Write-Host "Error while installing Partner Center Module"
        exit
    }
}

Import-Module -Force "$resourcespath\PartnerCenterAuthentication.psm1"
Import-Module -Force "$resourcespath\UserConfiguration.psm1"
Import-Module -Force "$resourcespath\ErrorHandling.psm1"
Import-Module -Force "$resourcespath\PartnerCenterCustomer.psm1"
Import-Module -Force "$resourcespath\FreshServiceManageAssets.psm1"
Import-Module -Force "$resourcespath\FreshServiceManageRelationships.psm1"
Import-Module -Force "$resourcespath\XflexAssetManagement.psm1"
Import-Module -Force "$resourcespath\GetHash.psm1"

"$(Get-Date) [START] script" >> $Global:logFile

$freshServiceItems = Get-NewFreshServiceManageAssets
#$assetTypeList = $freshServiceItems.getFreshServiceItemsAsList("asset_types", $false)
$xflex = Get-XflexAssetManagement

$page = 1
$type = "asset_types"
$items = $freshServiceItems.getFreshServiceItems($type, $page)
do {
    foreach ($entry in $items.asset_types){
        $assetTypeListExtendedProperties += @{$entry.id =  @{
                                "name" = $entry.name
                                "parent_asset_type_id" = $entry.parent_asset_type_id
                                }
                            }
    } 
    $page++
    $items = $freshServiceItems.getFreshServiceItems($type,$page)
} while ($items.asset_types.Count -ne 0)

$freshServiceRelationships = Get-NewFreshServiceManageRelationships

#Look for Dinotronic Managed Services
$results = $assetTypeListExtendedProperties.GetEnumerator() | Where-Object {
    $_.Key -eq 7001249774 -or 
    $_.value.parent_asset_type_id -eq 7001249774 -or 
    $_.value.parent_asset_type_id -eq 7001249908
}

$page = 1
$results.GetEnumerator() | ForEach-Object {
    do {
        $assets = $freshServiceItems.getFreshServiceItemsWithQuery("assets","asset_type_id:{0}" -f $_.Key, $page)
        $services += $assets
        $page++
    } while ($assets.assets.Count -eq 30)
    $page = 1
}
$x = 1

#Update related items with new quantity count and update xflex related contract
$Global:hash = @{}
Foreach ($service in $services.assets){
    "Service $x" >> $Global:logFile
    $freshServiceRelationships.getRelationships($service.display_id)
    "$(Get-Date) " + $Global:hash["$($service.display_id)"] >> $Global:logFile
    $x++
    $quantityTypeFieldName = $freshServiceItems.getQuantityPropertyName($service.type_fields)

    $quantitytable =@{
        asset =@{
            type_fields = @{
                "$($quantityTypeFieldName)" = $Global:hash["$($service.display_id)"]
            } 
        }
    }
    &{$freshServiceItems.updateFreshServiceItem($service.display_id,$quantitytable)} 3>&1 2>&1 >> $Global:logFile

    $artikelnummer = $xflex.getArtikelPropertyName($service.type_fields)
    $vertragsprojekt = $xflex.getProjektPropertyName($service.type_fields)

    try {
        $service.type_fields."$($artikelnummer)" = $xflex.cleanInputString($service.type_fields."$($artikelnummer)")
        $service.type_fields."$($vertragsprojekt)" = $xflex.cleanInputString($service.type_fields."$($vertragsprojekt)")
        $material = $xflex.getMaterials($service.type_fields."$($artikelnummer)")
        $project = $xflex.getProjects($service.type_fields."$($vertragsprojekt)")
        $registration = $xflex.getRegistration($material.MATNR, $project.PRONR)
        #Keep Transaction Status for severe Xflex API errors
        "$(Get-Date) [Xflex API] ===========================" >> $Global:XflexInterfaceLog
        "$(Get-Date) [Xflex API] New Registration processing" >> $Global:XflexInterfaceLog
        "$(Get-Date) [Xflex API] $($service.type_fields."$($artikelnummer)")::$($service.type_fields."$($vertragsprojekt)")" >> $Global:XflexInterfaceLog
        foreach($property in ($registration | Get-Member -ErrorAction Stop | Where-Object MemberType -like "noteproperty")){
            "$(Get-Date) [Xflex API] $($property.name) $($registration."$($property.name)")" >> $Global:XflexInterfaceLog 
        }
        "$(Get-Date) [Xflex API] ===========================" >> $Global:XflexInterfaceLog
        #update xflex via API
        #$xflex.setRegistration($registration, $quantity) and display results
        $response = $xflex.setRegistration($registration, $service.type_fields."$($quantityTypeFieldName)")
        $service | Add-Member -MemberType NoteProperty -Name Response -Value @($response) -Force
        $service | Add-Member -MemberType NoteProperty -Name Registration -Value @($registration) -Force
        $xflex.responseResults.Add($service)
    } catch [System.ArgumentNullException] {
        Write-host $service.name
        $response = [PSCustomObject]::new()
        $response | Add-Member -MemberType noteproperty -Name Content -Value "$($PSitem.Exception)" -force
        $service | Add-Member -MemberType NoteProperty -Name Response -Value @($response) -Force
        $xflex.responseResults.Add($service)
        "$(Get-Date) [Validation] $($service.name):$($service.response) Xflex API Error please check $Global:XflexInterfaceLog for Status" >> $Global:logFile
        Remove-Variable -Name response
        #Get-NewErrorHandling "Xflex API Severe Error" $PSitem
    } catch [System.MissingMemberException] {
        Write-host $service.name
        $response = [PSCustomObject]::new()
        $response | Add-Member -MemberType noteproperty -Name Content -Value "$($PSitem.Exception)" -force
        $service | Add-Member -MemberType NoteProperty -Name Response -Value @($response) -Force
        $xflex.responseResults.Add($service)
        "$(Get-Date) [Validation] $($service.name):$($service.response) Xflex API Error please check $Global:XflexInterfaceLog for Status" >> $Global:logFile
        Remove-Variable -Name response
    } catch [System.IO.IOException] {
        Write-host $service.name
        $response = [PSCustomObject]::new()
        $response | Add-Member -MemberType noteproperty -Name Content -Value "$($PSitem.Exception)" -force
        $service | Add-Member -MemberType NoteProperty -Name Response -Value @($response) -Force
        $xflex.responseResults.Add($service)
        "$(Get-Date) [Validation] $($service.name):$($service.response) Xflex API Error please check $Global:XflexInterfaceLog for Status" >> $Global:logFile
        Remove-Variable -Name response
    } catch {
        "$(Get-Date) [Unknown] $($PSitem.Exception)" >> $Global:logFile
    }
    
}

#Send Xflex response summary
$statusMail = Get-NewErrorHandling "Xflex Summary Simulation"
foreach($entry in $xflex.responseResults){
    $articleNumber = $xflex.getArtikelPropertyName($entry.type_fields)
    $vertragsprojekt = $xflex.getProjektPropertyName($entry.type_fields)
    $quantityTypeFieldName = $freshServiceItems.getQuantityPropertyName($entry.type_fields)

    switch ($entry.Response.Content){
        "System.IO.IOException: Input values are equal"
        {
            $quantityEqual += @("<br>")
            $quantityEqual += @("<li>Name: $($entry.name), Projekt: $($entry.type_fields."$($vertragsprojekt)")</li>")
            $quantityEqual += @("<li>Artikelnummer: $($entry.type_fields."$($articleNumber)")</li>")
            $quantityEqual += @("<li>Quantity: $($entry.type_fields."$($quantityTypeFieldName)")</li>")
            $quantityEqual += @("<li>Registration Status: $($entry.Response.Content)","$($entry.Response.StatusDescription)</li>")
        }
        "System.ArgumentNullException: Value cannot be null."
        {
            $nullOrEmpty += @("<br>")
            $nullOrEmpty += @("<li>Name: $($entry.name), Projekt: $($entry.type_fields."$($vertragsprojekt)")</li>")
            $nullOrEmpty += @("<li>Artikelnummer: $($entry.type_fields."$($articleNumber)")</li>")
            $nullOrEmpty += @("<li>Old Quantity: $($entry.Registration.QTY), New Quantity: $($entry.type_fields."$($quantityTypeFieldName)")</li>")
            $nullOrEmpty += @("<li>Registration Status: $($entry.Response.Content)","$($entry.Response.StatusDescription)</li>")
        }
        "System.MissingMemberException: Wrong material number"
        {
            $wrongMaterialNumber += @("<br>")
            $wrongMaterialNumber += @("<li>Name: $($entry.name), Projekt: $($entry.type_fields."$($vertragsprojekt)")</li>")
            $wrongMaterialNumber += @("<li>Artikelnummer: $($entry.type_fields."$($articleNumber)")</li>")
            $wrongMaterialNumber += @("<li>Old Quantity: $($entry.Registration.QTY), New Quantity: $($entry.type_fields."$($quantityTypeFieldName)")</li>")
            $wrongMaterialNumber += @("<li>Registration Status: $($entry.Response.Content)","$($entry.Response.StatusDescription)</li>")
        }
        "System.MissingMemberException: Wrong project number"
        {
            $wrongProjectNumber += @("<br>")
            $wrongProjectNumber += @("<li>Name: $($entry.name), Projekt: $($entry.type_fields."$($vertragsprojekt)")</li>")
            $wrongProjectNumber += @("<li>Artikelnummer: $($entry.type_fields."$($articleNumber)")</li>")
            $wrongProjectNumber += @("<li>Old Quantity: $($entry.Registration.QTY), New Quantity: $($entry.type_fields."$($quantityTypeFieldName)")</li>")
            $wrongProjectNumber += @("<li>Registration Status: $($entry.Response.Content)","$($entry.Response.StatusDescription)</li>")
        }
        "System.MissingMemberException: No Booking available under this material and project number"
        {
            $noRegistration += @("<br>")
            $noRegistration += @("<li>Name: $($entry.name), Projekt: $($entry.type_fields."$($vertragsprojekt)")</li>")
            $noRegistration += @("<li>Artikelnummer: $($entry.type_fields."$($articleNumber)")</li>")
            $noRegistration += @("<li>Old Quantity: $($entry.Registration.QTY), New Quantity: $($entry.type_fields."$($quantityTypeFieldName)")</li>")
            $noRegistration += @("<li>Registration Status: $($entry.Response.Content)","$($entry.Response.StatusDescription)</li>")
        }
    }
    if ($entry.Response.StatusDescription -eq "OK"){
        $OKregistration += @("<br>")
        $OKregistration += @("<li>Name: $($entry.name), Projekt: $($entry.type_fields."$($vertragsprojekt)")</li>")
        $OKregistration += @("<li>Artikelnummer: $($entry.type_fields."$($articleNumber)")</li>")
        $OKregistration += @("<li>Old Quantity: $($entry.Registration.QTY), New Quantity: $($entry.type_fields."$($quantityTypeFieldName)")</li>")
        $OKregistration += @("<li>Registration Status: $($entry.Response.Content)","$($entry.Response.StatusDescription)</li>")
    }
}
$errorBody += @("<br><h3><u>registration updated</u></h3>")
$errorBody += $OKregistration
$errorBody += @("<br><h3><u>material or project number is empty</u></h3>")
$errorBody += $nullOrEmpty
$errorBody += @("<br><h3><u>wrong material Number</u></h3>")
$errorBody += $wrongMaterialNumber
$errorBody += @("<br><h3><u>wrong project Number</u></h3>")
$errorBody += $wrongProjectNumber
$errorBody += @("<br><h3><u>no registration available</u></h3>")
$errorBody += $noRegistration
$errorBody += @("<h3><u>registration equal</u></h3>")
$errorBody += $quantityEqual

$statusMail.sendMailwithInformMsgContent($errorBody)

#$partnerCenterAuthentication.disconnectPartnerCenter()
"$(Get-Date) [Statistics] .......................::::::::::::::::" >> $Global:logFile
"$(Get-Date) [Statistics] FreshService API Calls  $Global:APICalls" >> $Global:logFile
"$(Get-Date) [Statistics] .......................::::::::::::::::" >> $Global:logFile
"$(Get-Date) [STOP] script" >> $Global:logFile
if ((Get-ChildItem -path $Global:logFile).Length -gt 5242880) {
    Remove-Item -Path $Global:logFile
}
if ((Get-ChildItem -path $Global:XflexInterfaceLog).Length -gt 5242880) {
    Remove-Item -Path $Global:XflexInterfaceLog
}