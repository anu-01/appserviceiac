targetScope = 'resourceGroup'

param location string = resourceGroup().location

@description('The object holding the customer details')
param customerPlan  object =  {    
    name: 'plan1'
    sku: ''
    capacity: ''
    b2ctenant: ''
    customers: [
      {
        name: 'customer1'
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
      }
    ]
  }

@description('The language stack of the app.')
@allowed([
  '.net'
  'php'
  'node'
  'html'
])
param language string = '.net'
param sqlFQDN string
@description('The admin user of the SQL Server')
param sqlAdministratorLogin string

@description('The password of the admin user of the SQL Server')
@secure()
param sqlAdministratorLoginPassword string
@description('The name of the sql server where the db will be deployed')
param sqlserverName string
@description('Log analytics workspace id')
param logAnalyticsWorkspaceId string
@description('Name of the keyvault')
param kvname string
@description('The url of the b2c login page')
param b2cLoginUrl string

resource asp 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: customerPlan.name
  location: location
  sku: {
    name: customerPlan.sku
    capacity: customerPlan.capacity
  }
}

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: asp.name
  scope: asp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
} 


@batchSize(1)
module appService 'appservice.bicep' = [for customer in customerPlan.customers: {
  name: '${customer.name}-${uniqueString(resourceGroup().id)}'
  params: {
    customer: customer
    sqlFQDN: sqlFQDN
    language: language
    location: location
    appServicePlanId: asp.id
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    sqlserverName: sqlserverName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    kvname: kvname
    b2cLoginUrl: b2cLoginUrl
    b2ctenant: customerPlan.b2ctenant
  }  
}]





