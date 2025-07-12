targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@allowed(['dev', 'prod'])
@description('Name of the deployment environment')
param environmentName string

@minLength(1)
@maxLength(64)
@description('Name of the application')
param applicationName string

@minLength(1)
@description('Primary location for all resources')
param location string

param locationAbbreviation string

//group info
param spokeResourceGroupName string

//vnet
param addressPrefix01 int
param addressPrefix02 int

param tags object

resource spokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: spokeResourceGroupName
}

module spokeVNet 'spokeVNet.bicep' = {
  name: 'spokeVnet-deployment-${applicationName}-${location}-${environmentName}'
  scope: spokeRG
  params: {
    addressPrefix01: addressPrefix01
    addressPrefix02: addressPrefix02
    applicationName: applicationName
    environmentName: environmentName
    location: location
    locationAbbreviation: locationAbbreviation
    tags: tags
  }
}
