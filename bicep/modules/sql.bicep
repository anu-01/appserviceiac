targetScope = 'resourceGroup'
@description('Flag to indicate whether to deploy a database to the sql server')
param deployDatabase bool = false

@description('The admin user of the SQL Server')
param sqlAdministratorLogin string

@description('The password of the admin user of the SQL Server')
@secure()
param sqlAdministratorLoginPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

param dbsku object = {
  name: ''
  tier: ''
  family: ''
  capacity: ''
}

var sqlserverName = 'sqlServer${uniqueString(resourceGroup().id)}'
var databaseName = 'sampledb'

resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlserverName
  location: location
  tags: {
    displayName: 'SQL Server'
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = if (deployDatabase) {
  parent: sqlServer
  name: databaseName
  location: location
  tags: {
    displayName: 'Database'
  }
  sku: {
    name: dbsku.name
    tier: dbsku.tier
    family: dbsku.family
    capacity: dbsku.capacity
  }
  
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
  }
}



resource sqlServerDatabase 'Microsoft.Sql/servers/databases@2014-04-01' = {
  parent: sqlServer
  name: 'name'
  location: location
  properties: {
    collation: 'collation'
    edition: 'Basic'
    maxSizeBytes: 'maxSizeBytes'
    requestedServiceObjectiveName: 'Basic'
  }
}


resource allowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

output sqlFQDN string = sqlServer.properties.fullyQualifiedDomainName
output sqlServerName string = sqlServer.name









