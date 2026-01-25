#!/usr/bin/env python3

import subprocess
import os
import sys
import shutil
from pathlib import Path

TPCH_DIR = Path(__file__).parent / "TPC-H V3.0.1" / "dbgen"
OUTPUT_DIR = Path(__file__).parent / "generated_queries"
QGEN_BIN = TPCH_DIR / "qgen"

def compile_qgen():
    subprocess.run(
        ["make", "-f", "makefile.suite"],
        cwd=TPCH_DIR,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True
    )

def generate_queries(total_queries):
    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)
    OUTPUT_DIR.mkdir()

    variants_per_template = (total_queries + 21) // 22

    query_count = 0
    for template_num in range(1, 23):
        for variant in range(variants_per_template):
            if query_count >= total_queries:
                return

            seed = variant + 1
            result = subprocess.run(
                [str(QGEN_BIN), "-r", str(seed), str(template_num)],
                cwd=TPCH_DIR,
                capture_output=True,
                text=True,
                check=True
            )

            output_file = OUTPUT_DIR / f"query_{template_num}_{variant}.sql"
            output_file.write_text(result.stdout)
            query_count += 1

def main():
    if len(sys.argv) > 1:
        try:
            total_queries = int(sys.argv[1])
            if total_queries < 1:
                print("Error: Number of queries must be at least 1")
                sys.exit(1)
        except ValueError:
            print("Error: Argument must be an integer")
            sys.exit(1)
    else:
        total_queries = 22

    if not QGEN_BIN.exists():
        compile_qgen()

    os.environ["DSS_QUERY"] = str(TPCH_DIR / "queries")
    generate_queries(total_queries)

if __name__ == "__main__":
    main()
