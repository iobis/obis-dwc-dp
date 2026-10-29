# Representing BBNJ standardized batch identifiers in Darwin Core

## Context

The [BBNJ Agreement](https://www.un.org/bbnjagreement/en) (or High Seas Treaty) entered into force on 17 January 2026. Under Art. 12(2), a pre-collection notification needs to be sent to the Clearing-House Mechanism (CHM) six months in advance of the collection of marine genetic resources (MGR) from areas beyond national jurisdiction (ABNJ). MGR is defined here as *"any material of marine plant, animal, microbial or other origin containing functional units of heredity of actual or potential value"*. Per Art. 12(3), upon the pre-collection notification, the CHM automatically generates a **standardized batch identifier**. Art. 14(3) requires that MGR and related digital sequence information (DSI) are deposited along with their standardized batch identifier in publicly accessible repositories and databases. Separately, Art. 12(7) requires repositories and databases to prepare an **aggregate report on access** to MGR and DSI linked to their standardized batch identifier on a biennial basis, to the extent practicable.

The identifier format is still being discussed, but an interim example exists: [https://www.un.org/bbnjagreement/en/mgr-notifications/bbnj-mgr-temp-2026-001](https://www.un.org/bbnjagreement/en/mgr-notifications/bbnj-mgr-temp-2026-001)

I'm opening this as a discussion of options, not a formal request.

## Requirements

- The identifier attaches at the Event level and will in most cases cover a single scientific cruise or a cruise leg.
- The identifier will coexist with a scientific cruise code but not replace it (so `eventID` is not to be overloaded with the batch identifier).
- The solution should also work when no material is retained (for example eDNA sequenced and discarded), not just for sample or specimen collection.
- A generic solution not tied to this specific treaty is preferred.

## Options


| Approach                                   | Description                                                                                                                                                                                                                                                                        | Cons                                                                                                                                                             |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A. Guidance only: populate existing terms  | e.g. batch identifier in `eventID` or `projectID`                                                                                                                                                                                                                                  | Overloads semantics, projectID is funder/research projects ([#532](https://github.com/tdwg/dwc/issues/532)), eventID is a structural/scientific hierarchy key    |
| B. Adapt Alternative Identifiers extension | Broaden scope of GBIF [Alternative Identifiers](https://rs.gbif.org/extension/gbif/1.0/identifier.xml) to Event/Occurrence/Material, add `identifierType` (cf. [event-identifier](https://github.com/tdwg/rs.tdwg.org/blob/master/dwc-dp/1.0/table-schemas/event-identifier.json)) | Confusing extension history, requires GBIF commitment (although I believe GBIF already repurposes this row type for various identifiers during DwC-DP ingestion) |
| C. New DwC-A Event Identifier extension    | Mirror DwC-DP [event-identifier](https://dwc.tdwg.org/dwc-dp/qrg/#event-identifier)                                                                                                                                                                                                |                                                                                                                                                                  |
| D. New generic core term on Event          | e.g. `collectionBatchID` / `sampleBatchID`                                                                                                                                                                                                                                         | Single value, no typing                                                                                                                                          |
| E. New treaty-specific core term           | `bbnjBatchID`                                                                                                                                                                                                                                                                      | Not sufficiently generic                                                                                                                                         |


## Preferred direction (for discussion)

Lean toward **B or C**: `event-identifier` for DwC-DP, for DwC-A either update Alternative Identifiers (B) or add an Event Identifier extension that mirrors DwC-DP (C).

Happy to turn whatever emerges into a formal request.