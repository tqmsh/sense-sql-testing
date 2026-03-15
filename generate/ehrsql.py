#!/usr/bin/env python3
"""
EHRSQL extractor — medical EHR SQL queries (MIMIC-III & eICU).
CREDIT: https://github.com/glee4810/EHRSQL
        Gyubok Lee et al.

Sources:
  dataset/ehrsql/mimic_iii/{train,valid,test}.json
  dataset/ehrsql/eicu/{train,valid,test}.json
  dataset/ehrsql/tables.json  — schema for both DBs

Output layout:
  output/ehrsql/
    queries/   one .sql file per query (skips unanswerable)
    schema/    mimic_iii.sql, eicu.sql
    report.md  complexity report ranked by LOC
"""

import json
import shutil
from pathlib import Path

ROOT       = Path(__file__).parent.parent
VENDOR_DIR = ROOT / "vendor" / "ehrsql" / "dataset" / "ehrsql"
OUTPUT_DIR = ROOT / "output" / "ehrsql"


def collect_queries(db: str) -> list[dict]:
    queries = []
    db_dir = VENDOR_DIR / db
    for split in ["train", "valid", "test"]:
        split_file = db_dir / f"{split}.json"
        if not split_file.exists():
            continue
        data = json.loads(split_file.read_text())
        for row in data:
            if row.get("is_impossible"):
                continue
            sql = row.get("query", "").strip()
            if not sql or sql.lower() == "null":
                continue
            loc = len([l for l in sql.splitlines() if l.strip()])
            queries.append({
                "name": f"{db}_{split}_{row['id']}.sql",
                "content": sql,
                "loc": loc,
            })
    return queries


def build_schema(db_entry: dict) -> str:
    table_names = db_entry["table_names_original"]
    col_names   = db_entry["column_names_original"]   # list of [table_idx, col_name]
    col_types   = db_entry["column_types"]
    primary_keys = set(db_entry.get("primary_keys", []))

    tables: dict[int, list[str]] = {}
    for col_idx, (tbl_idx, col_name) in enumerate(col_names):
        if tbl_idx < 0:
            continue
        col_type = col_types[col_idx] if col_idx < len(col_types) else "TEXT"
        pk_marker = " PRIMARY KEY" if col_idx in primary_keys else ""
        tables.setdefault(tbl_idx, []).append(f"  {col_name} {col_type}{pk_marker}")

    parts = []
    for tbl_idx, cols in tables.items():
        tbl_name = table_names[tbl_idx]
        parts.append(f"CREATE TABLE {tbl_name} (\n" + ",\n".join(cols) + "\n);")
    return "\n\n".join(parts)


def collect_schemas() -> dict[str, str]:
    tables_data = json.loads((VENDOR_DIR / "tables.json").read_text())
    return {entry["db_id"]: build_schema(entry) for entry in tables_data}


def write_report(queries: list[dict], output_dir: Path):
    ranked = sorted(queries, key=lambda q: q["loc"], reverse=True)
    locs = [q["loc"] for q in queries]
    locs_sorted = sorted(locs)
    n = len(locs_sorted)

    def pct(p):
        return locs_sorted[min(int(p / 100 * n), n - 1)]

    lines = [
        "# EHRSQL — Query Complexity Report",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "|--------|-------|",
        f"| Total queries | {n} |",
        f"| Min LOC | {min(locs)} |",
        f"| p25 LOC | {pct(25)} |",
        f"| Median LOC | {pct(50)} |",
        f"| Mean LOC | {sum(locs)/n:.1f} |",
        f"| p75 LOC | {pct(75)} |",
        f"| Max LOC | {max(locs)} |",
        f"| Queries ≥ 10 LOC | {sum(1 for l in locs if l >= 10)} |",
        "",
        "## Queries Ranked by Complexity (LOC, descending)",
        "",
        "| Rank | File | LOC |",
        "|------|------|-----|",
    ]
    for i, q in enumerate(ranked[:100], 1):
        lines.append(f"| {i} | {q['name']} | {q['loc']} |")
    if len(ranked) > 100:
        lines.append(f"| ... | (showing top 100 of {len(ranked)}) | ... |")

    (output_dir / "report.md").write_text("\n".join(lines) + "\n")


def main():
    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)

    queries_out = OUTPUT_DIR / "queries"
    schema_out  = OUTPUT_DIR / "schema"
    queries_out.mkdir(parents=True)
    schema_out.mkdir(parents=True)

    all_queries = []
    for db in ["mimic_iii", "eicu"]:
        queries = collect_queries(db)
        for q in queries:
            (queries_out / q["name"]).write_text(q["content"] + "\n")
        print(f"[{db}] {len(queries)} queries extracted")
        all_queries.extend(queries)

    schemas = collect_schemas()
    for db_id, ddl in schemas.items():
        (schema_out / f"{db_id}.sql").write_text(ddl + "\n")
    print(f"[schema] {len(schemas)} databases extracted")

    write_report(all_queries, OUTPUT_DIR)

    print()
    print("=== EHRSQL Extraction Complete ===")
    print(f"  queries/: {len(all_queries)} SQL files")
    print(f"  schema/:  {len(schemas)} DDL files")
    print(f"  Output:   {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
