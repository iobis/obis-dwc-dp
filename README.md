# OBIS and Darwin Core Data Package (DwC-DP)

DRAFT DOCUMENT

## What is Darwin Core Data Package (DwC-DP)?

Darwin Core Data Package is a community-developed container format to exchange biodiversity data. It extends the [Data Package specification](https://specs.frictionlessdata.io/) developed by Frictionless Data as an implementation for the [Darwin Core Conceptual Model](https://gbif.github.io/dwc-dp/cm/). It complements the [Darwin Core Archive (DwC-A)](https://ipt.gbif.org/manual/en/ipt/latest/dwca-guide) standard which is commonly used in OBIS and GBIF.

Documentation:

| Resource | URL |
| --- | --- |
| Darwin Core Data Package guide | https://gbif.github.io/dwc-dp/dp/ |
| Darwin Core Data Package Designer | https://gbif.github.io/dwc-dp/designer/ |
| DwC-DP table schemas | https://github.com/tdwg/rs.tdwg.org/tree/master/dwc-dp/table-schemas |


## How data are indexed in OBIS now

Datasets are submitted to OBIS as DwC-A using either Event or Occurrence Core. Accepted extensions are DNADerivedData and (Extended)MeasurementOrFact. Datasets are converted to GeoParquet and indexed in ElasticSearch using an Occurrence centric data model. Occurrences inherit field values as well as extension records from linked event and parent event records. This inheritance potentially introduces mass duplication of extension records at the occurrence level, for example when many abiotic measurements are associated with sampling events. It was introduced for performance reasons, but is now causing issues related to data volume.

GBIF does not have this inheritance of extension records. For example, occurrence record <https://www.gbif.org/occurrence/3863984603> in GBIF only has a single extension record associated with it:

```json
{
  "key": 3863984603,
  "datasetKey": "2ecef267-0e17-4f3f-adf9-20b036e6167a",
  "publishingCountry": "GB",
  "extensions": {
    "http://rs.iobis.org/obis/terms/ExtendedMeasurementOrFact": [
      {
        "http://rs.tdwg.org/dwc/terms/measurementUnit": "Millimetres",
        "http://rs.tdwg.org/dwc/terms/measurementType": "standard length (mm)",
        "http://rs.tdwg.org/dwc/terms/occurrenceID": "AWI_PS69_494-4_1_234695_PS69_FF_0660",
        "http://rs.iobis.org/obis/terms/measurementUnitID": "https://vocab.nerc.ac.uk/collection/P06/current/UXMM/",
        "http://rs.tdwg.org/dwc/terms/measurementValue": "48"
      }
    ]
  },
  "basisOfRecord": "PRESERVED_SPECIMEN",
```

While [the OBIS record](https://api.obis.org/occurrence?scientificname=Notolepis%20coatsi&startdate=2006-07-12&enddate=2006-07-12&mof=true) has event level extension records as well:

```json
{
  "catalogNumber": "PS69_FF_0660",
  "date_year": 2006,
  "decimalLatitude": -67.529,
  "decimalLongitude": -0.216,
  "mof": [
    {
      "measurementType": "standard length (mm)",
      "measurementUnit": "Millimetres",
      "measurementUnitID": "https://vocab.nerc.ac.uk/collection/P06/current/UXMM/",
      "measurementValue": "48",
      "occurrenceID": "AWI_PS69_494-4_1_234695_PS69_FF_0660",
      "level": 0
    },
    {
      "measurementType": "net number (i.e., six codends labelled from 1 to 6 or two nets labelled 1 to 2).",
      "measurementUnit": "Not applicable",
      "measurementUnitID": "https://vocab.nerc.ac.uk/collection/P06/current/XXXX/",
      "measurementValue": "1",
      "level": 1
    },
    {
      "measurementType": "station ID/number from research cruise",
      "measurementUnit": "Not applicable",
      "measurementUnitID": "https://vocab.nerc.ac.uk/collection/P06/current/XXXX/",
      "measurementValue": "494-4",
      "level": 1
    },
    {
      "measurementType": "duration of net tow (min).",
      "measurementTypeID": "https://vocab.nerc.ac.uk/collection/P01/current/AZDRZZ01/",
      "measurementUnit": "Minutes",
      "measurementUnitID": "https://vocab.nerc.ac.uk/collection/P06/current/UMIN/",
      "measurementValue": "49",
      "level": 1
    },
```

To be able to handle growing data volumes, it would be good if this inheritance could also be removed in OBIS. However, this will require significant changes in how the data are made available. If users still need to be able to access event level extension records with their occurrence downloads, there will need to be a way to join occurrences and (parent) events on the fly. This will also impact the R package which currently relies on embedded extension records from ElasticSearch.

Although this problem is not related to DwC-DP, it could be tackled in parallel with the DwC-DP implementation, as that will also require joining data tables on the fly.

## A new indexing model

### For DwC-A

Ignoring DwC-DP implications for now, the data duplication issue with Event core datasets could be tackled by creating an Event index with nested extension records. Such an index exists in fact in OBIS but it is not well developed or used very often. This solution would require:

- Creating separate Parquet files for event records with nested extension records
- Joining occurrence and events records during downloads
- Limiting the R package to occurrences records with directly linked extension records, or adding download functionality to the R package
- Changing the way dataset statistics are made available to the OBIS website

### For DwC-DP
