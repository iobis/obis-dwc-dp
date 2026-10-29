// DwC-A and DwC-DP eDNA packages → shared index tables (horizontal).
// Compile: typst compile diagrams/edna-index.typ diagrams/edna-index.svg

#set page(width: 1020pt, height: auto, margin: 28pt, fill: white)
#set text(font: ("Helvetica Neue", "Helvetica", "Arial"), size: 11pt, fill: rgb("#111827"), weight: "medium")

#let ink = rgb("#111827")
#let mute = rgb("#4b5563")
#let rule = rgb("#d1d5db")
#let event-fill = rgb("#eff6ff")
#let event-stroke = rgb("#1d4ed8")
#let occ-fill = rgb("#fff7ed")
#let occ-stroke = rgb("#c2410c")
#let seq-fill = rgb("#ecfdf5")
#let seq-stroke = rgb("#047857")
#let id-fill = rgb("#f5f3ff")
#let id-stroke = rgb("#6d28d9")
#let idx-fill = rgb("#f8fafc")

#let code(body, size: 10.5pt, fill: ink, weight: "bold") = text(
  font: ("JetBrains Mono", "DejaVu Sans Mono", "Menlo"),
  size: size,
  fill: fill,
  weight: weight,
  body,
)

#let col-label(body) = text(size: 10pt, weight: "bold", fill: mute, tracking: 0.7pt, upper(body))

#let card(title, body, fill: white, stroke: rule, width: 100%) = block(
  width: width,
  fill: fill,
  stroke: 0.9pt + stroke,
  radius: 8pt,
  inset: 10pt,
)[
  #text(size: 9.5pt, weight: "bold", fill: stroke, tracking: 0.3pt, upper(title))
  #v(6pt, weak: true)
  #body
]

#let tbl(name, note: none, fill: white, stroke: rule) = block(
  width: 100%,
  fill: fill,
  stroke: 0.9pt + stroke,
  radius: 6pt,
  inset: (x: 9pt, y: 7pt),
)[
  #code(name, size: 10.5pt)
  #if note != none {
    h(1fr)
    text(size: 9pt, fill: mute, note)
  }
]

#let flow-right = align(
  center + horizon,
  stack(
    spacing: 3pt,
    text(size: 20pt, weight: "bold", fill: ink)[→],
    text(size: 8.5pt, weight: "bold", fill: mute, tracking: 0.4pt)[INDEX],
  ),
)

#let flow-left = align(
  center + horizon,
  stack(
    spacing: 3pt,
    text(size: 20pt, weight: "bold", fill: ink)[←],
    text(size: 8.5pt, weight: "bold", fill: mute, tracking: 0.4pt)[INDEX],
  ),
)

#let dwca = stack(
  spacing: 8pt,
  col-label[DwC-A publish],
  card(
    "Star schema",
    stack(
      spacing: 6pt,
      tbl("event", note: "optional core", fill: event-fill, stroke: event-stroke),
      tbl("occurrence", note: "1 row / sample × ASV", fill: occ-fill, stroke: occ-stroke),
      tbl("DNADerivedData", note: "densified sequence", fill: seq-fill, stroke: seq-stroke),
    ),
    fill: luma(252),
  ),
)

#let dwcdp = stack(
  spacing: 8pt,
  col-label[DwC-DP publish],
  card(
    "Normalised tables",
    stack(
      spacing: 6pt,
      tbl("event", fill: event-fill, stroke: event-stroke),
      tbl("material", note: "optional / stub", fill: luma(248), stroke: rule),
      tbl("nucleotide_analysis", note: "sample × ASV", fill: seq-fill, stroke: seq-stroke),
      tbl("nucleotide_sequence", note: "distinct ASVs", fill: seq-fill, stroke: seq-stroke),
      tbl("identification", note: "on sequence", fill: id-fill, stroke: id-stroke),
      tbl("occurrence", note: "often absent", fill: luma(248), stroke: rule),
    ),
    fill: luma(252),
  ),
)

#let shared = stack(
  spacing: 8pt,
  align(center, col-label[Shared eDNA index]),
  block(
    width: 100%,
    fill: idx-fill,
    stroke: 1pt + ink,
    radius: 10pt,
    inset: 12pt,
  )[
    #stack(
      spacing: 7pt,
      tbl("event", note: "sample / station", fill: event-fill, stroke: event-stroke),
      tbl("occurrence", note: "published or inferred", fill: occ-fill, stroke: occ-stroke),
      tbl("nucleotide_analysis", note: "occ ↔ seq · read_count", fill: seq-fill, stroke: seq-stroke),
      tbl("nucleotide_sequence", note: "stored once", fill: seq-fill, stroke: seq-stroke),
    )
  ],
)
#grid(
  columns: (1.05fr, 44pt, 1.15fr, 44pt, 1.05fr),
  column-gutter: 8pt,
  align: (top, horizon, top, horizon, top),
  dwca,
  flow-right,
  shared,
  flow-left,
  dwcdp,
)
