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

    [Object] getFreshServiceItemsIncludeFields([String] $type, [String] $page){
        $url = "https://dinotronic.freshservice.com/api/v2/{0}?page={1}&include=type_fields" -f $type, $page
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET" #-Debug -Verbose #-ErrorAction SilentlyContinue
    }

    [Hashtable] getFreshServiceItemsAsList([string] $type, [boolean] $typefields){
        $page = 1
        $itemsList =@{}
        if($typefields){
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

        $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "PUT" -Body $json #-Debug -Verbose #-ErrorAction SilentlyContinue
        return $response
    }

    [Array] createFreshServiceItem([Hashtable] $valuestable){
        $url = "https://dinotronic.freshservice.com/api/v2/assets"
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $json = $valuestable | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "POST" -Body $json #-Debug -Verbose #-ErrorAction SilentlyContinue
        return $response
    }

    [Array] deleteFreshServiceItem([String] $assetId){
        $url = "https://dinotronic.freshservice.com/api/v2/assets/{0}" -f $assetId
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}

        $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "DELETE" #-Debug -Verbose #-ErrorAction SilentlyContinue
        return $response
    }
}
