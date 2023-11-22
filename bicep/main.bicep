targetScope = 'resourceGroup'
@description('The user name to access the sql server')
@secure()
param sqlAdministratorLogin string
@description('TYhe password for the sql user')
@secure()
param sqlAdministratorLoginPassword string
@description('The region for the resources, taken from the resource group')
param location string = resourceGroup().location
@description('Name of the keyvault')
param kvname string
@description('The B2c login url of the main b2c tenant.  This is used in the app settings to perform the login')
param b2cLoginUrl string
@description('The prifix for the central storage account')
param storagePrefix string = 'stgiacdev'
@description('SAS token lifetime in ISO 8601 duration format e.g. PT1H for 1 hour')
param sasTokenLifetime string = 'P7D'
@description('The customer app service to plan mappings')
param customerPlans array = [
  {    
    name: ''
    sku: ''
    capacity: ''
    b2ctenant: ''
    customers: [
      {
        name: ''
        existing: ''
        logo: ''
        splash: ''
        start: ''
        productHubUrl: ''
        volumes: [{
          documents: [{
            icon: ''
            path: ''
          }]
        }]
        links: [{
          name: ''
          url: ''
        }]
        dbSku: [
          {
              name: ''
              tier: ''
              family: ''
              capacity: ''
          }
        ]
        loginUrls: ''
        appRegClientId: ''
      }
    ]
  }
]

//variables
var logAnalyticsName = 'logAnalytics${uniqueString(resourceGroup().id)}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 120
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

module sql 'modules/sql.bicep' = {
  name: '${deployment().name}-SqlDeploy'
  params: {
    location: location
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
  }
}

module storage 'modules/storage.bicep' = {
  name: '${deployment().name}-StorageDeploy'
  params: {
    location: location
    prefix: storagePrefix
  }
}

@batchSize(1)
module customers 'modules/customers.bicep' = [for plan in customerPlans: {
  name: plan.name
  params: {
    location: location
    customerPlan: plan
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    sqlserverName: sql.outputs.sqlServerName
    sqlFQDN: sql.outputs.sqlFQDN
    logAnalyticsWorkspaceId: logAnalytics.id
    kvname: kvname
    b2cLoginUrl: b2cLoginUrl
    storageAccountName: storage.outputs.storageAccountName
  }
}]


