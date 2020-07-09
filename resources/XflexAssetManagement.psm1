function Get-XflexAssetManagement(){
    return [XflexAssetManagement]::new()
}

class XflexAssetManagement {

    $userconfiguration
    [Hashtable] $authentication
    $responseResults = [System.Collections.ArrayList]::New()

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
        $this.validation($response)
        return $response.Content | ConvertFrom-Json
    }

    [PSCustomObject] getMaterials([String] $materialnumber){
        $url = "https://rest.xflex.ch/api/matread"
        $this.validation($materialNumber)
        $body = $this.getLoginData()
        $body.MATINR = $materialnumber
        $bodyJson = $body | ConvertTo-Json
        return $this.convertContentToObject((Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json" -Method "POST"))
    }

    [PSCustomObject] getProjects([String] $projectNumber){
        $url = "https://rest.xflex.ch/api/project"
        $this.validation($projectNumber)
        $body = $this.getLoginData()
        $body.PROINR = $projectNumber
        $bodyJson = $body | ConvertTo-Json
        return $this.convertContentToObject((Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json" -Method "POST"))
    }

    [PSCustomObject] getRegistration([String] $internalMaterialNumber, [String]$internalProjectNumber){
        $url = "https://rest.xflex.ch/api/regread"
        $this.validation($internalMaterialNumber)
        $this.validation($internalProjectNumber)
        $body = $this.getLoginData()
        $body.MATNR = $internalMaterialNumber
        $body.PRONR = $internalProjectNumber
        $bodyJson = $body | ConvertTo-Json
        return $this.convertContentToObject((Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json" -Method "POST"))
    }

    [PSCustomObject] setRegistration([PSCustomObject] $registration, [int] $quantity){
        $url = "https://rest.xflex.ch/api/regadd"
        #$this.validation($registration)
        $this.validation($quantity)
        $this.validation([math]::Truncate("$($registration.QTY)"),$quantity)
        $body = $this.getLoginData()
        $body.REG = @{}
        foreach($property in ($registration | Get-Member | Where-Object MemberType -like "noteproperty")){
                $body.REG."$($property.name)" = $registration."$($property.name)"  
        }
        $body.REG.qty = $quantity
        $bodyJson = $body | ConvertTo-Json
        #TODO Nullreference Error beim Testen
        $response = Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json; charset=utf-8" -Method "POST"
        "$(Get-Date) [Xflex Update] Registration $($response.content) :: Update Status: $($response.StatusDescription)" >> $Global:logFile
        return $response
        #return $this.convertContentToObject((Invoke-WebRequest -Uri $url -Body $bodyJson -ContentType "application/json" -Method "POST"))
    }

    [String] getArtikelPropertyName($string){
        return $string | Get-Member -MemberType NoteProperty | ForEach-Object {
            if($_.Name -like "xflex_artikelnummer*"){$_.Name}}
    }

    [String] getProjektPropertyName($string){
        return $string | Get-Member -MemberType NoteProperty | ForEach-Object {
            if($_.Name -like "xflex_vertragsprojekt*"){$_.Name}}
    }

    [String] cleanInputString($string){
        $this.validation($string)
        return $string.trim()
    }

    [Exception] validation($value){
        if ([string]::IsNullOrEmpty($value) -or ($value -is [array])){
            return Write-Error -Exception ([System.ArgumentNullException]::New()) -ErrorAction Stop
        }
        if (($value.BaseResponse.ResponseUri.AbsolutePath -eq "/api/matread") -and ($value.content -eq "[]")){
            return Write-Error -Exception ([System.MissingMemberException]::New("Wrong material number")) -ErrorAction Stop
        } 
        if (($value.BaseResponse.ResponseUri.AbsolutePath -eq "/api/project") -and ($value.content -eq "[]")){
            return Write-Error -Exception ([System.MissingMemberException]::New("Wrong project number")) -ErrorAction Stop
        } 
        if (($value.BaseResponse.ResponseUri.AbsolutePath -eq "/api/regread") -and ($value.content -eq "[]")){
            return Write-Error -Exception ([System.MissingMemberException]::New("No Booking available under this material and project number")) -ErrorAction Stop
        }
        return $null
    }

    [Exception] validation($valueA, $valueB){
        if ($valueA -eq $valueB){
            return Write-Error -Exception ([System.IO.IOException]::New("Input values are equal")) -ErrorAction Stop
        }
        return $null
    }
}