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

@minLength(1)
@description('Primary location for all resources')
param locationAbbreviation string

param tags object

//vnet
param addressPrefix01 int
param addressPrefix02 int

var vnetPrefix = 'vnet'
var vnetSpokeName = '${vnetPrefix}-spoke-${applicationName}-${locationAbbreviation}-${environmentName}'
var vnetAddressSpacePrefix = '${addressPrefix01}.${addressPrefix02}'
var vnetAddressSpace = '${vnetAddressSpacePrefix}.0.0/16'

//app gateway subnet
var appGatewaySubnetPrefix03 = 0
var appGatewaySubnetPrefix04 = 0
var appGatewaySubnetSize = 24
var appGatewaySubnetName = 'ApplicationGatewaySubnet' // This is an arbitrary name for the app gateway subnet, you can change it as needed
var appGatewaySubnetAddress = '${vnetAddressSpacePrefix}.${appGatewaySubnetPrefix03}.${appGatewaySubnetPrefix04}/${appGatewaySubnetSize}'

//storage subnet
var storageSubnetPrefix03 = 1
var storageSubnetPrefix04 = 0
var storageSubnetSize = 24
var storageSubnetName = 'storage' // Custom name for the storage subnet, you can change this as needed
var storageSubnetAddress = '${vnetAddressSpacePrefix}.${storageSubnetPrefix03}.${storageSubnetPrefix04}/${storageSubnetSize}'

//data subnet
var dataSubnetPrefix03 = 2
var dataSubnetPrefix04 = 0
var dataSubnetSize = 24
var dataSubnetName = 'data' // Custom name for the data subnet, you can change this as needed
var dataSubnetAddress = '${vnetAddressSpacePrefix}.${dataSubnetPrefix03}.${dataSubnetPrefix04}/${dataSubnetSize}'

//vault subnet
var vaultSubnetPrefix03 = 3
var vaultSubnetPrefix04 = 0
var vaultSubnetSize = 24
var vaultSubnetName = 'vault' // Custom name for the vault subnet, you can change this as needed
var vaultSubnetAddress = '${vnetAddressSpacePrefix}.${vaultSubnetPrefix03}.${vaultSubnetPrefix04}/${vaultSubnetSize}'

//web subnet
var webSubnetPrefix03 = 4
var webSubnetPrefix04 = 0
var webSubnetSize = 24
var webSubnetName = 'web' // Custom name for the web subnet, you can change this as needed
var webSubnetAddress = '${vnetAddressSpacePrefix}.${webSubnetPrefix03}.${webSubnetPrefix04}/${webSubnetSize}'

//functions subnet
var functionsSubnetPrefix03 = 5
var functionsSubnetPrefix04 = 0
var functionsSubnetSize = 24
var functionsSubnetName = 'functions' // Custom name for the functions subnet, you can change this as needed
var functionsSubnetAddress = '${vnetAddressSpacePrefix}.${functionsSubnetPrefix03}.${functionsSubnetPrefix04}/${functionsSubnetSize}'

//endpoints subnet
var endpointsSubnetPrefix03 = 6
var endpointsSubnetPrefix04 = 0
var endpointsSubnetSize = 24
var endpointsSubnetName = 'endpoints' // Custom name for the endpoints subnet, you can change this as needed
var endpointsSubnetAddress = '${vnetAddressSpacePrefix}.${endpointsSubnetPrefix03}.${endpointsSubnetPrefix04}/${endpointsSubnetSize}'

//spoke VNet
resource vnetSpoke 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetSpokeName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: appGatewaySubnetAddress
          delegations: []
        }
      }
      {
        name: storageSubnetName
        properties: {
          addressPrefix: storageSubnetAddress
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: dataSubnetName
        properties: {
          addressPrefix: dataSubnetAddress
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: vaultSubnetName
        properties: {
          addressPrefix: vaultSubnetAddress
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: webSubnetName
        properties: {
          addressPrefix: webSubnetAddress
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: functionsSubnetName
        properties: {
          addressPrefix: functionsSubnetAddress
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: endpointsSubnetName
        properties: {
          addressPrefix: endpointsSubnetAddress
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetSpokeId string = vnetSpoke.id
output vnetSpokeName string = vnetSpoke.name
output appGatewaySubnetName string = appGatewaySubnetName
output storageSubnetName string = storageSubnetName
output dataSubnetName string = dataSubnetName
output vaultSubnetName string = vaultSubnetName
output webSubnetName string = webSubnetName
output functionsSubnetName string = functionsSubnetName
output endpointsSubnetName string = endpointsSubnetName
