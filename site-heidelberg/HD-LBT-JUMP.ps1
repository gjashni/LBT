Rename-Computer HD-LBT-JUMP

# Interface
Rename-Netadapter -Name Ethernet0 -NewName lan1
New-NetIPAddress `
    -IPAddress 172.16.0.100 `
    -InterfaceAlias lan1 `
    -DefaultGateway 172.16.0.254 `
    -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias lan1 -ServerAddresses ("172.16.0.1", "10.0.30.1")
Restart-NetAdapter -Name lan1

# Disable IPv6
Disable-NetAdapterBinding -Name "lan1" -ComponentID ms_tcpip6

# NTP
Set-TimeZone -ID "W. Europe Standard time"
w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /reliable:yes /update

Add-Computer `
    -NewName "HD-LBT-JUMP" `
    -DomainName "heidelberg.lbt12.at" `
    -Credential (Get-Credential HEIDELBERG\Administrator) `
    -Restart
