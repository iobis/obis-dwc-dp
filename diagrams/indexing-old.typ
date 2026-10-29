// Old densify model: raw → occurrence-centric index.
// Compile: typst compile diagrams/indexing-old.typ diagrams/indexing-old.svg

#import "indexing-lib.typ": *

#set page(width: 920pt, height: auto, margin: 28pt, fill: white)
#set text(font: ("Helvetica Neue", "Helvetica", "Arial"), size: 11pt, fill: ink, weight: "medium")

#let occ-doc(id, name) = block(
  width: 100%,
  fill: occ-fill,
  stroke: 1pt + occ-stroke,
  radius: 8pt,
  inset: 12pt,
)[
  #text(size: 10pt, weight: "bold", fill: occ-stroke, tracking: 0.4pt)[OCCURRENCE DOC]
  #h(1fr)
  #badge(id, fill: occ-stroke)
  #v(8pt, weak: true)
  #stack(
    spacing: 6pt,
    chip("name = " + name),
    stack(
      dir: ltr,
      spacing: 6pt,
      chip("lat = 51.26", kind: "inherited"),
      chip("date = 2000-06-12", kind: "inherited"),
    ),
  )
  #v(8pt, weak: true)
  #chip("extensions.mof | abundance", kind: "mof")
  #v(8pt, weak: true)
  #block(
    width: 100%,
    fill: warn-fill,
    stroke: 1.25pt + warn,
    radius: 6pt,
    inset: 10pt,
  )[
    #badge("duplicated", fill: warn)
    #h(8pt)
    #code("extensions.mof | sediment ×55", size: 11pt)
    #v(4pt, weak: true)
    #text(size: 10.5pt, weight: "medium", fill: warn)[
      Copied from the parent event into every occurrence document.
    ]
  ]
]

#diagram(
  [Indexed - occurrence.parquet / Elasticsearch],
  stack(
    spacing: 12pt,
    occ-doc("A", "Branchiostoma"),
    occ-doc("B", "Nephtys"),
  ),
)
