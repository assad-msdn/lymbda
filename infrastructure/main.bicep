// param location string = resourceGroup().location
param location string
// param storageAccountName string = 'msdnsa${uniqueString(resourceGroup().id)}'
param prefix string

param vnetSettings object = {
  addressPrefixes: [
    '10.0.0.0/19'
  ]
  subnets: [
    {
      name: 'subnet1'
      addressPrefixes: '10.0.0.0/21'
    }
    {
      name: 'acaAppSubnet'
      addressPrefixes: '10.0.8.0/21'
    }
    {
      name: 'acaControlplaneSubnet'
      addressPrefixes: '10.0.16.0/21'
    }
  ]
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${prefix}-default-nsg'
  location: location
  properties: {
    securityRules: [
      
    ]
  }
}


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes:  vnetSettings.addressprefixes
            
    }
    subnets: [ for subnet in vnetSettings.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefixes
        networkSecurityGroup: {
          id:networkSecurityGroup.id
        }
      }
    }]
  }
}


resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' = {
  name: '${prefix}-cosmo-account'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource sqlDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  name: '${prefix}-sqldb'
  parent: cosmosDbAccount
  properties: {
    resource: {
      id: '${prefix}-sqldb'
    }
    options: {
    }
  }
}


resource sqlContainerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  parent: sqlDb 
  name: '${prefix}-orders'
  properties: {
    resource: {
      id: '${prefix}-orders'
      partitionKey: {
        paths: [
          '/id'
        ]
      }
    }
    options: {}
  }
}

resource stateContainerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  parent: sqlDb
  name: '${prefix}-state'
  properties: {
    resource: {
      id:  '${prefix}-state'
       partitionKey:{
        paths:[
         '/partitionkey'
        ]
       }
    }
    options:{
      
    }
  }
}

resource cosmoPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01'={
  name: 'privatelink.documents.azure.com'
  location: 'global'
}

resource cosmoPrivateDnsNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01'= {
  name: '${prefix}-cosmo-dns-link'
  location: 'global'
  parent: cosmoPrivateDns
  properties: {
   registrationEnabled: false
   virtualNetwork: {
    id:virtualNetwork.id
   } 
  }
}


resource cosmoPrivateEndPoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: '${prefix}-cosmo-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${prefix}-cosmo-pe'
        properties: {
          privateLinkServiceId: cosmosDbAccount.id
          groupIds: [
            'SQL'
          ]
        }
      }
    ]
    subnet: {
      id: virtualNetwork.properties.subnets[0].id
    }
  }
}

resource cosmosPrivateEnspointDnsLink 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01'= {
  name: '${prefix}-cosmo-pe-dns'
  parent:cosmoPrivateEndPoint
  properties: {
   privateDnsZoneConfigs: [
      {
       name: 'privatelink.documents.azure.com'
       properties: {
        privateDnsZoneId: cosmoPrivateDns.id
       } 
      }
   ] 
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: '${replace(prefix, '-','')}acr'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'assadkvmsdn01'
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
        sku: {
      name: 'standard'
      family: 'A'
    }
  }
}


resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVault.name}/acrAdminPassword'
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value
  }
}
