function Get-NewPartnerCustomer(){
    return [PartnerCenterCustomer]::new()
}

class PartnerCenterCustomer {

    PartnerCenterCustomer(){
        
    }

    [PSCustomObject] getPartnerCenterCustomer(){
        return Get-PartnerCustomer | Sort-Object -Property Name
    }

    [PSCustomObject] getPartnerCenterSubscriptions([PSCustomObject] $partnerCenterCustomer){
        try {
            #Extending customer object with subscriptions
            foreach ($item in $partnerCenterCustomer){
                $subscriptions = @()
                $subscriptions = Get-PartnerCustomerSubscription -CustomerId $item.CustomerId | 
                Select-Object -Property offerId,orderId,offerName,quantity,effectiveStartDate,commitmentEndDate,status,billingCycle |
                Sort-Object -Property offerName
                $item | Add-Member -MemberType NoteProperty -Name SubscriptionsList -Value $subscriptions -Force
            }
            return $partnerCenterCustomer 
        } catch {
           "DT: error with subscription adding: $PSItem" >> $Global:logFile
            return $partnerCenterCustomer
        }   
        return $partnerCenterCustomer 
    }
}