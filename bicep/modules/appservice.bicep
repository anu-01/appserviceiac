targetScope = 'resourceGroup'

@description('The language stack of the app.')
@allowed([
  '.net'
  'php'
  'node'
  'html'
])
param language string = '.net'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The FQDN of the Sql Server to connect to')
param sqlFQDN string

@description('Optional Git Repo URL, if empty a \'hello world\' app will be deploy from the Azure-Samples repo')
param repoUrl string = ''

@description('The customer object, it is anticipated additional properties will be required here')
param customer object = {
  name: 'customerName'
}

@description('The app service plan id that this app service will use')
param appServicePlanId string

@description('The admin user of the SQL Server')
param sqlAdministratorLogin string

@description('The password of the admin user of the SQL Server')
@secure()
param sqlAdministratorLoginPassword string
param sqlserverName string

@description('Log analytics workspace id')
param logAnalyticsWorkspaceId string

// Variables
var gitRepoReference = {
  '.net': 'https://github.com/Azure-Samples/app-service-web-dotnet-get-started' //'https://github.com/RussSmi/curly-guide'
  node: 'https://github.com/Azure-Samples/nodejs-docs-hello-world'
  php: 'https://github.com/Azure-Samples/php-docs-hello-world'
  html: 'https://github.com/Azure-Samples/html-docs-hello-world'
}
var gitRepoUrl = (empty(repoUrl) ? gitRepoReference[language] : repoUrl)
var appServiceName = '${customer.name}-app-${uniqueString(resourceGroup().id)}'

module appInsights 'appinsights.bicep' = {
  name: 'appInsights-${appServiceName}'
  params: {
    applicationInsightsLocation: location
    applicationInsightsName: '${customer.name}-appInsights'
  }
}

// Resources
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      //scmType: 'GitHub'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.outputs.instrumentationKey
        }     
      ]
    }
    serverFarmId: appServicePlanId
    httpsOnly: true
  }
}

resource gitsource 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: webApp
  name: 'web'
  properties: {
    repoUrl: gitRepoUrl
    branch: 'master'
    isManualIntegration: true
  }
} 



resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' existing = {
  name: sqlserverName
}

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: webApp.name
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
     logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ] 
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

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  parent: sqlServer
  name: '${customer.name}-db-${uniqueString(resourceGroup().id)}'
  location: location
  tags: {
    displayName: 'Database'
  }
  sku: {
    name: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
  }
}

resource webSiteConnectionStrings 'Microsoft.Web/sites/config@2020-12-01' = {
  parent: webApp
  name: 'connectionstrings'
  properties: {
    DefaultConnection: {
      value: 'Data Source=tcp:${sqlFQDN},1433;Initial Catalog=${sqlDatabase.name};User Id=${sqlAdministratorLogin}@${sqlFQDN};Password=${sqlAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
}
