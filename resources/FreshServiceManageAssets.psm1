function Get-NewFreshServiceManageAssets(){
    return [FreshServiceManageAssets]::GetInstance()
}

class FreshServiceManageAssets {

    #Instanced Properties
    static [FreshServiceManageAssets] $instance
    $userConfiguration

    static [FreshServiceManageAssets] GetInstance() {
        if ([FreshServiceManageAssets]::instance -eq $null) { [FreshServiceManageAssets]::instance = [FreshServiceManageAssets]::new() }
            return [FreshServiceManageAssets]::instance
    }

    FreshServiceManageAssets (){
        $this.userConfiguration = Get-NewUserConfiguration
    }

    [Array] getFreshServiceItems([String] $type, [String] $page){
        $url = "https://dinotronic.freshservice.com/api/v2/{0}?page={1}" -f $type, $page
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    }

    [Array] getFreshServiceItems([String] $type){
        $url = "https://dinotronic.freshservice.com/api/v2/{0}?include=type_fields" -f $type
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    }

    [Object] getFreshServiceItemsWithQuery([String] $type, [String] $query, [String] $page){
        $url = "https://dinotronic.freshservice.com/api/v2/{0}?query=""{1}""&page={2}&include=type_fields" -f $type, $query, $page
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    }

    [Object] getFreshServiceItemsIncludeFields([String] $type, [String] $page){
        $url = "https://dinotronic.freshservice.com/api/v2/{0}?page={1}&include=type_fields" -f $type, $page
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    }

    #API V1, wait for API v2 to arrive
    [Object] getFreshServiceItemsRelationships([String] $displayid, [String] $page){
        $url = "https://dinotronic.freshservice.com/cmdb/items/{0}/relationships.json?page={1}" -f $displayid, $page
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    }

    [Hashtable] getFreshServiceItemsAsList([string] $type, [boolean] $typefields){
        $page = 1
        $itemsList =@{}
        if($typefields -eq $true){
            $items = $this.getFreshServiceItemsIncludeFields($type,$page)
            while ($items.$($type).Count -ne 0) {
                foreach ($entry in $items."$($type)"){
                    $itemslist += @{"$($entry.id)" = @{
                                        "displayId" = $entry.display_id
                                        "offerId" = $entry.type_fields.offerid_7001248569
                                        "orderId" = $entry.type_fields.orderid_7001248569
                                        "companyName" = $entry.type_fields.companyname_7001248569
                                        "offerName" = $entry.type_fields.offername_7001248569
                                        }
                                    }
                }
                $page++
                $items = $this.getFreshServiceItemsIncludeFields($type,$page)
            }
        } else {
            $items = $this.getFreshServiceItems($type,$page)
            while ($items.$($type).Count -ne 0) {
                foreach ($entry in $items."$($type)"){
                    $itemslist += @{$entry.id = "$($entry.name)"}
                }
                $page++
                $items = $this.getFreshServiceItems($type,$page)
            }
        }
    return $itemsList
    }

    [Array] updateFreshServiceItem([String] $assetId, [Hashtable] $valuestable){
        $url = "https://dinotronic.freshservice.com/api/v2/assets/{0}" -f $assetId
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $json = $valuestable | ConvertTo-Json
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "PUT" -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
    }

    [Array] createFreshServiceItem([Hashtable] $valuestable){
        $url = "https://dinotronic.freshservice.com/api/v2/assets"
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $json = $valuestable | ConvertTo-Json
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "POST" -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
    }

    [Array] deleteFreshServiceItem([String] $assetId){
        $url = "https://dinotronic.freshservice.com/api/v2/assets/{0}" -f $assetId
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "DELETE" 
    }
}
