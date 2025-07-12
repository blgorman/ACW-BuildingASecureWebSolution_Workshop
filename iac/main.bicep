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

//vnet hub
param addressPrefix01 int = 10
param addressPrefix02Hub int = 150

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

module hubVNet 'modules/hubVNet.bicep' = {
  scope: rgHub
  name: 'regional-deployment-hub-${applicationName}-${locationAbbreviation}-${environmentName}'
  params: {
    environmentName: environmentName
    location: location
    applicationName: applicationName
    locationAbbreviation: locationAbbreviation
    tags: tags
    addressPrefix01: addressPrefix01
    addressPrefix02: addressPrefix02Hub
  }
}
