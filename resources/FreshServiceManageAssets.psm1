function Get-NewFreshServiceManageAssets(){
    return [FreshServiceManageAssets]::new()
}

class FreshServiceManageAssets {

    #Instanced Properties
    $userConfiguration

    FreshServiceManageAssets (){
        $this.userConfiguration = Get-NewUserConfiguration
    }

    [Object] getFreshServiceDepartments(){
        $url = "https://dinotronic.freshservice.com/itil/departments.json"
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET" #-Debug -Verbose #-ErrorAction SilentlyContinue
        return $response
    }
}
