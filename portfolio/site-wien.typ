#import "@htl3r/document:0.1.0": *
#import "@preview/treet:0.1.1": *
#import "@preview/codly:1.2.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(languages: codly-languages)

Standort Wien bildet den zentralen Knotenpunkt des Unternehmens. Auf diesem Ort laufen die wichtigsten Dienste des Active-Directories. Zu diesen zählen eine PKI in Kombinaiton mit IIS, DHCP, ein mithilfe von AGDLP umgesetzter Share und IPAM.

#figure(
  image("../portfolio/assets/netzplan-wien.png", width: 100%),
  caption: [Aufbau des Standortes Wien],
)

#pagebreak()

Das Netzwerk ist in vier VLANs mikrosegmentiert:

#figure(
  table(
    columns: (auto, 1fr, auto),
    inset: 10pt,
    align: (center, center, left),
    table.header(
      [*VLAN*], [*Name*], [*Description*],
    ),
    "10", "CLIENTS", "Alle Mitarbeiter-PCs",
    "20", "SERVICES", "Für Services wie PKI & IIS",
    "30", "DC", "Alle Domain-Controller inklusive JUMP-Server",
    "40", "MGMT", "Management VLAN mit SYSLOG-Server und PAW"
  ),
  caption: [Mikrosegmentierung des Standorts Wien]
)


== FortiGate

An jeweils beiden Core-Switches ist eine FortiGate angeschlossen, die als HA-Cluster geformt ist. Hier stellt sich nun die Frage: an welchem Interface terminiert der Site-to-Site VPN? Hierfür wurde an der FortiGate ein Loopback-Interface konfiguriert und mithilfe von BGP an die beiden autonomen Systeme propagiert. Dadurch erreicht die pfSense über ihre ISP-Anbindung das Loopback Interface einer der beiden FortiGates, auch im Falle eines Ausfalls.

In einem HA-Cluster existieren Primary und Secondary Rollen. Die Secondary-FortiGate spricht über die Heartbeat-Ports mit der Primary-Rolle und aktualisiert damit die Konfiguration.

#figure(
  image("../portfolio/assets/fg-ha.png", width: 100%),
  caption: [Die Secondary-FortiGate beim synchronisieren der Konfiguration],
)

Die FortiGates übernehmen das Inter-VLAN-Routing der Mikrosegmentierung. Hierfür wurden an einem Trunk-Interface die VLANs angelegt. Im folgenden Abbild sind die konfigurierten Interfaces zu sehen. An erster Stelle ist auch das vorher erwähnte Loopback-Interface aufgelistet.

#figure(
  image("../portfolio/assets/fg-int.png", width: 80%),
  caption: [Die Interfaces der FortiGate W-LBT-FG],
)

Sehen wir uns nun die BGP-Konfiguration an. Als AS-Nummer wurdfe 99 gewählt. Wie vorhin erwähnt, wird das Netz `12.12.12.12` via BGP an die Nachbarn von AS815 und AS2 verteilt.

#figure(
  image("../portfolio/assets/fg-bgp2.png", width: 60%),
  caption: [BGP-Konfiguration an der FortiGate W-LBT-FG],
)

Am Border-Router vom ISP Magenta sehen wir die BGP-Route in der ROuting-Tabelle aufscheinen.

#figure(
  image("../portfolio/assets/bgp-loopback.png", width: 80%),
  caption: [BGP-Konfiguration an der FortiGate W-LBT-FG],
)

#pagebreak()

Nun kann auch der VPN konfiguriert werden. Dafür werden für beide IKEv2 Phasen entsprechende Konfigurationen angelegt.


#figure(
  image("../portfolio/assets/fg-phase1.png", width: 50%),
  caption: [IKEv2 Phase1-Konfiguration an der FortiGate W-LBT-FG],
)

#figure(
  image("../portfolio/assets/fg-phase2.png", width: 50%),
  caption: [IKEv2 Phase2-Konfiguration an der FortiGate W-LBT-FG],
)

#pagebreak()

Zur guter Letzt dürfen Policies nicht fehlen. Besonders bei Inter-VLAN-Routing sind diese essenziell, um den Traffic zwischen den VLANs aufs nötigste zu limitieren. Die letzte Policy ist besonders für Jump-Server und PAW relevant, da dies den VLAN-übergreifenden Traffic nur mit der MAC-Adresse der PAW auf die MAC-Adresse des Jump-Servers zulässt (siehe @jump-paw). Des Weiteren sind für die Internet-Policy Malware- und Webfilter sowie SSL- und Signature-Based-Inspection konfiguriert. Dies wird beim Testen mit einem EICAR-File relevant.

#figure(
  image("../portfolio/assets/fg-policies.png", width: 100%),
  caption: [Policies an der FortiGate W-LBT-FG],
)

== Active Directory

=== OUs, Benutzer und Gruppen

Für die OU-Struktur wurde sich an die Mikrosegmentieurng der VLANs orientiert. Dabei werden Server in Services und Domain Controllers eingeteilt. Für die Gruppen wird in Global und Domain Local unterschieden. Die Benutzer werden entsprechend ihren Abteilungen zugeteilt (inkl. Protected Users). In W-LBT-DC1 und wW-LBT-DC2 (siehe @config) werden die Powershell-Scripts für das automatische Anlegen der Benutzer, Gruppen und OUs sowie die Konfiguration der Domain-Controller aufgelistet.

#figure(
  align(center, box(align(left, text[
    #text(blue, tree-list(
      marker: text(gray)[├── ],
      last-marker: text(gray)[└── ],
      indent: text(gray)[│#h(1.5em)],
      empty-indent: h(2em),
    )[
      - Servers
        - Services
        - Domain Controllers
      - Computers
      - Groups
        - Global
        - Domain Local
      - Users
        - Management
        - Finance
        - IT
        - Protected Users
    ])
  ]))),
  caption: [Die OU-Struktur von lbt12.at und heidelberg.lbt12.at]
)

#figure(
  table(
    columns: (auto, 1fr, auto),
    inset: 10pt,
    align: (left, left, left),
    table.header[*Benutzername*][*Name*][*Gruppe*],
    [smueller], [Sarah Müller], [IT, Protected Users],
    [mschmidt], [Markus Schmidt], [Management],
    [lweber], [Lena Weber], [Finanzen],
  ),
  caption: [Die Benutzer der Domäne lbt12.at]
)

=== Berechtigungen auf dem DFS-Share

Den Usern wurde mittels AGDLP Berechtigungen auf dem DFS-Share erteilt. Dabei erhält jede globale Gruppe eine Domain Local Gruppe mit spezifischen Berechtigungen wie Read oder Write.

#figure(
  image("../portfolio/assets/agdlp_finanzen.png", width: 85%),
  caption: [Befehlsausgabe von #emph("Get-ACL") für den Finanzen-Ordner],
)

#figure(
  image("../portfolio/assets/agdlp_mgmt.png", width: 85%),
  caption: [Befehlsausgabe von #emph("Get-ACL") für den Management-Ordner],
)

#figure(
  image("../portfolio/assets/agdlp_it.png", width: 85%),
  caption: [Befehlsausgabe von #emph("Get-ACL") für den IT-Ordner],
)

#pagebreak()

=== Group Policy Objects <gpo>

In der folgenden Tabelle werden alle implementierten GPOs und ihre Funktion aufgelistet:

#figure(
  table(
    columns: (auto, 1fr, 0.35fr),
    inset: 10pt,
    align: (left, left, center),
    table.header[*GPO*][*Funktion*][*verknüpft*],
    [DriveMount], [Mountet den DFS-Share automatisch an den Clients an], [lbt12.at],
    [LastUserNotShown], [Am Login-Screen der Mitarbeiter-PCs werden keine anderen User angezeigt], [lbt12.at],
    [DesktopWallpaper], [Setzt für alle PCs ein einheitliches Desktop-Wallpaper], [lbt12.at],
    [LogonScreen], [Setzt für alle PCs ein einheitliches Login-Wallpaper], [lbt12.at],
    [PasswordPolicy], [Setzt für alle Benutzer eine Mindestlänge und Komplexität für Passwörter voraus], [lbt12.at],
    [LocalFirewall], [Aktiviert die Lokale Firewall an den PCs und blockiert ICMP], [lbt12.at],
    [AutoCertEnroll], [Installiert automatisch an allen Clients die Root- und Sub-CA-Zertifikate], [lbt12.at],
    [Audits], [Setzt Advanced Audit Policies für besseres Logging im Event Viewer], [lbt12.at],
    [CredentialGuard], [Aktiviert den Credential Guard für PAW und DCs], [DCs, PAW],
    [PAW_AppLocker], [Limitiert bestimmte Apps (z.B. Powershell) für die PAW-Workstation], [PAW],
  ),
  caption: [Die Benutzer der Domäne lbt12.at]
)

=== Public-Key-Infrastructure

Auf dem Standort Wien wird eine Two-Tier-PKI betrieben. Dabei ist die Root-CA vom Netzwerk vollkommen abgekoppelt und die Sub-CA übernimmt die Aufgaben der Zertifikatsausstellungen. Mithilfe eines IIS-Webservers werden den PCs über dem Verzeichnis https://pki.lbt12.at/CertEnroll die Zertifikate bereitgestellt. Des Weiteren wird mittels GPO allen Mitarbeiter-PCs automatisch die Root- und Sub-CA-Zertifikate installiert. Der Webserver ist mit einem SSL-Zertifikat ausgestattet.

#figure(
  image("../portfolio/assets/ca.png", width: 100%),
  caption: [Auszug aus der PKIView von W-LBT-SubCA],
)

=== Jump-Server und PAW <jump-paw>

Der Standort Wien wird über einen Jump-Server administriert, der nur durch eine Priviledged Access Workstation (kurz PAW) über RDP erreichbar ist. Die PAW befindet sich im Management-VLAN, dass vom Internet abgekoppelt ist. Zusätzlich wird an der FortiGate über Inter-VLAN-Routing nur die MAC-Adresse der PAW zugelassen, um zum Jump-Server zu gelangen. Auf der PAW werden über AppLocker Dienste wie Powershell gesperrt, um die weitere Sicherheit zu gewährleisten.

#figure(
  image("../portfolio/assets/jump-server.png", width: 100%),
  caption: [Auszug aus dem Server-Manager von W-LBT-JUMP],
)

=== IPAM

Zur besseren Übersicht auf das Unternehmensnetzwerk wurde am JUMP-Server IPAM implementiert.

#figure(
  image("../portfolio/assets/ipam.png", width: 100%),
  caption: [Auszug aus dem IPAM-Dashboard von W-LBT-JUMP],
)

=== Device Hardening

Trotz der Mikrosegmentierungen müssen die Geräte selbst ebenfalls gehärtet werden. Dabei wurden die Domain-Controller sowie die PAW näher betrachtet. Als erstes wurde ein Credential Guard implementiert, wie es auch bei GPOs in @gpo aufgelistet ist. Dafür wurden die virtuellen Maschinen mit TPM verschlüsselt und anschließend der Credential Guard angewendet.

#figure(
  image("../portfolio/assets/tpm-verified.png", width: 85%),
  caption: [Das aktivierte TPM auf der PAW],
)

Zusätzlich wurde für die PAW eine Local Administrator Password Solution angewendet. Nach der Installation und der Implementierung der GPO wurde es auf dem Jump-Server mit folgenden Befehlen getestet:
/*
```powershell
Import-Module AdmPwd.PS
Update-AdmPwdADSchema
Get-AdmPwdPassword -ComputerName "W-LBT-PAW"
```
*/
#figure(
  image("../portfolio/assets/laps.png", width: 100%),
  caption: [Ausgabe des Administratorpassworts von der PAW],
)
