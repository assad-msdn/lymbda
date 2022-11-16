// param location string = resourceGroup().location
param location string
// param storageAccountName string = 'msdnsa${uniqueString(resourceGroup().id)}'
param prefix string
param vNetid string


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${prefix}-la-workspace'
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}

resource env 'Microsoft.Web/kubeEnvironments@2022-03-01'= {
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
        sharedKey: logAnalyticsWorkspace.listkeys().primerySharedKey

      }
    }
    containerAppsConfiguration: {
      appSubnetResourceId: '${vNetid}/subnets/acaAppSubnet'
      controlPlaneSubnetResourceId: '${vNetid}/subnets/acaControlPlaneSubnet'
    }
  }
}
