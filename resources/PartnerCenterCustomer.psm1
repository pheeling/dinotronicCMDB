function Get-NewPartnerCustomer(){
    return [PartnerCenterCustomer]::new()
}

class PartnerCenterCustomer {

    PartnerCenterCustomer(){
        
    }

    [PSCustomObject] getPartnerCenterCustomer(){
        return Get-PartnerCustomer
    }

    [PSCustomObject] getPartnerCenterSubscriptions([PSCustomObject] $partnerCenterCustomer){
        #Extending customer object with subscriptions
        foreach ($item in $partnerCenterCustomer){
            $subscriptions = Get-PartnerCustomerSubscription -CustomerId $item.CustomerId | 
            Select-Object -Property offerId,orderId,offerName,quantity,effectiveStartDate,commitmentEndDate,status,billingCycle
            $properties = Get-Member -InputObject $subscriptions -MemberType Property
            foreach ($p in $properties)
            {
                $item | Add-Member -MemberType NoteProperty -Name $p.Name -Value $subscriptions.$($p.Name) -Force
            }
        }
        return $partnerCenterCustomer
    }
}