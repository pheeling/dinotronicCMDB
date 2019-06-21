#TODO Abstract Class Assets, Classdiagramm update

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

foreach ($customer in $partnerCenterCustomerList){
    write-host $customer.name
    write-host $customer.customerid
    $departmentId = $departmentsList.Keys | Where-Object { $departmentsList[$_] -eq "$($customer.name)" }

    foreach ($offer in $customer.syncroot){

        $freshServiceMatch = $assetsList.Keys | Where-Object { 
            #TODO Verification if delete or update job updates the right object
            #$assetsList.$_.orderId -eq "$($offer.orderId)" -and 
            $assetsList.$_.offerId -eq "$($offer.offerId)" -and
            $assetsList.$_.companyName -eq $customer.name       
        }
        Write-Host $offer
        Write-Host $departmentId

        if($null -eq $offer.orderId){
            $valuestable =@{
                asset =@{
                    name ="$($offer.OfferName)"
                    asset_type_id = $freshServiceCiTypeId
                    department_id = $departmentId
                    type_fields = @{
                        status_7001248569 = "$($offer.status)"
                        offerid_7001248569 = "$($offer.offerId)"
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
        

        #TODO Check Update and delete function not match with FreshServiceMatch
        #TODO OfferId is not unique in combination with Name. Have to check orderId
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