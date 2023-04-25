targetScope = 'resourceGroup'
@description('The user name to access the sql server')
@secure()
param sqlAdministratorLogin string
@description('TYhe password for the sql user')
@secure()
param sqlAdministratorLoginPassword string
@description('The region for the resources, taken from the resource group')
param location string = resourceGroup().location
@description('The customer app service to plan mappings')
param customerPlans array = [
  {    
    name: ''
    sku: ''
    capacity: ''
    customers: [
      {
        name: ''
        dbSku: [
          {
              name: ''
              tier: ''
              family: ''
              capacity: ''
          }
        ]
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
  }
}]
