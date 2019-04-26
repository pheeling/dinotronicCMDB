function Get-NewMain(){
        return [Main]::new()
}

class Main {

    Main(){
        $partnerCenterAuthentication = Get-NewPartnerCenterAuthentication
        $partnerCenterAuthentication.getPartnerCenterConsent()
        $partnerCenterAuthentication.connectPartnerCenter()

        Get-Command -Module PartnerCenter -Name "*Customer*"

        $output = Get-PartnerCustomer
        $output

        $partnerCenterAuthentication.disconnectPartnerCenter()
    }

}

