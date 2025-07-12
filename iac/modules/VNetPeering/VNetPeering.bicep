targetScope='subscription'  

@description('Name of the hub resource group')
param rgHubName string

@description('Name of the spoke resource group')
param rgSpokeName string

@description('Name of the hub virtual network')
param vnetHubName string

@description('Name of the spoke virtual network')
param vnetSpokeName string

//hub group
resource hubRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: rgHubName
}

//spoke group
resource spokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: rgSpokeName
}

//hub vnet
resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetHubName
  scope: hubRG
}

//spoke vnet
resource spokeVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetSpokeName
  scope: spokeRG
}

module hubPeeringModule 'hubPeering.bicep' = {
  name: 'hubPeeringDeployment'
  scope: hubRG
  params: {
    vnetName: vnetHubName
    remoteVNetId: spokeVnet.id
  }
}

module spokePeeringModule 'spokePeering.bicep' = {
  name: 'spokePeeringDeployment'
  scope: spokeRG
  params: {
    vnetName: vnetSpokeName
    remoteVNetId: hubVnet.id
  }
}
