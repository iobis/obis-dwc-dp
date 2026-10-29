#set document(
  title: "Technical Identifiers vs Composite Joins in OBIS",
  author: "Research briefing",
  date: datetime(year: 2026, month: 10, day: 13),
)
#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.4cm),
  numbering: "1",
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 8.5pt, fill: luma(100))
      [Technical IDs in Parquet #h(1fr) Research briefing · 13 Oct 2026]
      line(length: 100%, stroke: 0.4pt + luma(180))
    }
  },
  footer: context {
    set text(size: 8.5pt, fill: luma(100))
    line(length: 100%, stroke: 0.4pt + luma(180))
    v(4pt)
    [Confidential research note #h(1fr) #counter(page).display("1")]
  },
)
#set text(font: "New Computer Modern", size: 10.5pt)
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  v(1.0em)
  set text(size: 14pt, weight: "bold")
  block(it)
  v(0.3em)
}
#show heading.where(level: 2): it => {
  v(0.7em)
  set text(size: 11.5pt, weight: "bold")
  block(it)
  v(0.2em)
}
#show link: set text(fill: rgb("#0B5A8C"))
#show raw.where(block: true): it => block(
  width: 100%,
  fill: luma(246),
  inset: 10pt,
  radius: 3pt,
  stroke: 0.4pt + luma(210),
  it,
)

#let callout(title, body, accent: rgb("#0B5A8C")) = block(
  width: 100%,
  inset: 10pt,
  radius: 3pt,
  stroke: (left: 3pt + accent, rest: 0.4pt + luma(200)),
  fill: luma(250),
)[
  #text(weight: "bold", fill: accent)[#title]
  #v(4pt)
  #body
]

#align(center)[
  #v(1.2cm)
  #text(size: 11pt, fill: luma(90), tracking: 1.2pt)[RESEARCH BRIEFING]
  #v(0.45cm)
  #text(size: 20pt, weight: "bold")[
    Technical identifiers in the \
    OBIS Parquet lake
  ]
  #v(0.3cm)
  #text(size: 12pt, fill: luma(60))[
    Which columns to mint, how they relate to \
    `(dataset_id, DwC ID)` joins, and how GBIF does it
  ]
  #v(0.55cm)
  #line(length: 40%, stroke: 0.8pt + luma(160))
  #v(0.35cm)
  #text(size: 9.8pt)[
    Context: `separate-tables` prototype; GBIF `gbifID` / DwC-A `id`/`coreid`; \
    #link("https://github.com/gbif/dwc-dp/issues/159")[gbif/dwc-dp\#159]
  ]
  #v(0.2cm)
  #text(size: 9.5pt, fill: luma(90))[Prepared 13 October 2026]
]

#v(0.9cm)

= Executive summary

Mint technical identifiers into Parquet *now* if multi-dataset DwC-A / DwC-DP downloads are a product goal — the same reason GBIF mints `gbifID` and remints package structural keys (#159). Keep publisher Darwin Core IDs untouched. Composite `(dataset_id, occurrenceID|eventID)` joins remain valid for DuckDB analytics; they are not enough inside one zip that concatenates many datasets.

#callout("Bottom line", [
  Add `event_pk` / `occurrence_pk` (and matching FKs on extension rows) to every lake table at land time. Keep `dataset_id` and DwC ID fields as data. Use the `*_pk` columns for multi-dataset packaging and, optionally, for DuckDB joins. Map `occurrence_pk` → search `obisID` (GBIF’s `gbifID` role).
])

= Why not composites alone

The prototype joins on `(dataset_id, DwC ID)` inside per-dataset folders. That works for DuckDB subsets. It fails for *one* archive spanning many datasets:

- `occurrenceID = 123` in two datasets → colliding package keys.
- Extension `coreid = <occurrenceID>` is not unique after concatenation.
- Frictionless / DwC-A validators expect structural PKs, not an informal “also filter by dataset_id” rule.

GBIF already separates these roles: `gbifID` for search; `id`/`coreid` (DwC-A) or `_pk`/`_fk` (DwC-DP \#159) for package joins; `occurrenceID` left as publisher data.

= Parquet fields to add

Mint at land / interpret time. Values are aggregator-owned integers or ULIDs, unique within the lake (or reminted unique within each download zip). Never overwrite DwC fields.

== Every table (envelope)

#figure(
  kind: table,
  caption: [Columns on all Parquet row types.],
)[
  #set text(size: 9pt)
  #table(
    columns: (1.2fr, 0.7fr, 2.1fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Field*], [*Required*], [*Role*],
    [`dataset_id`], [yes], [Existing. Dataset UUID; provenance and lake partitioning.],
    [`source` / `verbatim`], [yes], [Existing. Publisher strings — including DwC IDs.],
    [`interpreted`], [yes], [Existing. Typed view — including DwC IDs for QC/filters.],
  )
]

== `event.parquet`

#figure(
  kind: table,
  caption: [Technical IDs on events.],
)[
  #set text(size: 9pt)
  #table(
    columns: (1.2fr, 0.7fr, 2.1fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Field*], [*Required*], [*Role*],
    [`event_pk`], [yes], [*Minted.* Primary structural key for this event row.],
    [`parent_event_fk`], [no], [*Minted.* Points at parent row’s `event_pk` when `parentEventID` resolves inside the dataset; null at roots / unresolved.],
    [`interpreted.eventID`], [yes\*], [Publisher semantic ID (\*required by DwC when present in source). Not the join key for multi-dataset zips.],
    [`interpreted.parentEventID`], [no], [Publisher parent pointer; keep for hierarchy display and composite walks.],
  )
]

== `occurrence.parquet`

#figure(
  kind: table,
  caption: [Technical IDs on occurrences.],
)[
  #set text(size: 9pt)
  #table(
    columns: (1.2fr, 0.7fr, 2.1fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Field*], [*Required*], [*Role*],
    [`occurrence_pk`], [yes], [*Minted.* Primary structural key; also the natural value to expose as API `obisID` / ES document id (1∶1 or mapped).],
    [`event_fk`], [no\*], [*Minted.* Points at `event.event_pk` when the occurrence is linked to an event (\*required for Event-core datasets).],
    [`interpreted.occurrenceID`], [yes\*], [Publisher semantic ID.],
    [`interpreted.eventID`], [no], [Publisher event link; keep alongside `event_fk`.],
  )
]

== Extension tables

Apply the same pattern to every extension file (`event_measurementorfact`, `occurrence_measurementorfact`, `event_dnaderiveddata`, `occurrence_dnaderiveddata`, multimedia, …):

#figure(
  kind: table,
  caption: [Technical IDs on extension rows.],
)[
  #set text(size: 9pt)
  #table(
    columns: (1.2fr, 0.7fr, 2.1fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Field*], [*Required*], [*Role*],
    [`row_pk`], [yes], [*Minted.* Unique key for this extension row (needed when packing DwC-DP or citing a MoF row).],
    [`event_fk`], [if event-level], [*Minted.* → `event.event_pk`.],
    [`occurrence_fk`], [if occurrence-level], [*Minted.* → `occurrence.occurrence_pk`.],
    [DwC / extension ID fields], [as published], [e.g. `measurementID` if present — data only, not the structural join.],
  )
]

Split event- vs occurrence-level files as today; the FK tells you which parent table to join, so you do not rely on densified copies.

== Optional later (DwC-DP-shaped lake)

When landers grow Agent / Survey / Material tables, add the matching pair per table: `agent_pk`, `survey_pk`, `material_pk`, plus FKs on rows that point at them (`recorded_by_fk`, …). Same \#159 rule: remintable structural columns; semantic `agentID` etc. stay in `interpreted`.

= How joins work with these fields

#figure(
  kind: table,
  caption: [Join recipe by consumer.],
)[
  #set text(size: 8.8pt)
  #table(
    columns: (1.2fr, 2.3fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Consumer*], [*Join*],
    [DuckDB subset (prototype)], [Still fine: `(dataset_id, eventID|occurrenceID)`. Or switch to `event_fk = event_pk` once minted.],
    [Event hierarchy walk], [`occurrence.event_fk` → `event.event_pk`; recurse `parent_event_fk`.],
    [Extension attach], [`mof.occurrence_fk` → `occurrence.occurrence_pk` or `mof.event_fk` → `event.event_pk`.],
    [Multi-dataset DwC-A zip], [Map `occurrence_pk` → file `id`; extension `occurrence_fk` / `event_fk` → `coreid`. Remint per zip if you want zip-local integers.],
    [Multi-dataset DwC-DP zip], [Copy (or remint) `*_pk` / `*_fk` into package columns; leave DwC ID terms unchanged (\#159).],
    [Elasticsearch / API], [`obisID` = `occurrence_pk` (or a stable mapping table if you remint package keys separately).],
  )
]

= Comparison with GBIF

#figure(
  kind: table,
  caption: [OBIS Parquet column ↔ GBIF analogue.],
)[
  #set text(size: 8.8pt)
  #table(
    columns: (1.2fr, 1.2fr, 1.6fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*OBIS Parquet*], [*GBIF*], [*Notes*],
    [`occurrence_pk` / `obisID`], [`gbifID`], [Search + citation; remappable on major ID churn.],
    [`event_pk`], [event structural id in pipelines / DwC-DP `event_pk`], [Needed for event index + Event-core packaging.],
    [`event_fk` / `occurrence_fk` / `parent_event_fk`], [`coreid` / `_fk`], [Package and lake joins.],
    [`dataset_id`], [`datasetKey`], [Already present.],
    [`interpreted.occurrenceID`], [`occurrenceID`], [Publisher data — never overwrite.],
  )
]

= Policy

1. *Mint into the lake at land time* — do not wait for the packager if multi-dataset downloads are in scope.
2. *Never put technical values into DwC ID fields.*
3. *QC* duplicates of `(dataset_id, occurrenceID)` and unresolved `parentEventID` / `eventID` links at land time; structural FKs make those failures visible.
4. *Packager may remint* `_pk`/`_fk` again inside a download zip (\#159); lake keys are the default source, not a sacred global IRI.

= Short answers

1. *Need technical IDs?* Yes — for multi-dataset DwC-A/DwC-DP and for stable `obisID`.
2. *Drop composite joins?* No — keep them for provenance/QC; prefer `*_pk`/`*_fk` for packaging.
3. *Which Parquet fields?* `event_pk`, `parent_event_fk`, `occurrence_pk`, `event_fk` on occurrences, and on each extension row `row_pk` plus `event_fk` or `occurrence_fk`.
)
