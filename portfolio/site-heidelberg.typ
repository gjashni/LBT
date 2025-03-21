Der Standort Heidelberg bildet mit einer Child-Domain eine weitere administrative Organisationseinheit im Unternehmen LBT12. Sie besitzt eine pfSense als Firewall und verbindet sich mit dem Standort Wien über einen plattformübergreifenden Site-to-Site VPN via PSK.

#figure(
  image("../portfolio/assets/netzplan-hd.png", width: 100%),
  caption: [Aufbau des Standortes Heidelberg],
)

Die Geräte des Standorts wurden in VLANs segmentiert und über die pfSense mittels Inter-VLAN-Routing verbunden.

#figure(
  table(
    columns: (auto, 1fr, auto),
    inset: 10pt,
    align: (center, center, left),
    table.header(
      [*VLAN*], [*Name*], [*Description*],
    ),
    "10", "CLIENTS", "Alle Mitarbeiter-PCs",
    "20", "SERVERS", "Alle Server der Site Heidelberg",
    "30", "MGMT", "SYSLOG, RSPAN und Netflow",
  ),
  caption: [VLANs des Standort Heidelberg]
)


== pfSense

Als Firewall am Standort Heidelberg wurde eine pfSense implementiert. Sie führt, wie am Standort Wien, ebenfalls das Inter-VLAN-Routing durch. Gemeinsam mit der FortiGate baut sie den Site-to-Site VPN für die Site-Replikation auf.

#figure(
  image("../portfolio/assets/pf-vpn.png", width: 100%),
  caption: [Auszug aus dem pfSense-Dashboard für den IPsec-VPN],
)

#pagebreak()

== Active Directory

In Heidelberg wird ein Domain Controller mit einem Jump-Server zur besseren Administrierung betrieben. Zusätzlich dazu steht ein BIND9-Server als DNS-Forwarder inklusive Caching bereit. Der DFS-Server repliziert den Share des Standort Wien.

#figure(
  image("../portfolio/assets/replicationsite.png", width: 100%),
  caption: [Befehlsausgabe von #emph("Get-ADReplicationSite") für den Site-Link WIEN-HEIDELBERG],
)

#figure(
  image("../portfolio/assets/hd-dfs.png", width: 100%),
  caption: [Die Shares der Active-Directory-Struktur im Überblick],
)
