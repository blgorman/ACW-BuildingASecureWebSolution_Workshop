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
@description('location for all resources')
param location string

@minLength(1)
@description('location abbreviation for all resources')
param locationAbbreviation string

@description('Tags for the resources')
param tags object

//vnet
param addressPrefix01 int
param addressPrefix02 int

//hub variables
var vnetPrefix = 'vnet'
var vnetHubName = '${vnetPrefix}-hub-${applicationName}-${locationAbbreviation}-${environmentName}'
var vnetAddressSpacePrefix = '${addressPrefix01}.${addressPrefix02}'
var vnetAddressSpace = '${vnetAddressSpacePrefix}.0.0/16'

//vnet gateway subnet (Azure VPN Gateway)
var gatewaySubnetPrefix03 = 1
var gatewaySubnetPrefix04 = 0
var gatewaySubnetSize = 24
var gatewaySubnetName = 'GatewaySubnet' // Azure requires this specific name for the gateway subnet, do not change it
var gatewaySubnetAddress = '${vnetAddressSpacePrefix}.${gatewaySubnetPrefix03}.${gatewaySubnetPrefix04}/${gatewaySubnetSize}'

//vnet firewall subnet (Azure Firewall)
var firewallSubnetPrefix03 = 2
var firewallSubnetPrefix04 = 0
var firewallSubnetSize = 26
var firewallSubnetName = 'AzureFirewallSubnet'  // Azure requires this specific name for the firewall subnet, do not change it
var firewallSubnetAddress = '${vnetAddressSpacePrefix}.${firewallSubnetPrefix03}.${firewallSubnetPrefix04}/${firewallSubnetSize}'

//firewall-management-subnet (Azure Firewall Management)
var firewallManagementSubnetPrefix03 = 2
var firewallManagementSubnetPrefix04 = 64
var firewallManagementSubnetSize = 26
var firewallManagementSubnetName = 'AzureFirewallManagementSubnet' // Azure requires this specific name for the firewall management subnet, do not change it
var firewallManagementSubnetAddress = '${vnetAddressSpacePrefix}.${firewallManagementSubnetPrefix03}.${firewallManagementSubnetPrefix04}/${firewallManagementSubnetSize}'

//bastion subnet
var bastionSubnetPrefix03 = 3
var bastionSubnetPrefix04 = 0
var bastionSubnetSize = 24
var bastionSubnetName = 'AzureBastionSubnet' // Azure requires this specific name for the Bastion subnet, do not change it
var bastionSubnetAddress = '${vnetAddressSpacePrefix}.${bastionSubnetPrefix03}.${bastionSubnetPrefix04}/${bastionSubnetSize}'

//management (vm) subnet
var managementSubnetPrefix03 = 4
var managementSubnetPrefix04 = 0
var managementSubnetSize = 24
var managementSubnetName = 'ManagementSubnet' // Custom name for the management subnet, you can change this as needed
var managementSubnetAddress = '${vnetAddressSpacePrefix}.${managementSubnetPrefix03}.${managementSubnetPrefix04}/${managementSubnetSize}'

//hub VNet
resource vnetHub 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetHubName
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
        name: gatewaySubnetName
        properties: {
          addressPrefix: gatewaySubnetAddress
          delegations: []
        }
      }
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: firewallSubnetAddress
          delegations: []
        }
      }
      {
        name: firewallManagementSubnetName
        properties: {
          addressPrefix: firewallManagementSubnetAddress
          delegations: []
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddress
          delegations: []
        }
      }
      {
        name: managementSubnetName
        properties: {
          addressPrefix: managementSubnetAddress
          delegations: []
        }
      }
    ]
  }
}

output vnetHubId string = vnetHub.id
output vnetHubName string = vnetHub.name
