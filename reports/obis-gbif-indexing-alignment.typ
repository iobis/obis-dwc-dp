#set document(
  title: "Aligning OBIS Indexing with GBIF: Verbatim, Interpreted, and Extensions",
  author: "Research briefing",
  date: datetime(year: 2026, month: 10, day: 12),
)
#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.4cm),
  numbering: "1",
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 8.5pt, fill: luma(100))
      [OBIS · GBIF indexing alignment #h(1fr) Research briefing · Oct 2026]
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
  v(1.2em)
  set text(size: 14pt, weight: "bold")
  block(it)
  v(0.4em)
}
#show heading.where(level: 2): it => {
  v(0.9em)
  set text(size: 11.5pt, weight: "bold")
  block(it)
  v(0.25em)
}
#show heading.where(level: 3): it => {
  v(0.55em)
  set text(size: 10.5pt, weight: "bold")
  block(it)
  v(0.15em)
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
  #v(1.4cm)
  #text(size: 11pt, fill: luma(90), tracking: 1.2pt)[RESEARCH BRIEFING]
  #v(0.55cm)
  #text(size: 20pt, weight: "bold")[
    Aligning OBIS’s new indexing model \
    with GBIF’s data representation
  ]
  #v(0.4cm)
  #text(size: 12pt, fill: luma(60))[
    Verbatim vs interpreted fields, and how \
    extension records are named and nested
  ]
  #v(0.7cm)
  #line(length: 40%, stroke: 0.8pt + luma(160))
  #v(0.45cm)
  #text(size: 10pt)[
    Context: OBIS `separate-tables` Parquet prototype, Elasticsearch redesign, \
    GBIF Pipelines / occurrence API / download formats, DwC-A extensions registry
  ]
  #v(0.3cm)
  #text(size: 9.5pt, fill: luma(90))[Prepared 12 October 2026]
]

#v(1.1cm)

= Executive summary

OBIS is redesigning how DwC-A data are stored and served: separate Parquet tables for events, occurrences, and extensions (the `separate-tables` branch), plus a leaner Elasticsearch surface that no longer densifies event-level MoF onto every occurrence. That redesign is not only a scaling fix. It is a rare chance to *align the OBIS internal model with GBIF’s* on two points that matter for shared tooling, dual-network publishing, and user expectations:

1. *Verbatim vs interpreted* — keep publisher strings separate from typed, QC’d, taxonomy-matched values.
2. *Extension containers* — stop using OBIS-only short names (`mof`, `dna`) as the *canonical* storage/API shape; prefer GBIF’s `extensions` map keyed by extension *rowType* IRI (with optional short aliases for the OBIS API and R package).

The prototype already gestures at (1) with top-level `source` and `interpreted` structs. The recommendation below is to push that further toward GBIF naming and semantics, while keeping OBIS-specific QC (`dropped`, `absence`, bathymetry enrichments) as first-class companion fields — not mixed into verbatim.

#callout("Bottom line", [
  Use the new Parquet + ES indexes to adopt GBIF’s *split*: `verbatim` (IRI-keyed or local-name maps of publisher strings) + `interpreted` (typed OBIS/WoRMS view) + `extensions` (rowType-keyed, *directly linked only* on occurrence documents). Keep multi-table Parquet as the download truth for event-level extensions. Do not wait for DwC-DP to make this change — it helps today’s DwC-A stack and leaves the door open for DwC-DP landers later.
])

= Why alignment matters now

== What is changing in OBIS

Today’s production path is occurrence-centric: Event-core archives are flattened so occurrences inherit empty core fields *and* parent event extension rows. Elasticsearch documents expose a flat bag of Darwin Core–ish fields plus nested `mof` / `dna` arrays (often including `level` markers for event inheritance). That made the R package and simple API clients easy — and created mass duplication when stations carry dozens of sediment parameters.

The new model (documented in the project README and `diagrams/indexing-old.svg` / `diagrams/indexing.svg`) keeps:

- *Field inheritance* onto interpreted occurrence/event rows (so filters on latitude or date still work).
- *Extension rows in separate tables* (occurrence vs event MoF / DNA), joined at download time via `(dataset_id, …ID)`.

Elasticsearch should then nest only *directly linked* extensions on occurrences (DNA is the obvious case), matching how GBIF already behaves for the same Antarctic fish record: one length MoF on the occurrence in GBIF; many event-level MoF rows nested under the occurrence in OBIS today.

== What GBIF already does

GBIF’s public processing story is three layers (#link("https://www.gbif.org/article/5i3CQEZ6DuWiycgMaaakCo/gbif-infrastructure-data-processing")[GBIF infrastructure: data processing]):

#figure(
  kind: table,
  caption: [GBIF occurrence processing layers (simplified).],
)[
  #set text(size: 9pt)
  #table(
    columns: (1.1fr, 2.4fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Layer*], [*Role*],
    [Fragment], [Raw crawl payload (DwC-A row, ABCD, …) as received.],
    [Verbatim (`ExtendedRecord`)], [Normalised DwC star: core terms + map of extensions; values still *strings*; terms often stored as IRIs.],
    [Interpreted], [Typed fields, controlled vocabularies, taxonomy match, coordinates/issues; category Avro files in Pipelines; ES / API / `occurrence.txt` downloads.],
  )
]

The occurrence API returns the *interpreted* view with an `extensions` object keyed by extension rowType IRI. A separate `/verbatim` view (and download `verbatim.txt` + optional verbatim extension files) preserves publisher strings (#link("https://techdocs.gbif.org/en/data-use/download-formats")[GBIF download formats]). Core identity uses `gbifID` structurally while `occurrenceID` remains publisher data — the same structural/semantic split later formalised for DwC-DP (\#159).

OBIS does not need to copy Spark, Avro category files, or `gbifID` minting to benefit from this *shape*.

= Gap analysis: OBIS today vs GBIF

== Verbatim vs interpreted

#figure(
  kind: table,
  caption: [How publisher vs processed values appear today.],
)[
  #set text(size: 8.6pt)
  #table(
    columns: (1.15fr, 1.4fr, 1.45fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Aspect*], [*GBIF*], [*OBIS (production / prototype)*],
    [Publisher strings], [`/verbatim` API; `verbatim.txt`; IRI-keyed core terms in `ExtendedRecord`], [Mostly lost at API surface; prototype Parquet has `source` struct],
    [Processed values], [Typed API fields; `occurrence.txt`; issues list], [Flat API fields (`decimalLatitude`, `aphiaID`, `flags`, …); prototype `interpreted` struct],
    [Taxonomy], [GBIF Backbone (+ multi-classification payloads)], [WoRMS / Aphia IDs and ranks on the document],
    [QC / enrichment], [`issues`, media, facts, …], [`dropped`, `absence`, `bathymetry`, `sst`, `sss`, `shoredistance`, node tags],
    [Naming of raw layer], [`verbatim`], [`source` (prototype) — easy to rename],
  )
]

The prototype schema already separates concerns:

```json
{
  "dataset_id": "…",
  "source": { "…publisher fields…" },
  "interpreted": { "eventID": "…", "occurrenceID": "…", "…" }
}
```

That is closer to GBIF than the flat production ES document. The remaining gaps are mostly *naming*, *term keying*, and *what is allowed inside each struct* (do not put OBIS enrichments into `source` / `verbatim`).

== Extension record containers and field names

#figure(
  kind: table,
  caption: [How extension rows are exposed.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.1fr, 1.45fr, 1.45fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Aspect*], [*GBIF*], [*OBIS today*],
    [Top-level key], [`extensions`], [`mof`, `dna` (and similar short names)],
    [Extension identity], [RowType IRI, e.g. `http://rs.iobis.org/obis/terms/ExtendedMeasurementOrFact`], [Implied by property name],
    [Term keys inside a row], [Usually full IRIs in verbatim/API extensions], [Local names (`measurementType`, …)],
    [Event MoF on occurrence], [Not densified], [Densified with `level` (0 = occurrence, 1 = event, …)],
    [Downloads], [Separate extension files / `verbatim/*.txt` when requested], [Historically nested in occurrence export; prototype: separate Parquet tables],
  )
]

Concrete contrast for the same occurrence (`gbifID` / shared dataset content around Notolepis coatsi, July 2006):

- *GBIF API* — `extensions["http://rs.iobis.org/obis/terms/ExtendedMeasurementOrFact"]` with one length measurement; IRI-keyed fields.
- *OBIS API* — `mof: [ … many rows … ]` with local names and `level`, including station/net parameters inherited from the event.

The separate-tables prototype already *stores* event and occurrence MoF apart (`event_measurementorfact.parquet` vs `occurrence_measurementorfact.parquet`). Aligning the *API and ES field names* with GBIF is the remaining product choice.

== Field inheritance (related, not identical)

OBIS still fills empty occurrence core fields from parent events in the interpreted view (needed for geographic/temporal filters). GBIF’s behaviour is more conservative for some Event-core datasets (coordinates/depth may remain on the event only — see pipelines \#878 and the Humboldt hierarchy notes). Recommendation for OBIS: keep *interpreted* field inheritance for search; do *not* inherit extension rows; document that `verbatim` / `source` reflects the publisher row *before* inheritance.

= Target model for the new indexes

== Parquet lake (Track B — downloads and analytics)

Adopt a GBIF-inspired row shape for every core and extension table:

```json
{
  "dataset_id": "5adfc524-…",
  "verbatim": { },
  "interpreted": { },
  "issues": [ ],
  "obis": { "dropped": false, "absence": false, "node_ids": [], "…" }
}
```

#callout("Naming", [
  Prefer renaming prototype `source` → `verbatim` in new exports. Keep a temporary dual-read (`source` alias) for one migration cycle if needed. Do not invent a third name.
])

Conventions:

- *`verbatim`* — publisher strings only; prefer *stable local Darwin Core / extension term names* in Parquet for DuckDB ergonomics, and retain a mapping table (local name ↔ IRI) shared with GBIF’s TermFactory list where possible. Optionally store IRI keys in a parallel `verbatim_iri` map if round-tripping to GBIF-shaped JSON matters.
- *`interpreted`* — typed or normalised values OBIS is willing to filter and display; includes inherited event fields when OBIS chooses to inherit; includes WoRMS matches.
- *`issues` / flags* — machine-readable QC, analogous to GBIF `issues` (OBIS can keep existing flag vocabularies under a clear namespace).
- *`obis` (or top-level OBIS columns)* — enrichments that are not Darwin Core (`bathymetry`, `sst`, …). Keeping them out of `interpreted` DwC keys avoids pretending they were published.

Extension tables stay separate files (as now), each row with the same verbatim/interpreted envelope and composite join keys `(dataset_id, occurrenceID|eventID)`. Table file names can stay snake_case for the lake (`occurrence_measurementorfact.parquet`) while *API* uses rowType IRIs.

== Elasticsearch / API (Track A — search)

Mirror GBIF’s public occurrence document *shape* without giving up OBIS fields:

#figure(
  kind: table,
  caption: [Proposed occurrence search document (conceptual).],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.2fr, 2.3fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Block*], [*Content*],
    [Identity], [`id` / `obisID`, `dataset_id`, `occurrenceID`, `eventID`, …],
    [Interpreted DwC], [Flattened searchable fields (as today), clearly documented as interpreted],
    [OBIS enrichments], [`bathymetry`, `sst`, `dropped`, …],
    [`extensions`], [Map of rowType IRI → array of term maps; *only directly linked* rows],
    [`extensionsShort` (optional)], [Aliases `mof` / `dna` for backward-compatible API clients — derived views, not a second store],
    [`verbatim` (optional on ES)], [Omit or store sparsely; full verbatim lives in Parquet / a `/verbatim` style endpoint if needed],
  )
]

Event index documents follow the same pattern: event-level MoF/DNA live under the *event* document’s `extensions`, not copied onto child occurrences.

Priority extensions (from the project README) should register under their GBIF/TDWG rowType IRIs from day one of the new index:

- Measurement or Facts / eMoF — `http://rs.tdwg.org/dwc/terms/MeasurementOrFact` or `http://rs.iobis.org/obis/terms/ExtendedMeasurementOrFact` (pick one canonical per pipeline version; map the other on read if both exist in the wild).
- DNA derived data — `http://rs.gbif.org/terms/1.0/DNADerivedData`
- Simple Multimedia — `http://rs.gbif.org/terms/1.0/Multimedia`
- Audiovisual / Identification History / Humboldt — as registered on rs.gbif.org

== Download packaging

Align *user-facing* download layouts with GBIF vocabulary even when the bytes are Parquet:

#figure(
  kind: table,
  caption: [Conceptual mapping of GBIF download files → OBIS multi-table export.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.3fr, 2.2fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*GBIF download*], [*OBIS Track B analogue*],
    [`occurrence.txt` (interpreted)], [`occurrence.parquet` → `interpreted` (+ flattened CSV option)],
    [`verbatim.txt`], [`occurrence.parquet` → `verbatim` (CSV/JSONL projection)],
    [Extension files / `verbatim/*.txt`], [`occurrence_*` / `event_*` extension Parquets; optional IRI-keyed JSON],
    [DwC-A zip with `id`/`coreid`], [Future packager: remint structural keys; see companion briefing on \#159 / composite lake keys],
  )
]

Document explicitly: event-level measurements are *not* repeated under each occurrence in either Parquet or default API payloads.

= Implementation sketch (stay close to GBIF, stay runnable on DuckDB)

== Pipeline stages

1. *Land* DwC-A (and later DwC-DP) into per-dataset table folders — already the `separate-tables` direction.
2. *Build verbatim maps* from core + extension files (stringly; preserve empty vs absent if possible).
3. *Interpret* into typed fields + WoRMS + OBIS enrichments; apply *field* inheritance here only.
4. *Write Parquet* with `verbatim` / `interpreted` / OBIS blocks; extension tables without cross-occurrence copy.
5. *Project ES documents* from interpreted + *direct* extensions only; attach `extensions` as rowType map.
6. *Downloads* = DuckDB key walk over Parquet (existing `query_subset.py` pattern).

== Term keys: IRI vs local name

GBIF verbatim JSON leans on IRIs; DuckDB users prefer `measurementType`. Pragmatic compromise:

- *Parquet lake:* local names inside `verbatim` / `interpreted` structs (current prototype style).
- *API `extensions` objects:* IRI keys for extension *types*; local names *or* IRIs for fields inside rows — if only one, prefer local names plus a published term list, or emit both (`measurementType` and the IRI) during a transition.
- *Interop export* aimed at GBIF-shaped consumers: a small serializer that rewrites local names → IRIs using a shared dictionary (the same list GBIF’s TermFactory knows).

== Backward compatibility

Breaking `mof` / `dna` will hurt the R package and existing scripts. Mitigations:

1. API flag `extensions=true` returns GBIF-shaped map; default retains `mof`/`dna` aliases for one major version.
2. R package gains download helpers for multi-table subsets (event MoF via join) while keeping “quick DNA on occurrence” via nested direct extensions.
3. Dual-write `source`≡`verbatim` in Parquet until downstream jobs migrate.

= What not to copy from GBIF

- Spark / HDFS / category Avro file sprawl — DuckDB + Parquet is enough at OBIS scale.
- Blind adoption of GBIF Backbone as the only taxonomy — keep WoRMS; optionally *add* a GBIF backbone classification block later for crosswalk, as GBIF’s multi-classification payload shows is possible.
- Densifying DwC-DP graphs into occurrence documents — the companion cross-dataset briefing already argues for bounded projection.
- Using Darwin Core ID fields as the only join keys inside multi-dataset Frictionless zips — composite `(dataset_id, …)` in the lake; remint `_pk`/`_fk` at package time.

= Recommendations

1. *Treat the indexing redesign as an alignment project*, not only a densify-removal project. Freeze a target document schema before rebuilding production ES.
2. *Rename `source` → `verbatim`* in new Parquet exports; keep `interpreted`; park OBIS-only enrichments outside DwC maps.
3. *Canonical extension container = `extensions` keyed by rowType IRI* in ES/API; provide `mof`/`dna` aliases temporarily.
4. *Nest only directly linked extensions* on occurrence search documents; serve event extensions from the event index or from Parquet downloads.
5. *Preserve verbatim for provenance and debugging* (Parquet always; API `/verbatim` or include-on-demand later).
6. *Publish a short term/extension dictionary* (local name ↔ IRI ↔ table file) so OBIS and GBIF tooling can share serializers.
7. *Sequence work as:* Parquet shape → download/API contracts → ES mapping → R package — so clients move once.

#callout("Decision needed", [
  Confirm the canonical eMoF rowType string for OBIS indexes (`rs.iobis.org` ExtendedMeasurementOrFact vs TDWG MeasurementOrFact) and whether API extension *field* keys go IRI-first or local-name-first. Everything else in this briefing can proceed either way if the choice is explicit and versioned.
], accent: rgb("#8a4b2a"))

= Conclusions

The new OBIS indexes already move toward GBIF’s architecture by splitting tables and stopping extension densification. Closing the remaining gap — *verbatim vs interpreted envelopes* and *GBIF-like `extensions` naming* — is mostly convention and API design, not a new storage platform. Doing it now reduces future DwC-DP friction, improves dual-network mental models for users, and makes shared validation/export utilities realistic. Composite lake keys and optional structural keys for packages remain as in the companion DwC-DP cross-dataset briefing; they complement, rather than replace, this representation alignment.

#pagebreak()

= References

#set par(justify: false)
#set text(size: 9.5pt)

+ OBIS DwC-DP / indexing notes — project `README.md` (draft), `diagrams/indexing-old.svg` / `diagrams/indexing.svg`.
+ #link("https://github.com/iobis/pipeline/tree/separate-tables")[iobis/pipeline `separate-tables`] — multi-table Parquet export prototype.
+ Local subset exporter — `scripts/query_subset.py`.
+ #link("https://www.gbif.org/article/5i3CQEZ6DuWiycgMaaakCo/gbif-infrastructure-data-processing")[GBIF infrastructure: data processing] — fragment / verbatim / interpreted.
+ #link("https://techdocs.gbif.org/en/data-use/download-formats")[GBIF occurrence download formats] — `occurrence.txt`, `verbatim.txt`, extension files.
+ #link("https://github.com/gbif/pipelines")[gbif/pipelines] — `ExtendedRecord`, interpretation to category Avro, ES indexing.
+ #link("https://api.gbif.org/v1/occurrence/3863984603")[GBIF occurrence API example] and `/verbatim` sibling.
+ #link("https://api.obis.org/occurrence")[OBIS occurrence API] — flat fields + `mof` / `dna`.
+ #link("https://github.com/gbif/pipelines/issues/878")[gbif/pipelines\#878] — event hierarchy / inheritance discussion.
+ #link("https://eco.tdwg.org/hierarchy/")[Humboldt hierarchical events] — event levels and inheritance expectations.
+ #link("https://rs.gbif.org/")[GBIF extensions registry] — MoF, DNA, Multimedia, Humboldt, …
+ Companion briefing — `reports/gbif-cross-dataset-dwcdp.typ` (structural vs semantic keys; OBIS Track A/B).

#v(1.1cm)
#line(length: 100%, stroke: 0.4pt + luma(180))
#v(0.35cm)
#text(size: 8.5pt, fill: luma(90))[
  This briefing synthesizes OBIS prototype work and public GBIF processing/API documentation as of 12 October 2026. It proposes representation alignment for the new Parquet and Elasticsearch indexes; it does not commit OBIS to GBIF’s taxonomy backbone or compute stack. Typographic report generated with Typst.
]
