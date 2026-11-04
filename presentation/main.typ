#import "theme.typ": *

#show: theme.with(
  title: [Darwin Core Data Package],
)

#cover(
  title: [Darwin Core Data Package \ (DwC-DP)],
  //subtitle: [Introduction to Darwin Core Data package (DwC-DP) and implications for OBIS indexing],
  meta: [31 October 2026],
)

#section[Overview]

#slide(title: [The building blocks])[
  == 1. Darwin Core List of Terms

  Darwin Core terms provide *identifiers, labels, definitions, and usage guidance for concepts* used to describe taxa, organisms, occurrences, events, material entities, identifications, locations, geological context, measurements and assertions, agents, media, protocols, references, and related biodiversity information.

  https://dwc.tdwg.org/list/

]

#slide(title: [The building blocks])[
  == 2. Darwin Core Conceptual Model (DwC-CM)

  The Darwin Core Conceptual Model (DwC-CM) provides a *high‑level framework that shows how Darwin Core (DwC) classes relate to one another* in typical biodiversity information workflows. Darwin Core formally defines a set of terms grouped by classes; DwC‑CM clarifies the conceptual meaning of those classes and the relationships among them so implementers can make consistent, interoperable design choices across different technologies.

  https://dwc.tdwg.org/cm/
]

#slide(title: [The building blocks])[
  == 3. Frictionless Data Package

  Frictionless Data Package is an open, *lightweight container format* and specification used to bundle a collection of data files together with standardized metadata and schemas.

  https://specs.frictionlessdata.io/
]

#slide(title: [The building blocks])[
  == 4. Darwin Core Data Package (DwC-DP)

  Darwin Core Data Package (hereafter referred to as DwC-DP) is a *community-developed container format* to exchange biodiversity data. It extends the Data Package specification (developed by Frictionless Data) as an implementation for the Darwin Core Conceptual Model. This document specifies the requirements for a dataset to comply with DwC-DP.

  https://dwc.tdwg.org/dp/
]

#slide(title: [Darwin Core Conceptual Model])[
  #align(center)[
    #image("assets/dwc-cm.png", height: 380pt)
  ]
]

#slide(title: [Darwin Core Conceptual Model])[

  In Darwin Core, an *Event* is an action, a process, or a set of circumstances occurring at some place during some interval of time.

  #align(center)[
    #image("assets/event.png", height: 280pt)
  ]
]

#slide(title: [Darwin Core Conceptual Model])[
  
  In Darwin Core, a *Survey* refers to an Event that is a biotic survey or inventory, which, with sufficiently detailed information, can support not only evidence of presence of Organisms but also absences of detection and estimations of abundance. 

  #align(center)[
    #image("assets/survey.png", height: 300pt)
  ]
]

#slide(title: [Darwin Core Conceptual Model])[

  An *Occurrence* is an Event that establishes the state of an Organism at a particular place and time. The state of an Organism covered by the Occurrence class consists of attributes of an Organism that can differ between Occurrences, such as lifeStage, sex, etc.

  #align(center)[
    #image("assets/occurrence-organism.png", height: 280pt)
  ]
]

#slide(title: [Darwin Core Conceptual Model])[

  In Darwin Core, an *Identification* is defined as "A classification of a resource according to a classification scheme". For Organisms, this means a taxonomic determination (i.e., the assignment of a Taxon to an Organism).

  #align(center)[
    #image("assets/identification.png", height: 280pt)
  ]
]

#slide(title: [Darwin Core Conceptual Model])[

  A *Nucleotide Analysis* is a link between a *Nucleotide Sequence* or an *Identification*, and an Event and a Material Entity from which it was derived, using a specified *Molecular Protocol*.

  #align(center)[
    #image("assets/nucleotide.png", height: 300pt)
  ]
]

#slide(title: [Darwin Core Data Package])[

  == DwC-DP content

  - EML metadata file `eml.xml` (optional)
  - JSON descriptor `datapackage.json`
  - At least one resource file representing a data package table
  - Other resource files (optional)

]

#slide(title: [Darwin Core Data Package])[

  == DwC-DP table properties

  - Name
  - Path
  - Profile (must be `tabular-data-resource`)
  - Format
  - Media type (must be `text/csv`)
  - Table schema (provided at `rs.tdwg.org`)
    - Fields
    - Primary key
    - Foreign keys (have a `predicate` property to document relationship semantics)
]

#section[In practice]

#slide(title: [Example dataset: ARMS])[
  #align(center)[
    #box[
      #image("assets/arms.svg", height: 410pt)
      #place(top + right, dx: 40pt, dy: -150pt)[
        #box(width: 240pt)[
          #image("assets/20201203-151235345.jpg", width: 100%)
          #v(-8pt)
          #align(right)[
            #text(size: 11pt, fill: rgb("#59636e"))[Image: Alf Norkko]
          ]
        ]
      ]
    ]
  ]
]

#slide(title: [OBIS indexing])[
  #grid(
    columns: (1fr, auto),
    column-gutter: 48pt,
    align: horizon,
    [
      == Implementation proposal
      
      === Phase 1
      
      Project most common patterns to existing index (Event and Occurrence)
      
      === Phase 2
      
      Provide SQL-like access to full data model
    ],
    image("assets/dwc-cm-boxes.png", height: 380pt),
  )
]


#slide(title: [But... eDNA])[

  The DNADerivedData extension is not a very efficient way of storing sequence data, as identical sequences are repeated for every sample.

  #v(30pt)

  ```
  ➜  b508f7bc-8708-43d5-b940-e44f2765d1af ls -alh
  total 319219120
  drwx------  7 pieter  staff   224B Nov  4 12:16 .
  drwxr-xr-x@ 5 pieter  staff   160B Nov  4 12:16 ..
  -rw-rw-r--  1 pieter  staff    21G Dec 23  2025 dnaderiveddata.txt
  -rw-rw-r--  1 pieter  staff   4.5K Dec 23  2025 eml.xml
  -rw-rw-r--  1 pieter  staff   126G Dec 23  2025 extendedmeasurementorfact.txt
  -rw-rw-r--  1 pieter  staff   5.0K Dec 23  2025 meta.xml
  -rw-rw-r--  1 pieter  staff   5.9G Dec 23  2025 occurrence.txt
  ```

]

#slide(title: [But... eDNA])[

  DwC-DP offers a solution through the `nucleotide-analysis` table.

  #v(30pt)

  #align(center)[
    #image("../diagrams/nucleotide-foreign-keys.svg", height: 320pt)
  ]

]

#slide(title: [But... eDNA])[

  DwC-DP offers a solution through the `nucleotide-analysis` table.

  #v(30pt)

  #align(center)[
    #image("../diagrams/edna-index.svg", height: 240pt)
  ]

]

#slide(title: [The other eDNA issue])[

  Current indexing repeats Event level measurement at every occurrence, which is problematic in particular for high volume eDNA datasets.

  #align(center)[
    #image("../diagrams/indexing-old.svg", height: 380pt)
  ]
]

#slide(title: [The other eDNA issue])[

  Proposal: keep extension records in separate tables, provide tooling for user side joining.

  #align(center)[
    #image("../diagrams/indexing.svg", height: 380pt)
  ]
]

