
[Cmdletbinding()]
Param(
    [Parameter(Mandatory = $true)][string]$ClientID,
    [Parameter(Mandatory = $true)][string]$ClientSecret,
    [Parameter(Mandatory = $true)][string]$TenantId,
    [Parameter(Mandatory = $true)][string]$CustomerTenants,
    [Parameter(Mandatory = $true)][string]$CustomerName,
    [Parameter(Mandatory = $true)][string]$CustomerAppReg,
    [Parameter(Mandatory = $true)][string]$B2CTenant,
    [Parameter(Mandatory = $true)][string]$PolicyId,
    [Parameter(Mandatory = $true)][string]$policyXml,
    [Parameter(Mandatory = $true)][string]$customerSecret,
    [Parameter(Mandatory = $true)][string]$customerDomain
)
#function that prints hello world
function HelloWorld() {
    Write-Host "Hello World"
}

HelloWorld

try {  
    $policycontent = $policyXml
    Write-Host "Current directory: " $PSScriptRoot
    Write-Host "Building credentials..."
    $body = @{grant_type = "client_credentials"; scope = "https://graph.microsoft.com/.default"; client_id = $ClientID; client_secret = $ClientSecret }

    Write-Host "Requesting token..."
    $response = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token -Method Post -Body $body
    $token = $response.access_token
    
    $KeyContainerName = "B2C_1A_$CustomerName" + "Key"

    #Need to create policy key first...

    $continue = $true
    $containerExists = $false
    $keyCount = 0

    $authHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $authHeader.Add("Content-Type", 'application/json')
    $authHeader.Add("Authorization", 'Bearer ' + $token) 

    $GraphEndpoint = 'https://graph.microsoft.com/beta/trustFramework/keySets/' + $KeyContainerName
    Write-Host "GraphEndpoint = " $GraphEndpoint

    try {
        $resp = Invoke-RestMethod -Method GET -Uri $GraphEndpoint -Headers $authHeader -ErrorAction SilentlyContinue
        write-warning "$($resp.id) already has $($resp.keys.Length) keys"
        $keyCount = $resp.keys.Length
        $containerExists = $true
    } catch {
        Write-Host "Getting Containers, it doesn't exist"
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }

    if ($false -eq $containerExists) {

        $body = @"
    {
        "id": "$KeyContainerName"
    }
"@
        $GraphEndpoint = 'https://graph.microsoft.com/beta/trustFramework/keySets/'
        Write-Host "GraphEndpoint2 = " $GraphEndpoint

        try {
            # create the key container
            $resp = Invoke-RestMethod -Method POST -Uri $GraphEndpoint -Headers $authHeader -Body $body -ContentType "application/json" -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "Error Creating Containers, it may already exist"
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
            $continue = $false
        }
    }

    if($continue -eq $true -and $keyCount -eq 0) 
    {
        <##>
        $url = "https://graph.microsoft.com/beta/trustFramework/keySets/$KeyContainerName/uploadSecret"
        Write-Host "url = " $url
        $body = @"
        {
            "use": "sig",
            "k": "$Secret"
        }
"@
        Write-Host "Param Check url = " $url 
        Write-Host "Param Check authHeader = " $authHeader
        Write-Host "Param Check body = " $body

        try {
            $resp = Invoke-RestMethod -Method POST -Uri $url -Headers $authHeader -Body $body -ContentType "application/json"
            write-host "key created: $KeyContainerName" 
            $continue = $true
        }
        catch {
            Write-Host "Error Creating Key"
            Write-Host "Exception:" $_.Exception
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription

    $_
            $continue = $false
        }
    } # end if continue and keyCount == 0

    if ($continue) {
        #Now upload the policy

        Write-Host "Building headers..."
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Content-Type", 'application/xml')
        $headers.Add("Authorization", 'Bearer ' + $token)    

        Write-Host "Policy content replacements..."
        $policycontent = $policycontent.Replace("yourtenant.onmicrosoft.com", $B2CTenant + ".onmicrosoft.com")
        $policycontent = $policycontent.Replace("https://login.microsoftonline.com/00000000-0000-0000-0000-000000000000", $CustomerTenants)
        $policycontent = $policycontent.Replace("00000000-0000-0000-0000-000000000000", $CustomerAppReg)
        $policycontent = $policycontent.Replace("B2C_1A_IDP_AAD_Multi", $PolicyId )
        $policycontent = $policycontent.Replace("StorageReferenceId='B2C_1A_AADAppSecret'", "StorageReferenceId='$KeyContainerName'" )
        $policycontent = $policycontent.Replace("https://login.microsoftonline.com/common/v2.0/", "https://login.microsoftonline.com/$customerDomain/v2.0/" )
        
    
        $policycontent = [System.Text.Encoding]::UTF8.GetBytes($policycontent)

        $graphuri = 'https://graph.microsoft.com/beta/trustframework/policies/' + $PolicyId + '/' + $value

        Write-Host "graphuri = " $graphuri
        
        $content = $policycontent
        $response = Invoke-RestMethod -Uri $graphuri -Method Put -Body $content -Headers $headers -ContentType "application/xml; charset=utf-8"   
    }
    
}
catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription

    $_

    <# $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $streamReader.BaseStream.Position = 0
    $streamReader.DiscardBufferedData()
    $errResp = $streamReader.ReadToEnd()
    $streamReader.Close()

    $ErrResp #>

    exit 1
}

exit 0

