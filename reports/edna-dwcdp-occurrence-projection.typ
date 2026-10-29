#set document(
  title: "Projecting the OBIS eDNA DwC-DP Example to DwC-A: Are Occurrences Inferred?",
  author: "Research briefing",
  date: datetime(year: 2026, month: 10, day: 20),
)
#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.4cm),
  numbering: "1",
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 8.5pt, fill: luma(100))
      [OBIS · eDNA DwC-DP → DwC-A projection #h(1fr) Research briefing · Oct 2026]
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
    Projecting the OBIS eDNA DwC-DP example \
    into DwC-A via the GBIF pipeline
  ]
  #v(0.4cm)
  #text(size: 12pt, fill: luma(60))[
    How (and whether) occurrences are inferred \
    from nucleotide analysis rows
  ]
  #v(0.7cm)
  #line(length: 40%, stroke: 0.8pt + luma(160))
  #v(0.45cm)
  #text(size: 10pt)[
    Source package: #link("https://github.com/gbif/dwc-dp-examples/tree/master/edna/obis-edna-expeditions")[`gbif/dwc-dp-examples` · `edna/obis-edna-expeditions`] \
    Mapping code: #link("https://github.com/gbif/pipelines/tree/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config")[`gbif/pipelines` · `…/dwcdp/mapping/config`] (`dev`)
  ]
  #v(0.3cm)
  #text(size: 9.5pt, fill: luma(90))[Prepared 20 October 2026]
]

#v(1.0cm)

= Executive summary

#callout("Bottom line", [
  *Conceptually*, the Darwin Core Conceptual Model treats Material + Nucleotide Analysis + Sequence (+ Identification) as *evidence from which an Occurrence may be inferred*. *In code today*, GBIF’s DwC-DP → DwC-A recipes *do not* perform that inference: Occurrence rows are emitted only from an `occurrence` table. The OBIS eDNA Expeditions example omits that table (detections live as analyses). Under current `EventDwcaMapping`, the package would index *sampling events* (plus event-level assertions), not densified ASV occurrences — and material-linked analyses also miss the Event-scoped DNA fragments. Public 2026 plans (Work Programme, eDNA roadmap workshop) aim at DwC-DP as the DNA publish model and at *sequence-based occurrence search*, but they have not yet shipped a pipelines fragment that mints Occurrences from analyses.
])

The input DwC-A was Occurrence core + DNADerivedData. DwC-DP remapping is richer for publishing; the *inference* step the Conceptual Model describes is still a product/engineering gap between “store the graph” and “show detections in occurrence search.”

= The example package

The #link("https://github.com/gbif/dwc-dp-examples/tree/master/edna/obis-edna-expeditions")[OBIS eDNA Expeditions] example maps two Calanques field samples (`OBIS_EDNA_140`, `OBIS_EDNA_142`) from an Occurrence-core + DNADerivedData export into DwC-DP tables shaped like the GBIF Metabarcoding Data Toolkit (MDT) export, *plus* a `material` stub required by the examples repo SQL schema.

#figure(
  kind: table,
  caption: [Tables present in the example (no `occurrence`).],
)[
  #set text(size: 9pt)
  #table(
    columns: (1.3fr, 2.3fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Table*], [*Role in this package*],
    [`event`], [One row per field sample (`sample_id`).],
    [`event_assertion`], [Sample size, replicate, `env_medium`.],
    [`material`], [One environmental-DNA sample per event (stub; MDT omits this).],
    [`molecular_protocol`], [One row per distinct assay / primer set.],
    [`nucleotide_sequence`], [One row per distinct ASV sequence.],
    [`nucleotide_analysis`], [One row per *sample × ASV* detection (`read_count`). Links event, material, sequence, protocol.],
    [`identification`], [Taxonomy; linked to `nucleotide_sequence` only (not to analysis or occurrence).],
  )
]

#figure(
  kind: image,
  caption: [Publisher graph for the example. Dashed material edges are the stub added for the SQL schema.],
)[
  #block(width: 100%, inset: 11pt, radius: 4pt, stroke: 0.5pt + luma(180), fill: luma(250))[
    #set text(size: 8.8pt)
    #align(center)[
      `identification` —based on→ `nucleotide_sequence` \
      `material` —collected during→ `event` \
      `event_assertion` —about→ `event` \
      `nucleotide_analysis` —of→ `material` \
      `nucleotide_analysis` —material collected during→ `event` \
      `nucleotide_analysis` —produced→ `nucleotide_sequence` \
      `nucleotide_analysis` —followed→ `molecular_protocol`
    ]
  ]
]

Mapping detail that matters for projection (from `map_obis_edna_input.sql`):

- `nucleotide_analysis.nucleotide_analysis_id` = original `occurrenceID` (so the *semantic* detection ID from DwC-A is preserved on the analysis row, not on an occurrence).
- `nucleotide_analysis.material_entity_id` = sample id (always set).
- `identification.nucleotide_sequence_id` only — no `occurrence_fk`, no `nucleotide_analysis_fk`.

= How GBIF projects DwC-DP to DwC-A

GBIF does not index the DwC-DP graph as-is. `DwcDpVerbatimConverter` picks a *governing plan*, compiles/prunes fragments against `datapackage.json`, runs Spark joins, and writes DwC-A-shaped `verbatim.avro` (`ExtendedRecord`) for the existing interpretation stack. Background: project briefing `reports/gbif-cross-dataset-dwcdp.typ`.

#figure(
  kind: table,
  caption: [Governing-plan choice (`DwcDpVerbatimConverter`).],
)[
  #set text(size: 9pt)
  #table(
    columns: (1.5fr, 2.1fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Condition*], [*Plan*],
    [Event-bearing crawl *and* package has `event`], [#link("https://github.com/gbif/pipelines/blob/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config/EventDwcaMapping.java")[`EventDwcaMapping.current`] — Event core; occurrences only as *Occurrence extension* under events],
    [Else if package has `occurrence`], [#link("https://github.com/gbif/pipelines/blob/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config/OccurrenceDwcaMapping.java")[`OccurrenceDwcaMapping.current`] — Occurrence core],
    [Otherwise], [Empty verbatim + warning — no “index whatever exists” fallback],
  )
]

This example has `event` and *no* `occurrence` → *Event-core plan*. Nested Occurrence rows come exclusively from fragments that start at the `occurrence` table.

= Are occurrences inferred from nucleotide analyses?

== Short answer

*No.* There is no fragment that mints an Occurrence from `nucleotide_analysis`, `nucleotide_sequence`, or `identification`.

== Where Occurrence rows come from

Under `EventDwcaMapping.current`, the Occurrence extension is opened and seeded by:

#callout("Occurrence seed fragment", [
  `OccurrenceMapping.directOccurrence` — path root = `occurrence`; `scopeKey = event_fk`; `rowIdentity = occurrence_pk`. Direct DwC fields are copied; `occurrenceID` falls back to `gbif:dwcdp:occurrence:occurrence_pk:…` when blank.
])

Every other Occurrence fragment (`acceptedIdentification`, `material`, `eventIdentity`, basisOfRecord fallbacks, …) *enriches* or *matches* an existing `occurrence_pk`. They do not create rows.

If the `occurrence` resource is absent from `datapackage.json`, the dataset pruner drops the whole Occurrence-extension branch. *Result for this example: zero Occurrence extension rows.*

== What DNA fragments actually do

#link("https://github.com/gbif/pipelines/blob/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config/NucleotideMapping.java")[`NucleotideMapping`] projects analyses into the *DNADerivedData* extension (`http://rs.gbif.org/terms/1.0/DNADerivedData`), not into Occurrence:

#figure(
  kind: table,
  caption: [DNA fragment families and their parents.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.4fr, 1.1fr, 2fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Fragment family*], [*Scope*], [*Path / filter*],
    [`eventAnalyses` (+ sequence / protocol)], [`event_pk`], [`event → nucleotide-analysis` via `event_fk`, *only if* `materialEntity_fk` *is null*; fan-out],
    [`materialAnalysesForOccurrence` (+ …)], [`occurrence_pk`], [`occurrence → material` via `evidenceForOccurrenceID` (exactly one) → `nucleotide-analysis` via `materialEntity_fk`],
  )
]

`EventDwcaMapping` imports *only* the event-owned DNA fragments. `OccurrenceDwcaMapping` imports *only* the material-for-occurrence DNA fragments. There is no third path “analysis with material but no occurrence → invent an occurrence.”

== Identification fragments for DNA

#link("https://github.com/gbif/pipelines/blob/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config/IdentificationMapping.java")[`IdentificationMapping`] similarly distinguishes:

- *Event-owned* DNA IDs: analyses with `materialEntity_fk` null, then identification via `nucleotideAnalysis_fk` or (weaker) via sequence with `nucleotideAnalysis_fk` and `occurrence_fk` null.
- *Occurrence / material* DNA IDs: require an occurrence with exactly one evidence material, then analyses on that material.

Again: enrichment of Identification *extension* rows under Event or Occurrence — not synthesis of Occurrence cores.

= Walk-through: this package under `EventDwcaMapping`

#figure(
  kind: table,
  caption: [What survives pruning for `obis-edna-expeditions` as published.],
)[
  #set text(size: 8.7pt)
  #table(
    columns: (1.35fr, 0.7fr, 2.1fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Target*], [*Emitted?*], [*Why*],
    [Event core (2 samples)], [yes], [`event` table present; direct event fields + parent/protocol enrichments as available.],
    [Occurrence extension], [*no*], [No `occurrence` table → `directOccurrence` pruned.],
    [DNADerivedData on Event], [*no*], [`eventAnalyses` requires `materialEntity_fk` *null*; example always sets material.],
    [DNADerivedData on Occurrence], [*no*], [Needs occurrence parent; Event plan does not import material-for-occurrence DNA fragments.],
    [Identification (DNA paths)], [*no*], [Event DNA ID paths also require material-null analyses; sequence-linked IDs in the example never attach via those filters.],
    [eMoF from `event_assertion`], [yes], [`AssertionMapping.eventAssertions` — sample size / replicate / env_medium.],
    [Material as searchable core], [*no*], [Material never becomes its own GBIF.org index type; only enriches occurrences or feeds extensions.],
  )
]

#figure(
  kind: image,
  caption: [Intended DwC-A densify path (publisher mental model) vs current pipeline behaviour.],
)[
  #block(width: 100%, inset: 10pt, radius: 4pt, stroke: 0.5pt + luma(180), fill: luma(250))[
    #set text(size: 8.6pt)
    #grid(
      columns: (1fr, 1fr),
      gutter: 12pt,
      [
        *Input DwC-A (source platform)* \
        #v(4pt)
        Occurrence core \
        (one row per sample × ASV) \
        + DNADerivedData extension \
        #v(4pt)
        → searchable GBIF/OBIS occurrences
      ],
      [
        *After DwC-DP remapping + today’s recipes* \
        #v(4pt)
        Event core (sample) \
        + event assertions \
        Analyses / sequences / IDs \
        stay off the occurrence index \
        #v(4pt)
        → *no* densified occurrence docs
      ],
    )
  ]
]

So the critical inference question — “does each `nucleotide_analysis` become an Occurrence?” — is answered by the *current* code: *not with the fragments that ship today*. The next section separates that fact from what standards and GBIF planning documents say *should* or *will* happen.

= Plans for inferring Occurrences from DwC-DP

Public sources agree that DNA-derived *detections are meant to surface as Occurrences* for discovery, but they split across three layers: conceptual model, product roadmap, and pipelines engineering. They do *not* yet document a finished “analysis → Occurrence” recipe in `gbif/pipelines`.

== Darwin Core Conceptual Model (what inference *means*)

The #link("https://dwc.tdwg.org/cm/#26-nucleotideanalysis-nucleotidesequence-and-molecularprotocol-non-normative")[DwC Conceptual Model §2.6] (NucleotideAnalysis, NucleotideSequence, MolecularProtocol) is explicit:

- A Nucleotide Analysis of a Material Entity follows a Molecular Protocol; it may produce Sequences and/or confirm presence/absence of a target.
- Material, Analysis, and Sequence provide evidence for Identifications (morphological, assay-based, or reference-catalogue matches).
- *“The resulting body of evidence may be used to infer the Occurrence of an Organism in the sampled Material Entity”* — for qPCR-style detections and for barcoding / metabarcoding / metagenomics.
- *Inferred Occurrences should carry quality or confidence measures*; the CM does not prescribe how.
- If Material is not preserved or documented, implementers *may link the Nucleotide Analysis directly to the sampling Event* so spatio-temporal context (and thus Occurrence inference) remains possible.

DwC-DP is the reference tabular implementation of that model. So *omitting* an `occurrence` table in a metabarcoding package is a legitimate DwC-DP publishing choice *only if* some downstream process is allowed to *infer* Occurrences — which is exactly what today’s Event/Occurrence mapping plans do not do.

Related CM language elsewhere: an Identification based on a Nucleotide Analysis “may subsequently be used to infer an Occurrence”; Occurrence itself covers direct observation, *indirect inference* that an Organism existed, or absence of detection.

== GBIF product / DNA roadmap (2026 direction)

#figure(
  kind: table,
  caption: [Public planning signals relevant to DNA → occurrence discovery.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.15fr, 2.4fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Source*], [*What it commits (or strongly signals)*],
    [#link("https://docs.gbif.org/2026-work-programme/en/")[GBIF Work Programme 2026]], [Lead *sequence-based occurrence search*; improve DNA-derived filtering/downloads; prototype continuous taxonomic reinterpretation via reference catalogues; *implement DwC-DP processing* and richer visualisations; engage DNA infrastructures / eDNA community.],
    [#link("https://assets.ctfassets.net/uo17ejk9rkwj/5UjNNCN9MeielJ3avwr8tr/1eba40277406f7cdda4222450d1fa7e1/GBIF_eDNA_Data_Infrastructure.pdf")[eDNA Data Infrastructure workshop] (Copenhagen, 11–13 Nov 2025)], [Endorse treating biodiversity data as *event-based*, with eDNA as a special case; *ultimately use DwC-DP as the primary model* for complex DNA datasets including NucleotideAnalysis and related CM tables; add a *sequence service layer* (clean + hash + non-redundant store); ASV→taxon index with publisher ID preserved + GBIF-mediated reinterpretations; DNA reference-library catalogue; mOTU prototyping; MDT/IPT/API publishing and ENA brokerage. Priorities include MIxS–DwC–DwC-DP alignment and DwC-DP review feedback on NucleotideAnalysis (OBIS contributing).],
    [#link("https://github.com/gbif/pipelines/issues/1547")[pipelines \#1547] medallion store], [Design Bronze/Silver/Gold lake; *Gold* example use cases include *DNA* or a *material catalogue* — i.e. specialised services over a multi-table store, not only flat occurrence docs.],
    [#link("https://github.com/gbif/pipelines/issues/1543")[pipelines \#1543]], [Document how DwC-DP ingestion plugs into *existing occurrence–event pipelines* — confirms near-term path is still projection into that world.],
  )
]

Reading those together:

1. *Publish* complex DNA in DwC-DP (analyses, sequences, protocols, material, events) — not densified DwC-A forever.
2. *Discover* sequence-based evidence through occurrence-oriented (and later sequence-oriented) search services, with continuous taxonomic reinterpretation.
3. *Near-term engineering* still funnels DwC-DP through the occurrence/event verbatim path; a dedicated DNA “Gold” layer is sketched, not shipped as the default search surface.

What the roadmap documents *do not* yet specify in public detail: the exact join cardinality for “one Occurrence per `nucleotide_analysis` vs per distinct sequence vs per accepted identification,” how confidence is encoded on inferred Occurrences, or whether inference runs at ingest (new fragments) vs in a later DNA service that *exposes* occurrence-like documents without writing classic `occurrence` rows into verbatim.

== Publishing practice in examples (inference deferred to the package)

DwC-DP community examples often *materialise* Occurrences rather than relying on network-side inference. The Insektmobilen DNA survey use case in the #link("https://gbif.github.io/dwc-dp/docs/dwc_dp_implementation_feature_reports.pdf")[DwC-DP implementation feature reports] maps Event, Material, Nucleotide Analysis/Sequence, Molecular Protocol, Identification, *and* Occurrence — and notes missing `occurrenceID`s as a blocker for test IPT publication. That pattern matches counterfactual A below: publisher-supplied Occurrence stubs keep today’s recipes working while the CM’s inference story matures.

The OBIS eDNA Expeditions example is the sharper stress test: it follows the CM/MDT-shaped graph *without* Occurrence, so it depends on future inference (or a synthetic fragment) to re-enter occurrence search.

== Engineering gap (honest summary)

#figure(
  kind: table,
  caption: [Three layers of “infer Occurrence from DNA”.],
)[
  #set text(size: 8.7pt)
  #table(
    columns: (1.1fr, 2.4fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Layer*], [*Status*],
    [Conceptual (DwC-CM)], [Inference from Material/Analysis/Sequence/Identification → Occurrence is *in scope* and recommended to carry confidence.],
    [Product (WP 2026 + eDNA workshop)], [DwC-DP for complex DNA; sequence-based *occurrence* search; reinterpretation services; DwC-DP ingest — direction clear, recipe underspecified.],
    [Pipelines mapping (`dev`)], [*No* fragment mints Occurrence from `nucleotide_analysis`. DNA attaches as DNADerivedData / Identification *extensions* under Event (material-null analyses) or under Occurrence (via evidence material).],
  )
]

Interim historical note: #link("https://github.com/gbif/pipelines/issues/885")[pipelines \#885] explored indexing MaterialEntity-core DwC-A *as if* Occurrence (`basisOfRecord` MaterialSample) for workshops — a different shortcut (material ≈ occurrence), not CM-style inference from nucleotide detections. DNA `basisOfRecord` values were earlier mapped to MaterialSample (#link("https://github.com/gbif/pipelines/issues/538")[\#538]) for filterability while modelling continued.

= Counterfactuals (what *would* project today)

Understanding the gaps helps choose a publishing or engineering fix.

== A. Keep an `occurrence` table (classic DNA-derived path)

If the package also published one Occurrence per detection (as the source DwC-A did), with:

- `occurrence.event_fk` → sample event,
- exactly one `material.evidenceForOccurrenceID` → that occurrence,
- `nucleotide_analysis.materialEntity_fk` → that material,
- identification accepted on the occurrence *or* reachable via the material DNA ID fragments,

then `OccurrenceDwcaMapping` (or Event-core nested Occurrence + DNA-on-occurrence fragments) would emit the familiar Occurrence + DNADerivedData shape. Taxonomy enrichment still prefers an accepted identification *on the occurrence*; sequence-only IDs need the DNA identification fragments to fire.

Cost: reintroduces densification / duplication that DwC-DP was meant to avoid at publish time — unless occurrences are thin stubs and heavy DNA stays in extensions.

== B. MDT-style: analyses owned by Event, no material

If `materialEntity_fk` were left null and analyses hung only off `event_fk` (MDT omits material), then under Event-core:

- `NucleotideMapping.eventAnalyses` *would* fan DNADerivedData rows onto the Event,
- `eventDnaSequenceIdentifications` *could* attach Identification extensions to the Event when IDs hang off the sequence with the documented null filters,

…but those are still *Event extensions*, not Occurrence records. Occurrence *search* on GBIF.org would remain empty unless an Occurrence extension/core exists.

== C. Implement the CM inference as a mapping fragment (aligned with plans)

A recipe that matches DwC-CM §2.6 and the Work Programme’s “sequence-based occurrence search” framing could, for Event-core packages:

1. Path: `event → nucleotide-analysis` (fan-out; optionally via material — *including* non-null `materialEntity_fk`, unlike today’s event DNA path),
2. Emit Occurrence extension/core row with `occurrenceID` = analysis id (or generated), `eventID` from parent, quantity from `read_count`, `basisOfRecord` suitable for DNA-derived detection,
3. Attach DNADerivedData from sequence + molecular protocol,
4. Attach / enrich Identification from sequence- or analysis-linked IDs,
5. Carry a confidence / QC field (CM requirement) — publisher score, reference-library match metrics, and later GBIF reinterpretation provenance.

That fragment *does not exist* in `NucleotideMapping` / `OccurrenceMapping` as of the `dev` tree reviewed here. Until it (or an equivalent DNA Gold service) ships, networks that need occurrence search from analysis-only packages must either add an `occurrence` table at publish time or run their own projector.

= Implications for OBIS

#callout("For the OBIS indexing roadmap", [
  1. *Today:* do not assume GBIF-like projection of the current eDNA DwC-DP example yields occurrence documents. \
  2. *Directionally:* DwC-CM + GBIF 2026 DNA plans *expect* inferred / sequence-based occurrences from DwC-DP molecular graphs — track fragment or Gold-layer design with GBIF rather than inventing a permanently divergent inference rule. \
  3. *Phase 2 choice:* Event+DNA search, densified Occurrence+DNA (publisher stubs *or* shared synthetic fragment), multi-table Parquet without densify, and/or a sequence service that *exposes* occurrence-like hits. Prefer aligning cardinality and confidence fields with CM §2.6. \
  4. The material stub is schema-faithful but *blocks* GBIF’s only Event-scoped DNA path (`materialEntity_fk` must be null). If OBIS keeps material, the shared inference fragment must be the material-aware path (CM’s preferred story), not the material-null workaround.
])

= Sources

+ #link("https://github.com/gbif/dwc-dp-examples/tree/master/edna/obis-edna-expeditions")[gbif/dwc-dp-examples — `edna/obis-edna-expeditions`] (README, `map_obis_edna_input.sql`).
+ #link("https://github.com/gbif/pipelines/blob/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config/EventDwcaMapping.java")[`EventDwcaMapping.java`] · #link("https://github.com/gbif/pipelines/blob/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config/OccurrenceDwcaMapping.java")[`OccurrenceDwcaMapping.java`] · #link("https://github.com/gbif/pipelines/blob/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config/OccurrenceMapping.java")[`OccurrenceMapping.java`] · #link("https://github.com/gbif/pipelines/blob/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config/NucleotideMapping.java")[`NucleotideMapping.java`] · #link("https://github.com/gbif/pipelines/blob/dev/gbif/ingestion/spark-jobs/src/main/java/org/gbif/pipelines/spark/dwcdp/mapping/config/IdentificationMapping.java")[`IdentificationMapping.java`] (`dev` branch).
+ #link("https://dwc.tdwg.org/cm/#26-nucleotideanalysis-nucleotidesequence-and-molecularprotocol-non-normative")[Darwin Core Conceptual Model §2.6] — inference of Occurrence from nucleotide evidence.
+ #link("https://docs.gbif.org/2026-work-programme/en/")[GBIF Work Programme 2026] — sequence-based occurrence search; DwC-DP processing.
+ #link("https://assets.ctfassets.net/uo17ejk9rkwj/5UjNNCN9MeielJ3avwr8tr/1eba40277406f7cdda4222450d1fa7e1/GBIF_eDNA_Data_Infrastructure.pdf")[GBIF eDNA Data Infrastructure: Technical Roadmap Review] (Nov 2025 workshop).
+ #link("https://github.com/gbif/pipelines/issues/1543")[pipelines \#1543], #link("https://github.com/gbif/pipelines/issues/1547")[\#1547], #link("https://github.com/gbif/pipelines/issues/885")[\#885], #link("https://github.com/gbif/pipelines/issues/538")[\#538].
+ #link("https://gbif.github.io/dwc-dp/docs/dwc_dp_implementation_feature_reports.pdf")[DwC-DP implementation feature reports] — Insektmobilen / DNA tables including Occurrence.
+ Companion briefings in this repo: `reports/gbif-cross-dataset-dwcdp.typ`, project `README.md` (DwC-DP / eDNA section).

#align(center)[
  #v(0.8cm)
  #text(size: 9pt, fill: luma(100))[
    This briefing synthesizes public `gbif/pipelines` mapping configs, DwC-CM, GBIF Work Programme 2026, \
    the Nov 2025 eDNA roadmap workshop report, and the published eDNA example (reviewed 20 October 2026). \
    Internal GBIF designs not published online may differ. Typographic report generated with Typst.
  ]
]
