param (
    [string]$OutputPath="DefaultPath",
    [string]$Version="DefaultVersion"
)

Function Get-CapitalizedString([string]$Value) {
    Write-Host "Capitalizing string $Value"
    return $Value.ToUpperInvariant()
}
    
Write-Host (Get-CapitalizedString -Value $OutputPath),$Version
HelloWorld
$ctx = Get-AzContext
Write-Host $ctx.ctx.Tenant.Id

Function HelloWorld() {
    Write-Host "Hello World 2"
}