function Get-NewPartnerCustomer(){
    return [PartnerCenterCustomer]::new()
}

class PartnerCenterCustomer {

    PartnerCenterCustomer(){
        
    }

    [PSCustomObject] getPartnerCenterCustomer(){
        return Get-PartnerCustomer | Sort-Object #-Property Name
    }

    [PSCustomObject] getPartnerCenterSubscriptions([PSCustomObject] $partnerCenterCustomer){
            #Extending customer object with subscriptions
            foreach ($item in $partnerCenterCustomer){
                $subscriptions = @()
                try {
                    $subscriptions = Get-PartnerCustomerSubscription -CustomerId $item.CustomerId | 
                    Select-Object -Property offerId,SubscriptionId,offerName,quantity,effectiveStartDate,commitmentEndDate,status,billingCycle |
                    Sort-Object -Property offerName
                    $item | Add-Member -MemberType NoteProperty -Name SubscriptionsList -Value $subscriptions -Force
                    "$(Get-Date) [PartnerCenter] Adding Subscriptions to Customer" >> $Global:logFile
                } catch {
                    "DT: Issue adding Subscription: $($PSItem) : $($item.customerid): $($item.name)" >> $Global:logFile
                }
            }   
        return $partnerCenterCustomer 
    }
}