function Get-NewGetHash(){
    return [GetHash]::new()
}

class GetHash {

    GetHash(){
        
    }

    [string] getHashValue ([String] $string) {
        #http://jongurgul.com/blog/get-stringhash-get-filehash/
        $hashName = "SHA256"
        $StringBuilder = New-Object System.Text.StringBuilder 
        [System.Security.Cryptography.HashAlgorithm]::Create($hashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($string)) | ForEach-Object { 
        [Void]$StringBuilder.Append($_.ToString("x2")) 
        } 
        return $StringBuilder.ToString() 
    }
}