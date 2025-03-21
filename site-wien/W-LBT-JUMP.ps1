# Interface
Rename-Netadapter -Name Ethernet0 -NewName lan1
New-NetIPAddress -IPAddress 10.0.30.10 -InterfaceAlias lan1 -DefaultGateway 10.0.30.254 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias lan1 -ServerAddresses ("10.0.30.1", "10.0.30.2")
Restart-NetAdapter -Name lan1

# Disable IPv6
Disable-NetAdapterBinding -Name "lan1" -ComponentID ms_tcpip6

# NTP
Set-TimeZone -ID "W. Europe Standard time"
w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /reliable:yes /update

#netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow

Add-Computer -NewName "W-LBT-JUMP" –DomainName "lbt12.at" -Credential (Get-Credential LBT12\Administrator) -Restart

Invoke-IpamGpoProvisioning -Domain lbt12.at -GpoPrefixName GPO_IPAM -IpamServerFqdn w-lbt-jump.lbt12.at

gpupdate /force
