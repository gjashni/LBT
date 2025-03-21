Rename-Computer W-LBT-DC1

# Interface
Rename-Netadapter -Name Ethernet0 -NewName lan1
New-NetIPAddress `
    -IPAddress 10.0.30.1 `
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

Restart-Computer

# --- RESTART


$pw = convertto-securestring -string "TeamLBT12!" -asplaintext -force

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName lbt12.at -SafeModeAdministratorPassword $pw

# Rename Site
Get-ADObject `
    -SearchBase (Get-ADRootDSE).ConfigurationNamingContext `
    -filter "objectclass -eq 'site'" | `
    Set-ADObject -DisplayName Wien
Get-ADObject `
    -SearchBase (Get-ADRootDSE).ConfigurationNamingContext `
    -filter "objectclass -eq 'site'" | `
    Rename-ADObject -NewName Wien

# Create Site
New-ADReplicationSite -Name "Heidelberg"
New-ADReplicationSiteLink `
    -Name "Wien-Heidelberg" `
    -SitesIncluded Wien,Heidelberg `
    -Cost 100 `
    -ReplicationFrequencyInMinutes 15 `
    -InterSiteTransportProtocol IP

Remove-ADReplicationSiteLink -Identity DEFAULTIPSITELINK

# Set Subnets to Site
New-ADReplicationSubnet -Name "10.0.30.0/24" -Site "Wien"
New-ADReplicationSubnet -Name "172.16.10.0/24" -Site "Heidelberg"
New-ADReplicationSubnet -Name "192.168.10.0/24" -Site "Eisenstadt"

Move-ADDirectoryServer -Identity "HD-LBT-DC1" -Site "Heidelberg"
Move-ADDirectoryServer -Identity "ES-LBT-DC1" -Site "Eisenstadt"

# DNS-Zone
Add-DnsServerPrimaryZone -Name lbt12.at -ReplicationScope Domain
Set-DnsServerScavenging `
    -ApplyOnAllZones `
    -ScavengingState $true `
    -RefreshInterval 7.00:00:00 `
    -NoRefreshInterval 7.00:00:00
Set-DnsServerZoneAging lbt12.at -Aging $true

# Forwarder
Set-DnsServerForwarder -IPAddress "1.1.1.1" -PassThru

# OUs erstellen
New-ADOrganizationalUnit -Name "Vienna" -Path "DC=lbt12,DC=at"
New-ADOrganizationalUnit -Name "Servers" -Path "OU=Vienna,DC=lbt12,DC=at"
New-ADOrganizationalUnit -Name "Special Accounts" -Path "OU=Vienna,DC=lbt12,DC=at"
New-ADOrganizationalUnit -Name "Mitarbeiter" -Path "OU=Vienna,DC=lbt12,DC=at"

# Gruppen erstellen
# Global
New-ADGroup -Name "Finanzen" `
    -GroupCategory Security `
    -GroupScope Global `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"
New-ADGroup -Name "Management" `
    -GroupCategory Security `
    -GroupScope Global `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"
New-ADGroup -Name "IT" `
    -GroupCategory Security `
    -GroupScope Global `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"

# Local
New-ADGroup -Name "LBT12_1_Finanzen_R" `
    -GroupCategory Security `
    -GroupScope DomainLocal `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"
New-ADGroup -Name "LBT12_1_Finanzen_M" `
    -GroupCategory Security `
    -GroupScope DomainLocal `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"
New-ADGroup -Name "LBT12_2_Management_R" `
    -GroupCategory Security `
    -GroupScope DomainLocal `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"
New-ADGroup -Name "LBT12_2_Managment_M" `
    -GroupCategory Security `
    -GroupScope DomainLocal `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"
New-ADGroup -Name "LBT12_3_IT_R" `
    -GroupCategory Security `
    -GroupScope DomainLocal `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"
New-ADGroup -Name "LBT12_3_IT_M" `
    -GroupCategory Security `
    -GroupScope DomainLocal `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"

# User erstellen (PW: TeamLBT12!)
$pw = convertto-securestring -string "TeamLBT12!" -asplaintext -force
New-ADUser -Name "Sarah Müller" `
    -AccountPassword $pw `
    -DisplayName smueller `
    -Enabled $true `
    -SAMAccountName smueller `
    -UserPrincipalName smueller `
    -Department Geschäftsfürhung `
    -ChangePasswordAtLogon $false `
    -Path "OU=Mitarbeiter, OU=Vienna,DC=lbt12,DC=at"
New-ADUser -Name "Markus Schmidt" `
    -AccountPassword $pw `
    -DisplayName mschmidt `
    -Enabled $true `
    -SAMAccountName mschmidt `
    -UserPrincipalName mschmid `
    -Department Buchhaltung `
    -ChangePasswordAtLogon $false `
    -Path "OU=Mitarbeiter, OU=Vienna,DC=lbt12,DC=at"
New-ADUser -Name "Lena Weber" `
    -AccountPassword $pw `
    -DisplayName lweber `
    -Enabled $true `
    -SAMAccountName lweber `
    -UserPrincipalName lweber `
    -Department Office `
    -ChangePasswordAtLogon $false `
    -Path "OU=Mitarbeiter,OU=Vienna,DC=lbt12,DC=at"

# User zu Gruppen hinzufügen
Add-ADGroupMember -Identity 'IT' -Members "smueller"
Add-ADGroupMember -Identity "Protected Users" -Members "smueller"
Add-ADGroupMember -Identity "Management" -Members "mschmidt"
Add-ADGroupMember -Identity "Finanzen" -Members "lweber"

# DHCP installieren
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerv4Scope `
    -Name "W-LBT-SCOPE-CLIENTS" `
    -StartRange 10.0.10.100 `
    -EndRange 10.0.10.200 `
    -SubnetMask 255.255.255.0 `
    -LeaseDuration 24:00:00 `
    -State Active
Set-DhcpServerv4OptionValue `
    -ScopeID 10.0.10.0 `
    -DNSServer 10.0.30.1,10.0.30.2 `
    -DNSDomain lbt12.at `
    -Router 10.0.10.254
ADD-DHCPServerInDC -DnsName W-LBT-DC2 -IPaddress 10.0.30.2

# Secure Dynamic Updates
Set-DhcpServerv4DnsSetting -ComputerName "w-lbt-dc1.lbt12.at" -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True
Set-DhcpServerv4DnsSetting -ComputerName "w-lbt-dc2.lbt12.at" -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True

# Pointer
Add-DnsServerResourceRecordPtr -Name 10.0.30.1 -PtrDomainName w-lbt-dc1.lbt12.at -ZoneName 30.0.10.in-addr.arpa
Add-DnsServerResourceRecordPtr -Name 10.0.30.2 -PtrDomainName w-lbt-dc2.lbt12.at -ZoneName 30.0.10.in-addr.arpa
