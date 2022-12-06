targetScope = 'resourceGroup'
@description('The user name to access the sql server')
@secure()
param sqlAdministratorLogin string
@description('TYhe password for the sql user')
@secure()
param sqlAdministratorLoginPassword string

param location string = resourceGroup().location
param customerPlans array = [
  {    
    name: 'plan1'
    sku: 'F1'
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
  {
    name: 'plan2'
    sku: 'F1'
    capacity: ''
    customers: [
      {
        name: 'customer3'
      }
    ]
  }
]

module sql 'modules/sql.bicep' = {
  name: '${deployment().name}-SqlDeploy'
  params: {
    location: location
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
  }
}

module customers 'modules/customers.bicep' = [for plan in customerPlans: {
  name: plan.name
  params: {
    location: location
    customerPlan: plan
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    sqlserverName: sql.outputs.sqlServerName
    sqlFQDN: sql.outputs.sqlFQDN
  }
}]
