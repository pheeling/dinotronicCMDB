function Get-XflexAssetManagement(){
    return [XflexAssetManagement]::new()
}

class XflexAssetManagement {

    $userconfiguration
    [Hashtable] $authentication
    [Array] $responseResults

    XflexAssetManagement (){
        $this.userConfiguration = Get-NewUserConfiguration
    }

    [Hashtable] getLoginData(){       
        return $this.authentication = @{
                    ACCDAT = @{
                        CID = $this.userconfiguration.xflexCustomerId.GetNetworkCredential().UserName
                        UID = $this.userconfiguration.xflexLoginData.GetNetworkCredential().UserName
                        UPW = $this.userconfiguration.xflexLoginData.GetNetworkCredential().Password
                    }
                }
    }

    [PSCustomObject] convertContentToObject($response){
        return $response.Content | ConvertFrom-Json
    }

    [PSCustomObject] getMaterials([String] $materialnumber){
        $url = "https://rest.xflex.ch/api/matread"
        $body = $this.getLoginData()
        $body.MATINR = $materialnumber
        $bodyJson = $body | ConvertTo-Json
        return $this.convertContentToObject((Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json" -Method "POST"))
    }

    [PSCustomObject] getProjects([String] $projectNumber){
        $url = "https://rest.xflex.ch/api/project"
        $body = $this.getLoginData()
        $body.PROINR = $projectNumber
        $bodyJson = $body | ConvertTo-Json
        return $this.convertContentToObject((Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json" -Method "POST"))
    }

    [PSCustomObject] getRegistration([String] $internalMaterialNumber, [String]$internalProjectNumber){
        $url = "https://rest.xflex.ch/api/regread"
        $body = $this.getLoginData()
        $body.MATNR = $internalMaterialNumber
        $body.PRONR = $internalProjectNumber
        $bodyJson = $body | ConvertTo-Json
        return $this.convertContentToObject((Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json" -Method "POST"))
    }

    [PSCustomObject] setRegistration([PSCustomObject] $registration, [int] $quantity){
        $url = "https://rest.xflex.ch/api/regadd"
        $body = $this.getLoginData()
        $body.REG = @{}
        foreach($property in ($registration | Get-Member | Where-Object MemberType -like "noteproperty")){
                $body.REG."$($property.name)" = $registration."$($property.name)"  
        }
        $body.REG.qty = $quantity
        $bodyJson = $body | ConvertTo-Json
        $response = Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json" -Method "POST"
        "$(Get-Date) [Xflex Update] Registration $($response.content) :: Update Status: $($response.StatusDescription)" >> $Global:logFile
        return $response
        #return $this.convertContentToObject((Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json" -Method "POST"))
    }

}