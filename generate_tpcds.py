#!/usr/bin/env python3

import subprocess
import os
import shutil
import argparse
from pathlib import Path

TPCDS_DIR = Path(__file__).parent / "vendor" / "TPC-DS" / "tools"
OUTPUT_DIR = Path(__file__).parent / "OUTPUT" / "TPC-DS"
DSDGEN_BIN = TPCDS_DIR / "dsdgen"
DSQGEN_BIN = TPCDS_DIR / "dsqgen"
QUERY_TEMPLATES_DIR = Path(__file__).parent / "vendor" / "TPC-DS" / "query_templates"
TEMPLATES_LIST = QUERY_TEMPLATES_DIR / "templates.lst"

def compile_tools():
    """Compile dsdgen and dsqgen if not exists"""
    if not DSDGEN_BIN.exists() or not DSQGEN_BIN.exists():
        print("Compiling TPC-DS tools...")
        subprocess.run(
            ["make", "OS=MACOS"],
            cwd=TPCDS_DIR,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True
        )
        print("Compilation complete")

def generate_queries(query_dir, scale_factor):
    """Generate 99+ TPC-DS queries from templates"""
    print(f"Generating TPC-DS queries...")

    template_names = TEMPLATES_LIST.read_text().strip().split('\n')

    for template_name in template_names:
        result = subprocess.run(
            [
                "./dsqgen",
                "-DIRECTORY", "../query_templates",
                "-TEMPLATE", template_name,
                "-SCALE", str(int(scale_factor)),
                "-DIALECT", "netezza",
                "-FILTER", "Y"
            ],
            cwd=TPCDS_DIR,
            capture_output=True,
            text=True,
            check=True
        )

        query_sql = result.stdout.strip()

        query_name = template_name.replace('.tpl', '.sql')
        (query_dir / query_name).write_text(query_sql + '\n')

    query_files = sorted(query_dir.glob("*.sql"))
    print(f"Generated {len(query_files)} queries")

    if query_files:
        complexities = []
        for qf in query_files[:5]:
            lines = len(qf.read_text().strip().split('\n'))
            complexities.append((qf.name, lines))
        print("Sample query complexities:")
        for name, lines in complexities:
            print(f"  {name}: {lines} lines")

def copy_schema(output_base):
    """Copy TPC-DS schema (25 tables) to output"""
    print("Copying schema files...")
    schema_dir = output_base / "schema"
    schema_dir.mkdir()

    # TPC-DS has multiple schema files
    schema_files = ["tpcds.sql", "tpcds_ri.sql", "tpcds_source.sql"]
    for schema_file in schema_files:
        source_schema = TPCDS_DIR / schema_file
        if source_schema.exists():
            shutil.copy(source_schema, schema_dir / schema_file)
            print(f"  Copied {schema_file}")

def generate_data(output_base, scale_factor):
    """Generate TPC-DS data for 25 tables"""
    print(f"Generating data at scale factor {scale_factor}...")
    data_dir = output_base / "data"
    data_dir.mkdir()

    subprocess.run(
        [
            str(DSDGEN_BIN),
            "-SCALE", str(scale_factor),
            "-DIR", str(data_dir),
            "-QUIET", "Y"
        ],
        cwd=TPCDS_DIR,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True
    )

    # Count generated data files
    data_files = list(data_dir.glob("*.dat"))
    print(f"Generated {len(data_files)} data files")

    # Show total size
    total_size = sum(f.stat().st_size for f in data_files)
    print(f"Total data size: {total_size / (1024*1024):.2f} MB")

def main():
    parser = argparse.ArgumentParser(
        description='Generate TPC-DS queries, schema, and data'
    )
    parser.add_argument('--data-size', type=float, default=1,
                       help='Data size in GB (default: 1GB, minimum: 1GB)')
    args = parser.parse_args()

    scale_factor = max(1, args.data_size)

    print(f"=== TPC-DS Generator ===")
    print(f"Scale factor: {scale_factor} GB")
    print()

    # Clean output directory
    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)
    OUTPUT_DIR.mkdir(parents=True)

    # Compile tools if needed
    compile_tools()

    # Generate queries
    query_dir = OUTPUT_DIR / "queries"
    query_dir.mkdir()
    generate_queries(query_dir, scale_factor)

    # Copy schema
    copy_schema(OUTPUT_DIR)

    # Generate data
    generate_data(OUTPUT_DIR, scale_factor)

    print()
    print("=== Generation Complete ===")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"  - queries/: TPC-DS SQL queries")
    print(f"  - schema/: DDL files")
    print(f"  - data/: .dat files (pipe-delimited)")

if __name__ == "__main__":
    main()
