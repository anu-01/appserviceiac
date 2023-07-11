[Cmdletbinding()]
Param(
    [Parameter(Mandatory = $true)][string]$ClientID,
    [Parameter(Mandatory = $true)][string]$ClientSecret,
    [Parameter(Mandatory = $true)][string]$TenantId,
    [Parameter(Mandatory = $true)][string]$CustomerTenants,
    [Parameter(Mandatory = $true)][string]$CustomerName,
    [Parameter(Mandatory = $true)][string]$B2CTenant,
    [Parameter(Mandatory = $true)][string]$PolicyId,
    [Parameter(Mandatory = $true)][string]$PolicyPath
)

try {

    # Check if file exists
    $FileExists = Test-Path -Path $filePath #-PathType 
    $DeploymentScriptOutputs = @{}

    if ($FileExists) {
        $policycontent = Get-Content $filePath -Encoding UTF8
    
        Write-Host "Building credentials..."
        $body = @{grant_type = "client_credentials"; scope = "https://graph.microsoft.com/.default"; client_id = $ClientID; client_secret = $ClientSecret }

        Write-Host "Requesting token..."
        $response = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token -Method Post -Body $body
        $token = $response.access_token
        DeploymentScriptOutputs['tokenresponse'] = $response

        Write-Host "Building headers..."
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Content-Type", 'application/xml')
        $headers.Add("Authorization", 'Bearer ' + $token)    

        Write-Host "Policy content replacements..."
        $policycontent = $policycontent.Replace("your-tenant.onmicrosoft.com", $B2CTenant + ".onmicrosoft.com")
        $policycontent = $policycontent.Replace("00000000-0000-0000-0000-000000000000", $ClientID)
        $policycontent = $policycontent.Replace("B2C_1A_IDP_AAD_Multi", $PolicyId )
   
        Write-Host "Uploading the" $PolicyId "policy..."

        $graphuri = 'https://graph.microsoft.com/beta/trustframework/policies/' + $PolicyId + '/$value'
        $content = [System.Text.Encoding]::UTF8.GetBytes($policycontent)
        $response = Invoke-RestMethod -Uri $graphuri -Method Put -Body $content -Headers $headers -ContentType "application/xml; charset=utf-8"
        DeploymentScriptOutputs['uploadresponse'] = $response

        Write-Host "Policy" $PolicyId "uploaded successfully."
    }
    else {
        Write-Host "Policy file not found."
        $warning = "File " + $filePath + " couldn't be not found."
        Write-Warning -Message $warning
    }
    
}
catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__

    $_

    $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $streamReader.BaseStream.Position = 0
    $streamReader.DiscardBufferedData()
    $errResp = $streamReader.ReadToEnd()
    $streamReader.Close()

    $ErrResp

    exit 1
}

exit 0