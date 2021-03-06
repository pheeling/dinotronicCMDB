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
        $Global:APICalls++
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    }

    [Array] getFreshServiceItems([String] $type){
        $url = "https://dinotronic.freshservice.com/api/v2/{0}?include=type_fields" -f $type
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $Global:APICalls++
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    }

    [Array] getFreshServiceItemsWithQuery([String] $type, [String] $query, [String] $page){
        $url = "https://dinotronic.freshservice.com/api/v2/{0}?query=""{1}""&page={2}&include=type_fields" -f $type, $query, $page
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $Global:APICalls++
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    }

    [Object] getFreshServiceItemsIncludeFields([String] $type, [String] $page){
        $url = "https://dinotronic.freshservice.com/api/v2/{0}?page={1}&include=type_fields" -f $type, $page
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $Global:APICalls++
        return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    }

    #API V1, wait for API v2 to arrive
    [Object] getFreshServiceItemsRelationships([String] $displayid, [String] $page){
        $url = "https://dinotronic.freshservice.com/cmdb/items/{0}/relationships.json?page={1}" -f $displayid, $page
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
        $headers = @{Authorization="Basic $($base64AuthInfo)"}
        $Global:APICalls++
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
                                        "domain" = $entry.type_fields.domain_7001248569
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

    [String] getQuantityPropertyName($string){
        return $string | Get-Member -MemberType NoteProperty | ForEach-Object {
            if($_.Name -like "quantity*"){$_.Name}}
    }

    [Array] updateFreshServiceItem([String] $assetId, [Hashtable] $valuestable){
        try {
            $url = "https://dinotronic.freshservice.com/api/v2/assets/{0}" -f $assetId
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
            $headers = @{Authorization="Basic $($base64AuthInfo)"}
            $json = $valuestable | ConvertTo-Json
            $Global:APICalls++
            return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "PUT" -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
        } catch {
            #"DT: Updating FreshServiceItem: $PSItem" >> $Global:logFile
            Get-NewErrorHandling "DT: Updating FreshServiceItem" $PSItem
            return $null
        }
    }

    [Array] createFreshServiceItem([Hashtable] $valuestable){
        try {
            $url = "https://dinotronic.freshservice.com/api/v2/assets"
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
            $headers = @{Authorization="Basic $($base64AuthInfo)"}
            $json = $valuestable | ConvertTo-Json
            $Global:APICalls++
            return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "POST" -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
        } catch {
            #"DT: Creating FreshServiceItem: $PSItem" >> $Global:logFile
            Get-NewErrorHandling "DT: Creating FreshServiceItem" $PSItem
            return $null
        }
    }

    [Array] deleteFreshServiceItem([String] $assetId){
        try {
            $url = "https://dinotronic.freshservice.com/api/v2/assets/{0}/delete_forever" -f $assetId
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:X" -f $this.userConfiguration.freshServiceAPIKey)))
            $headers = @{Authorization="Basic $($base64AuthInfo)"}
            $Global:APICalls++
            return Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "PUT" 
        } catch {
            #"DT: Deleting FreshServiceItem: $PSItem" >> $Global:logFile
            Get-NewErrorHandling "DT: Deleting FreshServiceItem" $PSItem
            return $null
        }
    }
}
