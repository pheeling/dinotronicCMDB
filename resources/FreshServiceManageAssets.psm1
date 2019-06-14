function Get-NewFreshServiceManageAssets(){
    return [FreshServiceManageAssets]::new()
}

class FreshServiceManageAssets {

    #Instanced Properties
    $userConfiguration

    FreshServiceManageAssets (){
        $this.userConfiguration = Get-NewUserConfiguration
    }

    [Object] getFreshServiceDepartments([String] $page){
        $url = "https://dinotronic.freshservice.com/itil/departments.json?page=$($page)"
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET" #-Debug -Verbose #-ErrorAction SilentlyContinue
        return $response
    }

    [Hashtable] getAllDepartmentsAsList(){
        $page = 1
        $departmentGet = $this.getFreshServiceDepartments($page)
        $departmentlist =@{}

        while ($departmentGet.Length -ne 0) {
            foreach ($entry in $departmentGet){
                $departmentlist += @{$entry.id = "$($entry.name)"}
            }
            $page++
            $departmentGet = $this.freshServiceAsset.getFreshServiceDepartments($page)
        }
    return $departmentlist
    }
}
