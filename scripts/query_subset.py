#!/usr/bin/env python3
"""Query DwC-DP parquet tables and export taxonomic subsets.

Selects relevant occurrences, linked events (including parent events),
and linked extension records (MOF, DNA). Exports interpreted fields
without flattening — one JSON object per row in JSONL, or a single
`interpreted` JSON column in TSV.

Example:

    python scripts/query_subset.py \\
        --family Spionidae \\
        --output ./output/queries/no_keys/spionidae \\
        --format jsonl
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import duckdb

DEFAULT_DATA_ROOT = Path(__file__).resolve().parents[1] / "output" / "parquet" / "no_keys"

TABLE_EXPORTS: dict[str, dict[str, object]] = {
    "occurrence": {
        "filename": "occurrence",
        "select": """
            SELECT dataset_id, interpreted, dropped, absence
            FROM _filtered_occurrences
        """,
    },
    "event": {
        "filename": "event",
        "select": """
            SELECT e.dataset_id, e.interpreted, e.dropped, e.absence
            FROM read_parquet('{data_root}/*/event.parquet') e
            INNER JOIN _event_keys k
              ON e.dataset_id = k.dataset_id
             AND e.interpreted.eventID = k.event_id
        """,
    },
    "occurrence_measurementorfact": {
        "filename": "occurrence_measurementorfact",
        "select": """
            SELECT m.dataset_id, m.interpreted
            FROM read_parquet('{data_root}/*/occurrence_measurementorfact.parquet') m
            INNER JOIN _occurrence_keys k
              ON m.dataset_id = k.dataset_id
             AND m.interpreted.occurrenceID = k.occurrence_id
        """,
    },
    "event_measurementorfact": {
        "filename": "event_measurementorfact",
        "select": """
            SELECT m.dataset_id, m.interpreted
            FROM read_parquet('{data_root}/*/event_measurementorfact.parquet') m
            INNER JOIN _event_keys k
              ON m.dataset_id = k.dataset_id
             AND m.interpreted.eventID = k.event_id
        """,
    },
    "occurrence_dnaderiveddata": {
        "filename": "occurrence_dnaderiveddata",
        "select": """
            SELECT d.dataset_id, d.interpreted
            FROM read_parquet('{data_root}/*/occurrence_dnaderiveddata.parquet') d
            INNER JOIN _occurrence_keys k
              ON d.dataset_id = k.dataset_id
             AND d.interpreted.occurrenceID = k.occurrence_id
        """,
        "optional": True,
    },
    "event_dnaderiveddata": {
        "filename": "event_dnaderiveddata",
        "select": """
            SELECT d.dataset_id, d.interpreted
            FROM read_parquet('{data_root}/*/event_dnaderiveddata.parquet') d
            INNER JOIN _event_keys k
              ON d.dataset_id = k.dataset_id
             AND d.interpreted.eventID = k.event_id
        """,
        "optional": True,
    },
}


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
        [args.family, args.genus, args.aphiaid is not None, args.scientific_name, args.taxonomic_class, args.phylum]
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
) -> dict[str, int]:
    """Materialize filtered occurrences and join keys as temp tables."""
    con.execute(
        f"""
        CREATE OR REPLACE TEMP TABLE _filtered_occurrences AS
        SELECT o.*
        FROM read_parquet('{data_root}/*/occurrence.parquet') o
        WHERE coalesce(o.dropped, false) = false
          {occurrence_filter}
        """,
        params,
    )

    con.execute(
        f"""
        CREATE OR REPLACE TEMP TABLE _occurrence_keys AS
        SELECT DISTINCT dataset_id, interpreted.occurrenceID AS occurrence_id
        FROM _filtered_occurrences
        """
    )

    con.execute(
        f"""
        CREATE OR REPLACE TEMP TABLE _event_keys AS
        WITH RECURSIVE relevant_event_ids AS (
          SELECT DISTINCT
            o.dataset_id,
            o.interpreted.eventID AS event_id,
            0 AS depth
          FROM _filtered_occurrences o
          WHERE o.interpreted.eventID IS NOT NULL

          UNION ALL

          SELECT
            e.dataset_id,
            e.interpreted.parentEventID,
            r.depth + 1
          FROM read_parquet('{data_root}/*/event.parquet') e
          INNER JOIN relevant_event_ids r
            ON e.dataset_id = r.dataset_id
           AND e.interpreted.eventID = r.event_id
          WHERE e.interpreted.parentEventID IS NOT NULL
            AND r.depth < {max_event_depth}
        )
        SELECT DISTINCT dataset_id, event_id FROM relevant_event_ids
        """
    )

    counts = {
        "occurrences": con.execute("SELECT count(*) FROM _filtered_occurrences").fetchone()[0],
        "events": con.execute("SELECT count(*) FROM _event_keys").fetchone()[0],
        "occurrence_measurementorfact": con.execute(
            f"""
            SELECT count(*)
            FROM read_parquet('{data_root}/*/occurrence_measurementorfact.parquet') m
            INNER JOIN _occurrence_keys k
              ON m.dataset_id = k.dataset_id
             AND m.interpreted.occurrenceID = k.occurrence_id
            """
        ).fetchone()[0],
        "event_measurementorfact": con.execute(
            f"""
            SELECT count(*)
            FROM read_parquet('{data_root}/*/event_measurementorfact.parquet') m
            INNER JOIN _event_keys k
              ON m.dataset_id = k.dataset_id
             AND m.interpreted.eventID = k.event_id
            """
        ).fetchone()[0],
        "occurrence_dnaderiveddata": con.execute(
            f"""
            SELECT count(*)
            FROM read_parquet('{data_root}/*/occurrence_dnaderiveddata.parquet') d
            INNER JOIN _occurrence_keys k
              ON d.dataset_id = k.dataset_id
             AND d.interpreted.occurrenceID = k.occurrence_id
            """
        ).fetchone()[0],
        "event_dnaderiveddata": con.execute(
            f"""
            SELECT count(*)
            FROM read_parquet('{data_root}/*/event_dnaderiveddata.parquet') d
            INNER JOIN _event_keys k
              ON d.dataset_id = k.dataset_id
             AND d.interpreted.eventID = k.event_id
            """
        ).fetchone()[0],
    }
    return counts


def export_query(
    con: duckdb.DuckDBPyConnection,
    query: str,
    output_path: Path,
    fmt: str,
) -> int:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    row_count = con.execute(f"SELECT count(*) FROM ({query})").fetchone()[0]

    if row_count == 0:
        return 0

    if fmt == "jsonl":
        copy_sql = f"COPY ({query}) TO '{output_path}' (FORMAT NDJSON)"
    elif fmt == "tsv":
        copy_sql = f"""
            COPY (
              SELECT dataset_id, to_json(interpreted) AS interpreted
              FROM ({query}) exported
            ) TO '{output_path}' (FORMAT CSV, HEADER true, DELIMITER '\t')
        """
    else:
        raise ValueError(f"Unsupported format: {fmt}")

    con.execute(copy_sql)
    return row_count


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
        help="Maximum number of parentEventID hops to follow (default: 20)",
    )
    parser.add_argument(
        "--skip-empty",
        action="store_true",
        help="Do not write files for optional tables with zero matching rows",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    data_root = str(args.data_root.resolve())

    if not args.data_root.is_dir():
        print(f"Data root not found: {args.data_root}", file=sys.stderr)
        return 1

    occurrence_filter, params = build_occurrence_filter(args)
    con = duckdb.connect()

    counts = prepare_subset_tables(con, data_root, occurrence_filter, params, args.max_event_depth)

    print("Matching records:")
    for label, count in counts.items():
        print(f"  {label}: {count:,}")

    extension = "jsonl" if args.format == "jsonl" else "tsv"
    for table_name, spec in TABLE_EXPORTS.items():
        query = spec["select"].format(data_root=data_root)
        output_path = args.output / f"{spec['filename']}.{extension}"
        optional = bool(spec.get("optional", False))

        try:
            row_count = export_query(con, query, output_path, args.format)
        except duckdb.Error as exc:
            if optional:
                print(f"  skipped {table_name}: {exc}")
                continue
            raise

        if row_count == 0 and optional and args.skip_empty:
            print(f"  skipped {table_name}: no rows")
            continue

        print(f"  wrote {output_path} ({row_count:,} rows)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
