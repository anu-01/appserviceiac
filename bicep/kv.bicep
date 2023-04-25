@description('Specifies the name of the key vault.')
param keyVaultName string = 'kviac'

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool = false

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool = false

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = true

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@secure()
@description('The B2C Tenant Id')
param b2cTenantId string

@secure()
@description('The B2C Service Principal App Id')
param b2cSpAppId string

@secure()
@description('The B2C Service Principal Secret')
param b2cSpSecret string

var finalKvName = '${keyVaultName}${uniqueString(resourceGroup().id)}'

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: finalKvName
  location: location  
  properties: {
    createMode: 'default'
    enableRbacAuthorization: true
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId    
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource secret1 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: 'b2ctenantId'
  properties: {
    value: b2cTenantId
  }
}

resource secret2 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: 'b2cspappid'
  properties: {
    value: b2cSpAppId
  }
}

resource secret3'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: 'b2cspsecret'
  properties: {
    value: b2cSpSecret
  }
}


