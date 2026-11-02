#import "@preview/cetz:0.5.2": canvas, draw

#set page(
  width: 54cm,
  height: 22.3cm,
  margin: 0pt,
  fill: white,
)
#set text(font: "Arial", fill: rgb("#161616"))

#let cm-green = rgb("#b8d0a8")
#let cm-blue = rgb("#90b8d8")
#let cm-orange = rgb("#e8a078")
#let cm-line = rgb("#5c5c5c")
#let cm-ink = rgb("#161616")
#let band = rgb("#f3f6ef")
#let band-line = rgb("#8d9784")
#let cm-edge = (paint: cm-line, thickness: 0.8pt, cap: "round", join: "round")
#let cm-box = (paint: cm-line, thickness: 0.9pt, cap: "butt", join: "miter")

#let cm-words(title, subtitle, width) = box(width: width * 1cm)[
  #set text(font: "Arial", fill: cm-ink, hyphenate: false)
  #set par(leading: 0.06em)
  #align(center)[
    #text(size: 8pt, weight: "bold", title)
    #if subtitle != none [
      #v(1.2pt)
      #text(size: 7.5pt, weight: "regular", subtitle)
    ]
  ]
]

#let cm-tag(body) = box(fill: white, inset: (x: 2.5pt, y: 1pt))[
  #set text(font: "Arial", size: 7.5pt, fill: cm-ink, hyphenate: false)
  #body
]

#let entity(x, y, w, bh, title, subtitle) = {
  draw.rect(
    (x - w / 2, y - bh / 2),
    (x + w / 2, y + bh / 2),
    fill: cm-green,
    stroke: cm-box,
  )
  draw.content((x, y), cm-words(title, subtitle, w - 0.22))
}

#let agent-box(x, y, w, bh, title, subtitle) = {
  draw.rect(
    (x - w / 2, y - bh / 2),
    (x + w / 2, y + bh / 2),
    fill: cm-orange,
    stroke: cm-box,
  )
  draw.content((x, y), cm-words(title, subtitle, w - 0.22))
}

#let event-box(x, y, w, bh, title, subtitle) = {
  draw.rect(
    (x - w / 2, y - bh / 2),
    (x + w / 2, y + bh / 2),
    fill: cm-blue,
    stroke: cm-box,
  )
  draw.content((x, y), cm-words(title, subtitle, w - 0.3))
}

#let arrow-mark = (end: (symbol: ">", fill: cm-line, scale: 1.05))

#let up-arrow(x, y0, y1, label, side: 1, at: none) = {
  draw.line((x, y0), (x, y1), stroke: cm-edge, mark: arrow-mark)
  let anchor = if side < 0 { "east" } else { "west" }
  let my = if at == none { (y0 + y1) / 2 } else { at }
  draw.content((x + side * 0.14, my), cm-tag(label), anchor: anchor)
}

#let down-arrow(x, y0, y1, label, side: 1, at: none) = {
  draw.line((x, y0), (x, y1), stroke: cm-edge, mark: arrow-mark)
  let anchor = if side < 0 { "east" } else { "west" }
  let my = if at == none { (y0 + y1) / 2 } else { at }
  draw.content((x + side * 0.14, my), cm-tag(label), anchor: anchor)
}

// Arrow from an analysis to the protocol beside it. The label sits above the line.
#let h-arrow(x0, y, x1, label) = {
  draw.line((x0, y), (x1, y), stroke: cm-edge, mark: arrow-mark)
  draw.content(((x0 + x1) / 2, y + 0.07), cm-tag(label), anchor: "south")
}

#let fan-up(px, py, tops, label, below: false) = {
  let bus-y = py - 0.58
  draw.line((px, bus-y), (px, py), stroke: cm-edge, mark: arrow-mark)
  let xs = tops.map(t => t.at(0)).sorted()
  draw.line((xs.first(), bus-y), (xs.last(), bus-y), stroke: cm-edge)
  for x in xs {
    draw.line((x, tops.find(t => t.at(0) == x).at(1)), (x, bus-y), stroke: cm-edge)
  }
  let lx = (xs.first() + px) / 2
  if below {
    draw.content((lx, bus-y - 0.05), cm-tag(label), anchor: "north")
  } else {
    draw.content((lx, bus-y + 0.05), cm-tag(label), anchor: "south")
  }
}

#let band-box(x0, y0, x1, y1, title) = {
  draw.rect(
    (x0, y0),
    (x1, y1),
    fill: band,
    stroke: (paint: band-line, thickness: 0.7pt, dash: "dashed"),
  )
  draw.content(
    (x0 + 0.28, y1 - 0.16),
    text(font: "Arial", size: 8.5pt, weight: "bold", fill: rgb("#2c2c2c"), title),
    anchor: "north-west",
  )
}

#let bh = 1.22
#let top(y) = y + bh / 2
#let bot(y) = y - bh / 2

// The 106 μm fraction repeats the 500 μm fraction, so it is not drawn.
// The extra width gives each analysis a protocol beside it.
#let band-x = (0.55, 17.65, 34.6)
#let band-w = (16.15, 16.0, 18.95)

#let y-event = 21.05
#let y-unit = 18.65
#let y-frac = 15.35
#let y-split = 12.85
#let y-work = 10.35
#let y-seq = 7.85
#let y-dna = 5.35
#let y-occ = 2.85
#let frame-top = 16.65
#let frame-bot = 1.7

#canvas(length: 1cm, {
  import draw: *
  rect((0, 0), (54.0, 22.3), stroke: none, fill: none)

  for i in range(3) {
    let titles = (
      [Sessile organisms],
      [500 μm fraction],
      [Animals > 2 mm],
    )
    band-box(
      band-x.at(i),
      frame-bot,
      band-x.at(i) + band-w.at(i),
      frame-top,
      titles.at(i),
    )
  }

  let s-media = 3.3
  let s-hom = 8.9
  let s-frac = 6.1
  let s-agent = 2.08
  let s-occ = 4.52
  let s-proto = 14.4
  let w-hom = 20.3
  let w-arch = 31.25
  let w-frac = 25.775
  let w-proto = 25.8
  let a-id = 37.45
  let a-occ = 36.17
  let a-agent = 38.73
  let a-media = 42.25
  let a-dna = 46.3
  let a-proto = 51.4
  let a-frac = 41.875
  let ux = (s-frac + w-frac + a-frac) / 3

  event-box(ux, y-event, 5.3, bh, [Event], [ARMS deployment])
  entity(ux, y-unit, 5.6, bh, [Material Entity], [ARMS unit])

  entity(s-frac, y-frac, 7.6, bh, [Material Entity], [growth on the plates])
  entity(w-frac, y-frac, 12.2, bh, [Material Entity], [caught on the 500 μm sieve])
  entity(a-frac, y-frac, 10.2, bh, [Material Entity], [one animal])

  // Sessile: photographs, and a homogenate of the scraped growth.
  entity(s-media, y-split, 4.7, bh, [Media Entity], [plate photographs])
  entity(s-hom, y-split, 4.4, bh, [Material Entity], [scraped homogenate])
  entity(s-media, y-seq, 4.7, bh, [Identification], [from the photographs])
  agent-box(s-agent, y-dna, 2.15, bh, [Agent], [identifier])
  event-box(s-occ, y-dna, 2.15, bh, [Occurrence], [on the plates])
  entity(s-proto, y-work, 3.6, bh, [Molecular Protocol], [COI metabarcoding])
  entity(s-hom, y-work, 4.4, bh, [Nucleotide Analysis], [COI metabarcoding])
  entity(s-hom, y-seq, 4.4, bh, [Nucleotide Sequence], [the ASVs])
  entity(s-hom, y-dna, 4.4, bh, [Identification], [DNA])
  event-box(s-hom, y-occ, 4.4, bh, [Occurrence], [an ASV])

  // 500 μm fraction, split by weight. The archived half is not sequenced.
  entity(w-hom, y-split, 4.4, bh, [Material Entity], [homogenate · eDNA])
  entity(w-arch, y-split, 4.0, bh, [Material Entity], [archived half])
  entity(w-hom, y-work, 4.3, bh, [Nucleotide Analysis], [COI metabarcoding])
  entity(w-proto, y-work, 3.6, bh, [Molecular Protocol], [COI metabarcoding])
  entity(w-hom, y-seq, 4.3, bh, [Nucleotide Sequence], [the ASVs])
  entity(w-hom, y-dna, 4.3, bh, [Identification], [DNA])
  event-box(w-hom, y-occ, 4.3, bh, [Occurrence], [an ASV])

  // Animals retained on the 2 mm sieve. The identification is of the
  // material itself; the photograph is a separate media link.
  entity(a-id, y-split, 4.8, bh, [Identification], [of the animal])
  event-box(a-occ, y-work, 2.2, bh, [Occurrence], [the animal])
  agent-box(a-agent, y-work, 2.2, bh, [Agent], [identifier])
  entity(a-media, y-split, 3.4, bh, [Media Entity], [photograph, alive])
  entity(a-dna, y-split, 3.5, bh, [Nucleotide Analysis], [COI barcode])
  entity(a-proto, y-split, 3.6, bh, [Molecular Protocol], [COI barcode])
  entity(a-dna, y-work, 3.5, bh, [Nucleotide Sequence], [the barcode])
  entity(a-dna, y-dna, 3.5, bh, [Identification], [DNA])
  event-box(a-dna, y-occ, 3.5, bh, [Occurrence], [the barcode])

  // Edges. Drawn after the boxes so the arrowheads stay visible.
  up-arrow(ux, top(y-unit), bot(y-event), [collected during])
  fan-up(
    ux,
    bot(y-unit),
    (s-frac, w-frac, a-frac).map(x => (x, top(y-frac))),
    [derived from],
  )

  up-arrow(s-media, top(y-split), bot(y-frac), [about])
  up-arrow(s-hom, top(y-split), bot(y-frac), [derived from], side: -1)
  up-arrow(s-media, top(y-seq), bot(y-split), [based on], at: bot(y-split) - 0.5)
  h-arrow(s-hom + 4.4 / 2, y-work, s-proto - 3.6 / 2, [followed])
  down-arrow(s-agent, bot(y-seq), top(y-dna), [identified by], side: -1)
  down-arrow(s-occ, bot(y-seq), top(y-dna), [based on], side: 1)
  up-arrow(s-hom, top(y-work), bot(y-split), [based on], side: -1)
  down-arrow(s-hom, bot(y-work), top(y-seq), [produced], side: -1)
  up-arrow(s-hom, top(y-dna), bot(y-seq), [based on], side: -1)
  down-arrow(s-hom, bot(y-dna), top(y-occ), [based on], side: 1)

  fan-up(
    w-frac,
    bot(y-frac),
    ((w-hom, top(y-split)), (w-arch, top(y-split))),
    [derived from],
    below: true,
  )
  up-arrow(w-hom, top(y-work), bot(y-split), [based on], side: -1)
  h-arrow(w-hom + 4.3 / 2, y-work, w-proto - 3.6 / 2, [followed])
  down-arrow(w-hom, bot(y-work), top(y-seq), [produced], side: -1)
  up-arrow(w-hom, top(y-dna), bot(y-seq), [based on], side: -1)
  down-arrow(w-hom, bot(y-dna), top(y-occ), [based on], side: 1)

  up-arrow(a-id, top(y-split), bot(y-frac), [of a])
  down-arrow(a-occ, bot(y-split), top(y-work), [based on], side: -1)
  down-arrow(a-agent, bot(y-split), top(y-work), [identified by], side: 1)
  up-arrow(a-media, top(y-split), bot(y-frac), [about])
  up-arrow(a-dna, top(y-split), bot(y-frac), [based on], side: -1)
  h-arrow(a-dna + 3.5 / 2, y-split, a-proto - 3.6 / 2, [followed])
  down-arrow(a-dna, bot(y-split), top(y-work), [produced], side: -1)
  up-arrow(a-dna, top(y-dna), bot(y-work), [based on], side: -1)
  down-arrow(a-dna, bot(y-dna), top(y-occ), [based on], side: 1)
})
