@description('Required. Display name of the script to be run.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('comma separate string of the full login urls')
param CustomerTenants string 

@description('The B2C Tenant Name, name only, not FQ')
param B2CTenantName string

@secure()
@description('The B2C Tenant Id')
param b2cTenantId string

@secure()
@description('The B2C Service Principal App Id')
param b2cSpAppId string

@secure()
@description('The B2C Service Principal Secret')
param b2cSpSecret string

@secure()
@description('The value of the customer appreg secret from the customer tenant')
param customerSecret string

@description('The name of the customer for whom the app reg is being created')
param customerName string

@description('The customers login domain, e.g. firmname.onmicrosoft.com')
param domain string

param policyId string

param customerAppReg string

var scriptContentPolicy = loadTextContent('../scripts/DeployToB2C.ps1')
var policyXml = loadTextContent('../b2c/IDP_AAD_Multi.xml', 'utf-8')
//var policyPath = './bicep/b2c/IDP_AAD_Multi.xml'
var args = '-ClientID \\"${b2cSpAppId}\\" -ClientSecret \\"${b2cSpSecret}\\" -TenantId \\"${b2cTenantId}\\" -CustomerTenants \\"${CustomerTenants}\\" -CustomerName \\"${customerName}\\" -CustomerAppReg \\"${customerAppReg}\\" -B2CTenant \\"${B2CTenantName}\\" -PolicyId \\"${policyId}\\" -policyXml \\"${policyXml}\\" -customerSecret \\"${customerSecret}\\" -customerDomain \\"${domain}\\"'
var timeout  = 'PT1H'
var cleanupPreference = 'OnSuccess'
var  retentionInterval = 'P1D'
var azPowerShellVersion = '8.3'


resource deploymentScriptPolicy 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: azPowerShellVersion  
    arguments: args
    scriptContent: empty(scriptContentPolicy) ? null : scriptContentPolicy
    supportingScriptUris: []
    cleanupPreference: cleanupPreference
    retentionInterval: retentionInterval
    timeout: timeout
  }
} 





