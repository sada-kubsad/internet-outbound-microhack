param ($AzFwName)
$rg = "internet-outbound-microhack-rg"
$wvdSessionHostPoolSubnet = "10.59.1.0/24"

$appRulesUrls = @( `
@('gcs.prod.monitoring.core.windows.net','https'), ` 	
@('production.diagnostics.monitoring.core.windows.net','https'), ` 	
@('*xt.blob.core.windows.net','https'), `
@('*eh.servicebus.windows.net','https'), ` 	
@('*xt.table.core.windows.net','https'), ` 	
@('catalogartifact.azureedge.net','https'), `
@('kms.core.windows.net','https:1688'), `
@('mrsglobalsteus2prod.blob.core.windows.net','https'), `
@('wvdportalstorageblob.blob.core.windows.net','https'))

$appRules = @()

$index = 1
foreach ($url in $appRulesUrls) {
    $fqdn = $url[0]
    $port = $url[1]

    $appRules += new-AzFirewallApplicationRule -Name "wvd_app_rule_$index" -SourceAddress $wvdSessionHostPoolSubnet -TargetFqdn $fqdn -Protocol $port -Description "Allow access to $fqdn"
    $index += 1
         
}

$wvdApplicationRuleCollection = New-AzFirewallApplicationRuleCollection -Name WVD-DIRECT-ApplicationRules -Priority 1157 -ActionType Allow -Rule $appRules

$netRules = @()
$netRules += new-AzFirewallNetworkRule -Name "wvd_net_rule_1" -SourceAddress $wvdSessionHostPoolSubnet -DestinationAddress "WindowsVirtualDesktop" -DestinationPort 443 -Protocol TCP -Description "Allow access to WindowsVirtualDesktop service tag"
    $index += 1
$wvdNetworkRuleCollection = New-AzFirewallNetworkRuleCollection -Name WVD-DIRECT-NetworkRules -Priority 1157 -ActionType Allow -Rule $netRules


$azfw = Get-AzFirewall -Name $azFwName -ResourceGroupName $rg
$azfw.ApplicationRuleCollections.Add($wvdApplicationRuleCollection)
$azfw.NetworkRuleCollections.Add($wvdNetworkRuleCollection)
Set-AzFirewall -AzureFirewall $azfw
