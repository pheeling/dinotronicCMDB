function Get-NewFreshServiceManageAssets(){
    return [FreshServiceManageAssets]::new()
}

class FreshServiceManageAssets {

    #Instanced Properties
    $userConfiguration

    FreshServiceManageAssets (){
        $this.userConfiguration = Get-NewUserConfiguration
    }

    [PSCustomObject] getFreshServiceDepartments([String] $page){
        $url = "https://dinotronic.freshservice.com/api/v2/departments?page=$($page)"
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET" #-Debug -Verbose #-ErrorAction SilentlyContinue
        return $response
    }

    [Hashtable] getAllDepartmentsAsList(){
        $page = 1
        $departmentGet = $this.getFreshServiceDepartments($page)
        $departmentlist =@{}

        while ($departmentGet.departments.Length -ne 0) {
            foreach ($entry in $departmentGet.departments){
                $departmentlist += @{$entry.id = "$($entry.name)"}
            }
            $page++
            $departmentGet = $this.getFreshServiceDepartments($page)
        }
    return $departmentlist
    }
}
