// param location string = resourceGroup().location
param location string
// param storageAccountName string = 'msdnsa${uniqueString(resourceGroup().id)}'
param prefix string
param vnetid string


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${prefix}-la-workspace'
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
  }
}

resource env 'Microsoft.App/managedEnvironments@2022-06-01-preview'= {
  name: '${prefix}-container-env'
  location: location
  kind: 'containerenvironment'
  properties: {
    environmentType: 'managed'
    internalLoadBalancerEnabled: false
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listkeys().primarySharedKey

      }
    }
    containerAppsConfiguration: {
      appSubnetResourceId: '${vnetid}/subnets/acaAppSubnet'
      controlPlaneSubnetResourceId: '${vnetid}/subnets/acaControlPlaneSubnet'
    }
  }
}
