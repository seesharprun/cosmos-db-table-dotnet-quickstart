metadata description = 'Create web application resources.'

param workspaceName string
param envName string
param appName string
param serviceTag string
param location string = resourceGroup().location
param tags object = {}

@description('Endpoint for Azure Cosmos DB for Table account.')
param databaseAccountEndpoint string

@description('Name of the referenced table.')
param databaseTableName string

@description('Client ID of the service principal to assign database and application roles.')
param appClientId string

@description('Resource ID of the service principal to assign database and application roles.')
param appResourceId string

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.7.0' = {
  name: 'log-analytics-workspace'
  params: {
    name: workspaceName
    location: location
    tags: tags
  }
}

module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.8.0' = {
  name: 'container-apps-env'
  params: {
    name: envName
    location: location
    tags: tags
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
  }
}

module containerAppsApp 'br/public:avm/res/app/container-app:0.9.0' = {
  name: 'container-apps-app'
  params: {
    name: appName
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    location: location
    tags: union(tags, { 'azd-service-name': serviceTag })
    ingressTargetPort: 8080
    ingressExternal: true
    ingressTransport: 'auto'
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        appResourceId
      ]
    }
    secrets: {
      secureList: [
        {
          name: 'azure-cosmos-db-table-endpoint'
          value: databaseAccountEndpoint
        }
        {
          name: 'azure-cosmos-db-table-name'
          value: databaseTableName
        }
        {
          name: 'user-assigned-managed-identity-client-id'
          value: appClientId
        }
      ]
    }
    containers: [
      {
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        name: 'web-front-end'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
        env: [
          {
            name: 'AZURE_COSMOS_DB_TABLE_ENDPOINT'
            secretRef: 'azure-cosmos-db-table-endpoint'
          }
          {
            name: 'AZURE_COSMOS_DB_TABLE_NAME'
            secretRef: 'azure-cosmos-db-table-name'
          }
          {
            name: 'AZURE_CLIENT_ID'
            secretRef: 'user-assigned-managed-identity-client-id'
          }
        ]
      }
    ]
  }
}

output endpoint string = 'https://${containerAppsApp.outputs.fqdn}'
output envName string = containerAppsApp.outputs.name
output systemAssignedManagedIdentityPrincipalId string = containerAppsApp.outputs.systemAssignedMIPrincipalId
