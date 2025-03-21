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
    -NewName "W-LBT-SubCA" `
    -DomainName "lbt12.at" `
    -Credential (Get-Credential LBT12\Administrator) `
    -Restart

# --- RESTART

$SubCAPolicy = @"
[Version]
Signature='$Windows NT$'

[PolicyStatementExtension]
Policies=InternalPolicy

[InternalPolicy]
OID= 1.2.3.4.1455.67.89.5
Notice='This is the Sub-Certificate-Authority of the LBT Team 12 Domain'
URL=http://pki.lbt12.at/CertEnroll/cps.txt

[Certsrv_Server]
RenewalKeyLength=4096
RenewalValidityPeriod=Years
RenewalValidityPeriodUnits=20
CRLPeriod=weeks
CRLPeriodUnits=26
CRLDeltaPeriod=Days
CRLDeltaPeriodUnits=0
LoadDefaultTemplates=0
AlternateSignatureAlgorithm=0
"

New-Item "C:\Windows\CAPolicy.inf" -ItemType File -Value $SubCAPolicy

cp -r E:\W* C:\
certutil -addstore -f root C:\W-LBT-RootCA_W-LBT-RootCA.crt
certutil -addstore -f root C:\W-LBT-RootCA.crl

Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

Install-ADCSCertificationAuthority `
    -CAType EnterpriseSubordinateCA `
    -CACommonName W-LBT-SubCA `
    -KeyLength 4096 `
    -HashAlgorithmName SHA256 `
    -CryptoProviderName "RSA#Microsoft Software Key Storage Provider"

cp -r C:\*.req E:\

mkdir C:\CertEnroll\
cp E:\cert\* C:\CertEnroll\

$allCRLs = Get-CACRLDistributionPoint
foreach ($crl in $allCRLs) {
    Remove-CACRLDistributionPoint $crl.uri -Force
};

Add-CACRLDistributionPoint `
    -Uri C:\Windows\System32\CertSrv\CertEnroll\<CaName><CRLNameSuffix><DeltaCRLAllowed>.crl `
    -PublishToServer `
    -PublishDeltaToServer `
    -Force

Add-CACRLDistributionPoint `
    -Uri http://pki.lbt12.at/CertEnroll/<CaName><CRLNameSuffix><DeltaCRLAllowed>.crl `
    -AddToCertificateCdp `
    -Force

Add-CACRLDistributionPoint file://\\pki.lbt12.at\CertEnroll\<CaName><CRLNameSuffix><DeltaCRLAllowed>.crl `
    -PublishToServer `
    -PublishDeltaToServer `
    -Force

$allAIAs = Get-CAAuthorityInformationAccess
foreach ($aia in $allAIAs) {
    Remove-CAAuthorityInformationAccess $aia.uri -Force
};

Add-CAAuthorityInformationAccess `
    -AddToCertificateAia http://pki.lbt12.at/CertEnroll/<ServerDNSName>_<CaName><CertificateName>.crt `
    -Force

certutil -setreg CA\CRLPeriodUnits 2
certutil -setreg CA\CRLPeriod "Weeks"
certutil -setreg CA\CRLDeltaPeriodUnits 2
certutil -setreg CA\CRLDeltaPeriod "Days"
certutil -setreg CA\CRLOverlapPeriodUnits 12
certutil -setreg CA\CRLOverlapPeriod "Hours"
certutil -setreg CA\ValidityPeriodUnits 5
certutil -setreg CA\ValidityPeriod "Years"

Restart-Service CertSvc
certutil -crl
