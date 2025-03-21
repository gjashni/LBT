# Interface
Rename-Netadapter -Name Ethernet0 -NewName lan1
New-NetIPAddress `
    -IPAddress 10.0.30.20 `
    -InterfaceAlias lan1 `
    -DefaultGateway 10.0.30.254 `
    -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias lan1 -ServerAddresses ("10.0.30.1", "10.0.30.2")
Restart-NetAdapter -Name lan1

# Disable IPv6
Disable-NetAdapterBinding -Name "lan1" -ComponentID ms_tcpip6

# NTP
Set-TimeZone -ID "W. Europe Standard time"
w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /reliable:yes /update

Add-Computer `
    -NewName "W-LBT-IIS" `
    -DomainName "lbt12.at" `
    -Credential (Get-Credential LBT12\Administrator) `
    -Restart

# --- RESTART

Install-WindowsFeature Web-WebServer -IncludeManagementTools

New-SmbShare `
    -Name CertEnroll `
    -Path C:\CertEnroll `
    -FullAccess SYSTEM,"lbt12\Domain Admins" `
    -ChangeAccess "lbt12\Cert Publishers"
New-WebVirtualDirectory `
    -Site "Default Web Site" `
    -Name CertEnroll `
    -PhysicalPath C:\CertEnroll

icacls C:\CertEnroll\  /grant:r '"IIS APPPOOL\DefaultAppPool":(OI)(CI)(RX)'
icacls C:\CertEnroll\  /grant:r '"LBT12\Cert Publishers":(OI)(CI)(M)'

Set-WebConfigurationProperty `
    -Filter system.webServer/security/requestFiltering `
    -PSPath 'IIS:\Sites\Default Web Site\CertEnroll' `
    -Name allowDoubleEscaping `
    -Value True

iisreset
