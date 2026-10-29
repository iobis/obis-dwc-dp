#!/usr/bin/env python3
"""Query DwC-DP parquet tables using technical identifiers.

Selects relevant occurrences, linked events (including parent events),
and linked extension records (MOF, DNA). Joins use the structural keys
minted by the pipeline branch ``table-parquet-structural-keys``:

- ``occurrence_pk`` / ``event_fk`` on occurrences
- ``event_pk`` / ``parentEvent_fk`` on events
- ``occurrence_fk`` or ``event_fk`` on extension rows
- ``extendedMeasurementOrFact_pk`` / ``dnaDerivedData_pk`` on extension rows
- ``nucleotide_analysis_pk`` / ``nucleotide_sequence_fk`` / ``molecular_protocol_fk`` /
  ``occurrence_fk`` / ``event_fk`` when DNA was exported with ``EXPORT_NUCLEOTIDE_TABLES``

Those keys are lake-unique (``_id`` UUIDs for events and occurrences,
fresh UUIDs for extension rows), so joins do not also match ``dataset_id``
or Darwin Core ``occurrenceID`` / ``eventID`` / ``parentEventID``.

Exports one JSON object per row in JSONL, or a TSV with technical keys
as columns and ``interpreted`` as a JSON column.

Example:

    python scripts/query_subset_structural_keys.py \\
        --family Spionidae \\
        --output ./output/queries/keys/spionidae \\
        --format jsonl
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import duckdb

DEFAULT_DATA_ROOT = Path(__file__).resolve().parents[1] / "output" / "parquet" / "keys"

TABLE_EXPORTS: dict[str, dict[str, object]] = {
    "occurrence": {
        "filename": "occurrence",
        "select": """
            SELECT
                dataset_id,
                occurrence_pk,
                event_fk,
                interpreted,
                dropped,
                absence
            FROM _filtered_occurrences
        """,
    },
    "event": {
        "filename": "event",
        "optional": True,
        "select": """
            SELECT
                e.dataset_id,
                e.event_pk,
                e."parentEvent_fk",
                e.interpreted,
                e.dropped,
                e.absence
            FROM read_parquet('{data_root}/*/event.parquet') e
            INNER JOIN _event_keys k
              ON e.event_pk = k.event_pk
        """,
    },
    "occurrence_measurementorfact": {
        "filename": "occurrence_measurementorfact",
        "optional": True,
        "select": """
            SELECT
                m.dataset_id,
                m."extendedMeasurementOrFact_pk",
                m.occurrence_fk,
                m.interpreted
            FROM read_parquet('{data_root}/*/occurrence_measurementorfact.parquet') m
            INNER JOIN _occurrence_keys k
              ON m.occurrence_fk = k.occurrence_pk
        """,
    },
    "event_measurementorfact": {
        "filename": "event_measurementorfact",
        "optional": True,
        "select": """
            SELECT
                m.dataset_id,
                m."extendedMeasurementOrFact_pk",
                m.event_fk,
                m.interpreted
            FROM read_parquet('{data_root}/*/event_measurementorfact.parquet') m
            INNER JOIN _event_keys k
              ON m.event_fk = k.event_pk
        """,
    },
    "occurrence_dnaderiveddata": {
        "filename": "occurrence_dnaderiveddata",
        "select": """
            SELECT
                d.dataset_id,
                d."dnaDerivedData_pk",
                d.occurrence_fk,
                d.interpreted
            FROM read_parquet('{data_root}/*/occurrence_dnaderiveddata.parquet') d
            INNER JOIN _occurrence_keys k
              ON d.occurrence_fk = k.occurrence_pk
        """,
        "optional": True,
    },
    "event_dnaderiveddata": {
        "filename": "event_dnaderiveddata",
        "select": """
            SELECT
                d.dataset_id,
                d."dnaDerivedData_pk",
                d.event_fk,
                d.interpreted
            FROM read_parquet('{data_root}/*/event_dnaderiveddata.parquet') d
            INNER JOIN _event_keys k
              ON d.event_fk = k.event_pk
        """,
        "optional": True,
    },
    "nucleotide_analysis": {
        "filename": "nucleotide_analysis",
        "select": """
            SELECT
                d.dataset_id,
                d.nucleotide_analysis_pk,
                d.nucleotide_sequence_fk,
                d.molecular_protocol_fk,
                d.occurrence_fk,
                d.event_fk,
                d.material_entity_fk,
                d.interpreted
            FROM read_parquet('{data_root}/*/nucleotide_analysis.parquet') d
            WHERE d.occurrence_fk IN (SELECT occurrence_pk FROM _occurrence_keys)
               OR d.event_fk IN (SELECT event_pk FROM _event_keys)
        """,
        "optional": True,
    },
    "nucleotide_sequence": {
        "filename": "nucleotide_sequence",
        "select": """
            SELECT DISTINCT
                s.dataset_id,
                s.nucleotide_sequence_pk,
                s.interpreted
            FROM read_parquet('{data_root}/*/nucleotide_sequence.parquet') s
            INNER JOIN read_parquet('{data_root}/*/nucleotide_analysis.parquet') d
              ON d.nucleotide_sequence_fk = s.nucleotide_sequence_pk
            WHERE d.occurrence_fk IN (SELECT occurrence_pk FROM _occurrence_keys)
               OR d.event_fk IN (SELECT event_pk FROM _event_keys)
        """,
        "optional": True,
    },
    "molecular_protocol": {
        "filename": "molecular_protocol",
        "select": """
            SELECT DISTINCT
                p.dataset_id,
                p.molecular_protocol_pk,
                p.interpreted
            FROM read_parquet('{data_root}/*/molecular_protocol.parquet') p
            INNER JOIN read_parquet('{data_root}/*/nucleotide_analysis.parquet') d
              ON d.molecular_protocol_fk = p.molecular_protocol_pk
            WHERE d.occurrence_fk IN (SELECT occurrence_pk FROM _occurrence_keys)
               OR d.event_fk IN (SELECT event_pk FROM _event_keys)
        """,
        "optional": True,
    },
}


def sql_path(path: str) -> str:
    return path.replace("'", "''")


def build_occurrence_filter(args: argparse.Namespace) -> tuple[str, list[object]]:
    clauses: list[str] = []

    if args.family:
        clauses.append("o.interpreted.family = ?")
    if args.genus:
        clauses.append("o.interpreted.genus = ?")
    if args.aphiaid is not None:
        clauses.append("o.interpreted.aphiaid = ?")
    if args.scientific_name:
        clauses.append("o.interpreted.scientificName ILIKE ?")
    if args.taxonomic_class:
        clauses.append('o.interpreted."class" = ?')
    if args.phylum:
        clauses.append("o.interpreted.phylum = ?")
    if not args.include_absence:
        clauses.append("coalesce(o.absence, false) = false")

    if not any(
        [
            args.family,
            args.genus,
            args.aphiaid is not None,
            args.scientific_name,
            args.taxonomic_class,
            args.phylum,
        ]
    ):
        raise SystemExit(
            "Provide at least one taxonomic filter: --family, --genus, --aphiaid, "
            "--scientific-name, --class, or --phylum"
        )

    params: list[object] = []
    if args.family:
        params.append(args.family)
    if args.genus:
        params.append(args.genus)
    if args.aphiaid is not None:
        params.append(args.aphiaid)
    if args.scientific_name:
        params.append(f"%{args.scientific_name}%")
    if args.taxonomic_class:
        params.append(args.taxonomic_class)
    if args.phylum:
        params.append(args.phylum)

    occurrence_filter = ""
    if clauses:
        occurrence_filter = "AND " + " AND ".join(clauses)

    return occurrence_filter, params


def prepare_subset_tables(
    con: duckdb.DuckDBPyConnection,
    data_root: str,
    occurrence_filter: str,
    params: list[object],
    max_event_depth: int,
) -> None:
    """Materialize filtered occurrences and technical-key temp tables."""
    root = sql_path(data_root)
    con.execute(
        f"""
        CREATE OR REPLACE TEMP TABLE _filtered_occurrences AS
        SELECT o.*
        FROM read_parquet('{root}/*/occurrence.parquet') o
        WHERE coalesce(o.dropped, false) = false
          {occurrence_filter}
        """,
        params,
    )

    con.execute(
        """
        CREATE OR REPLACE TEMP TABLE _occurrence_keys AS
        SELECT DISTINCT occurrence_pk
        FROM _filtered_occurrences
        WHERE occurrence_pk IS NOT NULL
        """
    )

    event_keys_sql = f"""
        CREATE OR REPLACE TEMP TABLE _event_keys AS
        WITH RECURSIVE relevant_events AS (
          SELECT DISTINCT
            o.event_fk AS event_pk,
            0 AS depth
          FROM _filtered_occurrences o
          WHERE o.event_fk IS NOT NULL

          UNION ALL

          SELECT
            e."parentEvent_fk" AS event_pk,
            r.depth + 1 AS depth
          FROM read_parquet('{root}/*/event.parquet') e
          INNER JOIN relevant_events r
            ON e.event_pk = r.event_pk
          WHERE e."parentEvent_fk" IS NOT NULL
            AND r.depth < {int(max_event_depth)}
        )
        SELECT DISTINCT event_pk FROM relevant_events
        """
    try:
        con.execute(event_keys_sql)
    except duckdb.IOException as exc:
        if "No files found" not in str(exc):
            raise
        con.execute("CREATE OR REPLACE TEMP TABLE _event_keys (event_pk VARCHAR)")


def require_technical_keys(con: duckdb.DuckDBPyConnection, data_root: str) -> None:
    root = sql_path(data_root)
    try:
        described = con.execute(
            f"DESCRIBE SELECT * FROM read_parquet('{root}/*/occurrence.parquet')"
        ).fetchall()
    except duckdb.Error as exc:
        raise SystemExit(f"Could not read occurrence parquet under {data_root}: {exc}") from exc

    columns = {row[0] for row in described}
    required = {"occurrence_pk", "event_fk", "interpreted"}
    missing = sorted(required - columns)
    if missing:
        raise SystemExit(
            "occurrence.parquet is missing "
            + ", ".join(missing)
            + ". This script expects table parquets from pipeline branch "
            "table-parquet-structural-keys."
        )


def render_query(spec: dict[str, object], data_root: str) -> str:
    select = spec["select"]
    if not isinstance(select, str):
        raise TypeError("TABLE_EXPORTS select must be SQL text")
    return select.replace("{data_root}", sql_path(data_root))


def query_count(con: duckdb.DuckDBPyConnection, query: str) -> int:
    return con.execute(f"SELECT count(*) FROM ({query})").fetchone()[0]


def friendly_duckdb_error(exc: duckdb.Error) -> str:
    message = str(exc).strip().splitlines()[0]
    if "No files found" in message:
        return "no parquet files"
    return message


def tsv_export_query(con: duckdb.DuckDBPyConnection, query: str) -> str:
    described = con.execute(f"DESCRIBE SELECT * FROM ({query})").fetchall()
    parts: list[str] = []
    for name, col_type, *_rest in described:
        quoted = '"' + name.replace('"', '""') + '"'
        if col_type.upper().startswith(("STRUCT", "MAP", "LIST", "UNION")):
            parts.append(f"to_json({quoted}) AS {quoted}")
        else:
            parts.append(quoted)
    return f"SELECT {', '.join(parts)} FROM ({query}) exported"


def export_query(
    con: duckdb.DuckDBPyConnection,
    query: str,
    output_path: Path,
    fmt: str,
    row_count: int,
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    destination = sql_path(str(output_path))

    if fmt == "jsonl":
        copy_sql = f"COPY ({query}) TO '{destination}' (FORMAT NDJSON)"
    elif fmt == "tsv":
        copy_sql = f"""
            COPY (
              {tsv_export_query(con, query)}
            ) TO '{destination}' (FORMAT CSV, HEADER true, DELIMITER '\t')
        """
    else:
        raise ValueError(f"Unsupported format: {fmt}")

    if row_count == 0:
        return

    con.execute(copy_sql)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--data-root",
        type=Path,
        default=Path(DEFAULT_DATA_ROOT),
        help=f"Root folder containing dataset subdirectories (default: {DEFAULT_DATA_ROOT})",
    )
    parser.add_argument("--output", type=Path, required=True, help="Output directory for exported files")
    parser.add_argument(
        "--format",
        choices=("jsonl", "tsv"),
        default="jsonl",
        help="Output format (default: jsonl)",
    )
    parser.add_argument("--family", help="Filter occurrences by interpreted.family")
    parser.add_argument("--genus", help="Filter occurrences by interpreted.genus")
    parser.add_argument("--aphiaid", type=int, help="Filter occurrences by interpreted.aphiaid")
    parser.add_argument("--scientific-name", help="Filter occurrences by interpreted.scientificName (substring match)")
    parser.add_argument("--class", dest="taxonomic_class", help='Filter occurrences by interpreted."class"')
    parser.add_argument("--phylum", help="Filter occurrences by interpreted.phylum")
    parser.add_argument(
        "--include-absence",
        action="store_true",
        help="Include absence records (excluded by default)",
    )
    parser.add_argument(
        "--max-event-depth",
        type=int,
        default=20,
        help="Maximum number of parentEvent_fk hops to follow (default: 20)",
    )
    parser.add_argument(
        "--skip-empty",
        action="store_true",
        help="Do not write files for optional tables with zero matching rows",
    )
    args = parser.parse_args()
    if args.max_event_depth < 0:
        parser.error("--max-event-depth must be >= 0")
    return args


def main() -> int:
    args = parse_args()
    data_root = str(args.data_root.resolve())

    if not args.data_root.is_dir():
        print(f"Data root not found: {args.data_root}", file=sys.stderr)
        return 1

    occurrence_filter, params = build_occurrence_filter(args)
    con = duckdb.connect()
    require_technical_keys(con, data_root)
    prepare_subset_tables(con, data_root, occurrence_filter, params, args.max_event_depth)

    extension = "jsonl" if args.format == "jsonl" else "tsv"
    planned: list[tuple[str, str, Path, int]] = []
    print("Matching records:")
    for table_name, spec in TABLE_EXPORTS.items():
        query = render_query(spec, data_root)
        output_path = args.output / f"{spec['filename']}.{extension}"
        optional = bool(spec.get("optional", False))
        label = {"occurrence": "occurrences", "event": "events"}.get(table_name, table_name)
        try:
            row_count = query_count(con, query)
        except duckdb.Error as exc:
            if optional:
                print(f"  skipped {label}: {friendly_duckdb_error(exc)}")
                continue
            raise
        print(f"  {label}: {row_count:,}")
        planned.append((table_name, query, output_path, row_count))

    for table_name, query, output_path, row_count in planned:
        optional = bool(TABLE_EXPORTS[table_name].get("optional", False))
        if row_count == 0 and optional and args.skip_empty:
            print(f"  skipped {table_name}: no rows")
            continue
        if row_count == 0:
            print(f"  {table_name}: no rows")
            continue

        try:
            export_query(con, query, output_path, args.format, row_count)
        except duckdb.Error as exc:
            if optional:
                print(f"  skipped {table_name}: {friendly_duckdb_error(exc)}")
                continue
            raise

        print(f"  wrote {output_path} ({row_count:,} rows)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
