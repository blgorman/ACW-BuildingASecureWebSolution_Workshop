targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@allowed(['dev', 'prod'])
@description('Name of the deployment environment')
param environmentName string

@minLength(1)
@maxLength(64)
@description('Name of the application')
param applicationName string = 'securemvcauthweb'

@minLength(1)
@description('Location for all resources (i.e. centralus) ')
param location string

@minLength(1)
@description('Location Abbreviation for all resources (i.e. cus) ')
param locationAbbreviation string

var tags = {
  environment: environmentName
  workshop: 'buildsecureweb'
}

resource rgHub 'Microsoft.Resources/resourceGroups@2025-03-01' = {
  name: 'rg-hub-${applicationName}-${locationAbbreviation}-${environmentName}'
  location: location
  tags: tags
}

resource rgApp 'Microsoft.Resources/resourceGroups@2025-03-01' = {
  name: 'rg-spoke-${applicationName}-${locationAbbreviation}-${environmentName}'
  location: location
  tags: tags
}
