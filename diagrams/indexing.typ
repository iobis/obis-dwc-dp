// Separate-tables indexing model: raw → separate parquet tables.
// Compile: typst compile diagrams/indexing.typ diagrams/indexing.svg

#import "indexing-lib.typ": *

#set page(width: 920pt, height: auto, margin: 28pt, fill: white)
#set text(font: ("Helvetica Neue", "Helvetica", "Arial"), size: 11pt, fill: ink, weight: "medium")

#let indexed = stack(
  spacing: 12pt,
  parquet-panel(
    "event.parquet",
    stack(
      spacing: 8pt,
      record(
        "Event",
        stack(dir: ltr, spacing: 6pt, chip("lat = 51.26"), chip("date", kind: "empty")),
        width: 100%,
        right: "ST1",
      ),
      record(
        "Event",
        stack(
          dir: ltr,
          spacing: 6pt,
          chip("lat = 51.26", kind: "inherited"),
          chip("date = 2000-06-12"),
        ),
        width: 100%,
        right: "ST1:S1  parent=ST1",
      ),
    ),
    width: 100%,
  ),
  parquet-panel(
    "occurrence.parquet",
    stack(
      spacing: 8pt,
      record(
        "Occurrence A → ST1:S1",
        stack(
          dir: ltr,
          spacing: 6pt,
          chip("lat = 51.26", kind: "inherited"),
          chip("date = 2000-06-12", kind: "inherited"),
        ),
        fill: occ-fill,
        stroke: occ-stroke,
        width: 100%,
      ),
      record(
        "Occurrence B → ST1:S1",
        stack(
          dir: ltr,
          spacing: 6pt,
          chip("lat = 51.26", kind: "inherited"),
          chip("date = 2000-06-12", kind: "inherited"),
        ),
        fill: occ-fill,
        stroke: occ-stroke,
        width: 100%,
      ),
    ),
    width: 100%,
  ),
  grid(
    columns: (1fr, 1fr),
    column-gutter: 12pt,
    parquet-panel(
      "occurrence_measurementorfact",
      stack(
        spacing: 6pt,
        chip("A | abundance", kind: "mof"),
        chip("B | abundance", kind: "mof"),
      ),
      width: 100%,
    ),
    parquet-panel(
      "event_measurementorfact",
      chip("ST1:S1 | sediment ×55", kind: "mof"),
      width: 100%,
    ),
  ),
)

#diagram(
  [Indexed - separate tables],
  indexed,
)
