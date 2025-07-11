@minLength(1)
@maxLength(64)
@description('Name of the application')
param applicationName string

@minLength(1)
@description('Location for all resources (i.e. centralus)')
param location string

@minLength(1)
@description('Location Abbreviation for all resources (i.e. cus)')
param locationAbbreviation string

@minLength(1)
@description('GitHub account name')
param githubAccount string

@minLength(1)
@description('GitHub repository name')
param githubRepository string

@minLength(1)
@maxLength(64)
@allowed(['dev', 'prod'])
@description('Name of the deployment environment')
param deploymentEnvironment string

var managedIdentityName = 'mi-${applicationName}-${locationAbbreviation}-${deploymentEnvironment}'
var fcName = 'fc-${applicationName}-${deploymentEnvironment}'
var tags = {
  environment: deploymentEnvironment
  workshop: 'buildsecureweb'
}

// Create the User Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

// Create federated credential for the environment strategy
resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: fcName
  parent: managedIdentity
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubAccount}/${githubRepository}:environment:${deploymentEnvironment}'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

// Outputs
output clientId string = managedIdentity.properties.clientId
output tenantId string = managedIdentity.properties.tenantId
output subscriptionId string = subscription().subscriptionId
