metadata description = 'Create an Azure Cosmos DB for NoSQL role definition.'

@description('Name of the target Azure Cosmos DB account.')
param targetAccountName string

@description('Name of the role definiton.')
param definitionName string

@description('An array of data actions that are allowed. Defaults to an empty array.')
param permissionsDataActions string[] = []

resource account 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = {
  name: targetAccountName
}

resource definition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2024-05-15' = {
  name: guid('nosql-role-definition', account.id)
  parent: account
  properties: {
    assignableScopes: [
      account.id
    ]
    permissions: [
      {
        dataActions: permissionsDataActions
      }
    ]
    roleName: definitionName
    type: 'CustomRole'
  }
}

output id string = definition.id