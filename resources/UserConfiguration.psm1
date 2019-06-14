function Get-NewUserConfiguration(){
        return [UserConfiguration]::GetInstance()
}

class UserConfiguration {
    
    # Instanced Property
    static [UserConfiguration] $instance
    [string] $freshServiceAPIKey = ""
    [String] $freshServiceAPIKeyXMLFileName = "$Global:resourcespath\${env:USERNAME}_freshServiceAPIKey.xml"
    [String] $nativePartnerCenterAppId = ""
    [String] $tenantId = ""
    [pscredential] $webPartnerCenterCredentials
    [String] $webPartnerCenterAppXMLFileName = "$Global:resourcespath\${env:USERNAME}_webPartnerCenterApp.xml"
    [String] $tenantAndNativeAppXMLFileName = "$Global:resourcespath\${env:USERNAME}_TenantandNativeAppId.xml"

    static [UserConfiguration] GetInstance() {
        if ([UserConfiguration]::instance -eq $null) { [UserConfiguration]::instance = [UserConfiguration]::new() }
          return [UserConfiguration]::instance
    }

    UserConfiguration(){
        if ((Test-Path $this.webPartnerCenterAppXMLFileName) -and 
            (Test-Path $this.tenantAndNativeAppXMLFileName) -and 
            (Test-Path $this.freshServiceAPIKeyXMLFileName)) {
            $this.tenantId = $this.getTenantandNativePCAppId().tenantId
            $this.nativePartnerCenterAppId = $this.getTenantandNativePCAppId().nativePartnerCenterAppId
            $this.webPartnerCenterCredentials = $this.getWebPartnerCenterAppIdAndSecretKey()
            $this.freshServiceAPIKey = $this.getFreshServiceCredential().GetNetworkCredential().Password
        }
        else {
            $this.setTenantandNativePCAppId()
            $this.setWebPartnerCenterAppCredential()
            $this.setFreshServiceCredential()
            $this.tenantId = $this.getTenantandNativePCAppId().tenantId
            $this.nativePartnerCenterAppId = $this.getTenantandNativePCAppId().nativePartnerCenterAppId
            $this.webPartnerCenterCredentials = $this.getWebPartnerCenterAppIdAndSecretKey()
            $this.freshServiceAPIKey = $this.getFreshServiceCredential().GetNetworkCredential().Password
        }
    }

    [PSCredential] getWebPartnerCenterAppIdAndSecretKey(){
        return Import-Clixml $this.webPartnerCenterAppXMLFileName
    }

    setWebPartnerCenterAppCredential(){
        Get-Credential | Export-Clixml -Path $this.webPartnerCenterAppXMLFileName
    }

    setTenantandNativePCAppId(){
        $tenantNativeIdFile = @([PSCustomObject]@{
            tenantId = Read-Host -Prompt "Provide Tenant-ID:";
            nativePartnerCenterAppId = Read-Host -Prompt "Provide Native Partner Center App Id:"
        })
        $tenantNativeIdFile | Export-Clixml -Path $this.tenantAndNativeAppXMLFileName
    }

    [PSobject] getTenantandNativePCAppId(){
        return Import-Clixml $this.tenantAndNativeAppXMLFileName
    }

    setFreshServiceCredential(){
        Get-Credential | Export-Clixml -Path $this.freshServiceAPIKeyXMLFileName
    }

    [PSobject] getFreshServiceCredential(){
        return Import-Clixml $this.freshServiceAPIKeyXMLFileName
    }
}