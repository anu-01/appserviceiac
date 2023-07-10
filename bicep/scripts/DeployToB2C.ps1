[Cmdletbinding()]
Param(
    [Parameter(Mandatory = $true)][string]$ClientID,
    [Parameter(Mandatory = $true)][string]$ClientSecret,
    [Parameter(Mandatory = $true)][string]$TenantId,
    [Parameter(Mandatory = $true)][string]$CustomerTenants,
    [Parameter(Mandatory = $true)][string]$CustomerName,
    [Parameter(Mandatory = $true)][string]$B2CTenant,
    [Parameter(Mandatory = $true)][string]$PolicyId,
    [Parameter(Mandatory = $true)][string]$PolicyContent
)

try {
    $body = @{grant_type = "client_credentials"; scope = "https://graph.microsoft.com/.default"; client_id = $ClientID; client_secret = $ClientSecret }

    $response = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token -Method Post -Body $body
    $token = $response.access_token

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", 'application/xml')
    $headers.Add("Authorization", 'Bearer ' + $token)    

    $policycontent = $PolicyContent.Replace("your-tenant.onmicrosoft.com", $B2CTenant + ".onmicrosoft.com")
    $policycontent = $olicyContent.Replace("00000000-0000-0000-0000-000000000000", $ClientID)
    $policycontent = $olicyContent.Replace("B2C_1A_IDP_AAD_Multi", $PolicyId )
   
    Write-Host "Uploading the" $PolicyId "policy..."

    $graphuri = 'https://graph.microsoft.com/beta/trustframework/policies/' + $PolicyId + '/$value'
    $content = [System.Text.Encoding]::UTF8.GetBytes($policycontent)
    $response = Invoke-RestMethod -Uri $graphuri -Method Put -Body $content -Headers $headers -ContentType "application/xml; charset=utf-8"

    Write-Host "Policy" $PolicyId "uploaded successfully."
    
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