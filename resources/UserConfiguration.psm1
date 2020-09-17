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
    [pscredential] $xflexLoginData
    [pscredential] $xflexCustomerId
    [String] $webPartnerCenterAppXMLFileName = "$Global:resourcespath\${env:USERNAME}_webPartnerCenterApp.xml"
    [String] $tenantAndNativeAppXMLFileName = "$Global:resourcespath\${env:USERNAME}_TenantandNativeAppId.xml"
    [String] $xflexAuthenticationXMLFileName = "$Global:resourcespath\${env:USERNAME}_XflexAuthenticationXML.xml"
    [String] $xflexCustomerIdXMLFileName = "$Global:resourcespath\${env:USERNAME}_XflexCustomerIdXML.xml"

    static [UserConfiguration] GetInstance() {
        if ([UserConfiguration]::instance -eq $null) { [UserConfiguration]::instance = [UserConfiguration]::new() }
          return [UserConfiguration]::instance
    }

    #Order of password and key generation:
    # 1. TenantID and Native Partner Center ID
    # 2. WebPartnerApp ID and Secret key
    # 3. FreshService Credential X:<APIKey>
    # 4. Xflex Username and Password
    # 5. Xflex Customer ID, password field not used
    UserConfiguration(){
        if ((Test-Path $this.webPartnerCenterAppXMLFileName) -and 
            (Test-Path $this.tenantAndNativeAppXMLFileName) -and 
            (Test-Path $this.freshServiceAPIKeyXMLFileName) -and
            (Test-Path $this.xflexAuthenticationXMLFilename) -and
            (Test-Path $this.xflexCustomerIdXMLFileName)) {
            $this.tenantId = $this.getTenantandNativePCAppId().tenantId
            $this.nativePartnerCenterAppId = $this.getTenantandNativePCAppId().nativePartnerCenterAppId
            $this.webPartnerCenterCredentials = $this.importXMLDataAsPsCredential($this.webPartnerCenterAppXMLFileName)
            $this.freshServiceAPIKey = $this.getFreshServiceCredential().GetNetworkCredential().Password
            $this.xflexLoginData = $this.importXMLDataAsPsCredential($this.xflexAuthenticationXMLFileName)
            $this.xflexCustomerId = $this.importXMLDataAsPsCredential($this.xflexCustomerIdXMLFileName)
        }
        else {
            $this.setTenantandNativePCAppId()
            $this.setXMLDataAsFiles($this.webPartnerCenterAppXMLFileName)
            $this.setFreshServiceCredential()
            $this.setXMLDataAsFiles($this.xflexAuthenticationXMLFileName)
            $this.setXMLDataAsFiles($this.xflexCustomerIdXMLFileName)
            $this.tenantId = $this.getTenantandNativePCAppId().tenantId
            $this.nativePartnerCenterAppId = $this.getTenantandNativePCAppId().nativePartnerCenterAppId
            $this.webPartnerCenterCredentials = $this.importXMLDataAsPsCredential($this.webPartnerCenterAppXMLFileName)
            $this.freshServiceAPIKey = $this.getFreshServiceCredential().GetNetworkCredential().Password
            $this.xflexLoginData = $this.importXMLDataAsPsCredential($this.xflexAuthenticationXMLFileName)
            $this.xflexCustomerId = $this.importXMLDataAsPsCredential($this.xflexCustomerIdXMLFileName)
        }
    }

    [PSCredential] importXMLDataAsPsCredential($XMLFileName){
        return Import-Clixml $XMLFileName
    }

    setXMLDataAsFiles($XMLFileName){
        Get-Credential | Export-Clixml -Path $XMLFileName
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