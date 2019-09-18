$Global:srcPath = split-path -path $MyInvocation.MyCommand.Definition 
$Global:mainPath = split-path -path $srcPath
$Global:resourcespath = join-path -path "$mainPath" -ChildPath "resources"
$Global:errorVariable = "Stop"
$Global:logFile = "$resourcespath\processing_test.log"

Import-Module -Force "$resourcespath\UserConfiguration.psm1"
Import-Module -Force "$resourcespath\ErrorHandling.psm1"
Import-Module -Force "$resourcespath\FreshServiceManageAssets.psm1"

function Get-Relationships([String] $display_id){
    $display_id >> $Global:logFile
    If (-not $Global:hash.ContainsKey($display_id) ){
        #$childitems.getFreshServiceItems("assets/{0}" -f $display_id)
        $relationships = $freshServiceItems.getFreshServiceItemsRelationships($display_id, 1)
        "$($relationships.relationships.config_item.display_id), $($relationships.relationships.relationship_type)" >> $Global:logFile
        $end = 0
        Foreach ($relationship in $relationships.relationships){
            if ($relationship.relationship_type -eq "forward_relationship") {
                $childitems = $freshServiceItems.getFreshServiceItems("assets/{0}" -f $relationship.config_item.display_id)
                Get-Relationships($childitems.asset.display_id)
                If ($Global:hash.ContainsKey($display_id) ){
                    $Global:hash[$display_id] = ($Global:hash[$display_id], $Global:hash["$($childitems.asset.display_id)"] | Measure-Object -Max).Maximum
                }else {
                    $Global:hash[$display_id] = $Global:hash["$($childitems.asset.display_id)"]
                }
                $end = 1
            }
        }
        if ($end -eq 0){
            $finalasset = $freshServiceItems.getFreshServiceItems("assets/{0}" -f $display_id)
            $quantity = $finalasset.asset.type_fields.quantity_7001248569 -as [int]
            $Global:hash[$display_id] = $quantity
        }
        $Global:hash[$display_id] >> $Global:logFile
    }
}

"$(Get-Date) [START] script" >> $Global:logFile

$freshServiceItems = Get-NewFreshServiceManageAssets
$assetTypeList = $freshServiceItems.getFreshServiceItems("asset_types", 1)
#Look for Dinotronic Managed Services
$results = $assetTypeList.asset_types | Where-Object {$_.parent_asset_type_id -eq 7001249774 }
$services = $results | ForEach-Object {$freshServiceItems.getFreshServiceItemsWithQuery("assets","asset_type_id:{0}" -f $_.id, 1)}
$x = 1
$Global:hash = @{}
Foreach ($service in $services.assets){
    "Service $x" >> $Global:logFile
    Get-Relationships($service.display_id)
    "$(Get-Date) " + $Global:hash["$($service.display_id)"] >> $Global:logFile
    $x++
}

"$(Get-Date) [STOP] script" >> $Global:logFile
if ($Global:logFile.Length -gt 5120Kb) {
    Remove-Item -Path $Global:logFile
}