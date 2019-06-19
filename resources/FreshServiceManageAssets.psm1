function Get-NewFreshServiceManageAssets(){
    return [FreshServiceManageAssets]::new()
}

class FreshServiceManageAssets {

    #Instanced Properties
    $userConfiguration

    FreshServiceManageAssets (){
        $this.userConfiguration = Get-NewUserConfiguration
    }

    [Array] getFreshServiceItems([String] $type, [String] $page){
        $url = "https://dinotronic.freshservice.com/api/v2/{0}?page={1}" -f $type, $page
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET" #-Debug -Verbose #-ErrorAction SilentlyContinue
    }

    [Hashtable] getFreshServiceItemsAsList([string] $type){
        $page = 1
        $items = $this.getFreshServiceItems($type,$page)
        $itemsList =@{}

        while ($items.$($type).Count -ne 0) {
            foreach ($entry in $items."$($type)"){
                $itemslist += @{$entry.id = "$($entry.name)"}
            }
            $page++
            $items = $this.getFreshServiceItems($type,$page)
        }
    return $itemsList
    }

}
