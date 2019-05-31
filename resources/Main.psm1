function Get-NewMain(){
        return [Main]::new()
}

class Main {
    $partnerCenterAuthentication

    Main(){
        $this.partnerCenterAuthentication = Get-NewPartnerCenterAuthentication
        $this.partnerCenterAuthentication.getPartnerCenterConsent()
        $this.partnerCenterAuthentication.connectPartnerCenter()
    }

    stop(){
        $this.partnerCenterAuthentication.disconnectPartnerCenter()
    }

}

