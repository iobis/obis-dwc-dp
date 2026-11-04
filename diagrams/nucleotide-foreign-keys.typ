// Foreign keys among the DwC-DP eDNA tables.
// Compile: typst compile diagrams/nucleotide-foreign-keys.typ diagrams/nucleotide-foreign-keys.svg

#import "@preview/cetz:0.5.2": canvas, draw

#set page(width: auto, height: auto, margin: 14pt, fill: white)
#set text(font: ("Helvetica Neue", "Helvetica", "Arial"), fill: rgb("#111827"), hyphenate: false)

#let ink = rgb("#111827")
#let mute = rgb("#4b5563")
#let event-fill = rgb("#eff6ff")
#let event-stroke = rgb("#1d4ed8")
#let occ-fill = rgb("#fff7ed")
#let occ-stroke = rgb("#c2410c")
#let analysis-fill = rgb("#f0fdfa")
#let analysis-stroke = rgb("#0f766e")
#let seq-fill = rgb("#ecfdf5")
#let seq-stroke = rgb("#047857")
#let id-fill = rgb("#f5f3ff")
#let id-stroke = rgb("#6d28d9")

#let box-words(title, subtitle, width) = box(width: width * 1cm)[
  #set par(leading: 0.12em)
  #align(center)[
    #text(size: 13pt, weight: "bold", title)
    #v(3pt)
    #text(size: 9.5pt, fill: mute, subtitle)
  ]
]

#let fk-tag(field, predicate) = box(fill: white, inset: (x: 5pt, y: 3pt))[
  #set par(leading: 0.08em)
  #align(center)[
    #text(font: ("JetBrains Mono", "DejaVu Sans Mono", "Menlo"), size: 8.5pt, weight: "bold", field)
    #v(1pt)
    #text(size: 9pt, style: "italic", fill: mute, predicate)
  ]
]

#let entity(x, y, w, h, title, subtitle, fill, stroke) = {
  draw.rect(
    (x - w / 2, y - h / 2),
    (x + w / 2, y + h / 2),
    fill: fill,
    stroke: (paint: stroke, thickness: 1.1pt),
    radius: 0.15,
  )
  draw.content((x, y), box-words(title, subtitle, w - 0.35))
}

#let link(a, b, field, predicate) = {
  let stroke = (paint: ink, thickness: 0.9pt, cap: "round")
  draw.line(a, b, stroke: stroke, mark: (end: (symbol: ">", fill: ink, scale: 1.15)))
  let mid = ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2)
  draw.content(mid, fk-tag(field, predicate))
}

#canvas(length: 1cm, {
  import draw: *

  // event sits above the two records that must point at it.
  let event = (16.6, 13.15)
  let occurrence = (7.3, 7.35)
  let analysis = (25.5, 7.35)
  let identification = (7.3, 1.65)
  let sequence = (25.5, 1.65)
  let bh = 1.7
  let event-w = 5.4
  let side-w = 7.2
  let wide-w = 8.8

  link(
    (occurrence.at(0), occurrence.at(1) + bh / 2),
    (event.at(0) - 1.3, event.at(1) - bh / 2),
    "event_fk",
    "has context",
  )
  link(
    (analysis.at(0), analysis.at(1) + bh / 2),
    (event.at(0) + 1.3, event.at(1) - bh / 2),
    "event_fk",
    "material collected during",
  )
  link(
    (analysis.at(0) + 2.2, analysis.at(1) - bh / 2),
    (sequence.at(0) + 2.2, sequence.at(1) + bh / 2),
    "nucleotideSequence_fk",
    "produced",
  )
  link(
    (identification.at(0), identification.at(1) + bh / 2),
    (occurrence.at(0), occurrence.at(1) - bh / 2),
    "occurrence_fk",
    "based on",
  )
  link(
    (identification.at(0) + side-w / 2, identification.at(1)),
    (sequence.at(0) - wide-w / 2, sequence.at(1)),
    "nucleotideSequence_fk",
    "based on",
  )
  entity(..event, event-w, bh, [event], [sampling context], event-fill, event-stroke)
  entity(..occurrence, side-w, bh, [occurrence], [one detection], occ-fill, occ-stroke)
  entity(..analysis, wide-w, bh, [nucleotide-analysis], [sample × sequence, with read count], analysis-fill, analysis-stroke)
  entity(..identification, side-w, bh, [identification], [taxon assignment], id-fill, id-stroke)
  entity(..sequence, wide-w, bh, [nucleotide-sequence], [each distinct sequence, once], seq-fill, seq-stroke)
})
