Rename-Computer W-LBT-RootCA

Restart-Computer

# --- Restart

$RootCAPolicy = @"
[Version]
Signature='$Windows NT$'

[PolicyStatementExtension]
Policies=InternalPolicy

[InternalPolicy]
OID= 1.2.3.4.1455.67.89.5
Notice='This is the Root-Certificate-Authority of the LBT Team 12 Domain'
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

New-Item "C:\Windows\CAPolicy.inf" -ItemType File -Value $RootCAPolicy

Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

Install-AdcsCertificationAuthority `
    -CAType StandaloneRootCA `
    -CACommonName "W-LBT-RootCA" `
    -KeyLength 4096 `
    -HashAlgorithmName SHA256 `
    -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
    -DatabaseDirectory $(Join-Path $env:SystemRoot "System32\Certlog")

Restart-Computer

# --- RESTART

$allCRLs = Get-CACRLDistributionPoint
foreach ($crl in $allCRLs) {
    Remove-CACRLDistributionPoint $crl.uri -Force
};

Add-CACRLDistributionPoint `
    -Uri C:\Windows\System32\CertSrv\CertEnroll\W-LBT-RootCA.crl `
    -PublishToServer -Force

Add-CACRLDistributionPoint `
    -Uri http://pki.lbt12.at/CertEnroll/W-LBT-RootCA.crl `
    -AddToCertificateCDP -Force

$allAIAs = Get-CAAuthorityInformationAccess
foreach ($aia in $allAIAs) {
    Remove-CAAuthorityInformationAccess $aia.uri -Force
};

certutil -setreg CA\DSConfigDN "CN=Configuration,DC=lbt12,DC=at"
certutil -setreg CA\CRLPeriodUnits 52
certutil -setreg CA\CRLPeriod "Weeks"
certutil -setreg CA\CRLOverlapPeriodUnits 12
certutil -setreg CA\CRLOverlapPeriod "Hours"
certutil -setreg CA\ValidityPeriodUnits 15
certutil -setreg CA\ValidityPeriod "Years"

Restart-Service CertSvc
certutil -crl

cp C:\Windows\System32\CertSrv\CertEnroll\* E:\cert\

# --- Submit SubCA

certreq -submit E:\W-LBT-PKI.lbt.at_W-LBT-PKI.req
certutil -resubmit 2
certreq -retrieve 2 E:\W-LBT-PKI.lbt.at_W-LBT-PKI.crt
