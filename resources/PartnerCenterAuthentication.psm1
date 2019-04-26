function Get-NewPartnerCenterAuthentication(){
    return [PartnerCenterAuthentication]::new()
}

class PartnerCenterAuthentication {

    #Instanced Properties
    #TODO Save Refreshtoken in XML File and Import File
    #TODO Optional Check expiration date of Refreshtoken and restart file creation if expired, Send-Mail to helpdesk to refresh token
    $userConfiguration
    [String] $appsecret
    $partnerCentertokeninclRefresh
    [PSCredential] $appIdCredential

    PartnerCenterAuthentication (){
        $this.userConfiguration = Get-NewUserConfiguration
    }
    getPartnerCenterConsent(){
        $this.partnerCentertokeninclRefresh = New-PartnerAccessToken `
        -Consent `
        -Credential $this.userConfiguration.webPartnerCenterCredentials `
        -Resource "https://api.partnercenter.microsoft.com" `
        -TenantId $this.userConfiguration.tenantId `
        }

    connectPartnerCenter(){
        $pcToken = New-PartnerAccessToken -RefreshToken $this.partnerCentertokeninclRefresh.RefreshToken `
        -Resource "https://api.partnercenter.microsoft.com" `
        -Credential $this.userConfiguration.webPartnerCenterCredentials `
        -TenantId $this.userConfiguration.tenantId `

        Connect-PartnerCenter `
        -verbose `
        -AccessToken $pctoken.AccessToken `
        -ApplicationId $this.userConfiguration.nativePartnerCenterAppId `
        -TenantId $this.userConfiguration.tenantId `
    }

    disconnectPartnerCenter (){
        Disconnect-PartnerCenter -Verbose
    }

}