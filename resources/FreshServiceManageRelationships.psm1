function Get-NewFreshServiceManageRelationships(){
    return [FreshServiceManageRelationships]::new()
}

class FreshServiceManageRelationships {

    $freshServiceItems = ""

    FreshServiceManageRelationships (){
        $this.freshServiceItems = Get-NewFreshServiceManageAssets
    }

    getRelationships([String] $display_id){
        $display_id >> $Global:logFile
        If (-not $Global:hash.ContainsKey($display_id) ){
            #$childitems.getFreshServiceItems("assets/{0}" -f $display_id)
            $relationships = $this.freshServiceItems.getFreshServiceItemsRelationships($display_id, 1)
            "$($relationships.relationships.config_item.display_id), $($relationships.relationships.relationship_type)" >> $Global:logFile
            $end = 0
            Foreach ($relationship in $relationships.relationships){
                if ($relationship.relationship_type -eq "forward_relationship") {
                    $childitems = $this.freshServiceItems.getFreshServiceItems("assets/{0}" -f $relationship.config_item.display_id)
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
}