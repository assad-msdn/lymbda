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
      appSubnetResourceId: '${vnetid}/subnets/acaAppSubnet'
      controlPlaneSubnetResourceId: '${vnetid}/subnets/acaControlPlaneSubnet'
    }
  }
}
