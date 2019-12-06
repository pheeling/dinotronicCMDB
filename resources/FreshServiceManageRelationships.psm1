function Get-NewFreshServiceManageRelationships(){
    return [FreshServiceManageRelationships]::new()
}

class FreshServiceManageRelationships {

    $freshServiceItems

    FreshServiceManageRelationships (){
        $this.freshServiceItems = Get-NewFreshServiceManageAssets
    }

    getRelationships([String] $display_id){
        $display_id >> $Global:logFile
        If (-not $Global:hash.ContainsKey($display_id) ){
            $relationships = $this.freshServiceItems.getFreshServiceItemsRelationships($display_id, 1)
            "$($relationships.relationships.config_item.display_id), $($relationships.relationships.relationship_type)" >> $Global:logFile
            $end = 0
            Foreach ($relationship in $relationships.relationships){
                if ($relationship.relationship_type -eq "forward_relationship") {
                    $childitems = $this.freshServiceItems.getFreshServiceItems("assets/{0}" -f $relationship.config_item.display_id)
                    If (($childitems.asset.asset_type_id -eq 7001248569) -and ($childitems.asset.type_fields.hasrelationshipdropdown_7001248569 -eq $null)){
                        $this.setRelationshipStatus($childitems)
                    }
                    $this.getRelationships($childitems.asset.display_id)
                    If ($Global:hash.ContainsKey($display_id) ){
                        $Global:hash[$display_id] = ($Global:hash[$display_id], $Global:hash["$($childitems.asset.display_id)"] | Measure-Object -Max).Maximum
                    }else {
                        $Global:hash[$display_id] = $Global:hash["$($childitems.asset.display_id)"]
                    }
                    $end = 1
                }
            }
            if ($end -eq 0){
                $finalasset = $this.freshServiceItems.getFreshServiceItems("assets/{0}" -f $display_id)
                $quantity = $finalasset.asset.type_fields.quantity_7001248569 -as [int]
                $Global:hash[$display_id] = $quantity
            }
            $Global:hash[$display_id] >> $Global:logFile
        }
    }

    setRelationshipStatus([System.Object] $childitems){
        $hasrelationshiptable =@{
            asset =@{
                type_fields = @{
                    hasrelationshipdropdown_7001248569 = "Yes"
                } 
            }
        }
        &{$this.freshServiceItems.updateFreshServiceItem($childitems.asset.display_id,$hasrelationshiptable)} 3>&1 2>&1 >> $Global:logFile
    }
}