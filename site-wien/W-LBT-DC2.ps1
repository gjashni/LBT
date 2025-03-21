# Interface
Rename-Netadapter -Name Ethernet0 -NewName lan1
New-NetIPAddress `
    -IPAddress 10.0.30.2 `
    -InterfaceAlias lan1 `
    -DefaultGateway 10.0.30.254 `
    -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias lan1 -ServerAddresses ("10.0.30.1", "10.0.30.2")
Restart-NetAdapter -Name lan1

# Disable IPv6
Disable-NetAdapterBinding -Name "lan1" -ComponentID ms_tcpip6

Add-Computer `
    -NewName "W-LBT-DC2" `
    –DomainName "lbt12.at" `
    -Credential (Get-Credential LBT12\Administrator) `
    -Restart

# --- RESTART

$pw = convertto-securestring -string "TeamLBT12!" -asplaintext -force

# Install ADDS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-ADDSDomainController `
    -InstallDns `
    -DomainName "lbt12.at" `
    -SafeModeAdministratorPassword $pw `
    -Credential (Get-Credential 'LBT12\Administrator')

Install-WindowsFeature DHCP -IncludeManagementTools
