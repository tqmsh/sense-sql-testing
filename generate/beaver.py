#!/usr/bin/env python3
"""
BEAVER extractor — enterprise data warehouse SQL queries.
CREDIT: https://github.com/peterbaile/beaver
        Peter Baile Chen et al.

Sources:
  dev_dw.json  — data warehouse queries (121)
  dev_nw.json  — network queries
  dev_tables.json — schema (columns, types, PKs, FKs per table)

Output layout:
  output/beaver/
    queries/   one .sql file per query
    schema/    one .sql file per database (reconstructed CREATE TABLE)
    report.md  complexity report ranked by LOC
"""

import json
import shutil
from pathlib import Path
from utils import normalize_sql, count_loc

ROOT       = Path(__file__).parent.parent
VENDOR_DIR = ROOT / "vendor" / "beaver"
OUTPUT_DIR = ROOT / "output" / "beaver"


def build_create_table(table: dict) -> str:
    name = table["table_name_original"]
    cols = []
    for col, typ in zip(table["column_names_original"], table["column_types"]):
        cols.append(f"  {col} {typ}")
    if table.get("primary_key"):
        pk_cols = ", ".join(str(k) for k in table["primary_key"])
        cols.append(f"  PRIMARY KEY ({pk_cols})")
    return f"CREATE TABLE {name} (\n" + ",\n".join(cols) + "\n);"


def collect_queries(json_path: Path, prefix: str) -> list[dict]:
    data = json.loads(json_path.read_text())
    queries = []
    for i, row in enumerate(data):
        sql = row.get("oracle_sql") or row.get("sql", "")
        if not sql or sql.strip().lower() == "null":
            continue
        sql = normalize_sql(sql)
        loc = count_loc(sql)
        queries.append({
            "name": f"{prefix}_{i:04d}_{row.get('db_id','unknown')}.sql",
            "content": sql,
            "loc": loc,
            "db_id": row.get("db_id", ""),
        })
    return queries


def collect_schemas() -> dict[str, str]:
    tables_data = json.loads((VENDOR_DIR / "dev_tables.json").read_text())
    db_tables: dict[str, list] = {}
    for table in tables_data.values():
        db_tables.setdefault(table["db_id"], []).append(table)

    schemas = {}
    for db_id, tables in db_tables.items():
        ddl_parts = [build_create_table(t) for t in tables]
        schemas[db_id] = "\n\n".join(ddl_parts)
    return schemas


def write_report(queries: list[dict], output_dir: Path):
    ranked = sorted(queries, key=lambda q: q["loc"], reverse=True)
    locs = [q["loc"] for q in queries]
    locs_sorted = sorted(locs)
    n = len(locs_sorted)

    def pct(p):
        return locs_sorted[min(int(p / 100 * n), n - 1)]

    lines = [
        "# BEAVER — Query Complexity Report",
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
        f"| Queries ≥ 100 LOC | {sum(1 for l in locs if l >= 100)} |",
        "",
        "## Queries Ranked by Complexity (LOC, descending)",
        "",
        "| Rank | File | LOC |",
        "|------|------|-----|",
    ]
    for i, q in enumerate(ranked, 1):
        lines.append(f"| {i} | {q['name']} | {q['loc']} |")

    (output_dir / "report.md").write_text("\n".join(lines) + "\n")


def main():
    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)

    queries_out = OUTPUT_DIR / "queries"
    schema_out  = OUTPUT_DIR / "schema"
    queries_out.mkdir(parents=True)
    schema_out.mkdir(parents=True)

    all_queries = []
    for fname, prefix in [("dev_dw.json", "dw"), ("dev_nw.json", "nw")]:
        queries = collect_queries(VENDOR_DIR / fname, prefix)
        for q in queries:
            (queries_out / q["name"]).write_text(q["content"] + "\n")
        print(f"[{prefix}] {len(queries)} queries extracted")
        all_queries.extend(queries)

    schemas = collect_schemas()
    for db_id, ddl in schemas.items():
        (schema_out / f"{db_id}.sql").write_text(ddl + "\n")
    print(f"[schema] {len(schemas)} databases extracted")

    write_report(all_queries, OUTPUT_DIR)

    print()
    print("=== BEAVER Extraction Complete ===")
    print(f"  queries/: {len(all_queries)} SQL files")
    print(f"  schema/:  {len(schemas)} DDL files")
    print(f"  Output:   {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
