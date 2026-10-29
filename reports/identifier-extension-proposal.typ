// Compile: typst compile reports/identifier-extension-proposal.typ reports/identifier-extension-proposal.pdf
#set document(
  title: "Updating the GBIF Identifier extension",
  author: "Proposal guide",
  date: datetime(year: 2026, month: 10, day: 26),
)
#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.4cm),
  numbering: "1",
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 8.5pt, fill: luma(100))
      [Identifier extension · proposal guide #h(1fr) 26 October 2026]
      line(length: 100%, stroke: 0.4pt + luma(180))
    }
  },
  footer: context {
    set text(size: 8.5pt, fill: luma(100))
    line(length: 100%, stroke: 0.4pt + luma(180))
    v(4pt)
    [Guide for a gbif/rs.gbif.org issue #h(1fr) #counter(page).display("1")]
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

#let uri(s) = text(size: 8pt, s.replace("/", "/\u{200b}"))

#align(center)[
  #v(1.4cm)
  #text(size: 11pt, fill: luma(90), tracking: 1.2pt)[PROPOSAL GUIDE]
  #v(0.5cm)
  #text(size: 19pt, weight: "bold")[
    Updating the GBIF \
    Identifier extension
  ]
  #v(0.35cm)
  #text(size: 11.5pt, fill: luma(60))[
    Typed identifiers for Taxon, Event, and Occurrence, \
    aligned with DwC-DP `event-identifier`
  ]
  #v(0.6cm)
  #line(length: 40%, stroke: 0.8pt + luma(160))
  #v(0.4cm)
  #text(size: 9.8pt)[
    For a GitHub issue on `gbif/rs.gbif.org`. \
    Modelling discussion: #link("https://github.com/tdwg/dwc/issues/1083")[tdwg/dwc\#1083].
  ]
  #v(0.25cm)
  #text(size: 9.5pt, fill: luma(90))[26 October 2026]
]

#v(0.9cm)

= The change to ask for

Update the existing GBIF Identifier extension (`http://rs.gbif.org/terms/1.0/Identifier`, file `extension/gbif/1.0/identifier.xml`, issued 2015-02-13). Do not register a second extension, and do not add a Darwin Core term.

The 2015 text says each row is another identifier for the same taxon. That is too narrow. The same row type should carry a typed identifier for whichever core record `coreid` points at. The cores registered at `rs.gbif.org` are Taxon, Event, and Occurrence. There is no MaterialSample core in `core/` or on the live registry. `dwc:MaterialSample` is a class, and the IPT manual uses it only as the example of a core an administrator would configure by hand. GGBN's registered "Material Sample" entry is an extension (`http://data.ggbn.org/schemas/ggbn/terms/MaterialSample`), written against a core GBIF does not ship. DwC-DP does have `material-identifier`, and `IdentifierMapping` already attaches those rows to Event or Occurrence. The extension definition should match the three registered cores.

The concrete reason to do it now is the BBNJ standardized batch identifier: a Clearing-House URL that sits on a cruise or cruise-leg event, beside the scientific cruise code, including when no material is retained. The extension stays generic. `bbnjBatch` is one value of `identifierType`, not a term name.

#callout("Decision", [
  Keep the row type. Keep `dcterms:identifier` as the value column. Add the four DwC-DP typing columns (`identifierType`, `identifierTypeIRI`, `identifierTypeSource`, `identifierLanguage`) with the Dublin Core qualnames below. Leave `title`, `subject`, `format`, and `datasetID` in the file so existing checklist mappings still validate. Do not give those four a new job.
])

= Why the issue belongs on GBIF

#link("https://github.com/tdwg/dwc/issues/1083")[tdwg/dwc\#1083] compares ways to record the batch identifier. The preferred DwC-A path is to adapt this extension (option B). Cecilia Svensson's comment on 23 October 2026 supports that path. She asks whether the extension also needs `eventID`, whether the pre-collection notification needs its own term, and whether `identifierTypeIRI` and `identifierTypeSource` already cover that link. Those three are answered below. She also notes that the extension is not a TDWG vocabulary: the schema change is a `gbif/rs.gbif.org` issue. The modelling discussion stays on `tdwg/dwc`.

DwC-DP needs no new table. `event-identifier`, `survey-identifier`, `occurrence-identifier`, `material-identifier`, `organism-identifier`, `agent-identifier`, and `media-identifier` already share one column set: `identifier`, `identifierType`, `identifierTypeIRI`, `identifierTypeSource`, `identifierLanguage`, plus a foreign key. In a Darwin Core Archive the foreign key is `coreid`. It is not a property of the extension.

= Properties

== Terms that define the updated extension

`identifier` is already in the file. The other four are new. Only `identifier` stays required, so a taxon archive that today maps only that column remains valid. Event and occurrence publishers should fill `identifierType`.

#figure(
  kind: table,
  caption: [Terms to document as the identifier itself. `name` is the extension attribute and the DwC-DP column. IPT writes `qualName` into `meta.xml`.],
)[
  #set text(size: 8pt)
  #table(
    columns: (1.15fr, 2.15fr, 0.55fr, 1.7fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*`name`*], [*qualName*], [*Req.*], [*Role*],
    [`identifier`], [#uri("http://purl.org/dc/terms/identifier")], [yes], [The identifier string. For a BBNJ batch, the CHM URL.],
    [`identifierType`], [#uri("http://purl.org/dc/elements/1.1/type")], [no], [Category of that string: `bbnjBatch`, `cruise`, `wigos`, `lsid`, …],
    [`identifierTypeIRI`], [#uri("http://purl.org/dc/terms/type")], [no], [IRI of the vocabulary concept named in `identifierType`.],
    [`identifierTypeSource`], [#uri("http://purl.org/dc/elements/1.1/source")], [no], [Vocabulary or authority that defines the category.],
    [`identifierLanguage`], [#uri("http://purl.org/dc/elements/1.1/language")], [no], [Language of the identifier string, when it has one. Unused for registry ids.],
  )
]

These qualnames are the `dcterms:isVersionOf` values on the DwC-DP table, with one deliberate exception. On `event-identifier` the column `identifier` is `skos:notation` in the RDF mapping. The archive term stays `dcterms:identifier`, because that is the required column every existing mapping already uses. Adding a second value column under `skos:notation` would split the string across two fields.

== Why `name` and the URI local name differ

Both type qualnames end in `/type`. `dc:type` (`http://purl.org/dc/elements/1.1/type`) is the literal category. `dcterms:type` (`http://purl.org/dc/terms/type`) is the IRI of that category. This is the same split as `dc:language` and `dcterms:language` on the occurrence core. The extension `name` attribute has to be unique, so it cannot be `type` twice. Use the DwC-DP column names (`identifierType`, `identifierTypeIRI`) and put the real term in `qualName`.

IPT uses `qualName`. `GenerateDwca` resolves `extensionProperty.getQualname()` through `TermFactory` and that URI is what lands in `meta.xml`. `namespace` should be the namespace of the qualName (`http://purl.org/dc/elements/1.1/` or `http://purl.org/dc/terms/`). For these four properties, `namespace` + `name` will not equal `qualName`. That is intentional. A review that "corrects" `identifierType` to the local name `type` will collide with `identifierTypeIRI`.

`identifierTypeIRI` has to be declared. A DwC-A extension does not grow an IRI column because the literal term is listed. The occurrence core mentions a `dwciri:` equivalent in the comments of about forty terms and declares none of them (zero properties in `http://rs.tdwg.org/dwc/iri/`, core issued 2025-07-10). The #link("https://dwc.tdwg.org/rdf/")[RDF guide] defines `dwciri:lifeStage` as the IRI-object form of `dwc:lifeStage`. That is an RDF predicate rule. It does not add a column to an extension, and a URL typed into the literal column is still a literal.

== Columns to leave in the file

These four are already in `identifier.xml`. They are not part of `event-identifier` (except where noted). Keep them so a new version does not drop a column someone has mapped. The issue should say what each one actually is, so they are not reused for the batch identifier.

#figure(
  kind: table,
  caption: [Properties already in the 2015 extension. Retain. Do not repurpose.],
)[
  #set text(size: 8pt)
  #table(
    columns: (0.85fr, 1.7fr, 2.15fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*`name`*], [*qualName*], [*What it is*],
    [`title`], [#uri("http://purl.org/dc/terms/title")], [Optional display label for a link ("IPNI", "COL taxon LSID").],
    [`subject`], [#uri("http://purl.org/dc/terms/subject")], [Free keywords. Not the type. `identifierType` takes that job.],
    [`format`], [#uri("http://purl.org/dc/terms/format")], [Media type returned when a taxon identifier is a resolvable link (`application/rdf+xml`). Not in any DwC-DP `*-identifier` table. A batch id does not need it.],
    [`datasetID`], [#uri("http://rs.tdwg.org/dwc/terms/datasetID")], [Which constituent checklist contributed this row. Not a property of the identifier. See below.],
  )
]

`format` has been in the extension since the 2015 file. The description there is the MIME type of content returned when `identifier` is resolvable (HTML, XML, RDF, JSON). Plain UUIDs have no format. None of the seven DwC-DP identifier tables has this column. It belongs to the checklist case, where the row is often a webpage, LSID, or DOI for a taxon.

`datasetID` was not part of the original identifier design either. Commit #link("https://github.com/gbif/rs.gbif.org/commit/69d3c3bca4e8d5d38818819de6e91cd9702a66b8")[`69d3c3b`] (25 April 2016, "Add datasetID to gbif extensions") pasted the same property onto Identifier, Description, Distribution, Multimedia, References, Species Profile, Types and Specimen, and Vernacular Name. The shared description is the generic gloss "an identifier for a subset of data." The #link("https://ipt.gbif.org/manual/en/ipt/latest/best-practices-checklists")[checklist publishing guide] explains the pattern: one archive compiles several source checklists (Catalogue of Life global species datasets are the usual example), and `datasetID` points at the constituent. If that constituent's EML is inside the archive, the value is the filename. Otherwise it is a URL or another resolvable dataset id.

On an identifier row that means "the IPNI LSID on this taxon was contributed by the IPNI constituent," whose metadata might be `datasets/ipni.xml`. It does not mean "this string identifies a dataset." A single-dataset checklist leaves it empty. TaxonWorks' alternate-identifier export does not map it. A BBNJ batch row has nothing to put there: the cruise dataset is the archive itself.

= What not to add

- *`eventID` or `event_fk`.* In DwC-DP, `event_fk` points at `event.event_pk` and aggregators may remint it. The publisher's `eventID` stays on the Event row. In a Darwin Core Archive every extension row already joins its core record through `coreid`. On an Event-core archive that `coreid` is the event. A second `eventID` column would also be meaningless on the existing Taxon-core use of this extension.
- *A `dwciri:` twin of any of these properties.* Declare `identifierTypeIRI` explicitly, as above. Do not expect `http://rs.tdwg.org/dwc/iri/…` to appear on its own.
- *`bbnjBatchID`, or any treaty-named term.* The category lives in `identifierType`.
- *An ABSCH UID as an identifier type.* `ABSCH-IRCC-FR-252418` identifies the certificate in the ABS Clearing-House, not the event or occurrence it covers. One certificate can apply to many records, and one record can sit under several permits. That relationship belongs on the GGBN Permit extension (`permitType` for an IRCC, `permitURI` for the stable ABSCH URL). A `bbnjBatch` value still fits here, because that string is an identifier of the collection batch the event represents.
- *BioSample and BioProject accessions on the wrong event.* A BioSample accession (`SAMN`, `SAMEA`, `SAMD`) is an identifier of the sample. Put it on the event that is that sample, with `identifierType=biosample`, the same way an IGSN sits on a sample event. Do not put it on the cruise event, and do not put it on each metabarcoding occurrence: those occurrences are detections from the sample, not the sample. Also copy the accession into `materialSampleID` on the Occurrence so the field the GBIF DNA-derived data guide already indexes stays populated. A BioProject accession (`PRJNA`, `PRJEB`, `PRJDB`) is an identifier of the cruise event only when that cruise is the sequencing study. When one project covers several cruises, or one cruise feeds several projects, the accession names the study rather than each cruise, and it does not belong on those events. Sequence and read accessions stay in `associatedSequences`.
- *Pre-collection, post-collection, or utilization URL terms.* The interim batch identifier is itself the CHM URL (`https://www.un.org/bbnjagreement/en/mgr-notifications/bbnj-mgr-temp-2026-001`). That URL goes in `identifier`. The batch id stays stable while notification records around it are updated. `identifierTypeIRI` and `identifierTypeSource` point at the vocabulary entry for the category, not at the notification.
- *A new row type.* Ingest already targets `http://rs.gbif.org/terms/1.0/Identifier`. A parallel Event Identifier extension would be a second landing pad for the same rows.

= Publishing example

One cruise event, two identifier rows. `coreid` is the event's archive id. Scientific `eventID` and `parentEventID` are unchanged on the event file.

#figure(
  kind: table,
  caption: [Identifier extension rows for one event. Header names are the extension `name` attributes.],
)[
  #set text(size: 8pt)
  #table(
    columns: (1.3fr, 3.4fr, 1.1fr),
    stroke: 0.4pt + luma(180),
    inset: 4.5pt,
    [*coreid*], [*identifier*], [*identifierType*],
    [`<cruise event id>`], [#uri("https://www.un.org/bbnjagreement/en/mgr-notifications/bbnj-mgr-temp-2026-001")], [`bbnjBatch`],
    [`<cruise event id>`], [`MSM129`], [`cruise`],
  )
]

`identifierTypeIRI` and `identifierTypeSource` are filled when a vocabulary concept exists for `bbnjBatch`. Until then they stay empty. `format` may be `text/html` on the first row if a publisher wants to record that the URL returns HTML. It is optional and not part of the batch-identifier contract. `datasetID` stays empty.

The same pattern covers eDNA with no retained material, because the row hangs off the event. On an Occurrence-core archive the same string can be repeated with `coreid` pointing at the occurrence, for a consumer that will not walk the event hierarchy. The canonical row is the one on the batch event.

= Text and vocabulary

== Description to replace

The extension `dc:description` is empty, and the `identifier` property still says "other known identifier used for the same taxon." Replace that with wording along these lines.

- *Extension.* An identifier for the core record this row is attached to. The cores registered at `rs.gbif.org` are Taxon, Event, and Occurrence. The link to that record is the archive `coreid`.
- *`identifier`.* The identifier string: a URL, DOI, LSID, UUID, or other token for the core record. When the identifier is a resolvable registry or Clearing-House record, put that URL here.
- *`identifierType`.* The category of `identifier` (`bbnjBatch`, `cruise`, `wigos`, `lsid`, …). Recommended whenever the core is an Event or an Occurrence. This is `dc:type`, the literal, matching DwC-DP.
- *`identifierTypeIRI`.* IRI of the controlled-vocabulary concept named in `identifierType`. This is `dcterms:type`. It is not implied by `identifierType`, and it does not point at the identified resource.
- *`identifierTypeSource`.* Reference to the vocabulary or authority that defines `identifierType`.
- *`identifierLanguage`.* Language of the identifier string, if it has one. ISO 639-2. Rarely applicable to registry identifiers.

== `identifierType` vocabulary

Ship a small thesaurus and point the `identifierType` property at it with the `thesaurus` attribute. Suggested initial concepts: `bbnjBatch`, `cruise`, `expocode`, `biosample`, `bioproject`, `wigos`, `igsn`, `doi`, `lsid`, `local`, `other`. `cruise` is the operator's label (`MSM129`). `expocode` is the CCHDO expedition code: a 4-character platform code plus the departure date, for example `33RR20090329` (Roger Revelle, 29 March 2009). Both name the cruise and the strings differ, so they are two rows on that event. Do not put the code on stations or samples under the cruise. `biosample` is for the event that is the sample. `bioproject` is for the event that is the cruise, when that cruise is the sequencing study. `local` is the one token the DwC-DP mapping guide already uses, for a database key kept beside a minted UUID.

Leave the property open to other strings. The BBNJ token syntax is not fixed, and the list will grow (DOI-based batch ids are one option still in discussion). A closed dropdown would freeze a draft vocabulary into the extension. The thesaurus is the suggested list, not a validator.

= How to land it

Follow `versioning.md` in `gbif/rs.gbif.org`. Publish a new dated file under `sandbox/extension/` first. Do not edit `extension/gbif/1.0/identifier.xml` in place. Set `dc:issued` to the release date. Keep `rowType="http://rs.gbif.org/terms/1.0/Identifier"`. Production promotion is a later step, once an IPT can map a synthetic event archive (one event, two identifier rows, as in the example).

One pipelines follow-up belongs in the same issue or a linked one. `TargetTerms` in `gbif/pipelines` (`…/dwcdp/mapping/config/TargetTerms.java`) allowlists `identifierType`, `identifierTypeIRI`, `identifierTypeSource`, and `identifierLanguage` as raw simple names, because they are not known `TermFactory` terms. The `identifier` column already resolves to `dcterms:identifier`. After the extension exists, the fan-out should emit the qualnames in the table above, so a DwC-DP package and a hand-built DwC-A use the same term URIs in `meta.xml`.

= Suggested issue

Title: *Update the Identifier extension for typed identifiers on Taxon, Event, and Occurrence.*

Repository: `gbif/rs.gbif.org`. Link #link("https://github.com/tdwg/dwc/issues/1083")[tdwg/dwc\#1083].

Body, in short:

+ Keep row type `http://rs.gbif.org/terms/1.0/Identifier`. This is the landing pad DwC-DP ingest already uses.
+ Stop describing the row as taxon-only. `coreid` may point at a Taxon, Event, or Occurrence, which are the cores registered at `rs.gbif.org`. Do not depend on a MaterialSample core. DwC-DP `material-identifier` rows already land on Event or Occurrence.
+ Add `identifierType` (`dc:type`), `identifierTypeIRI` (`dcterms:type`), `identifierTypeSource` (`dc:source`), and `identifierLanguage` (`dc:language`), using the DwC-DP column names as the extension `name` and the Dublin Core URIs as `qualName`.
+ Keep `dcterms:identifier` as the only required column. Do not add `skos:notation` beside it.
+ Retain `title`, `subject`, `format`, and `datasetID` unchanged. `format` is the MIME type of a resolvable taxon link. `datasetID` attributes a checklist row to a constituent dataset. Neither describes a batch identifier.
+ Do not add `eventID`. Do not add `bbnjBatchID`.
+ Sandbox a dated version plus an open `identifierType` vocabulary (`bbnjBatch`, `cruise`, `expocode`, `biosample`, `bioproject`, `wigos`, `igsn`, `doi`, `lsid`, `local`, `other`). `expocode` is the CCHDO code and sits beside `cruise` on the same cruise event. `biosample` goes on the sample event. `bioproject` goes on the cruise event only when that cruise is the study. Do not add an ABSCH UID type. Leave sequence and read accessions in `associatedSequences`, and copy the BioSample accession into `materialSampleID`.
+ In `gbif/pipelines`, emit those qualnames from `TargetTerms` instead of the bare allowlisted names.

#v(0.6cm)
#text(size: 8.5pt, fill: luma(90))[
  Sources: `extension/gbif/1.0/identifier.xml`; DwC-DP `1.0` `*-identifier` table schemas; `IdentifierMapping` and `TargetTerms` in `gbif/pipelines`; Darwin Core RDF guide; IPT checklist publishing guide; `rs.gbif.org` commit `69d3c3b`; tdwg/dwc\#1083.
]
