@description('Location for all resources.')
param location string = resourceGroup().location

@description('Prefix for storage account name')
@maxLength(9)
param prefix string = 'stgiacdev'

var storageAccountName = '${prefix}${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

output storageAccountName string = storageAccount.name
