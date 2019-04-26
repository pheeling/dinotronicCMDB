function Get-NewUserConfiguration(){
        return [UserConfiguration]::new()
}

class UserConfiguration {
    
    # Instanced Property
    [String] $freshServiceUserName = ""
    [string] $freshServicePassword = ""
    [String] $nativePartnerCenterAppId = ""
    [String] $tenantId = ""
    [pscredential] $webPartnerCenterCredentials
    [String] $webPartnerCenterAppXMLFileName = "$Global:resourcespath\${env:USERNAME}_webPartnerCenterApp.xml"

    UserConfiguration(){
        if ((Test-Path "$Global:resourcespath\${env:USERNAME}_webPartnerCenterApp.xml") -and (Test-Path "$Global:resourcespath\${env:USERNAME}_TenantandNativeAppId.xml")) {
            $this.tenantId = $this.getTenantandNativePCAppId().tenantId
            $this.nativePartnerCenterAppId = $this.getTenantandNativePCAppId().nativePartnerCenterAppId
            $this.webPartnerCenterCredentials = $this.getWebPartnerCenterAppIdAndSecretKey()
        }
        else {
            $this.setTenantandNativePCAppId()
            $this.setWebPartnerCenterAppCredential()
            $this.tenantId = $this.getTenantandNativePCAppId().tenantId
            $this.nativePartnerCenterAppId = $this.getTenantandNativePCAppId().nativePartnerCenterAppId
            $this.webPartnerCenterCredentials = $this.getWebPartnerCenterAppIdAndSecretKey()
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
        $tenantNativeIdFile | Export-Clixml -Path "$Global:resourcespath\${env:USERNAME}_TenantandNativeAppId.xml"
    }

    [PSobject] getTenantandNativePCAppId(){
        return Import-Clixml "$Global:resourcespath\${env:USERNAME}_TenantandNativeAppId.xml"
    }
}