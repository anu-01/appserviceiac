
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
<#
.SYNOPSIS
    Registers a B2C IEF Policy Key

.DESCRIPTION
    Registers a B2C IEF Policy Key

.PARAMETER TenantName
    Name of tenant. Default is one currently connected to

.PARAMETER KeyContainerName
    Name of container

.PARAMETER KeyType
    Type of key. must be "RSA" or "secret"

.PARAMETER KeyUse
    Usage of key. must be "sig" or "enc" for signature or encryption

.PARAMETER secret
    the secret value

.PARAMETER AppID
    AppID for your client_credentials. Default is to use $env:B2CAppID

.PARAMETER AppKey
    secret for your client_credentials. Default is to use $env:B2CAppKey

.EXAMPLE
    New-AzADB2CPolicyKey -KeyContainerName "B2C_1A_TokenSigningKeyContainer" -KeyType "RSA" -KeyUse "sig"

.EXAMPLE
    New-AzADB2CPolicyKey -KeyContainerName "B2C_1A_TokenEncryptionKeyContainer" -KeyType "RSA" -KeyUse "enc"

.EXAMPLE
    New-AzADB2CPolicyKey -KeyContainerName "B2C_1A_FacebookSecret" -KeyType "secret" -KeyUse "sig" -Secret $FacebookSecret

#>
function New-AzADB2CPolicyKey
(
    [Parameter(Mandatory=$true)][Alias('n')][string]$KeyContainerName = "", # [B2C_1A_]Name
    [Parameter(Mandatory=$true)][Alias('y')][string]$KeyType = "secret",    # RSA, secret
    [Parameter(Mandatory=$true)][Alias('u')][string]$KeyUse = "sig",        # sig, enc
    [Parameter(Mandatory=$true)][Alias('s')][string]$Secret = "",           # used when $KeyType==secret
    [Parameter(Mandatory=$true)][Alias('t')][string]$Token = ""           # used when $KeyType==secret
)
{
    #RefreshTokenIfExpired
    $KeyType = $KeyType.ToLower()
    $KeyUse = $KeyUse.ToLower()
    $authHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $authHeader.Add("Content-Type", 'application/json')
    $authHeader.Add("Authorization", 'Bearer ' + $Token) 
    $GraphEndpoint="https://graph.microsoft.com/beta"

    if ( !("rsa" -eq $KeyType -or "secret" -eq $KeyType ) ) {
        write-error "KeyType must be RSA or secret"
        return
    }
    if ( !("sig" -eq $KeyUse -or "enc" -eq $KeyUse ) ) {
        write-error "KeyUse must be sig(nature) or enc(ryption)"
        return
    }
    if ( $false -eq $KeyContainerName.StartsWith("B2C_1A_") ) {
        $KeyContainerName = "B2C_1A_$KeyContainerName"
    }

    try {
        $resp = Invoke-RestMethod -Method GET -Uri "$GraphEndpoint/trustFramework/keySets/$KeyContainerName" -Headers $authHeader -ErrorAction SilentlyContinue
        write-warning "$($resp.id) already has $($resp.keys.Length) keys"
        return
    } catch {
    }
    $body = @"
    {
        "id": "$KeyContainerName"
    }
"@
    $resp = Invoke-RestMethod -Method POST -Uri "$GraphEndpoint/trustFramework/keySets" -Headers $authHeader -Body $body -ContentType "application/json" -ErrorAction SilentlyContinue
    <##>
    if ( "secret" -eq $KeyType ) {
        $url = "$GraphEndpoint/trustFramework/keySets/$KeyContainerName/uploadSecret"
        $body = @"
    {
        "use": "$KeyUse",
        "k": "$Secret"
    }
"@
    } 
    if ( "rsa" -eq $KeyType ) {
        $url = "$GraphEndpoint/trustFramework/keySets/$KeyContainerName/generateKey"
        $body = @"
    {
        "use": "$KeyUse",
        "kty": "RSA",
    }
"@
    } 

    $resp = Invoke-RestMethod -Method POST -Uri $url -Headers $authHeader -Body $body -ContentType "application/json"
    write-host "key created: $KeyContainerName"    
}


try {  
    $policycontent = $policyXml
    Write-Host "Current directory: " $PSScriptRoot
    Write-Host "Building credentials..."
    $body = @{grant_type = "client_credentials"; scope = "https://graph.microsoft.com/.default"; client_id = $ClientID; client_secret = $ClientSecret }

    Write-Host "Requesting token..."
    $response = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token -Method Post -Body $body
    $token = $response.access_token
    $continue = $true
    $KeyContainerName = "B2C_1A_$CustomerName" + "Key"  

    Write-Host "Calling New-AzADB2CPolicyKey..."
    New-AzADB2CPolicyKey -KeyContainerName $KeyContainerName -KeyType "secret" -KeyUse "sig" -Secret $customerSecret -Token $token
    Write-Host "New-AzADB2CPolicyKey completed"
    

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

        $graphuri = 'https://graph.microsoft.com/beta/trustframework/policies/' + $PolicyId + '/$value'

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

