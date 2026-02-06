#!/usr/bin/env python3

import subprocess
import os
import shutil
import argparse
from pathlib import Path

TPCH_DIR = Path(__file__).parent / "vendor" / "TPC-H" / "dbgen"
OUTPUT_DIR = Path(__file__).parent / "OUTPUT" / "TPC-H"
QGEN_BIN = TPCH_DIR / "qgen"
DBGEN_BIN = TPCH_DIR / "dbgen"

def compile_tools():
    if not QGEN_BIN.exists() or not DBGEN_BIN.exists():
        subprocess.run(
            ["make", "-f", "makefile.suite"],
            cwd=TPCH_DIR,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True
        )

def generate_queries(query_dir):
    for template_num in range(1, 23):
        result = subprocess.run(
            [str(QGEN_BIN), "-d", str(template_num)],
            cwd=TPCH_DIR,
            capture_output=True,
            text=True,
            check=True
        )

        output_file = query_dir / f"query_{template_num}.sql"
        output_file.write_text(result.stdout)

def copy_schema(output_base):
    schema_dir = output_base / "schema"
    schema_dir.mkdir()

    shutil.copy(TPCH_DIR / "dss.ddl", schema_dir / "dss.ddl")

    if (TPCH_DIR / "dss.ri").exists():
        shutil.copy(TPCH_DIR / "dss.ri", schema_dir / "dss.ri")

def generate_data(output_base, scale_factor):
    data_dir = output_base / "data"
    data_dir.mkdir()

    env = os.environ.copy()
    env["DSS_PATH"] = str(data_dir)

    subprocess.run(
        [str(DBGEN_BIN), "-s", str(scale_factor), "-f"],
        cwd=TPCH_DIR,
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True
    )

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data-size', type=float, default=10,
                       help='Data size in MB (default: 10MB)')
    args = parser.parse_args()

    scale_factor = args.data_size / 1000

    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)
    OUTPUT_DIR.mkdir()

    compile_tools()
    os.environ["DSS_QUERY"] = str(TPCH_DIR / "queries")

    query_dir = OUTPUT_DIR / "queries"
    query_dir.mkdir()
    generate_queries(query_dir)

    copy_schema(OUTPUT_DIR)
    generate_data(OUTPUT_DIR, scale_factor)

if __name__ == "__main__":
    main()
