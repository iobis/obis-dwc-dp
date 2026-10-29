#set document(
  title: "BBNJ Standardized Batch Identifiers in Darwin Core",
  author: "Research briefing",
  date: datetime(year: 2026, month: 9, day: 25),
)
#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.4cm),
  numbering: "1",
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 8.5pt, fill: luma(100))
      [BBNJ batch identifiers · Darwin Core #h(1fr) Research briefing · 25 Sep 2026]
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
  v(1.1em)
  set text(size: 14pt, weight: "bold")
  block(it)
  v(0.35em)
}
#show heading.where(level: 2): it => {
  v(0.8em)
  set text(size: 11.5pt, weight: "bold")
  block(it)
  v(0.2em)
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
  #v(1.2cm)
  #text(size: 11pt, fill: luma(90), tracking: 1.2pt)[RESEARCH BRIEFING]
  #v(0.5cm)
  #text(size: 19pt, weight: "bold")[
    Integrating BBNJ standardized batch \
    identifiers into Darwin Core
  ]
  #v(0.35cm)
  #text(size: 11.5pt, fill: luma(60))[
    Fields, extensions, EML, INSDC/BioSamples, and \
    linking sequences to OBIS/GBIF by batch ID
  ]
  #v(0.6cm)
  #line(length: 40%, stroke: 0.8pt + luma(160))
  #v(0.4cm)
  #text(size: 9.8pt)[
    Sources: BBNJ Agreement & PrepCom/CHM studies; Humphries, Rabone et al. \
    (Springer 2025); Frontiers CHM capacity paper (2026); DwC / DwC-DP / \
    Latimer Core; GBIF EML profile, extensions registry, projectId work; \
    UK guidance; INSDC notes; DwC/GGBN specs
  ]
  #v(0.25cm)
  #text(size: 9.5pt, fill: luma(90))[Prepared 25 September 2026 · revised 19 October 2026]
]

#v(0.85cm)

= Executive summary

The BBNJ Agreement requires a *“BBNJ” standardized batch identifier* (BSBI / BBNJ Identifier): a Clearing-House Mechanism (CHM) tag for a *batch* of marine genetic resource (MGR) collection in areas beyond national jurisdiction — not a per-specimen or per-sequence ID. It must travel with samples and digital sequence information (DSI) through notifications and support *aggregate* access reporting: a traceability end-point, not full track-and-trace.

*Format is still undecided* by the Conference of the Parties. There is *no ratified Darwin Core term* for it. State-of-the-art guidance (Rabone et al., 2025) says capture in OBIS/GBIF via *existing Darwin Core fields “may be achievable,”* while Latimer Core is better for *collection* holdings and INSDC likely needs more explicit UI fields. That advice is directionally right on reuse — but it under-specifies *which* fields, and it does not solve *queryability*.

For biodiversity portals the product goal is concrete: *filter occurrences (and events) in OBIS/GBIF by batch identifier* — and, equally, *join those records to INSDC/EBI BioSamples and sequence accessions that carry the same ID.* DwC field choice is not independent of what GenBank/ENA/DDBJ decide: if INSDC only accepts free-text cruise fields, DwC must still be typed and indexed, and a linking layer must normalise both sides. Dataset-only EML, untyped `eventID` overload, and eMoF-as-identifier all fall short.

#callout("Recommendation (authoritative)", [
  *Do not* open with a BBNJ-specific DwC core term (`bbnjBatchID`). TDWG prefers *generic* identifier concepts (cf. `recordedByID`, `projectID`) with schemes in usage guidance — Tim Robertson’s framing for the public issue. \
  *Canonical model:* DwC-DP `event-identifier` / `survey-identifier` (typed rows; multiple IDs per event; `identifierType=bbnjBatch`). \
  *DwC-A path (pick one, discuss at TDWG):* (C1) *update* the GBIF Identifier extension so it is not taxon-only and documents `identifierType` for Event/Occurrence; or (C2) sandbox a *new* Event Identifier extension mirroring DwC-DP. Prefer not “use Alternative Identifiers as-is.” \
  *Why C1 is suddenly credible:* GBIF’s DwC-DP → DwC-A-shaped ingest already fans `event-identifier` (and other `*-identifier` tables) out to rowType `http://rs.gbif.org/terms/1.0/Identifier` (`IdentifierMapping`). Updating that extension aligns publishing docs with what ingest already does. \
  *Processing + downloads:* project the typed batch ID onto Event *and* Occurrence search docs; for downloads prefer a *dedicated identifier file* (plus optional Occurrence column for simple CSV). Do not rely on extension rows alone. \
  Keep GGBN Permit for Nagoya/IRCC; align BioSamples to the same type string; MIxS is not the home (unsequenced MGR still need the ID).
])

= What the identifier is (and is not)

== Treaty role

Under arts. 12, 14 and 16:

- Pre-collection notification → CHM *automatically generates* the batch identifier (art. 12(3)).
- The same ID is carried in post-collection and utilization notifications.
- Repositories/databases under Party jurisdiction must accompany MGR/DSI with the ID where required (art. 14(3)).
- Biennial *aggregate* access reports are linked to batch identifiers (art. 12(7)) — not specimen-level use.

Negotiators chose *batch* rather than *cruise*: one ID may map to a cruise, leg, AUV deployment, or project once COP procedures fix the grain. It is deliberately lighter than PIP-style track-and-trace and closer to MSR cruise practice than to CBD/Nagoya IRCC identifiers.

== What is not decided

UK guidance states the *format has not yet been determined*. PrepCom/CHM materials leave generation procedures, machine-readability, resolution, and exact scope to COP/ABSC/STB. Biodiversity networks can design fields and indexes now, but should not freeze validators on a guessed syntax. Harmonisation with IGSN/SESAR-style batch registration is recommended in recent capacity work (Frontiers, 2026) to avoid colliding identifier ecosystems.

== Relation to scientific identifiers

#figure(
  kind: table,
  caption: [Grain and role of related identifiers.],
)[
  #set text(size: 9pt)
  #table(
    columns: (1.35fr, 1.1fr, 2.2fr),
    stroke: 0.4pt + luma(180),
    inset: 5pt,
    [*Concept*], [*Typical grain*], [*Role*],
    [BBNJ batch ID], [Collection batch / notification], [Legal–administrative link to CHM & aggregate reports],
    [Cruise / EXPOCODE], [Cruise / leg], [Scientific practice; may coincide with or nest under a batch],
    [`eventID`], [Sampling event in one DwC dataset], [Structural hierarchy inside a published dataset],
    [`occurrenceID` / `materialSampleID`], [Observation or sample], [Scientific identity],
    [INSDC accession / BioProject], [Sequence / study], [DSI identity; should *carry* the batch ID],
    [EML `project` / `alternateIdentifier`], [Dataset / package], [Resource metadata — not occurrence search],
  )
]

Conflating BBNJ batch ID with `eventID` breaks Event-core hierarchies already used in OBIS and breaks cross-dataset uniqueness expectations. Treat it as an *additional*, *typed* identifier.

=== Why not put the batch ID in `eventID`?

This is the most common shortcut (make the cruise/batch parent’s `eventID` equal the CHM string). It looks attractive with an event index — filter `eventID = batch` — but it conflates three different jobs:

1. *Structural key* inside a dataset (`eventID` / `parentEventID` tree; joins to occurrences and extensions).
2. *Scientific / operational label* (local cruise code, station code, or other human-readable campaign labels — better as *typed* alternate identifiers, not as the structural key).
3. *External legal–administrative identifier* issued by the CHM (and mirrored in INSDC/BioSamples).

`eventID` is defined only for (1): “an identifier for the set of information associated with a dwc:Event … specific to the data set” or a GUID. It is the hinge of the Event-core star schema. Overloading it with (3) fails in concrete ways:

- *Publishers already have their own `eventID`s.* Replacing a parent’s `eventID` with a CHM string forces a rewrite of every child’s `parentEventID`, breaks continuity with publications that cited the old codes, and collides when the same cruise already has a scientific cruise ID *and* a BBNJ ID (common: negotiators deliberately allowed batch ≠ cruise).
- *One string, many roles → untyped discovery.* Searchers cannot tell a CHM ID from a local cruise code. INSDC’s “put it where cruise identifiers go” has the same flaw; DwC should not copy it.
- *Hierarchy grain.* A batch may sit above several cruises, or one cruise may split into several batches (legs, AUV recoveries). `eventID` is 1:1 with an Event row; external IDs are often many:1 or 1:many relative to scientific events — that is why DwC-DP has a separate `event-identifier` table.
- *Aggregation / cross-dataset joins.* DwC-DP \#159’s whole point: semantic DwC IDs collide across datasets and must not be the only relational key. Making the BBNJ string the `eventID` couples a *global* legal ID to a *dataset-scoped* structural field — the opposite of the emerging `*_pk` / `*_fk` vs `eventID` split.
- *GBIF inheritance gap.* Even if OBIS walks parents, GBIF often does not promote parent `eventID` onto occurrences. Children keep station `eventID`s; the batch string on the parent is invisible at occurrence search unless denormalised as its *own* field.
- *Wrong equality for BioSamples.* The join to INSDC is “same batch string on both sides,” not “BioSample.eventID = DwC.eventID.” Samples need `materialSampleID` = BioSample accession *plus* a shared batch attribute.

*What to do instead with your prototype:* index a typed `bbnjBatchID` (or `event-identifier` row) on the event document/`event.parquet`; filter on that; join children and occurrences with the unchanged scientific `eventID`. Same retrieval power, without burning the structural key.

=== Precedents that inspire the right shape

#figure(
  kind: table,
  caption: [Precedents: external / typed IDs kept *beside* structural IDs.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.2fr, 2.4fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Precedent*], [*Lesson for BBNJ*],
    [DwC `fieldNumber` vs `eventID`], [Field-note / operational labels are *not* the Event’s structural ID (GBIF Humboldt survey guide; IPT quality checklist).],
    [DwC `projectID` / `projectTitle` (ratified 2025–26, #link("https://github.com/tdwg/dwc/issues/532")[tdwg/dwc\#532])], [Record-level project attribution got a *new term*, not overload of `eventID`. Closest DwC pattern; BBNJ is similar (external GUID on Event) but *not* the same semantics as funder/project IDs — do not silently reuse `projectID` for CHM batches.],
    [DwC-DP `event-identifier` / `survey-identifier`], [First-class table: `identifier` + `identifierType` (+ IRI/source) linked by `eventID` → Event. Designed for multiple typed IDs per event (cruise + DOI + BBNJ).],
    [DwC-DP \#159 / \#150], [Separate *structural* keys from *semantic* DwC identifiers so aggregates and joins stay faithful.],
    [GBIF Identifier extension; Latimer Core `Identifier`], [Typed alternate IDs beside core records / collections.],
    [Plant Treaty GLIS DOI vs accession ID], [Legal/global PID *alongside* local scientific accession — GLIS FAQ: DOI does not replace accession identifiers.],
    [`recordedByID` / ORCID vs `recordedBy`], [Machine ID in a dedicated field; human label stays separate (#link("https://github.com/tdwg/dwc/issues/102")[tdwg/dwc\#102] lineage).],
    [GGBN Permit extension], [ABS/legal metadata as extension rows, not stuffed into specimen IDs — see dedicated section below.],
    [ABSCH / IRCC Unique Identifier], [Cautionary tale + partial reuse: certificate-level UID via `permitURI`; low uptake / weak machine-readability — do *not* copy that failure mode.],
    [WIGOS station IDs (GOOS)], [External platform registry IDs kept distinct from sampling-event IDs — same dual-ID problem OBIS flags for BBNJ + WIGOS in the README.],
  )
]

=== Ongoing work and discussions (repos / issues)

- *gbif/dwc-dp \#159* (closed Jun 2026) — structural `*_pk`/`*_fk` vs semantic `eventID`; directly motivates not overloading `eventID` with global legal IDs. Related: \#150 weak foreign keys.
- *gbif/dwc-dp* table schemas — `event-identifier.json`, `survey-identifier.json` (typed identifiers); open housekeeping (\#139 production plan); no BBNJ-specific issue yet.
- *tdwg/dwc \#532 / \#527* — `projectID` / `projectTitle` (and funding terms) completed; pattern for external IDs on Event. \#671 `fieldNumber` in DwC-DP review. *gbif/dwc-dp \#112* — “where to put human-readable site identifiers?” — community repeatedly refuses to burn `eventID` for alternate labels.
- *gbif/pipelines \#836* (closed) / *gbif/rs.gbif.org \#115* (open) — promote `projectId` to *occurrence* search, not only EML; same “dataset metadata ≠ record filter” lesson for BBNJ.
- *iobis/pipeline* — `separate-tables` branch (event/occurrence/extension Parquet); little public BBNJ issue traffic yet; README Applications stubs for BBNJ SBI and WIGOS.
- *No TDWG issue titled for BBNJ batch ID* was found — green field for a term or `identifierType` vocabulary once CHM format stabilises.

*Interim temptation:* map BBNJ → `projectID` because the term exists. Resist unless CHM explicitly aligns batch≡project: `projectID` already means funder/research projects (Ocean Census, RCN, …). Prefer typed `event-identifier` / dedicated term / Identifier extension with `identifierType=bbnjBatch`.

=== ABSCH, Nagoya, and the GGBN Permit extension — what to reuse

==== ABSCH / IRCC (what it is, and why it is only a partial model)

Under the Nagoya Protocol, Parties that require PIC publish a permit (or equivalent) to the ABS Clearing-House; that publication *constitutes* an Internationally Recognized Certificate of Compliance (IRCC). Each IRCC carries an *ABSCH Unique Identifier* (UID). Minimum IRCC content (when not confidential): issuing authority, date, provider, UID, PIC grantee, subject-matter/resources, confirmation of PIC and MAT, commercial/non-commercial use. The UID attaches to the *certificate* (proof of lawful access), not to each physical sample — the same “tag the administrative act, not every organism” idea as the BBNJ batch ID.

*Documented problems (reuse as anti-patterns):*

- *Low uptake* — on the order of a few thousand IRCCs globally (≈5k as of May 2024 in Humphries et al.), concentrated in few Parties; most non-commercial research.
- *Weak machine-readability / propagation* — literature repeatedly flags that the ABSCH UID is hard to use as a join key into OBIS/GBIF/INSDC (Rabone et al. 2019; Rohden et al. 2020; Scholz et al. 2022; Humphries et al. 2025). Checkpoints and IRCC links rarely appear on sequence or occurrence records at scale.
- *Track-and-trace ambition vs reality* — Nagoya’s checkpoint machinery aims further down the R&D chain than BBNJ’s aggregate-report model; BBNJ negotiators deliberately chose a *lighter* end-point. Copying Nagoya’s *legal* shape without fixing *data* propagation would repeat the failure.

*What is still reusable from ABSCH/Nagoya:*

- *Certificate/notification-level ID, not specimen-level ID* — same grain philosophy as BBNJ.
- *Resolvable URI to the clearing-house record* as the primary machine link (`https://absch.cbd.int/...` today; analogous CHM URL tomorrow).
- *Revision policy lesson* — ABSCH UIDs can carry revision numbers on amendment; BBNJ keeps the batch ID stable while notification metadata updates (Humphries et al.). DwC should store the *stable* ID and optionally a separate CHM record URL/version.
- *Dual regimes* — ABNJ batches may still interact with Nagoya when materials later enter national jurisdiction, or when TK obligations apply. Records may legitimately carry *both* an IRCC UID and a BBNJ batch ID — another reason not to burn `eventID` for either.

==== GGBN Permit extension (the concrete DwC reuse path for ABS)

The Global Genome Biodiversity Network defined a *Permit* vocabulary and registered it as a GBIF DwC-A extension (`http://data.ggbn.org/schemas/ggbn/terms/Permit`, issued 2022-08-08; also ABCD-GGBN). Purpose: attach *legal/administrative documents* to *MaterialSample* (tissue/DNA/specimen) records in a 1∶many star — collecting permit, export/import, MTA, MoU, *and IRCC* — without overloading `catalogNumber` / `materialSampleID` / `eventID`.

*Extension properties (all under `ggbn:`):*

#figure(
  kind: table,
  caption: [GGBN Permit extension fields (rs.gbif.org / GGBN wiki).],
)[
  #set text(size: 8.6pt)
  #table(
    columns: (1.15fr, 0.55fr, 2.0fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Property*], [*Req.*], [*Role*],
    [`permitType`], [yes], [Controlled vocab: Collecting Permit, Export/Import, MTA, MoU, *Internationally Recognized Certificate of Compliance*, Patent, Data use, Other, …],
    [`permitStatus`], [yes], [Permit available / not required / not available / Unknown (post-2014-10-12 Nagoya entry: Unknown discouraged)],
    [`permitStatusQualifier`], [no], [Why not required / unknown — e.g. “pre-Nagoya”, “no national requirement”],
    [`permitURI`], [no], [Resolvable link to the permit or ABSCH IRCC record],
    [`permitText`], [no], [Human-readable excerpt or details],
  )
]

*How it is meant to be published:* MaterialSample core (GGBN preferred) or Occurrence with Material Sample extension; many Permit rows per sample. GGBN marks permit fields *highly recommended* once Nagoya is in force. Wiki note on `permitURI`: “One will eventually need a direct link to ggbn:IRCC in the future” — i.e. they already foresaw first-class IRCC linking beyond a generic URI.

*What this gives BBNJ / OBIS:*

1. *Proven pattern* for “legal ID beside scientific ID” in DwC-A — exactly the separation argued for batch IDs.
2. *Immediate dual-use:* for ABNJ work that also has Nagoya touchpoints, publish `permitType=IRCC` + `permitURI=https://absch.cbd.int/…` on the material/sample; publish BBNJ batch ID as a *typed event identifier* (or future permitType value / dedicated term) — do not merge them.
3. *Extension-as-carrier template* if CHM needs more than one string (notification URL, status, “permit not required for ABNJ multilateral mechanism”, etc.): a thin BBNJ extension can mirror GGBN’s five-field shape (`type`, `status`, `qualifier`, `uri`, `text`) rather than inventing a novel shape.
4. *Caveats for OBIS occurrence query:* GGBN Permit is *sample-centric* and *not* a first-class OBIS/GBIF occurrence search facet today. Reusing it for IRCC/MTA is right; relying on it *alone* for “filter all OBIS occurrences by BBNJ batch ID” is not — still need event-level typed ID + index promotion (your event index path).

#callout("Reuse verdict: ABSCH + GGBN", [
  *Reuse GGBN Permit* for Nagoya/IRCC/MTA documents on materials. *Learn from ABSCH* (stable certificate ID + URI; avoid non-machine-readable / non-propagated UIDs). *Do not treat IRCC UID or GGBN Permit as a substitute for a typed BBNJ batch field on events* — different legal instrument, different grain (certificate/sample vs collection batch), and Permit rows are not occurrence search keys. Where both apply, carry both.
], accent: rgb("#A65D00"))

= State of the art (what has actually been said)

== Policy and CHM operationalisation

- *Agreement text* — normative generation and use.
- *PrepCom / consolidated CHM technical study (2026)* — CHM generates and maintains identifiers but is *not* mandated to track-and-trace all downstream uses; lists OBIS, GBIF, INSDC among relevant infrastructures; notes an *OBIS–GenBank pilot* for batch-ID management and linking; INSDC expects to accept the ID in *free-text cruise-like metadata* without enforcing compliance.
- *National guidance* (e.g. UK) — operational flow; format unknown; associate ID with all project MGR/DSI.

== Scientific / legal literature (Springer 2025 and after)

Humphries et al. (data management & identifier) and Rabone et al. (scientists / end users) are the most concrete technical signals:

- Identifier should be unique, persistent, authoritative, interoperable — a *link*, so notification metadata need not be recopied into every deposition.
- For OBIS/GBIF: *“the BBNJ Identifier could be captured by existing data fields in … Darwin Core, and … incorporated into the occurrence record.”* Latimer Core is highlighted for *collection*-level holdings (repositories), not as a substitute for DwC occurrence publishing.
- For INSDC: more development (dedicated UI/metadata field) is expected.
- GGBN permit extensions and Digital Extended Specimen ideas are cited as parallels for propagating legal/administrative tags with samples.
- Caution from ABSCH uptake: machine-readability and adoption matter as much as inventing a string.

A 2026 Frontiers synthesis on CHM capacity adds: EML is routinely *coupled with DwC* in DwC Archives for GBIF/OBIS; CHM success depends on *propagating* identifiers into the repositories where data live; recommend harmonising SBIs with IGSN/SESAR batch approaches; machine-to-machine sync over manual duplicate entry.

== Infrastructure signals

- *OBIS* — GenBank pilot planned; local roadmap already treats batch IDs as a reason to query events/hierarchies efficiently (see also this repo’s README).
- *GBIF* — cited as target system; *no* occurrence API parameter or ratified DwC term for BBNJ batch ID. Closest *precedent*: EML/`projectId` at *dataset* grain is searchable in the dataset API, with ongoing debate about *record-level* `projectId` (pipelines \#836, rs.gbif.org \#115, tdwg/dwc \#527) — exactly the same grain problem BBNJ faces.
- *TDWG* — no completed vocabulary enhancement titled for BBNJ batch IDs. DwC-DP generic identifier tables and Latimer Core’s typed `Identifier` class are the closest structural hooks.
- *Registered DwC-A extensions* already relevant by analogy: GBIF *Alternative Identifiers* (`Identifier`), *ResourceRelationship*, OBIS *eMoF*, GGBN *Permit*, *dnaDerivedData*.

#callout("Honest reading of the state of the art", [
  Literature says “reuse DwC / put it on the occurrence” without naming the term. That is *permission to design a convention*, not evidence that a good convention already exists. Parallel work (GBIF projectId, Latimer typed identifiers, DwC-DP identifier tables) shows the community repeatedly rediscovers: *dataset metadata ≠ record filter.*
], accent: rgb("#A65D00"))

= Design constraints for the query goal

1. *Grain = batch*, often above station/sample → attach to a high-level Event (or Survey), then inherit/denormalise for occurrence query.
2. *Must not destroy* scientific `eventID` / `parentEventID` trees already used in Event-core publishing.
3. *Must be typed* so consumers distinguish CHM IDs from local cruise codes.
4. *Must be indexable* as a first-class occurrence (and ideally event) filter — not only full-text or dataset browse.
5. *Works for DwC-A now* and *DwC-DP next*, ideally via the same projection/lander patterns.
6. *Respect CHM uncertainty*: store opaque strings; validate format only after COP decides.
7. *One string everywhere*: OBIS, GBIF, INSDC, LIMS, CHM notifications.

= Option analysis

== EML (necessary packaging; insufficient for occurrence query)

OBIS and GBIF already use EML (GBIF Metadata Profile) as the DwC Archive sidecar. Relevant hooks:

- `alternateIdentifier` — list of IDs for the *metadata document / resource* (UUIDs, DOIs, IPT URLs, sometimes cruise codes in practice).
- `project` block — title, personnel, funding, study area; GBIF profile adds a *project identifier* used to group datasets (searchable via dataset API `projectId`).
- Free-text methods / abstract — human-readable only.

*What EML is good for*

- Associating a *whole published resource* with a batch when the dataset ≈ one cruise/batch (common for dedicated cruise products).
- CHM / DMP packaging: pointing from notification metadata to deposition endpoints.
- Dataset discovery: “show datasets tagged with this project/batch ID.”

*Why EML is not the solution for the stated goal*

- *Wrong grain for many real publications.* Large aggregated datasets (national nodes, multi-cruise compilations, continuous observatories) mix many batches in one EML document. A single `projectId` / `alternateIdentifier` cannot express per-record provenance.
- *Dataset search ≠ occurrence search.* GBIF’s `projectId` is a *dataset* facet. Finding datasets is not the same as `occurrenceSearch?bbnjBatchID=…` across the global index — the user goal.
- *No inheritance into occurrences.* Pipelines do not (and should not by default) stamp every occurrence with every EML alternate ID; when they *do* promote metadata (as discussed for projectId), it is an explicit denormalisation decision — which is already an admission that record-level fields are needed.
- *Mixed content.* Cruise codes, DOIs, GBIF UUIDs, and a future BBNJ ID would share undifferentiated identifier slots unless a type/system attribute is conventioned — and even then consumers of occurrence APIs never see it.

#callout("EML verdict", [
  *Publish the batch ID in EML too* (typed alternate or project identifier + human note) for FAIR packaging and dataset browse. *Never rely on EML alone* for occurrence/event query in OBIS/GBIF.
], accent: rgb("#A65D00"))

== Reusing existing Darwin Core core terms

Rabone et al.’s “existing fields” claim is best read as: *DwC already has identifier-shaped slots; do not invent a parallel data model.* Candidates and verdicts:

#figure(
  kind: table,
  caption: [Reuse of existing DwC terms for BBNJ batch ID.],
)[
  #set text(size: 8.8pt)
  #table(
    columns: (1.25fr, 2.4fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Term / pattern*], [*Assessment*],
    [`eventID` = BBNJ ID on a parent cruise event], [Works mechanically with `parentEventID`; *overloads* scientific hierarchy; collisions with cruise codes; GBIF does not inherit parent fields like OBIS — occurrences often *lose* the ID. Interim only with strict guidance.],
    [`parentEventID` tree only], [Hierarchy is necessary; *not* a typed carrier of the legal ID.],
    [`otherCatalogNumbers` / `fieldNumber`], [Untyped; polluted semantics; poor discovery.],
    [`dynamicProperties` JSON], [Possible interim dump; weakly/ inconsistently indexed; avoid as primary.],
    [`datasetID` / `collectionID`], [Wrong grain (publishing unit ≠ collection batch). Same confusion as Movebank/projectId debates.],
    [`associatedSequences` etc.], [Wrong direction (links *out* to DSI, does not tag the batch).],
    [eMoF / MoF (`measurementType` = BBNJ ID)], [Technically storable; mixes facts with identifiers; awkward as primary key filter; possible *secondary* carrier.],
  )
]

Reuse without a *type* discriminator fails the “typed” constraint. Reuse that only lives on a parent event fails the “query occurrences” constraint unless denormalised.

== New Darwin Core term? (probably not — and not BBNJ-named)

A dedicated core term such as `bbnjBatchID` is the instinctive “make it queryable” move. It is also a *large ask* under the TDWG Vocabulary Maintenance Specification (demand, efficacy, stability across the whole DwC community), and a *poor namespace choice* even if a term were justified.

=== Why a BBNJ-specific term is the wrong ask

- *Treaty-scoped vocabulary ages badly.* DwC is a cross-domain biodiversity standard. Terms named for one instrument (`nagoyaIRCC`, `bbnjBatchID`, …) invite an open-ended series of treaty fields. TDWG has preferred *generic* properties (`recordedByID`, `projectID`, `fieldNumber`) plus controlled values or extensions for jurisdiction-specific documents (GGBN Permit’s `permitType=IRCC`).
- *Demand is narrow for a core term.* OBIS/GBIF/INSDC need the *capability*; most DwC publishers never touch ABNJ MGR. Efficacy is easier to show for a reusable pattern (typed identifiers) than for a single-treaty property.
- *Format and governance are still unsettled.* Proposing a core term before CHM string rules exist burns process capital.
- *Index ≠ vocabulary.* OBIS/GBIF can expose an API parameter `bbnjBatchID=` that *reads from* `identifier where type=bbnjBatch` without ratifying a DwC term. Search UX does not require a TDWG local name.

=== If a term were ever justified — keep it generic

Should typed-identifier rows prove too heavy for mainstream IPT users, a *generic* Event property is the defensible shape, e.g. `collectionBatchID` / `samplingBatchID` for cruise-scale or registry batch tags (SESAR/IGSN, future CHM, similar schemes). BBNJ is then one *value system* in documentation / `identifierType`, not the term name.

`projectID` is already ratified and generic — but its semantics are research/funder projects (Ocean Census, RCN, …), not clearing-house collection batches. Stretching it to BBNJ muddies both use cases.

=== Why typed identifiers beat a BBNJ-named core term (genuine view)

The product need is an opaque registry string at *batch Event* grain, queryable, shareable with INSDC, and coexisting with a scientific cruise ID. That is multiple *typed* IDs on one event — which DwC-DP `event-identifier` models cleanly. A treaty-named core term (`bbnjBatchID`) still fails when the same event also needs cruise + WIGOS typed IDs, and burns TDWG capital on the wrong namespace.

=== GBIF Identifier extension: checklist lore vs DwC-DP ingest reality

Registered as `http://rs.gbif.org/terms/1.0/Identifier` (2015) — often called “Alternative Identifiers.” Documented properties: `dcterms:identifier` (required), `title`, `subject`, `format`, `datasetID`. Property text historically: “Other known identifier used for the *same taxon*.” IPT checklist practice uses it for Taxon-core alternate LSIDs/DOIs/URLs. As *publisher guidance for Event-core DwC-A*, “just use Alternative Identifiers” is therefore a weak recommendation: wrong documented intent, little Event use in the wild, and weak typing in the published schema text.

*But* GBIF’s DwC-DP → DwC-A-shaped ingest already *reuses that rowType* as the landing pad for typed identifier tables. In `gbif/pipelines` (`IdentifierMapping`), fragments such as `eventIdentifiers()` read `event-identifier`, scope by `event_fk`, and emit extension rows of rowType `http://rs.gbif.org/terms/1.0/Identifier`. Parallel fragments pull `survey-identifier`, `occurrence-identifier`, and `material-identifier` into the *same* extension (sometimes routed onto Event, sometimes Occurrence). Allowlisted raw keys include `identifierType` / `identifierTypeIRI`.

So: *mechanically*, Event identifiers can already appear as Identifier extension rows after DwC-DP ingest. *Philosophically / in DwC-A publishing docs*, the 2015 extension is still a checklist artefact. That gap is exactly what a TDWG discussion should resolve — either by *updating* Identifier, or by registering a clean Event Identifier mirror of DwC-DP.

== DwC-A options: update Identifier *or* new Event Identifier extension

DwC-A has *no* first-class Event equivalent to DwC-DP’s `event-identifier` in the *publishing* story. Two credible fixes (both better than a treaty-named core term):

#figure(
  kind: table,
  caption: [DwC-A paths after Tim Robertson’s “generic ID” framing.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (0.55fr, 1.5fr, 1.5fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Path*], [*Idea*], [*Trade-off*],
    [C1], [Update Identifier extension: Event/Occurrence/Material scope; first-class `identifierType` (+ IRI/source); drop “same taxon” wording], [Reuses rowType ingest already fans into; repairs a 2015 artefact; name “Alternative Identifiers” stays confusing],
    [C2], [Sandbox new Event Identifier extension mirroring DwC-DP (`identifier` + `identifierType` …)], [Cleaner mental model; second extension alongside Identifier until pipelines unify],
    [D], [Generic Event core term e.g. `collectionBatchID` (not `bbnjBatchID`)], [Simple IPT; single-valued; still need cruise as second field; larger VMS ask],
    [E], [`bbnjBatchID` core term], [Avoid — treaty namespace; invites parallel treaty fields],
  )
]

Prefer *C1 or C2* in a public TDWG issue framed as *options*, not a finished “New Term - bbnjBatchID” request. Escalate to *D* only if extension+projection fails IPT adoption.

=== Flat Event/Occurrence field vs `event-identifier` (will the ID get lost?)

The worry is real: *extension tables and DP child tables are the first things dropped* when data are reprocessed — Excel exports, R/`dplyr` pipelines that keep only core columns, GBIF “simple CSV”, occurrence-only indexes, LIMS hand-offs, and many IPT republishers who never tick the extension. A column sitting on Event or Occurrence *travels farther by default*.

#figure(
  kind: table,
  caption: [Where the batch ID survives common processing paths.],
)[
  #set text(size: 8.4pt)
  #table(
    columns: (1.35fr, 0.85fr, 0.85fr, 1.6fr),
    stroke: 0.4pt + luma(180),
    inset: 4pt,
    [*Carrier*], [*Survives Event keep?*], [*Survives Occ.-only?*], [*Cost*],
    [DwC-DP `event-identifier` / DwC-A typed-ID extension], [only if extension kept], [no (unless projected)], [Multiple typed IDs; clean model; easy to drop],
    [Flat field on *Event* only], [yes], [no — unless inherited], [One column; still lost in occurrence-centric tools; weak for BBNJ+cruise+WIGOS together],
    [Flat field on *Occurrence* (denormalised)], [n/a], [yes], [Survives most OBIS/GBIF use; duplicates; wrong grain; hard for multi-ID],
    [Extension *plus* pipeline projection to Event+Occ. search docs], [yes (index)], [yes (index)], [*Best of both:* canonical rows + resilient query surface],
    [Generic core term e.g. `collectionBatchID` on Event (± Occ.)], [yes], [if also on Occ.], [TDWG ask; single-value; still need second field for cruise code],
  )
]

*Verdict on the flat-field instinct:*

1. *Canonical store* should still be typed identifier rows (DP table / DwC-A extension). BBNJ almost always *coexists* with a scientific cruise ID and sometimes WIGOS/IGSN — one bare column cannot hold that without inventing parallel terms (`bbnjBatchID`, `cruiseID`, `wigosID`, …) or stuffing untyped multi-values into one cell.
2. *Query / hand-off surface* should *not* depend on consumers reading the extension. OBIS/GBIF ingest must *project* `identifier where type=bbnjBatch` onto indexed Event *and* Occurrence documents (API alias `bbnjBatchID=` is fine). That is the same lesson as `projectId` → occurrence search (pipelines \#836): metadata that only lives off-core is invisible.
3. *Publisher denormalisation* is optional insurance for flat archives: copy the batch string onto Occurrence (or MaterialSample) *in addition to* the Event-level typed row — documented as denormalised, not as a second source of truth.
4. A *generic* Event core term (`collectionBatchID`) only becomes attractive if, after a real DwC-A extension exists, IPT users still will not attach rows. Do not jump there first: you lose multi-ID and still need Occurrence projection for GBIF-style occurrence search.

So: flat field alone is *more sticky but less expressive*; identifier rows alone are *more correct but fragile*. The product answer is *both layers* — typed rows as source of truth, projected (and optionally denormalised) scalar for survival.

=== Attachment grain (one parent vs SBI on every sample)

DwC-A is a *star*: each extension row has exactly one `coreid` → one parent core record. DwC-DP `event-identifier` likewise has one `event_fk`. The *SBI string* may still be repeated.

- *Canonical:* one typed-identifier row on the *batch* Event (cruise/leg), `identifierType=bbnjBatch`. Children keep scientific `eventID` / `parentEventID`. Matches Art. 12 batch grain.
- *Allowed denormalisation:* same SBI string on many Occurrence (or station Event) identifier rows — copies for occurrence-centric search/downloads when parent Event extensions are not inherited (GBIF often does not inherit).
- *Not required:* one unique SBI per sample. Many samples share one CHM batch ID.

=== Should we act on DwC-A before COP freezes the CHM string?

*Yes — sandbox C1 and/or C2 soon.* Reasons:

- *OBIS (and most marine IPT publishers) still ship DwC-A Event-core.* Waiting for universal DwC-DP adoption leaves a years-long hole exactly where BBNJ pilots need to run. DwC-A → DwC-DP converters exist; reverse packaging remains hard.
- *DwC-DP already defines the structure* ([Event Identifier](https://dwc.tdwg.org/dwc-dp/qrg/#event-identifier)). C2 is a compatibility shim; C1 is documenting/repairing the slot ingest already uses.
- *Motivating types beyond BBNJ* (cruise, WIGOS, IGSN batch, DOI) make the pattern useful even if CHM format stays TBD.
- *Risk if we wait:* overloads of `eventID` / cruise free-text / `projectID` / eMoF calcify.
- *Risk if we ship poorly:* extension never projected → ID “gets lost.” Mitigate with `identifierType` vocab + indexing/download commitment in the same pilot.

*Process:* open a *discussion* issue on `tdwg/dwc` (options A–E; see `reports/bbnj-tdwg-github-issue.md`); sandbox C1/C2 in parallel; do *not* open “New Term - bbnjBatchID” first.

=== What it should look like

*Title:* Event / resource identifiers (or “Typed identifiers”) — *not* “BBNJ Extension.” \
*Namespace:* prefer `http://rs.tdwg.org/dwc/terms/`-aligned or a joint `obis`/`gbif` NS pending TDWG; rowType e.g. `…/EventIdentifier`. \
*Core:* Event (primary); optionally Occurrence / MaterialSample if flat archives need denormalised copies. \
*Properties (align with DwC-DP `event-identifier.json`):*

#figure(
  kind: table,
  caption: [Proposed DwC-A extension fields (mirror of DwC-DP event-identifier).],
)[
  #set text(size: 8.6pt)
  #table(
    columns: (1.2fr, 0.55fr, 2.0fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Property*], [*Req.*], [*Role*],
    [`identifier`], [yes], [The ID string (BBNJ batch, cruise code, WIGOS, …)],
    [`identifierType`], [yes], [Controlled: `bbnjBatch`, `cruise`, `wigos`, `igsnBatch`, …],
    [`identifierTypeIRI`], [no], [IRI for the type concept],
    [`identifierTypeSource`], [no], [Vocabulary / authority URL],
    [`identifierRemarks`], [no], [Optional human note],
  )
]

BBNJ specificity lives *only* in the type vocabulary value, not the extension name. IRCC stays on GGBN Permit (`permitType` + `permitURI`) on MaterialSample — different legal object.

=== How it would be published

1. Event-core DwC-A (OBIS normal path).
2. One extension row per ID on the *batch/cruise* event (`identifier` + `identifierType=bbnjBatch`).
3. Scientific `eventID` / `parentEventID` hierarchy unchanged; station/sample children keep their own `eventID`s.
4. Ingest: event index stores typed IDs; recurse hierarchy; join occurrences on `(dataset_id, eventID)`; *always* project `identifier` where type=`bbnjBatch` onto occurrence search docs / API alias (do not leave the value extension-only).
5. Optional publisher denormalisation: same string on Occurrence/MaterialSample for flat CSV consumers — marked as copy of the Event-level typed ID.
6. Molecular: same batch string on BioSample attribute; `materialSampleID` = BioSample accession; `associatedSequences` as today.
7. EML may repeat the ID for packaging — not the query path.

=== Community process

1. *Discussion issue* on `tdwg/dwc` (options A–E; draft in `reports/bbnj-tdwg-github-issue.md`) — not a finished `bbnjBatchID` term request.
2. Choose C1 vs C2 with GBIF/TDWG; draft extension/vocab XML; validate against `extension.xsd`.
3. PR to `gbif/rs.gbif.org` *sandbox*; IPT test; synthetic pilot (batch Event → children → BioSample).
4. Pipelines: project typed ID to Event+Occurrence indexes; download layouts as above.
5. Promote to production; publisher docs (OBIS/GBIF data blog / IPT notes).
6. Same type string in BioSamples pilot; revisit generic core term *only* if extension+projection fails adoption.

=== Fallbacks

- *DwC-DP-only:* if OBIS moves Event publishing to DwC-DP quickly, skip the DwC-A extension and use `event-identifier` natively.
- *Generic core term `collectionBatchID`:* simpler single column, but weak for multiple concurrent typed IDs on one event — inferior to the extension/DwC-DP table for BBNJ+cruise+WIGOS.
- *Provisional OBIS term URI on Event core* (custom IPT mapping): fastest pilot hack; acceptable for a prototype, not a multi-network standard.

=== ResourceRelationship / eMoF / dnaDerivedData / Identifier-as-is

Not primary homes without repair. Using today’s Alternative Identifiers *unchanged* (checklist wording, no documented Event `identifierType`) is insufficient — even though DwC-DP ingest already fans into that rowType.

#callout("Verdict", [
  *Canonical:* DwC-DP `event-identifier` with `identifierType=bbnjBatch`. *DwC-A:* update Identifier (C1) *or* sandbox Event Identifier mirror (C2). *Resilience:* project onto Event+Occurrence indexes; downloads: dedicated identifier table + optional Occurrence column. No treaty-named core term; GGBN Permit for IRCC.
])

= How users see the ID in downloads

Publishing and indexing are not enough if a Darwin Core or Parquet download still hides the batch ID. Treat download layout as part of the product.

== What not to do

- *Extension-only, no projection:* Identifier / Event Identifier file present in the zip, but simple CSV / occurrence.txt / R one-liners never see it — same failure mode as unindexed `projectId`.
- *BBNJ-only sidecar that replaces the generic identifier table:* works for a pilot, but breaks the multi-type story (cruise + BBNJ + WIGOS) and diverges from DwC-DP.
- *Rely on Event inheritance alone in GBIF-shaped occurrence downloads:* parent Event extensions often do not appear on child occurrences.

== Recommended download shapes

#figure(
  kind: table,
  caption: [How to present BBNJ batch IDs in user downloads.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.15fr, 2.3fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Product*], [*Presentation*],
    [DwC-A zip (Event-core)], [Core `event.txt` + *generic* identifier extension file (`identifier.txt` / Event Identifier) with `coreid` → batch Event. Occurrences join via `eventID` / `parentEventID`. Optionally add a *denormalised* column on `occurrence.txt` (e.g. interpreted `bbnjBatchID` or a documented dynamic field) for simple consumers.],
    [DwC-A zip (Occurrence-core / flat)], [Either denormalise SBI onto every occurrence row *or* ship identifier extension rows with `coreid` = occurrence `id` (repeated SBI string). Prefer also linking back to a batch `eventID` when Event hierarchy exists.],
    [DwC-DP zip], [`event-identifier` table (and `survey-identifier` if Survey-modelled). Do *not* invent a BBNJ-only table. Same string may appear on child events only if denormalised.],
    [OBIS multi-table Parquet], [`event` + extension/identifier parquet; DuckDB walk from filtered occurrences → parent events → identifier rows where `identifierType=bbnjBatch`. Optional: materialise `bbnjBatchID` on occurrence parquet for one-shot filters (projection, not source of truth).],
    [GBIF simple CSV / species list], [Must include a projected column if this format stays popular — otherwise BBNJ is invisible. Long-term: push users to DwC-A/DP or SQL downloads that retain the identifier table.],
    [GBIF SQL / DwC-DP download (future)], [Expose identifier table or a clear `bbnjBatchID` / typed-identifier view; document join to `gbifID` / `eventID`.],
  )
]

== Practical default for OBIS pilots

1. *Source of truth:* one typed-identifier row on the batch Event.
2. *Search:* project onto Event + Occurrence documents (API alias `bbnjBatchID=` fine).
3. *Full download:* always include the identifier table/file; do *not* make “every occurrence row carries SBI” mandatory in the relational export.
4. *Simple / occurrence-only download:* *yes*, add the SBI to every included occurrence (denormalised column or repeated extension row) so spreadsheet users are not forced to join.
5. *Do not* ship a separate `bbnj.txt` that invents treaty-only columns unless CHM workflow fields are explicitly mirrored — and even then prefer CHM URLs in EML / optional sparse fields over a parallel standard.

#callout("Download bottom line", [
  Relational download = dedicated identifier file (generic). Simple occurrence download = denormalised SBI on each row. Both read from the same Event-level typed source. Never BBNJ-only as the *only* carrier.
])

== Hypothetical: if there *were* a BBNJ-specific extension

This subsection is *not* the recommended path (prefer generic typed identifiers). It answers: *what fields would a treaty-branded extension reasonably contain?* Use it as a requirements checklist — many fields belong in the CHM or EML, not on every DwC row.

Attach primarily to *Event* (batch/cruise); optional denormalised copy on Occurrence/MaterialSample for flat archives. 1∶many if one event participates in several notifications (unusual).

=== Core identity (minimum viable)

#figure(
  kind: table,
  caption: [Hypothetical BBNJ extension — identity fields.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.25fr, 0.5fr, 2.0fr),
    stroke: 0.4pt + luma(180),
    inset: 4pt,
    [*Field*], [*Req.*], [*Notes*],
    [`bbnjBatchID`], [yes], [Opaque CHM-issued string. Format TBD — treat as string, no regex until COP decides.],
    [`bbnjBatchIDURI`], [no\*], [Resolvable CHM record URL. \*Required once CHM resolution exists.],
    [`bbnjIdentifierScheme`], [no], [Fixed or vocab: `BBNJ-CHM` — future-proofs if multiple issuers/versions.],
  )
]

=== Linkage to CHM workflow (optional, sparse)

#figure(
  kind: table,
  caption: [Hypothetical BBNJ extension — CHM workflow fields.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.25fr, 0.5fr, 2.0fr),
    stroke: 0.4pt + luma(180),
    inset: 4pt,
    [*Field*], [*Req.*], [*Notes*],
    [`bbnjNotificationStage`], [no], [Vocab: `preCollection` / `postCollection` / `utilization` — usually *wrong* on biodiversity deposits (those are CHM records). Include only if the DwC row is explicitly a notification mirror.],
    [`bbnjPreCollectionURI`], [no], [Link to pre-collection notification (art. 12(2)–(3)).],
    [`bbnjPostCollectionURI`], [no], [Link to post-collection update (art. 12(5)).],
    [`bbnjUtilizationURI`], [no], [Link to utilization notification (art. 12(8)), if any.],
    [`bbnjDMPURI`], [no], [Data management plan URI from notification — often better in EML `project` / additionalMetadata.],
  )
]

=== Provenance / deposit hints (optional)

#figure(
  kind: table,
  caption: [Hypothetical BBNJ extension — deposit and scope fields.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.25fr, 0.5fr, 2.0fr),
    stroke: 0.4pt + luma(180),
    inset: 4pt,
    [*Field*], [*Req.*], [*Notes*],
    [`bbnjMGRRepository`], [no], [Where physical MGR are/will be held (art. 12(5)) — name or URI.],
    [`bbnjDSIDatabase`], [no], [Where DSI is/will be recorded (e.g. INSDC) — prefer also `associatedSequences` / BioSample.],
    [`bbnjAppliesToRecord`], [no], [Vocab: `mgr` / `dsi` / `biodiversity` / `all` — for mixed cruises where not every occurrence is MGR.],
    [`bbnjGeographicScope`], [no], [Free text or URI; coordinates stay in DwC Location terms.],
    [`bbnjRemarks`], [no], [Human notes; never the only carrier of the ID.],
  )
]

*What not to stuff into a BBNJ extension:* full art. 12(2) narrative (objectives, vessel tonnage, participation opportunities) — that is CHM/EML content. Scientific cruise hierarchy — `eventID` / `parentEventID`. Nagoya IRCC — GGBN Permit. Sequence accessions — `associatedSequences` / DNA-derived data.

*Lean hypothetical profile for pilots:* require only `bbnjBatchID`; add `bbnjBatchIDURI` when resolvable; everything else optional or left in CHM.

== Draft / sandbox extensions without a definitive legal basis

CHM string format, resolution API, and exact batch grain are still COP follow-ons. That does *not* block technical prototyping — GBIF’s schema registry is built for iterative, pre-production definitions.

=== What “sandbox” means here

- Host: `https://rs.gbif.org/sandbox/` (`extension/`, `vocabulary/`, also `experimental/`).
- Listed on sandbox `extensions.html` / `extensions.json` — *not* the production registry IPT instances use by default.
- Purpose (IPT manual): communities *prototyping* new cores/extensions, mapping data, refining properties before freezing.
- Production promotion: only when the property set is stable; at GBIF Development team discretion; sandbox traces removed on move to production (`versioning.md`).

Sandbox ≠ TDWG ratification. Sandbox ≠ CHM legal validity. It is an engineering quarantine.

=== Recommended process while law/format is unsettled

#set enum(numbering: "1.")
1. *Write a short intent note* — problem (query by batch ID; link to INSDC), non-goals (not replacing CHM; not Nagoya IRCC), and explicit “format TBD / synthetic IDs.”
2. *Choose scope* — prefer *generic* typed-identifier extension; if exploring a BBNJ-branded draft, mark description as *VOLATILE / experimental* (precedent: UK NBN sandbox-style extensions flagged volatile).
3. *Author XML* — comply with `http://rs.gbif.org/schema/extension.xsd`; date-stamp filename (`…_YYYY-MM-DD.xml`); `dc:issued`; namespace under a non-production URI if needed (e.g. `http://rs.iobis.org/obis/terms/` or sandbox terms path).
4. *Vocabularies* — separate thesaurus XML for controlled values; keep `bbnjBatchID` format *unconstrained* (plain string) until COP publishes a pattern.
5. *PR to `gbif/rs.gbif.org`* — land under `sandbox/extension/` (and `sandbox/vocabulary/`); do *not* ask for production.
6. *Configure a test IPT* — point at sandbox registry / install the draft extension; map one synthetic dataset (fake batch IDs are fine).
7. *Iterate in sandbox* — adding/removing properties requires *new dated versions* (immutable extension policy); descriptions/examples can change without a new version.
8. *Align pilots* — GenBank/BioSamples use the same synthetic strings; document that IDs are non-authoritative.
9. *Stay out of production* until: (a) CHM can issue or resolve real IDs, or (b) the community agrees a *generic* typed-identifier extension is stable enough without waiting on BBNJ format.
10. *Optional parallel:* DwC-DP `event-identifier` examples in a data package — no IPT extension registry needed for pure DP trials.

=== Rules of engagement without legal basis

- *Do* prototype indexing, joins, and `resolve(batch_id)` with synthetic IDs.
- *Do* keep properties optional except the ID string; avoid validators that assume a CHM regex.
- *Do not* present sandbox terms as CHM-compliant or Party obligations.
- *Do not* freeze production vocabulary on guessed syntax.
- *Do not* conflate sandbox publication with TDWG DwC standard status.
- When COP decides format: issue a *new extension version* (or migrate values into the generic typed-identifier extension) and remap; IPT upgrade path is designed for that.

#callout("Sandbox takeaway", [
  No definitive legal basis is a reason to stay in *sandbox / experimental* and use *synthetic IDs* — not a reason to do nothing. Prefer sandboxing a *generic* typed-identifier extension; a BBNJ-named draft is only for exploring field lists, and should stay volatile until CHM exists.
], accent: rgb("#A65D00"))

== DwC-DP identifier tables (native for DP)

=== What `event-identifier` is

#link("https://github.com/tdwg/rs.tdwg.org/blob/master/dwc-dp/table-schemas/event-identifier.json")[`event-identifier`] is a DwC Data Package *child table*: one row = one *typed* external (or alternate) identifier *for* a `dwc:Event`. It is not a replacement for `event.eventID`. The Event table still has its structural `eventID`; this table hangs additional IDs off that key.

*Where it comes from:* DwC-DP (TDWG / GBIF data-package model under `tdwg/rs.tdwg.org` and `gbif/dwc-dp`). The table’s formal type is #link("http://www.w3.org/ns/adms#Identifier")[`adms:Identifier`] — the same pattern is repeated for `survey-identifier`, `occurrence-identifier`, `organism-identifier`, `material-identifier`, `media-identifier`, `agent-identifier`. So “typed identifiers beside the core record” is a DwC-DP design motif, not a BBNJ special case.

*Columns that matter:*

#figure(
  kind: table,
  caption: [DwC-DP `event-identifier` fields (from the table schema).],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.25fr, 2.5fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Field*], [*Role*],
    [`eventID` (required)], [Foreign key *to* the Event row this identifier is *for* (`predicate: for`). Not unique — many identifier rows may share one `eventID`.],
    [`identifier` (required)], [The ID string itself (`skos:notation` in the RDF mapping).],
    [`identifierType`], [Human/controlled category of the scheme (e.g. cruise, DOI, future `bbnjBatch`).],
    [`identifierTypeIRI` / `identifierTypeSource`], [Machine type + vocabulary/authority for that type.],
    [`identifierLanguage`], [Optional language of the identifier presentation.],
  )
]

*Intended use:* keep `event.eventID` as the dataset join key for `parentEventID` / occurrences / extensions; put *registry and campaign labels* (CHM batch ID, scientific cruise code, WIGOS, IGSN batch, …) as separate typed rows. Pipelines can project `identifier` where `identifierType = bbnjBatch` onto search documents without overloading the structural key.

*Multiple identifiers?* *Yes.* `eventID` is required but *not* unique on this table; the foreign key is many∶1 (many identifier rows → one Event). One cruise Event can carry BBNJ + cruise code + DOI as three rows.

=== What ADMS is

#link("https://www.w3.org/TR/vocab-adms/")[ADMS] (Asset Description Metadata Schema) is a W3C vocabulary for describing semantic assets (schemas, code lists, …) in catalogues. DwC-DP reuses only its *`Identifier` class* — based on the UN/CEFACT Identifier pattern: content string + optional scheme / scheme version / issuing agency. In RDF, the string is `skos:notation`; properties of `adms:Identifier` describe the *identifier*, not the Event. That is why DwC-DP separates “the Event” from “IDs that point at the Event,” and why `identifierType*` fields live on the identifier row.

Publish the batch ID as a typed row on the cruise/batch-level event (or use `survey-identifier` if the batch is modelled as a Survey). This is the cleanest structural fit and *avoids* a treaty-specific core term entirely.

== Latimer Core (complementary)

Latimer Core’s typed `Identifier` class at *collection / organisational unit* grain matches repository holdings and transfers (Rabone et al.). It does *not* replace DwC occurrence/event publishing into OBIS/GBIF. Use both: LtC for collection registries; DwC for occurrence query.

== Suggested architecture

#figure(
  kind: image,
  caption: [EML packaging; typed ID on batch Event; search alias may be BBNJ-named without a DwC term.],
)[
  #block(width: 100%, inset: 11pt, radius: 4pt, stroke: 0.5pt + luma(180), fill: luma(250))[
    #set text(size: 9pt)
    #align(center)[
      *CHM* issues BBNJ batch ID \
      ↓ \
      *EML* (optional): alternateIdentifier / project note \
      *and* \
      *Batch/cruise Event* + typed identifier \
      (DwC-A Identifier ext. / DwC-DP `event-identifier`; \
      optional GGBN Permit for IRCC on materials) \
      ↓ `parentEventID` / `event_fk` \
      Station / sample events → occurrences / materials / sequences \
      ↓ ingest projection \
      *Search document*: denormalised field or alias \
      (API may call it `bbnjBatchID` even if DwC does not)
    ]
  ]
]

= Decision matrix (query goal)

#figure(
  kind: table,
  caption: [How well each option supports occurrence query in OBIS/GBIF.],
)[
  #set text(size: 8.6pt)
  #table(
    columns: (1.35fr, 0.55fr, 0.55fr, 0.55fr, 1.4fr),
    stroke: 0.4pt + luma(180),
    inset: 4pt,
    [*Option*], [*Typed*], [*Occ. filter*], [*Effort*], [*Role*],
    [EML only], [weak], [no], [low], [Packaging / dataset browse],
    [EML + promote to all occ.], [weak], [yes\*], [med], [\*Only if 1 batch/dataset; brittle],
    [`eventID` overload], [no], [partial], [low], [Interim anti-pattern],
    [Untyped `otherCatalogNumbers`], [no], [poor], [low], [Avoid],
    [eMoF as ID], [via vocab], [awkward], [med], [Secondary only],
    [Identifier extension / `event-identifier` + index], [yes], [yes], [med], [*Best default — no new DwC term*],
    [Thin multi-field extension (GGBN-shaped)], [yes], [yes], [med], [If CHM needs status/URL fields],
    [Generic `collectionBatchID` term], [yes], [yes], [high], [Fallback only],
    [`bbnjBatchID` DwC core term], [yes], [yes], [very high], [Avoid — treaty-specific],
    [Latimer Core only], [yes], [no], [med], [Collections, not OBIS search],
  )
]

= Making it queryable in OBIS and GBIF

Publishing without indexing is theatre. Even perfect DwC still fails if the global search document lacks a dedicated field.

== OBIS

*Publish:* Event-core (or DwC-DP) with typed batch ID on the highest relevant event; document the field/type for publishers; also record in EML for the resource. \
*Ingest:* Prefer the *event-first* path enabled by the separate-tables prototype (event index + `event.parquet`): index the typed batch ID on events; resolve child events via `parentEventID`; join occurrences / DNA / MoF on `(dataset_id, eventID)`. Optionally still copy the batch ID onto occurrence search documents for one-shot occurrence filters — that denormalisation is a UX optimisation, not a substitute for an event store. \
*API/UI:* Explicit parameter and facet (`bbnjBatchID` / agreed name) on *both* event and occurrence search; do not rely on full-text. \
*Pilot:* Align with GenBank so one string retrieves OBIS events/occurrences and INSDC sequences.

=== Why the event index + `event.parquet` prototype helps

The README prototyping model (Event index; per-dataset `event.parquet` + occurrence/extension tables; DuckDB joins on `dataset_id` + DwC IDs; field inheritance for filtering) matches the BBNJ grain unusually well:

1. Batch IDs attach at *cruise/batch* events, not at every station/sample. An event index can filter those parents directly without stuffing the ID into every occurrence document up front.
2. `query_subset.py`-style recursion already expands `eventID` / `parentEventID` keys, then exports related occurrences and extensions — the same pattern yields “all samples/occurrences under this batch.”
3. Downloads stay non-duplicative: return the event subset + occurrence subset + DNA/MoF tables; clients join. That is exactly what you want for a batch-scoped MGR package.

*Critical distinction:* use the batch ID as a *filter field on the event* (typed term / identifier row / inherited interpreted field). Use `eventID` only as the *join key* to child events and occurrences. Do *not* set `eventID = BBNJ batch ID` unless you accept the scientific-hierarchy overload discussed above. With inheritance on interpreted fields, a child sample event can be filterable by the parent’s batch ID while keeping its own station-level `eventID`.

So: yes — event index + separate event Parquet makes “get everything for this batch” *easier and cleaner* than occurrence-only indexing. It does not remove the need for a typed batch-ID field; it removes the need to pretend the batch ID *is* the `eventID`.

== GBIF

*Publish:* Same convention via IPT (core term and/or Identifier/BBNJ extension; EML project/alternate for packaging). \
*Interpret:* Map typed identifier into the occurrence index as a dedicated interpretable field (learn from the `projectId` promotion debate — do it *explicitly* for BBNJ). \
*API:* Predicate download / occurrence search parameter; SQL downloads as a column. \
*Caveat:* Weaker event-inheritance than OBIS strengthens the case for denormalisation at publish *or* interpret time.

== Cross-system consistency

Agree one opaque string (then CHM format); prefer resolvable IRIs if offered; publish `identifierType` / term IRI so pipelines recognise BBNJ among cruise codes; keep scientific cruise IDs as *separate* typed identifiers. The same string must be what INSDC/BioSamples store — see next section.

= INSDC, EBI BioSamples, and the linking problem

Humphries et al. state the architectural intent plainly: a GBIF (or OBIS) record and an INSDC record that share the same BBNJ Identifier *are linked by that ID*, analogous to how BioProject groups related submissions. Building a system that *uses* that link is a separate engineering problem from choosing a DwC term.

== What INSDC has signalled (and what it has not)

From the consolidated CHM technical study (2026) and Rabone et al. (2025):

- INSDC is preparing to *accept* the batch identifier using *free-text metadata fields where submitters currently enter cruise identifiers*.
- INSDC would *not enforce* the requirement; compliance rests with the submitter (and ultimately Parties).
- More development may be needed for a *dedicated UI / explicit field* on DSI pages — free-text cruise slots are an interim, not necessarily the end state.
- *OBIS is planning a pilot with GenBank* to demonstrate technical linking of scientific data and DOIs across systems via the batch identifier.
- OBIS’s public BBNJ note (Nov 2025) further argues SBIs should be globally unique and persistent, and floats *DOI-based* SBIs as one way to power citation and provenance — a design choice that would also affect INSDC and DwC string patterns if COP adopts it.

*Not decided:* attribute local name on BioSamples; whether it becomes a checklist-mandatory field (like recent spatiotemporal minimum standards) or remains optional free text; GenBank flat-file `/source` qualifier vs BioSample-only; NCBI vs ENA vs DDBJ UI parity; search indexing of the attribute in ENA Portal vs BioSamples `attr:` filters only.

== What EBI / MIxS have (and have not) done — GitHub check

EMBL-EBI sits in this story as the European INSDC node (ENA) and as host of BioSamples and the OLS mirror of GSC MIxS — *not* as an independent BBNJ CHM implementer. A deliberate search of public GitHub and GSC issues (Sep 2026) finds *no* EBI/`enasequence`/`ebi` repository that implements, prototypes, or documents a BBNJ batch-identifier field. The only concrete INSDC signal remains the CHM study’s line about *cruise free-text* reuse; the OBIS–*GenBank* pilot named in that study is NCBI-facing, not an ENA code drop.

What *does* exist in the MIxS / GSC track is adjacent vocabulary work — and one dangerous name collision:

#figure(
  kind: table,
  caption: [GSC/MIxS terms adjacent to BBNJ — none are a BBNJ standardized batch identifier.],
)[
  #set text(size: 8.5pt)
  #table(
    columns: (1.15fr, 0.85fr, 2.2fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Term / issue*], [*Status*], [*Relevance to BBNJ BSBI*],
    [`batch_ids` (MIXS:0001382); #link("https://github.com/GenomicsStandardsConsortium/mixs/issues/1160")[mixs\#1160]], [Accepted; in current schema; Ancient / MInAS], [*Wrong semantics.* Lab / processing umbrella IDs (extract, library, seq run, sediment core) for *batch-effect* analysis — not a CHM legal collection batch. Do *not* overload this for BBNJ.],
    [`permit_id` / `permit_authority` / `permit_date` / `permit_scope` (MIXS:0001364+); #link("https://github.com/GenomicsStandardsConsortium/mixs/issues/1141")[mixs\#1141]–1144], [Accepted; Ancient / MInAS], [Generic ethical/legal approval IDs. Could *carry* a BBNJ string as free text, but typed discovery and cruise/batch semantics are wrong.],
    [`ethical_id`; #link("https://github.com/GenomicsStandardsConsortium/mixs/issues/573")[mixs\#573]], [Closed; MInAS], [Predecessor framing for permit-style IDs.],
    [`abs_certificate` / ABSCH UID; #link("https://github.com/GenomicsStandardsConsortium/mixs/issues/20")[mixs\#20] (2018–19)], [Approved at GSC CIG calls; *absent* from current `mixs.yaml` / OLS], [Nagoya IRCC / ABSCH unique identifier — *not* BBNJ. Shows GSC once agreed an ABS term and then *failed to ship it* into the live vocabulary. Cautionary precedent for hoping MIxS will spontaneously mint a BBNJ term.],
  )
]

*Bottom line on a MIxS term:* there is *no* evidence that EBI or GSC intend to create a dedicated BBNJ / BSBI MIxS slot. The live `batch_ids` term would be a *harmful* reuse target. The closest shipped pattern is `permit_*` (wrong grain/type), and the closest historical ABS work (`abs_certificate`) never landed in the published schema. For ENA/BioSamples, the practical path remains: (1) short-term cruise free-text as INSDC announced; (2) push for a *named, indexed BioSample attribute* (checklist or recognised optional key) aligned with the DwC `identifierType` string — via INSDC/GSC process, not by hijacking MIXS:0001382.

Non-EBI GitHub that *is* BBNJ-related: #link("https://github.com/iobis/bbnj-chm")[iobis/bbnj-chm] (CHM prototype project management — MGR/EIA modules, APIs, metadata fields; not sequence checklists) and older #link("https://github.com/iobis/bbnj")[iobis/bbnj] ABNJ dataset lists. Treat those as CHM/OBIS planning, not EBI deliverables.

#callout("Why INSDC’s choice cascades into DwC", [
  If INSDC standardises a *named, indexed* BioSample attribute (ideal), DwC should use the *same local name / type IRI* so joins are trivial. If INSDC stays on undifferentiated cruise free-text, DwC *still* needs a typed field — and the linking system must parse/normalise noisy cruise strings, which is fragile. Do not wait passively: propose a joint attribute name to INSDC/EBI while designing DwC, and treat the GenBank–OBIS pilot as the negotiation venue.
], accent: rgb("#A65D00"))

== Where the ID should live in the sequence stack

INSDC is a stack, not a single table. Placement matters for query and join:

#figure(
  kind: table,
  caption: [Candidate homes for the BBNJ batch ID in INSDC/EBI.],
)[
  #set text(size: 8.7pt)
  #table(
    columns: (1.15fr, 1.1fr, 2.2fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Object*], [*Grain*], [*Role for linking*],
    [BioSample (`SAMN`/`SAMEA`/…)], [Physical / material sample], [*Best primary home.* One sample → many runs/sequences. BioSamples API supports `filter=attr:field:value`. Checklist attributes index better than ad-hoc free text.],
    [BioProject / Study], [Study / programme], [Useful when one project = one batch; fails for multi-batch projects. Analogous to EML `projectId` pitfalls.],
    [Run / Experiment (SRA/ENA)], [Sequencing assay], [Too fine; inherit from sample.],
    [Nucleotide accession (GenBank flat file)], [Sequence record], [Human-visible; `/source` notes or structured qualifier if INSDC adds one. Secondary copy of sample-level ID.],
    [Cruise free-text (current practice)], [Varies], [Today’s slot INSDC cites; untyped; collisions with scientific cruise codes — same anti-pattern as overloading `eventID`.],
  )
]

State of the art for marine molecular submissions already puts rich campaign/station metadata on *BioSamples* (e.g. Tara Oceans attributes). That is the natural place for a typed `bbnj_batch_id` (name TBD) — ideally via an ENA checklist update or a recognised optional attribute, not only submitter-defined keys that Portal search may not return.

== Existing DwC ↔ sequence bridges (reuse these)

Do not invent a parallel molecular model. Current best practice already defines the *edges* of the link graph:

- `materialSampleID` — *use the BioSample accession* when one exists (GBIF/OBIS DNA guidance).
- `associatedSequences` — URLs/accessions for BioProject, nucleotide, or SRA/ENA records (DwC core; indexed enough for discovery when populated).
- *DNA-derived data extension* — MIxS-aligned method metadata; links via `occurrenceID` / `eventID`; OBIS indexes more of this path than GBIF’s portal (GBIF often leaves extension content to source-archive download).
- Future DwC-DP material / sequence tables — richer many-to-many without star-schema duplication.

The *missing node* is the shared batch ID on both sides. The *missing service* is a resolver that walks batch ID → {OBIS/GBIF occurrences, BioSamples, accessions, CHM notification}.

== Architecture for a linking system

Target capability: given a BBNJ batch ID (or a BioSample / occurrence / accession), return the connected set across CHM, OBIS/GBIF, and INSDC/EBI.

#figure(
  kind: image,
  caption: [Link graph centred on the batch identifier.],
)[
  #block(width: 100%, inset: 10pt, radius: 4pt, stroke: 0.5pt + luma(180), fill: luma(250))[
    #set text(size: 8.8pt)
    #align(center)[
      *CHM notification* (authoritative batch ID + DMP pointers) \
      ↕ \
      *Batch ID* (opaque string / future DOI) \
      ┌─────────────┼─────────────┐ \
      ↓             ↓             ↓ \
      *OBIS/GBIF*   *BioSamples*  *INSDC sequences* \
      Event/Occ.    `SAMN`/`SAMEA`  accessions / runs \
      (+ EML)       (+ checklist)   (via sample link) \
      └─────────────┴─────────────┘ \
      Cross-edges: `materialSampleID`, `associatedSequences`, \
      DNA-derived extension, reciprocal URLs in sample attributes
    ]
  ]
]

=== Link modes (align with CHM study)

The CHM study’s interoperability modes map cleanly onto what OBIS/GBIF should build:

1. *Link mode (baseline):* Stable URLs and typed IDs on record pages — CHM ↔ dataset/occurrence ↔ BioSample ↔ accession. Lowest burden; sufficient for human navigation and simple scripts.
2. *Harvest mode:* Periodically pull BioSamples/ENA metadata (and OBIS/GBIF occurrence docs) into a *batch-ID index* so one query returns cross-system hits without live federation. Fits DuckDB/Parquet lakes and Elasticsearch sidecar indices.
3. *API federation:* Authenticated joins for CHM aggregate reporting and Party dashboards — higher value, higher governance cost.

For an OBIS-led product, *harvest + link* is the pragmatic MVP; federation can wait for CHM APIs.

=== Join keys by grain

#figure(
  kind: table,
  caption: [Primary join keys between systems.],
)[
  #set text(size: 8.6pt)
  #table(
    columns: (1.1fr, 2.5fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*Grain*], [*Join*],
    [Batch], [Identical BBNJ string in DwC typed field *and* BioSample attribute (and CHM). This is the *only* key that works when sequences and occurrences were published by different teams.],
    [Sample], [`materialSampleID` = BioSample accession; also store batch ID on both sides for redundancy.],
    [Sequence], [`associatedSequences` / DNA extension → accession; accession → BioSample → batch ID.],
    [Dataset], [EML project/alternateIdentifier; BioProject ID — weak alone, useful as a hint.],
    [DOI], [If SBI is DOI-based (OBIS proposal), Content Negotiation / DOI API becomes a fourth resolver.],
  )
]

=== What the linker must normalise

Until INSDC and DwC converge on one attribute:

- Accept multiple source fields (typed DwC term, Identifier-extension type, BioSample `attr:*`, cruise free-text with heuristics, EML project ID).
- Emit a *canonical* batch ID record: `{id, id_type, sources[], occurrence_ids[], biosample_accessions[], sequence_accessions[], chm_url?}`.
- Flag low-confidence links (cruise-string fuzzy match) separately from high-confidence typed matches.
- Support *multiple batch IDs* per sample/occurrence if COP allows composite projects.

=== Implications for DwC publishing (molecular datasets)

For ABNJ molecular work published to OBIS/GBIF:

1. Put typed `bbnjBatchID` on the batch/cruise Event; denormalise to occurrences.
2. Set `materialSampleID` to the BioSample accession whenever sequences exist.
3. Fill `associatedSequences` with resolvable BioProject/SRA/nucleotide URLs.
4. Use DNA-derived data extension for MIxS method fields (already aligned with ENA checklists).
5. Mirror the batch ID into BioSample attributes *with the agreed attribute name* at submission time — do not rely on later text-mining.
6. Keep EML packaging in sync for the DwC Archive.

That is the publishing contract the linking system can rely on.

=== Pilot scope (OBIS–GenBank)

A minimal successful pilot:

- One synthetic (or consented real) batch ID.
- Matching BioSample(s) in GenBank/ENA with the ID in a documented attribute.
- Matching Event-core DwC-A in OBIS with typed ID + `materialSampleID` + `associatedSequences`.
- A small service or notebook: `resolve(batch_id) → {obis_occurrences, biosamples, accessions}`.
- Documentation of field names on *both* sides — feed that into TDWG / INSDC checklist discussions.

Failure mode to avoid: pilot only demonstrates DOI minting or only DwC publishing, without a round-trip query from batch ID through both infrastructures.

= Recommended path (actionable)

#set enum(numbering: "1.")
1. *Open TDWG discussion* on `tdwg/dwc` (options; see `reports/bbnj-tdwg-github-issue.md`) — not “New Term - bbnjBatchID.”
2. *DwC-DP:* publish via `event-identifier` (`identifierType=bbnjBatch`).
3. *DwC-A:* sandbox *C1* (update Identifier) and/or *C2* (Event Identifier mirror); do *not* recommend Identifier-as-is; do *not* wait for COP format.
4. *Index:* project typed batch ID onto event *and* occurrence search docs; join hierarchy on scientific `eventID`.
5. *Downloads:* identifier table in full/relational exports; denormalised SBI on simple occurrence exports.
6. *INSDC/BioSamples:* same type string in the GenBank–OBIS pilot — not cruise free-text long-term.
7. *GGBN Permit* for IRCC when Nagoya applies; MIxS carries the string beside checklists but is not the home.
8. *Pilot* `resolve(batch_id)` before wide rollout.
9. *Fallback only:* generic `collectionBatchID` core term if extension+projection still fails IPT adoption.

= Open questions

1. Final CHM string format — opaque token vs DOI — and resolution API?
2. Grain: cruise vs leg vs deployment vs project?
3. Multiple batch IDs on one occurrence/sample?
4. Tag non-MGR biodiversity from the same cruise?
5. Who validates published IDs against the CHM?
6. IGSN/SESAR relationship — alias, namespace, or independent?
7. Will INSDC promote a *checklist* attribute or stay on cruise free-text?
8. NCBI / ENA / DDBJ parity for UI and search indexing?
9. Will GSC ever mint a BBNJ-specific MIxS slot — or only reuse `permit_*` / free text? (Do not use `batch_ids`.)
10. Will GBIF index DNA-extension / associatedSequences richly enough for reverse links?
11. Who operates the harvest-mode link index?
12. C1 (update Identifier) vs C2 (new Event Identifier) — which does TDWG/GBIF prefer?
13. Download policy: always denormalise SBI onto occurrence simple CSV, or only when Event hierarchy is absent?

= Conclusions

1. The BBNJ batch ID is a batch-level provenance key — not a scientific DwC ID.
2. *Best solution:* typed identifier rows (DwC-DP; DwC-A via C1 or C2) *plus* pipeline projection so the ID does not vanish in occurrence-centric processing.
3. Act on DwC-A *now* (sandbox); do not wait for universal DwC-DP or final CHM syntax; open a *discussion* issue first.
4. Identifier-as-is is unsuitable as publisher guidance; updating it is a valid path because DwC-DP ingest already fans `event-identifier` into that rowType.
5. No BBNJ-specific DwC core term; flat generic core field only as fallback.
6. Downloads: dedicated identifier file for relational exports; denormalised SBI on simple occurrence downloads.
7. Do not overload `eventID` / `projectID`; attach canonically to the batch Event; denormalise to samples only for search/UX.
8. Spend effort on TDWG consensus, indexing/projection/downloads, and the GenBank–OBIS pilot.

#pagebreak()

= References

#set par(justify: false)
#set text(size: 9.3pt)

+ BBNJ Agreement (A/CONF.232/2023/4), arts. 12, 14, 16.
+ #link("https://www.un.org/bbnjagreement/sites/default/files/2026-03/20260309ConsolidatedDraftBBNJCHMStudy.pdf")[Consolidated draft study on technical aspects of CHM operationalisation] (2026) — OBIS–GenBank pilot; INSDC free-text approach.
+ #link("https://www.un.org/bbnjagreement/sites/default/files/2025-02/20250227BBNJPrepComNotebySecCHMAdvancedUnedited.pdf")[PrepCom note on CHM issues] (2025).
+ #link("https://www.gov.uk/guidance/bbnj-collection-of-marine-genetic-resources-in-areas-beyond-national-jurisdiction")[UK guidance — BBNJ collection of MGR in ABNJ].
+ Humphries et al., “Data Management and the ‘BBNJ Standardized Batch Identifier’…” in *Decoding Marine Genetic Resource Governance* (Springer, 2025) — #link("https://doi.org/10.1007/978-3-031-72100-7_12")[doi:10.1007/978-3-031-72100-7_12].
+ Rabone et al., “BBNJ Agreement: Considerations for Scientists and Commercial End Users…” (Springer, 2025) — #link("https://doi.org/10.1007/978-3-031-72100-7_14")[doi:10.1007/978-3-031-72100-7_14] — existing DwC fields; Latimer Core; INSDC gaps.
+ Related Springer chapters on notification systems and monitoring/transparency (same volume).
+ #link("https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2026.1840546/full")[Frontiers (2026) — data-centric capacity for the BBNJ CHM] — EML+DwC coupling; identifier propagation; IGSN/SESAR harmonisation.
+ #link("https://bbnj-mgr.fas.harvard.edu/mgr-mechanism")[Harvard BBNJ MGR Mechanism explainer].
+ #link("https://www.obis.org/2025/11/13/obis-support-to-bbnj/")[OBIS — digital foundation for BBNJ / SBI & DOI discussion] (Nov 2025).
+ #link("https://manual.obis.org/dna_data.html")[OBIS manual — DNA-derived data]; #link("https://docs.gbif.org/publishing-dna-derived-data/en/")[GBIF — publishing DNA-derived data] — `materialSampleID`, `associatedSequences`, DNA extension.
+ #link("https://www.insdc.org/news/insdc-spatiotemporal-metadata-minimum-standards-update-03-03-2023/")[INSDC spatiotemporal minimum standards] — precedent for BioSample checklist mandates.
+ #link("https://www.ebi.ac.uk/biosamples/docs/references/filters")[EBI BioSamples attribute filters] — `attr:field:value` search.
+ ENA sample checklists / Portal API — indexed checklist attributes vs submitter-only free text.
+ GSC MIxS: #link("https://github.com/GenomicsStandardsConsortium/mixs/issues/1160")[`batch_ids` \#1160] (MIXS:0001382 — lab batches, *not* BBNJ); #link("https://github.com/GenomicsStandardsConsortium/mixs/issues/1141")[`permit_id` \#1141]–1144; #link("https://github.com/GenomicsStandardsConsortium/mixs/issues/20")[`abs_certificate` \#20] (approved 2019, never shipped).
+ #link("https://github.com/iobis/bbnj-chm")[iobis/bbnj-chm] — BBNJ CHM prototype project management (not EBI).
+ #link("https://manual.obis.org/eml.html")[OBIS manual — EML]; #link("https://manual.obis.org/format_event.html")[Event format].
+ #link("https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile")[GBIF Metadata Profile (EML)] — `alternateIdentifier`, project block / project ID.
+ DwC `projectID` / `projectTitle` — #link("https://github.com/tdwg/dwc/issues/532")[tdwg/dwc\#532] (completed); Humboldt survey guides — keep project IDs and `fieldNumber` out of `eventID`.
+ #link("https://github.com/gbif/dwc-dp/issues/159")[gbif/dwc-dp\#159] / \#150 — structural vs semantic keys; \#112 site identifiers.
+ #link("https://github.com/gbif/pipelines/issues/836")[gbif/pipelines\#836] / #link("https://github.com/gbif/rs.gbif.org/issues/115")[rs.gbif.org\#115] — record-level `projectId` indexing.
+ GGBN Permit Vocabulary / #link("https://rs.gbif.org/extension/ggbn/permit_2022-08-08.xml")[Permit extension] — `permitType` (incl. IRCC), `permitStatus`, `permitURI`; #link("https://wiki.ggbn.org/ggbn/GGBN_Permit_Vocabulary")[GGBN wiki].
+ ABSCH / Nagoya IRCC guides — certificate UID; #link("https://absch.cbd.int/en/about/guides/IRCC")[publishing IRCC]; uptake critiques in Rabone et al. 2019, Rohden et al. 2020, Scholz et al. 2022, Humphries et al. 2025.
+ #link("https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2021.661313/full")[Humphries et al. 2021 — traceability approaches for MGR under BBNJ] — ABSCH vs GGBN permit standards.
+ #link("https://rs.gbif.org/extensions")[GBIF registered extensions] — Identifier, ResourceRelationship, eMoF, GGBN Permit, dnaDerivedData.
+ #link("https://dwc.tdwg.org/terms/")[Darwin Core terms]; #link("https://vms.tdwg.org/specification")[TDWG Vocabulary Maintenance Specification].
+ #link("https://ipt.gbif.org/manual/en/ipt/latest/core")[IPT — add a new core/extension]; #link("https://github.com/gbif/rs.gbif.org/blob/master/versioning.md")[rs.gbif.org versioning] — sandbox → production; immutable versions.
+ #link("https://rs.gbif.org/sandbox/")[GBIF schema sandbox] — draft extensions/vocabularies.
+ #link("https://ltc.tdwg.org/")[Latimer Core] — typed collection-level identifiers.

#v(0.8cm)
#line(length: 100%, stroke: 0.4pt + luma(180))
#v(0.3cm)
#text(size: 8.5pt, fill: luma(90))[
  Briefing based on public treaty, PrepCom, scholarly, and standards sources (Sep–Oct 2026).
  Revised 19 Oct 2026: TDWG options framing; DwC-DP `IdentifierMapping` fan-out; download presentation.
  CHM modalities and identifier format remain subject to COP decisions. Typst report.
]
