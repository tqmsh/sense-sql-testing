#!/usr/bin/env python3
"""
BIRD benchmark extractor — BIRD mini-dev gold SQL queries.
CREDIT: https://huggingface.co/datasets/birdsql/bird_mini_dev
        BIRD Team (birdsql)

Sources:
  birdsql/bird_mini_dev  — 500 gold SQL queries per dialect (MySQL, PostgreSQL, SQLite)

Output layout:
  output/bird/
    mysql/    one .sql per query
    pg/       one .sql per query
    sqlite/   one .sql per query
    report.md complexity report ranked by LOC

Note: Schema files are not included in the HuggingFace dataset.
"""

import shutil
from pathlib import Path

ROOT       = Path(__file__).parent.parent
OUTPUT_DIR = ROOT / "output" / "bird"

SPLITS = {
    "mysql":  "mini_dev_mysql",
    "pg":     "mini_dev_pg",
    "sqlite": "mini_dev_sqlite",
}


def collect_queries(split_name: str) -> list[dict]:
    from datasets import load_dataset
    ds = load_dataset("birdsql/bird_mini_dev", split=split_name)
    queries = []
    for row in ds:
        sql = row["SQL"].strip()
        if not sql:
            continue
        loc = len([l for l in sql.splitlines() if l.strip()])
        safe_name = f"{row['db_id']}__{row['question_id']}.sql"
        queries.append({
            "name": safe_name,
            "content": sql,
            "loc": loc,
            "difficulty": row.get("difficulty", ""),
        })
    return queries


def write_report(all_queries: list[dict], output_dir: Path):
    ranked = sorted(all_queries, key=lambda q: q["loc"], reverse=True)
    locs = [q["loc"] for q in all_queries]
    locs_sorted = sorted(locs)
    n = len(locs_sorted)

    def pct(p):
        return locs_sorted[min(int(p / 100 * n), n - 1)]

    from collections import Counter
    diffs = Counter(q.get("difficulty", "") for q in all_queries)

    lines = [
        "# BIRD Mini-Dev — Query Complexity Report",
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
        "## Difficulty Distribution",
        "",
        "| Difficulty | Count |",
        "|-----------|-------|",
    ]
    for d, c in sorted(diffs.items()):
        lines.append(f"| {d} | {c} |")

    lines += [
        "",
        "## Queries Ranked by Complexity (LOC, descending)",
        "",
        "| Rank | File | LOC | Difficulty |",
        "|------|------|-----|------------|",
    ]
    for i, q in enumerate(ranked[:100], 1):
        lines.append(f"| {i} | {q['name']} | {q['loc']} | {q.get('difficulty','')} |")
    if len(ranked) > 100:
        lines.append(f"| ... | (showing top 100 of {len(ranked)}) | ... | ... |")

    (output_dir / "report.md").write_text("\n".join(lines) + "\n")


def main():
    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)

    all_queries = []
    for dialect, split_name in SPLITS.items():
        out = OUTPUT_DIR / dialect
        out.mkdir(parents=True)
        queries = collect_queries(split_name)
        for q in queries:
            (out / q["name"]).write_text(q["content"] + "\n")
        print(f"[{dialect}] {len(queries)} queries")
        all_queries.extend(queries)

    write_report(all_queries, OUTPUT_DIR)

    print()
    print("=== BIRD Extraction Complete ===")
    print(f"  Total queries: {len(all_queries)}")
    print(f"  Output: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
