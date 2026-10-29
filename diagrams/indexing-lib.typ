// Shared building blocks for indexing diagrams.
// Used by indexing-old.typ and indexing.typ.

#let ink = rgb("#111827")
#let mute = rgb("#4b5563")
#let faint = rgb("#9ca3af")
#let rule = rgb("#d1d5db")
#let event-fill = rgb("#eff6ff")
#let event-stroke = rgb("#1d4ed8")
#let occ-fill = rgb("#fff7ed")
#let occ-stroke = rgb("#c2410c")
#let mof-fill = rgb("#ecfdf5")
#let mof-stroke = rgb("#047857")
#let inh-fill = rgb("#fff1e6")
#let inh-stroke = rgb("#c2410c")
#let warn = rgb("#b91c1c")
#let warn-fill = rgb("#fef2f2")

#let code(body, size: 11pt, fill: ink, weight: "bold") = text(
  font: ("JetBrains Mono", "DejaVu Sans Mono", "Menlo"),
  size: size,
  fill: fill,
  weight: weight,
  body,
)

#let col-label(body) = text(
  size: 11pt,
  weight: "bold",
  fill: mute,
  tracking: 0.8pt,
  upper(body),
)

#let badge(body, fill: mute, text-fill: white) = box(
  fill: fill,
  radius: 3pt,
  inset: (x: 6pt, y: 2pt),
  baseline: 1pt,
  text(size: 9pt, weight: "bold", fill: text-fill, tracking: 0.4pt, upper(body)),
)

/// Field chip. kind: plain | empty | inherited | mof
#let chip(label, kind: "plain") = {
  if kind == "inherited" {
    box(
      fill: inh-fill,
      stroke: 0.9pt + inh-stroke,
      radius: 4pt,
      inset: (x: 8pt, y: 5pt),
    )[
      #code(label, size: 11pt, fill: ink)
      #h(6pt)
      #badge("inherited", fill: inh-stroke)
    ]
  } else if kind == "empty" {
    box(
      fill: luma(248),
      stroke: 0.75pt + rule,
      radius: 4pt,
      inset: (x: 8pt, y: 5pt),
    )[
      #code(label + " = ", size: 11pt, fill: faint, weight: "medium")
      #text(size: 11pt, style: "italic", fill: faint, weight: "medium")[empty]
    ]
  } else if kind == "mof" {
    box(
      fill: mof-fill,
      stroke: 0.9pt + mof-stroke,
      radius: 4pt,
      inset: (x: 8pt, y: 5pt),
      code(label, size: 11pt, fill: ink),
    )
  } else {
    box(
      fill: white,
      stroke: 0.9pt + ink,
      radius: 4pt,
      inset: (x: 8pt, y: 5pt),
      code(label, size: 11pt, fill: ink),
    )
  }
}

#let record(
  title-text,
  chips,
  fill: event-fill,
  stroke: event-stroke,
  width: 280pt,
  right: none,
) = block(
  width: width,
  fill: fill,
  stroke: 1pt + stroke,
  radius: 8pt,
  inset: 10pt,
)[
  #text(size: 10pt, weight: "bold", fill: stroke, tracking: 0.4pt, upper(title-text))
  #if right != none {
    h(1fr)
    code(right, size: 10pt, fill: ink)
  }
  #v(7pt, weak: true)
  #chips
]

#let mof-bar(body, width: 280pt) = block(
  width: width,
  fill: mof-fill,
  stroke: 1pt + mof-stroke,
  radius: 8pt,
  inset: (x: 10pt, y: 10pt),
)[
  #badge("mof", fill: mof-stroke)
  #h(8pt)
  #code(body, size: 11pt)
]

#let flow-arrow = align(
  center + horizon,
  stack(
    spacing: 4pt,
    text(size: 22pt, weight: "bold", fill: ink)[→],
    text(size: 9pt, weight: "bold", fill: mute, tracking: 0.5pt)[INDEX],
  ),
)

#let parquet-panel(name, body, width: auto) = block(
  width: width,
  fill: luma(252),
  stroke: 0.9pt + rule,
  radius: 8pt,
  clip: true,
)[
  #block(
    width: 100%,
    fill: white,
    inset: (x: 12pt, y: 7pt),
    stroke: (bottom: 0.9pt + rule),
  )[
    #code(name, size: 11pt, fill: ink)
  ]
  #pad(x: 10pt, y: 10pt, body)
]

#let raw-column = stack(
  spacing: 8pt,
  record("Event ST1", chip("lat = 51.26")),
  record(
    "Event ST1:S1",
    stack(dir: ltr, spacing: 6pt, chip("date = 2000-06-12"), chip("lat", kind: "empty")),
  ),
  mof-bar("sediment ×55"),
  record(
    "Occurrence A",
    stack(
      spacing: 6pt,
      chip("name = Branchiostoma"),
      stack(dir: ltr, spacing: 6pt, chip("lat", kind: "empty"), chip("date", kind: "empty")),
    ),
    fill: occ-fill,
    stroke: occ-stroke,
  ),
  record(
    "Occurrence B",
    stack(
      spacing: 6pt,
      chip("name = Nephtys"),
      stack(dir: ltr, spacing: 6pt, chip("lat", kind: "empty"), chip("date", kind: "empty")),
    ),
    fill: occ-fill,
    stroke: occ-stroke,
  ),
  mof-bar("abundance ×2"),
)

#let diagram(indexed-label, indexed-body) = grid(
  columns: (280pt, 48pt, 1fr),
  column-gutter: 10pt,
  align: (top, horizon, top),
  [
    #col-label[Raw source]
    #v(10pt)
    #raw-column
  ],
  flow-arrow,
  [
    #col-label[#indexed-label]
    #v(10pt)
    #indexed-body
  ],
)
