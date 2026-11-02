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

#slide(title: [Darwin Core Data Package])[
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
