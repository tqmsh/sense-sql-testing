#!/usr/bin/env python3
"""
Spider 2.0 extractor — pulls gold SQL queries and DDL schemas from:
  - spider2-lite  (SQLite-based, 256 queries)
  - spider2-snow  (Snowflake-based, ~600 queries)

Output layout:
  output/spider2/
    queries/          all .sql files, named <source>_<original_name>
    schema/           DDL .sql files per database
    report.md         complexity report ranked by LOC
"""

import shutil
import csv
from pathlib import Path
from utils import normalize_sql, count_loc

ROOT        = Path(__file__).parent.parent
VENDOR_DIR  = ROOT / "vendor" / "spider2"
OUTPUT_DIR  = ROOT / "output" / "spider2"

SOURCES = {
    "lite": {
        "queries": VENDOR_DIR / "spider2-lite" / "evaluation_suite" / "gold" / "sql",
        "databases": VENDOR_DIR / "spider2-lite" / "resource" / "databases" / "sqlite",
    },
    "snow": {
        "queries": VENDOR_DIR / "spider2-snow" / "evaluation_suite" / "gold" / "sql",
        "databases": VENDOR_DIR / "spider2-snow" / "resource" / "databases",
    },
}


def collect_queries(query_dir: Path, prefix: str) -> list[dict]:
    queries = []
    for sql_file in sorted(query_dir.glob("*.sql")):
        content = sql_file.read_text(encoding="utf-8", errors="replace").strip()
        content = normalize_sql(content)
        loc = count_loc(content)
        queries.append({
            "name": f"{prefix}_{sql_file.name}",
            "original": sql_file.name,
            "content": content,
            "loc": loc,
        })
    return queries


def collect_schemas_sqlite(db_root: Path) -> dict[str, str]:
    """Each db dir has a DDL.csv with table_name,DDL columns."""
    schemas = {}
    for db_dir in sorted(db_root.iterdir()):
        ddl_file = db_dir / "DDL.csv"
        if not ddl_file.exists():
            continue
        parts = []
        with open(ddl_file, newline="", encoding="utf-8", errors="replace") as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row.get("DDL"):
                    parts.append(row["DDL"].strip())
        if parts:
            schemas[db_dir.name] = "\n\n".join(parts)
    return schemas


def collect_schemas_snow(db_root: Path) -> dict[str, str]:
    """Snowflake: nested <DB>/<SCHEMA>/DDL.csv structure."""
    schemas = {}
    for ddl_file in sorted(db_root.rglob("DDL.csv")):
        db_key = "__".join(ddl_file.parts[-(ddl_file.parts.index("DDL.csv")):-(1)])
        # Use path relative to db_root as the key
        rel = ddl_file.relative_to(db_root).parent
        db_key = str(rel).replace("/", "__").replace("\\", "__")
        parts = []
        with open(ddl_file, newline="", encoding="utf-8", errors="replace") as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row.get("DDL"):
                    parts.append(row["DDL"].strip())
        if parts:
            schemas[db_key] = "\n\n".join(parts)
    return schemas


def write_report(queries: list[dict], output_dir: Path):
    ranked = sorted(queries, key=lambda q: q["loc"], reverse=True)
    locs = [q["loc"] for q in queries]
    locs_sorted = sorted(locs)
    n = len(locs_sorted)

    def percentile(p):
        idx = int(p / 100 * n)
        return locs_sorted[min(idx, n - 1)]

    lines = [
        "# Spider 2.0 — Query Complexity Report",
        "",
        "## Summary",
        "",
        f"| Metric | Value |",
        f"|--------|-------|",
        f"| Total queries | {n} |",
        f"| Min LOC | {min(locs)} |",
        f"| p25 LOC | {percentile(25)} |",
        f"| Median LOC | {percentile(50)} |",
        f"| Mean LOC | {sum(locs) / n:.1f} |",
        f"| p75 LOC | {percentile(75)} |",
        f"| Max LOC | {max(locs)} |",
        f"| Queries ≥ 100 LOC | {sum(1 for l in locs if l >= 100)} |",
        "",
        "## Queries Ranked by Complexity (LOC, descending)",
        "",
        "| Rank | File | LOC |",
        "|------|------|-----|",
    ]

    for i, q in enumerate(ranked, 1):
        lines.append(f"| {i} | {q['name']} | {q['loc']} |")

    report_path = output_dir / "report.md"
    report_path.write_text("\n".join(lines) + "\n")
    print(f"Report written to {report_path}")


def main():
    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)

    queries_out = OUTPUT_DIR / "queries"
    schema_out  = OUTPUT_DIR / "schema"
    queries_out.mkdir(parents=True)
    schema_out.mkdir(parents=True)

    all_queries = []

    # --- Queries ---
    for source, paths in SOURCES.items():
        q_dir = paths["queries"]
        queries = collect_queries(q_dir, source)
        for q in queries:
            (queries_out / q["name"]).write_text(q["content"] + "\n")
        print(f"[{source}] {len(queries)} queries extracted")
        all_queries.extend(queries)

    # --- Schemas ---
    lite_schemas = collect_schemas_sqlite(SOURCES["lite"]["databases"])
    for db_name, ddl in lite_schemas.items():
        (schema_out / f"lite_{db_name}.sql").write_text(ddl + "\n")
    print(f"[lite] {len(lite_schemas)} schemas extracted")

    snow_schemas = collect_schemas_snow(SOURCES["snow"]["databases"])
    for db_key, ddl in snow_schemas.items():
        safe_name = db_key.replace("/", "__").replace("\\", "__")
        (schema_out / f"snow_{safe_name}.sql").write_text(ddl + "\n")
    print(f"[snow] {len(snow_schemas)} schemas extracted")

    # --- Report ---
    write_report(all_queries, OUTPUT_DIR)

    print()
    print("=== Spider 2.0 Extraction Complete ===")
    print(f"  queries/: {len(all_queries)} SQL files")
    print(f"  schema/:  {len(lite_schemas) + len(snow_schemas)} DDL files")
    print(f"  Output:   {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
