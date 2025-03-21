#import "@htl3r/document:0.1.0": *

#show: doc => conf(
  doc,
  title: [Little Big Topo],
  subtitle: [Eine gesamte Topologie über die Inhalte der 4. und 5. Klasse Netzwerktechnik],
  authors: ("Albin Gashi", ),
  fach: "NWT",
  thema: "Little Big Topo",
)

#set heading(numbering: (..nums) => {
  let numbers = nums.pos()
  if numbers.len() <= 4 {
    numbering("1.1.1.1", ..numbers)
  } else {
    numbering(() => {h(-0.3em)})
  }
})

= Einleitung

#include "portfolio/intro.typ"

#pagebreak()

#page(
  flipped: true
)[
  #grid(
    columns: 1fr,
    rows: (20pt, 1fr),
    [== Netzplan],
    align(center)[#image("portfolio/assets/LBT-Netzplan.png", width: 75%)]
  )
]

#pagebreak()

= Standort Wien

#include "portfolio/site-wien.typ"

= Standort Heidleberg

#include "portfolio/site-heidelberg.typ"

//#include "portfolio/firewalls.typ"

= Konfiguration <config>
Alle Scripts sind auf https://github.com/gjashni/LBT zu finden.
/*
#include "portfolio/config.typ"
*/
