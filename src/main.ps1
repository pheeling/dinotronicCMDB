$Global:srcPath = split-path -path $MyInvocation.MyCommand.Definition 
$Global:mainPath = split-path -path $srcPath
$Global:resourcespath = join-path -path "$mainPath" -ChildPath "resources"
$Global:errorVariable = "Stop"

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
    write-host $customer.name
    write-host $customer.customerid
    $departmentId = $departmentsList.Keys | Where-Object { $departmentsList[$_] -eq "$($customer.name)" }

    foreach ($offer in $customer.syncroot){

        if(!($offer.orderId)){
            $offer.orderId = $hash.getHashValue("$($customer.name)$($departmentId)$($offer.EffectiveStartDate)$($offer.CommitmentEndDate)")
        }

        $freshServiceMatch = $assetsList.Keys | Where-Object { 
            $assetsList.$_.orderId -eq "$($offer.orderId)" -and 
            $assetsList.$_.offerId -eq "$($offer.offerId)" -and
            $assetsList.$_.companyName -eq $customer.name       
        }
        Write-Host $offer.OfferName
        Write-Host $offer.orderId
        Write-Host $departmentId

        if([string]::IsNullOrEmpty($departmentId)){
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
        } else {
            $valuestable =@{
                asset =@{
                    name ="$($offer.OfferName)"
                    asset_type_id = $freshServiceCiTypeId
                    department_id = $departmentId
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
        }
        if($offer.status -eq "deleted" -and $freshServiceMatch){
            $freshServiceItems.deleteFreshServiceItem($assetsList.$freshServiceMatch.displayId)
        } elseif ($offer.status -ne "deleted" -and $freshServiceMatch){
            $freshServiceItems.updateFreshServiceItem($assetsList.$freshServiceMatch.displayId,$valuestable)
        } elseif ($offer.status -ne "deleted") {
            $freshServiceItems.createFreshServiceItem($valuestable)
        }
    }
}

$partnerCenterAuthentication.disconnectPartnerCenter()