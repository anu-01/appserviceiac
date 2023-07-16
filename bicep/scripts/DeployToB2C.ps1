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
    [Parameter(Mandatory = $true)][string]$policyXml
)

try {    
    
    $policycontent = $policyXml
    Write-Host "Current directory: " $PSScriptRoot
    Write-Host "Building credentials..."
    $body = @{grant_type = "client_credentials"; scope = "https://graph.microsoft.com/.default"; client_id = $ClientID; client_secret = $ClientSecret }

    Write-Host "Requesting token..."
    $response = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token -Method Post -Body $body
    $token = $response.access_token

    Write-Host "Building headers..."
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", 'application/xml')
    $headers.Add("Authorization", 'Bearer ' + $token)    

    Write-Host "Policy content replacements..."
    $policycontent = $policycontent.Replace("yourtenant.onmicrosoft.com", $B2CTenant + ".onmicrosoft.com")
    $policycontent = $policycontent.Replace("https://login.microsoftonline.com/00000000-0000-0000-0000-000000000000", $CustomerTenants)
    $policycontent = $policycontent.Replace("00000000-0000-0000-0000-000000000000", $CustomerAppReg)
    $policycontent = $policycontent.Replace("B2C_1A_IDP_AAD_Multi", $PolicyId )
   
   
   # Write-Host "Uploading the" $PolicyId "policy..."

    #$policycontent = [System.Web.HttpUtility]::HtmlEncode($policycontent)
    Write-Host "Policy content "
    Write-Host $policycontent

    #
    $policycontent = [System.Text.Encoding]::UTF8.GetBytes($policycontent)


    $graphuri = 'https://graph.microsoft.com/beta/trustframework/policies/' + $PolicyId + '/$value'

    Write-Host "graphuri = " $graphuri
    #$content = [System.Text.Encoding]::UTF8.GetBytes($policycontent)
    $content = $policycontent
    $response = Invoke-RestMethod -Uri $graphuri -Method Put -Body $content -Headers $headers -ContentType "application/xml; charset=utf-8"

    Write-Host "Policy" $PolicyId "uploaded successfully."
    
    
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