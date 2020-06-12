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

$partnerCenterAuthentication = Get-NewPartnerCenterAuthentication
$partnerCenterAuthentication.getPartnerCenterConsent()
$partnerCenterAuthentication.connectPartnerCenter()
$partnerCenterCustomer = Get-NewPartnerCustomer
$partnerCenterCustomerList = $partnerCenterCustomer.getPartnerCenterCustomer()
$partnerCenterCustomer.getPartnerCenterSubscriptions($partnerCenterCustomerList)
$freshServiceItems = Get-NewFreshServiceManageAssets
$assetTypeList = $freshServiceItems.getFreshServiceItemsAsList("asset_types", $false)
$departmentsList = $freshServiceItems.getFreshServiceItemsAsList("departments", $false)
$assetsList = $freshServiceItems.getFreshServiceItemsAsList("assets", $true)
$freshServiceCiTypeId = $assetTypeList.Keys | Where-Object { $assetTypeList[$_] -eq 'Azure / Office 365 Subscription' }
$hash = Get-NewGetHash
$xflex = Get-XflexAssetManagement

foreach ($customer in $partnerCenterCustomerList){
    $index = 0
    # "$(Get-Date) [Customer Processing] Start--------------------------" >> $Global:logFile
    # "$(Get-Date) [Customer Processing] Customername: $($customer.name)" >> $Global:logFile
    # "$(Get-Date) [Customer Processing] CustomerID: $($customer.customerid)" >> $Global:logFile
    $departmentId = $departmentsList.Keys | Where-Object { $departmentsList[$_] -like "*$($customer.name)*" }

    foreach ($offer in $customer.SubscriptionsList){
        $index++
        # "$(Get-Date) [Offer Processing] Start--------------------------" >> $Global:logFile
        # "$(Get-Date) [Offer Processing] OfferName: $($offer.OfferName)" >> $Global:logFile
        # "$(Get-Date) [Offer Processing] OrderID: $($offer.orderId)" >> $Global:logFile
        # "$(Get-Date) [Offer Processing] DepartmentID: $($departmentId)" >> $Global:logFile

        $freshServiceMatch = $assetsList.Keys | Where-Object { 
            $assetsList.$_.orderId -eq "$($offer.SubscriptionId)" -and 
            $assetsList.$_.offerId -eq "$($offer.offerId)" -and
            $assetsList.$_.companyName -like "*$($customer.name)*" -and
            $assetsList.$_.domain -eq "$($customer.domain)"
        }
        
        $valuestable =@{
            asset =@{
                name ="$($offer.OfferName)"
                asset_type_id = $freshServiceCiTypeId
                type_fields = @{
                    status_7001248569 = "$($offer.status)"
                    offerid_7001248569 = "$($offer.offerId)"
                    orderid_7001248569 = "$($offer.SubscriptionId)"
                    companyname_7001248569 = "$($customer.name)"
                    offername_7001248569 = "$($offer.OfferName)"
                    domain_7001248569 = "$($customer.domain)"
                    quantity_7001248569 = $offer.Quantity
                    #unitprice_7001248569 = "$($unitPrice)"
                    billingcycle_7001248569 = "$($offer.billingCycle)"
                    effectivestartdate_7001248569 = $offer.EffectiveStartDate.ToString("o")
                    commitmentenddate_7001248569 = $offer.CommitmentEndDate.ToString("o")
                } 
            }
        }

        if((-not [string]::IsNullOrEmpty($departmentId)) -and ($departmentId -isnot [array])){
            $valuestable.asset.department_id = $departmentId
        }

        if($offer.status -eq "deleted" -and $freshServiceMatch){
            &{$freshServiceItems.deleteFreshServiceItem($assetsList.$freshServiceMatch.displayId)} 3>&1 2>&1 >> $Global:logFile
            # "$(Get-Date) [Freshservice Delete] $($offer.status): $($offer.orderId): $($offer.OfferName): $($customer.Name)" >> $Global:logFile
        } elseif ($offer.status -ne "deleted" -and $freshServiceMatch){
            &{$freshServiceItems.updateFreshServiceItem($assetsList.$freshServiceMatch.displayId,$valuestable)} 3>&1 2>&1 >> $Global:logFile
            # "$(Get-Date) [Freshservice Update] $($offer.status): $($offer.orderId): $($offer.OfferName): $($customer.Name)" >> $Global:logFile
        } elseif ($offer.status -ne "deleted") {
            &{$freshServiceItems.createFreshServiceItem($valuestable)} 3>&1 2>&1 >> $Global:logFile
            # "$(Get-Date) [Freshservice Created] $($offer.status): $($offer.orderId): $($offer.OfferName): $($customer.Name)" >> $Global:logFile
        } else {
            # "$(Get-Date) [Freshservice uncertain action] $($offer.status): $($offer.orderId): $($offer.OfferName): $($customer.Name)" >> $Global:logFile
        }
        # "$(Get-Date) [Offer Processing] Stop--------------------------" >> $Global:logFile
    }
    # "$(Get-Date) [Customer Processing] Stop--------------------------" >> $Global:logFile
}

#Get All Related Services
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

#Update related items with new quantity count and update xflex related contract
$x = 1
$Global:hash = @{}
Foreach ($service in $services.assets){
    "Service $x" >> $Global:logFile
    $freshServiceRelationships.getRelationships($service.display_id)
    "$(Get-Date) " + $Global:hash["$($service.display_id)"] >> $Global:logFile
    $x++
    $quantityTypeFieldName = $service.type_fields | Get-Member -MemberType NoteProperty | ForEach-Object {
        if($_.Name -like "quantity*"){$_.Name}
    }
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
        if ((-not [string]::IsNullOrEmpty($service.type_fields."$($artikelnummer)")) -and 
            ($service.type_fields."$($artikelnummer)" -isnot [array]) -and
            (-not [string]::IsNullOrEmpty($service.type_fields."$($vertragsprojekt)")) -and 
            ($service.type_fields."$($vertragsprojekt)" -isnot [array]))
            {

            $service.type_fields."$($artikelnummer)" = $xflex.cleanInputString($service.type_fields."$($artikelnummer)")
            $service.type_fields."$($vertragsprojekt)" = $xflex.cleanInputString($service.type_fields."$($vertragsprojekt)")

            $material = $xflex.getMaterials($service.type_fields."$($artikelnummer)")
            $project = $xflex.getProjects($service.type_fields."$($vertragsprojekt)")
            $registration = $xflex.getRegistration($material.MATNR, $project.PRONR)

            #Keep Transaction Status for severe Xflex API errors
            "$(Get-Date) [Xflex API] ===========================" >> $Global:XflexInterfaceLog
            "$(Get-Date) [Xflex API] New Registration processing" >> $Global:XflexInterfaceLog
            foreach($property in ($registration | Get-Member -ErrorAction Stop | Where-Object MemberType -like "noteproperty")){
                "$(Get-Date) [Xflex API] $($property.name) $($registration."$($property.name)")" >> $Global:XflexInterfaceLog 
            }
            "$(Get-Date) [Xflex API] ===========================" >> $Global:XflexInterfaceLog
        } else {
            #Keep Transaction Status for severe Xflex API errors
            "$(Get-Date) [Xflex API] ===========================" >> $Global:XflexInterfaceLog
            "$(Get-Date) [Xflex API] New Registration processing" >> $Global:XflexInterfaceLog
            "$(Get-Date) [Xflex API] $($service.name) has no artikel or projektnummer" >> $Global:XflexInterfaceLog
        }

        #update xflex via API
        #$xflex.setRegistration($registration, $quantity) and display results
        #$response = $xflex.setRegistration($registration, $service.type_fields."$($quantityTypeFieldName)")
        $service | Add-Member -MemberType NoteProperty -Name Response -Value @($response) -Force
        $service | Add-Member -MemberType NoteProperty -Name Registration -Value @($registration) -Force
        $xflex.responseResults += @($service)
    } catch {
        "$(Get-Date) [Unknown] $($service.name) Xflex API Error please check $Global:XflexInterfaceLog for Status" >> $Global:logFile
        Write-host $service.name
        $response = [PSCustomObject]::new
        $response | Add-Member -MemberType noteproperty -Name Content -Value "Bitte Artikel und Projektzuweisung aktualisieren" -force
        $service | Add-Member -MemberType NoteProperty -Name Response -Value @($response) -Force
        $xflex.responseResults += @($service)
        $response = $null
        #Get-NewErrorHandling "Xflex API Severe Error" $PSitem
    }
}

#Send Xflex response summary
$statusMail = Get-NewErrorHandling "Xflex Summary Simulation"
foreach($entry in $xflex.responseResults){
    $artikelnummer = $xflex.getArtikelPropertyName($entry.type_fields)
    $vertragsprojekt = $xflex.getProjektPropertyName($entry.type_fields)
    $errorBody += @("<li>--------</li>")
    $errorBody += @("<li>Name: $($entry.name), Projekt: $($entry.type_fields."$($vertragsprojekt)")</li>")
    $errorBody += @("<li>Artikelnummer: $($entry.type_fields."$($artikelnummer)")</li>")
    $errorBody += @("<li>Old Quantity: $($entry.Registration.QTY), New Quantity: $($entry.type_fields."$($quantityTypeFieldName)")</li>")
    $errorBody += @("<li>Registration Status: $($entry.Response.Content)","$($entry.Response.StatusDescription)</li>")
}
$statusMail.sendMailwithInformMsgContent($errorBody)

$partnerCenterAuthentication.disconnectPartnerCenter()
"$(Get-Date) [Statistics] .......................::::::::::::::::" >> $Global:logFile
"$(Get-Date) [Statistics] FreshService API Calls  $Global:APICalls" >> $Global:logFile
"$(Get-Date) [Statistics] .......................::::::::::::::::" >> $Global:logFile
"$(Get-Date) [STOP] script" >> $Global:logFile
if ((Get-ChildItem -path $logfile).Length -gt 5242880) {
    Remove-Item -Path $Global:logFile
}