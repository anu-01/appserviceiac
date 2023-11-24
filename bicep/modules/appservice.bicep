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

@description('Name of the keyvault')
param kvname string = 'kvappserviceiac'

@description('The url of the b2c login page')
param b2cLoginUrl string

@description('The b2c tenant name')
param b2ctenant string

@description('The central storage account name, here the db bacpac will be uploaded')
param storageAccountName string
@description('SAS token lifetime in ISO 8601 duration format e.g. PT1H for 1 hour')
param sasTokenLifetime string = 'P7D'

param policyPrefix string = 'B2C_1A_IDP_AAD_' 
param baseTime string = utcNow('u')

// Variables
var gitRepoReference = {
  '.net': 'https://github.com/RussSmi/b2cwebapp' //'https://github.com/Azure-Samples/app-service-web-dotnet-get-started' //'https://github.com/RussSmi/curly-guide'
  node: 'https://github.com/Azure-Samples/nodejs-docs-hello-world'
  php: 'https://github.com/Azure-Samples/php-docs-hello-world'
  html: 'https://github.com/Azure-Samples/html-docs-hello-world'
}
var gitRepoUrl = (empty(repoUrl) ? gitRepoReference[language] : repoUrl)
var appServiceName = '${customer.name}-app-${uniqueString(resourceGroup().id)}'
var policyId = '${policyPrefix}${customer.name}'
var sasExpiryDate = dateTimeAdd(baseTime, sasTokenLifetime)

module appInsights 'appinsights.bicep' = {
  name: 'appInsights-${appServiceName}'
  params: {
    applicationInsightsLocation: location
    applicationInsightsName: '${customer.name}-appInsights'
  }
}

module b2c 'b2cappreg.bicep' = {
  name: '${customer.name}-${uniqueString(resourceGroup().id)}-appreg'
  params: {
    name: 'b2cappregscript'
    location: location
    customerName: customer.name
    customerAppName: appServiceName
    b2cTenantId: kv.getSecret('b2ctenantId')
    b2cSpAppId: kv.getSecret('b2cspappid')
    b2cSpSecret: kv.getSecret('b2cspsecret')
  }
}

module policy 'b2ccustompolicy.bicep' = {
  name: '${customer.name}-${uniqueString(resourceGroup().id)}-policy'
  params: {
    name: 'b2ccustompolicy'
    location: location
    CustomerTenants: customer.loginUrls
    B2CTenantName: b2ctenant    
    b2cTenantId: kv.getSecret('b2ctenantId')
    b2cSpAppId: kv.getSecret('b2cspappid')
    b2cSpSecret: kv.getSecret('b2cspsecret')
    customerName: customer.name    
    policyId: policyId
    customerAppReg: customer.appRegClientId
  }
}

resource storageRef 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName //'stgiacdev4xrn45j6h7wtc'

  resource blobServiceRef 'blobServices@2023-01-01' existing = {
    name: 'default'

    resource blobContainer 'containers@2023-01-01' = if (customer.existing == 'true') {
      name: customer.name
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

var sasConfig = {
  canonicalizedResource: '/blob/${storageAccountName}/${customer.name}' 
  signedResource: 'c'
  signedPermission: 'rwl'
  signedExpiry: sasExpiryDate
  signedProtocol: 'https'
  keyToSign: 'key1'
}

// Add sasToken to keyvault
resource sasTokenSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (customer.existing == 'true') {
  parent: kv
  name: '${customer.name}-upload-sas-token'
  properties: {
    value: 'BlobEndpoint=${storageRef.properties.primaryEndpoints.blob};SharedAccessSignature=${storageRef.listServiceSas(storageRef.apiVersion, sasConfig).serviceSasToken}'
  }
}

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
        {
          name: 'AzureAdB2C:ClientId'
          value: b2c.outputs.result.clientid
        }    
        {
          name: 'AzureAdB2C:Instance'
          value: b2cLoginUrl
        }
        {
          name: 'AzureAdB2C:SignUpSignInPolicyId'
          value: policyId
        }
        {
          name: 'AzureAdB2C:SignedOutCallbackPath'
          value: '/signout/${policyId}'
        }
        {
          name: 'Account'
          value: '{ "Name": "${customer.name}", "Logo": "${customer.logo}", "Splash": "${customer.splash}" }'
        }
        {
          name: 'Start'
          value: customer.start
        }
        {
          name: 'ProductHubUrl'
          value: customer.productHubUrl
        }
        {
          name: 'Volumes'
          value: string(customer.volumes)
        }
        {
          name: 'Links'
          value: string(customer.links)
        }        
      ]
    }
    serverFarmId: appServicePlanId
    httpsOnly: true
  }
  dependsOn: [
    appInsights
    b2c
  ]
}

resource gitsource 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: webApp
  name: 'web'
  properties: {
    repoUrl: gitRepoUrl
    branch: 'main'
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
    name: customer.dbSku.name
    tier: customer.dbSku.tier
    family: customer.dbSku.family
    capacity: customer.dbSku.capacity
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

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: kvname
  scope: resourceGroup()
}
