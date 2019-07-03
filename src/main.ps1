$Global:srcPath = split-path -path $MyInvocation.MyCommand.Definition 
$Global:mainPath = split-path -path $srcPath
$Global:resourcespath = join-path -path "$mainPath" -ChildPath "resources"
$Global:errorVariable = "Stop"
$Global:logFile = "$resourcespath\processing.log"

#Requirementcheck PartnerCenter Module
if (!(Get-Module -ListAvailable -Name PartnerCenter)) {
    Install-Module -Name PartnerCenter
}

Import-Module -Force "$resourcespath\PartnerCenterAuthentication.psm1"
Import-Module -Force "$resourcespath\UserConfiguration.psm1"
Import-Module -Force "$resourcespath\ErrorHandling.psm1"
Import-Module -Force "$resourcespath\PartnerCenterCustomer.psm1"
Import-Module -Force "$resourcespath\FreshServiceManageAssets.psm1"
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

foreach ($customer in $partnerCenterCustomerList){
    $index = 0
    # "$(Get-Date) [Customer Processing] Start--------------------------" >> $Global:logFile
    # "$(Get-Date) [Customer Processing] Customername: $($customer.name)" >> $Global:logFile
    # "$(Get-Date) [Customer Processing] CustomerID: $($customer.customerid)" >> $Global:logFile
    $departmentId = $departmentsList.Keys | Where-Object { $departmentsList[$_] -eq "$($customer.name)" }

    foreach ($offer in $customer.SubscriptionsList){
        $index++
        # "$(Get-Date) [Offer Processing] Start--------------------------" >> $Global:logFile
        # "$(Get-Date) [Offer Processing] OfferName: $($offer.OfferName)" >> $Global:logFile
        # "$(Get-Date) [Offer Processing] OrderID: $($offer.orderId)" >> $Global:logFile
        # "$(Get-Date) [Offer Processing] DepartmentID: $($departmentId)" >> $Global:logFile

        if(!($offer.orderId)){
            $offer.orderId = $hash.getHashValue("$($index)$($departmentId)$($offer.EffectiveStartDate)$($offer.CommitmentEndDate)")
            # "$(Get-Date) [Offer Processing] replaced offer.orderid" >> $Global:logFile
            # "$(Get-Date) [Offer Processing] new OrderID: $($offer.orderId)" >> $Global:logFile
        }

        $freshServiceMatch = $assetsList.Keys | Where-Object { 
            $assetsList.$_.orderId -eq "$($offer.orderId)" -and 
            $assetsList.$_.offerId -eq "$($offer.offerId)" -and
            $assetsList.$_.companyName -eq $customer.name       
        }

        $valuestable =@{
            asset =@{
                name ="$($offer.OfferName)"
                asset_type_id = $freshServiceCiTypeId
                type_fields = @{
                    status_7001248569 = "$($offer.status)"
                    offerid_7001248569 = "$($offer.offerId)"
                    orderid_7001248569 = "$($offer.orderId)"
                    companyname_7001248569 = "$($customer.name)"
                    offername_7001248569 = "$($offer.OfferName)"
                    quantity_7001248569 = $offer.Quantity
                    #unitprice_7001248569 = "$($unitPrice)"
                    billingcycle_7001248569 = "$($offer.billingCycle)"
                    effectivestartdate_7001248569 = $offer.EffectiveStartDate.ToString("o")
                    commitmentenddate_7001248569 = $offer.CommitmentEndDate.ToString("o")
                } 
            }
        }

        if([string]::IsNullOrEmpty($departmentId)){
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

$partnerCenterAuthentication.disconnectPartnerCenter()
"$(Get-Date) [STOP] script" >> $Global:logFile