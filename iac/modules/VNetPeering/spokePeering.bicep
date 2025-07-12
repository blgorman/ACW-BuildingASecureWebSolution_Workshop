param vnetName string 
param remoteVNetId string 

resource spokeVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: '${vnetName}/spoke-to-hub'
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
