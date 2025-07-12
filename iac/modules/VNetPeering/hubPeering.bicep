@description('Name of the hub vNet')
param vnetName string 
@description('ID of the spoke VNet for peering')
param remoteVNetId string 

resource hubVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: '${vnetName}/hub-to-spoke'
  properties: {
    remoteVirtualNetwork: {
      id: remoteVNetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}
