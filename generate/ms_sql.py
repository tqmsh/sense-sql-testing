#!/usr/bin/env python3
"""
Microsoft AdventureWorks & WideWorldImporters extractor.
CREDIT: https://github.com/microsoft/sql-server-samples
        Microsoft Corporation

Sources:
  AdventureWorks: single monolithic install script — split by GO batches
  WideWorldImporters: individual .sql files per object (SSDT layout)

Extracts: Stored Procedures, Functions, Triggers, Views, Tables (DDL only)
No data generation.

Output layout:
  output/ms_sql/
    adventureworks/
      queries/   one .sql per object (split from monolithic script)
      schema/    tables DDL
    wideworldimporters/
      queries/   one .sql per stored proc / function / trigger
      schema/    one .sql per table
    report.md    complexity report ranked by LOC
"""

import re
import shutil
from pathlib import Path

ROOT       = Path(__file__).parent.parent
AW_SCRIPT  = ROOT / "vendor" / "ms_sql_samples" / "samples" / "databases" / "adventure-works" / "oltp-install-script" / "instawdb.sql"
WWI_DIR    = ROOT / "vendor" / "ms_sql_samples" / "samples" / "databases" / "wide-world-importers" / "wwi-ssdt" / "wwi-ssdt"
OUTPUT_DIR = ROOT / "output" / "ms_sql"

OBJECT_PATTERN = re.compile(
    r"CREATE\s+(PROCEDURE|FUNCTION|TRIGGER|VIEW|TABLE)\s+",
    re.IGNORECASE
)

QUERY_DIRS = {"Stored Procedures", "Functions", "Triggers", "Views"}
SCHEMA_DIRS = {"Tables"}


def split_adventureworks() -> tuple[list[dict], list[dict]]:
    """Split the monolithic AdventureWorks script into per-object batches."""
    text = AW_SCRIPT.read_text(encoding="utf-8", errors="replace")
    batches = re.split(r"^\s*GO\s*$", text, flags=re.MULTILINE)

    queries, schemas = [], []
    for batch in batches:
        batch = batch.strip()
        if not batch:
            continue
        m = OBJECT_PATTERN.search(batch)
        if not m:
            continue
        obj_type = m.group(1).upper()
        # Extract object name
        name_match = re.search(
            r"CREATE\s+(?:PROCEDURE|FUNCTION|TRIGGER|VIEW|TABLE)\s+[\[\w\.]+[\]\w]*\.[\[\w]+\]?|"
            r"CREATE\s+(?:PROCEDURE|FUNCTION|TRIGGER|VIEW|TABLE)\s+[\[\w]+\]?",
            batch, re.IGNORECASE
        )
        raw_name = name_match.group(0).split()[-1] if name_match else f"object_{len(queries)}"
        safe_name = re.sub(r"[\[\]\s/\\]", "_", raw_name).strip("_") + ".sql"
        loc = len([l for l in batch.splitlines() if l.strip()])
        entry = {"name": safe_name, "content": batch, "loc": loc}
        if obj_type == "TABLE":
            schemas.append(entry)
        else:
            queries.append(entry)

    return queries, schemas


def collect_wwi() -> tuple[list[dict], list[dict]]:
    """Collect WideWorldImporters objects from SSDT folder structure."""
    queries, schemas = [], []

    for sql_file in sorted(WWI_DIR.rglob("*.sql")):
        parent = sql_file.parent.name
        if parent not in QUERY_DIRS and parent not in SCHEMA_DIRS:
            continue
        content = sql_file.read_text(encoding="utf-8", errors="replace").strip()
        if not content:
            continue
        loc = len([l for l in content.splitlines() if l.strip()])
        # Build a namespaced filename: Schema_ObjectName.sql
        schema_folder = sql_file.parent.parent.name
        safe_name = f"{schema_folder}__{sql_file.stem.replace(' ', '_')}.sql"
        entry = {"name": safe_name, "content": content, "loc": loc}
        if parent in SCHEMA_DIRS:
            schemas.append(entry)
        else:
            queries.append(entry)

    return queries, schemas


def write_report(all_queries: list[dict], output_dir: Path, title: str = "Microsoft SQL Samples"):
    ranked = sorted(all_queries, key=lambda q: q["loc"], reverse=True)
    locs = [q["loc"] for q in all_queries]
    locs_sorted = sorted(locs)
    n = len(locs_sorted)

    def pct(p):
        return locs_sorted[min(int(p / 100 * n), n - 1)]

    lines = [
        f"# {title} — Complexity Report",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "|--------|-------|",
        f"| Total objects | {n} |",
        f"| Min LOC | {min(locs)} |",
        f"| p25 LOC | {pct(25)} |",
        f"| Median LOC | {pct(50)} |",
        f"| Mean LOC | {sum(locs)/n:.1f} |",
        f"| p75 LOC | {pct(75)} |",
        f"| Max LOC | {max(locs)} |",
        f"| Objects ≥ 100 LOC | {sum(1 for l in locs if l >= 100)} |",
        "",
        "## Objects Ranked by Complexity (LOC, descending)",
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

    aw_q_out  = OUTPUT_DIR / "adventureworks" / "queries"
    aw_s_out  = OUTPUT_DIR / "adventureworks" / "schema"
    wwi_q_out = OUTPUT_DIR / "wideworldimporters" / "queries"
    wwi_s_out = OUTPUT_DIR / "wideworldimporters" / "schema"

    for d in [aw_q_out, aw_s_out, wwi_q_out, wwi_s_out]:
        d.mkdir(parents=True)

    aw_queries, aw_schemas = split_adventureworks()
    for q in aw_queries:
        (aw_q_out / q["name"]).write_text(q["content"] + "\n")
    for s in aw_schemas:
        (aw_s_out / s["name"]).write_text(s["content"] + "\n")
    print(f"[adventureworks] {len(aw_queries)} objects, {len(aw_schemas)} tables")

    wwi_queries, wwi_schemas = collect_wwi()
    for q in wwi_queries:
        (wwi_q_out / q["name"]).write_text(q["content"] + "\n")
    for s in wwi_schemas:
        (wwi_s_out / s["name"]).write_text(s["content"] + "\n")
    print(f"[wideworldimporters] {len(wwi_queries)} objects, {len(wwi_schemas)} tables")

    write_report(aw_queries, OUTPUT_DIR / "adventureworks", "AdventureWorks")
    write_report(wwi_queries, OUTPUT_DIR / "wideworldimporters", "WideWorldImporters")

    all_queries = aw_queries + wwi_queries
    print()
    print("=== MS SQL Extraction Complete ===")
    print(f"  Total objects: {len(all_queries)}")
    print(f"  Output: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
