function Get-NewPartnerCenterAuthentication(){
    return [PartnerCenterAuthentication]::new()
}

class PartnerCenterAuthentication {

    #Instanced Properties
    $userConfiguration
    [String] $appsecret
    $partnercenterRefreshToken
    [PSCredential] $appIdCredential
    [String] $refreshTokenXMLFileName = "$Global:resourcespath\${env:USERNAME}_refreshToken.xml"

    PartnerCenterAuthentication (){
        $this.userConfiguration = Get-NewUserConfiguration
    }
    getPartnerCenterConsent(){
        $this.checkRefreshToken()
        }

    connectPartnerCenter(){
        try {
            $pcToken = New-PartnerAccessToken -RefreshToken $this.partnercenterRefreshToken.RefreshToken `
            -Resource "https://api.partnercenter.microsoft.com" `
            -Credential $this.userConfiguration.webPartnerCenterCredentials `
            -TenantId $this.userConfiguration.tenantId

            Connect-PartnerCenter `
            -verbose `
            -AccessToken $pctoken.AccessToken `
            -ApplicationId $this.userConfiguration.nativePartnerCenterAppId `
            -TenantId $this.userConfiguration.tenantId
        } catch {
            "DT: Issue connecting CSP Data: $PSItem" >> $Global:logFile
            #Get-NewErrorHandling "DT: Issue connection CSP Data" $PSItem
        }
        
    }
    checkRefreshToken(){
        try {
            if ((Test-Path $this.refreshTokenXMLFileName)) {
                $this.partnercenterRefreshToken = Import-Clixml -Path $this.refreshTokenXMLFileName
            } else {
                $this.partnercenterRefreshToken = New-PartnerAccessToken -Consent `
                -Credential $this.userConfiguration.webPartnerCenterCredentials `
                -Resource "https://api.partnercenter.microsoft.com" `
                -TenantId $this.userConfiguration.tenantId
                $this.partnercenterRefreshToken | Export-Clixml -Path $this.refreshTokenXMLFileName
            }
        } catch {
            "DT: Issue creating or getting the RefreshToken CSP Data: $PSItem" >> $Global:logFile
            #Get-NewErrorHandling "DT: Issue creating or getting the RefreshToken CSP Data" $PSItem
        }
        
    }

    disconnectPartnerCenter (){
        Write-Host "i just got triggered"
        Disconnect-PartnerCenter -Verbose -Debug
    }

}