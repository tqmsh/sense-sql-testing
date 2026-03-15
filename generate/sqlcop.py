#!/usr/bin/env python3
"""
SQLCop extractor — tSQLt-based SQL Server static analysis stored procedures.
CREDIT: https://github.com/red-gate/SQLCop
        Red Gate Software

Sources:
  vendor/sqlcop/Current/  — latest version of each check procedure

Output layout:
  output/sqlcop/
    queries/   one .sql file per procedure
    report.md  complexity report ranked by LOC
"""

import shutil
from pathlib import Path

ROOT       = Path(__file__).parent.parent
VENDOR_DIR = ROOT / "vendor" / "sqlcop" / "Current"
OUTPUT_DIR = ROOT / "output" / "sqlcop"


def collect_procedures() -> list[dict]:
    procedures = []
    for sql_file in sorted(VENDOR_DIR.glob("*.sql")):
        content = sql_file.read_text(encoding="utf-8", errors="replace").strip()
        loc = len([l for l in content.splitlines() if l.strip()])
        safe_name = sql_file.stem.replace(" ", "_").replace("/", "_")
        procedures.append({
            "name": f"{safe_name}.sql",
            "content": content,
            "loc": loc,
        })
    return procedures


def write_report(procedures: list[dict], output_dir: Path):
    ranked = sorted(procedures, key=lambda p: p["loc"], reverse=True)
    locs = [p["loc"] for p in procedures]
    locs_sorted = sorted(locs)
    n = len(locs_sorted)

    def pct(p):
        return locs_sorted[min(int(p / 100 * n), n - 1)]

    lines = [
        "# SQLCop — Procedure Complexity Report",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "|--------|-------|",
        f"| Total procedures | {n} |",
        f"| Min LOC | {min(locs)} |",
        f"| p25 LOC | {pct(25)} |",
        f"| Median LOC | {pct(50)} |",
        f"| Mean LOC | {sum(locs)/n:.1f} |",
        f"| p75 LOC | {pct(75)} |",
        f"| Max LOC | {max(locs)} |",
        "",
        "## Procedures Ranked by Complexity (LOC, descending)",
        "",
        "| Rank | File | LOC |",
        "|------|------|-----|",
    ]
    for i, p in enumerate(ranked, 1):
        lines.append(f"| {i} | {p['name']} | {p['loc']} |")

    (output_dir / "report.md").write_text("\n".join(lines) + "\n")


def main():
    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)

    queries_out = OUTPUT_DIR / "queries"
    queries_out.mkdir(parents=True)

    procedures = collect_procedures()
    for p in procedures:
        (queries_out / p["name"]).write_text(p["content"] + "\n")

    write_report(procedures, OUTPUT_DIR)

    print("=== SQLCop Extraction Complete ===")
    print(f"  queries/: {len(procedures)} procedures")
    print(f"  Output:   {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
