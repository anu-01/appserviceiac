targetScope = 'resourceGroup'

param location string = resourceGroup().location
param customerPlan  object =  {    
    name: 'plan1'
    sku: ''
    capacity: ''
    customers: [
      {
        name: 'customer1'
      }
      {
        name: 'customer2'
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
param sqlserverName string

resource asp 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: customerPlan.name
  location: location
  sku: {
    name: customerPlan.sku
    capacity: customerPlan.capacity
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
  }  
}]





