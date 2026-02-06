# TPC SQL Generator

Generate SQL test queries and data for benchmarking LLMs with TPC-H and TPC-DS benchmarks.

## Quick Start

### TPC-H (Simple Queries) ✅
22 queries, 8 tables, 20-50 lines per query

```bash
python3 generate.py --data-size 10
```

Output: `OUTPUT/TPC-H/` (queries + schema + data)

### TPC-DS (Complex Queries) ✅
99 queries, 25 tables, up to 217 lines per query
Features: CTEs, window functions, deep joins

```bash
python3 generate_tpcds.py --data-size 10
```

Output: `OUTPUT/TPC-DS/` (queries + schema + data)

## What Gets Generated

```
OUTPUT/
├── TPC-H/               ✅ Fully working
│   ├── queries/         22 SQL files (20-50 lines each)
│   ├── schema/          dss.ddl + dss.ri
│   └── data/            8 .tbl files
└── TPC-DS/              ✅ Fully working
    ├── queries/         99 SQL files (20-217 lines each)
    ├── schema/          tpcds.sql + tpcds_ri.sql + tpcds_source.sql
    └── data/            25 .dat files (11+ GB at scale 10)
```

## Directory Structure

```
/
├── vendor/                     # Benchmark toolkits (not in git)
│   ├── TPC-H/                  TPC-H v3.0.1 toolkit
│   │   └── dbgen/              qgen + dbgen binaries
│   └── TPC-DS/                 TPC-DS v2.13 toolkit
│       └── tools/              dsdgen + dsqgen binaries
├── OUTPUT/                     # Generated outputs (not in git)
│   ├── TPC-H/                  TPC-H queries, schema, data
│   └── TPC-DS/                 TPC-DS schema and data
├── generate.py                 TPC-H generator ✅
├── generate_tpcds.py           TPC-DS generator ⚠️
└── *.md                        Documentation files
```

## Loading Data into DuckDB

### TPC-H (8 tables)
```bash
duckdb tpch.db <<EOF
.read OUTPUT/TPC-H/schema/dss.ddl

COPY nation FROM 'OUTPUT/TPC-H/data/nation.tbl' (DELIMITER '|');
COPY region FROM 'OUTPUT/TPC-H/data/region.tbl' (DELIMITER '|');
COPY customer FROM 'OUTPUT/TPC-H/data/customer.tbl' (DELIMITER '|');
COPY supplier FROM 'OUTPUT/TPC-H/data/supplier.tbl' (DELIMITER '|');
COPY part FROM 'OUTPUT/TPC-H/data/part.tbl' (DELIMITER '|');
COPY partsupp FROM 'OUTPUT/TPC-H/data/partsupp.tbl' (DELIMITER '|');
COPY orders FROM 'OUTPUT/TPC-H/data/orders.tbl' (DELIMITER '|');
COPY lineitem FROM 'OUTPUT/TPC-H/data/lineitem.tbl' (DELIMITER '|');

.read OUTPUT/TPC-H/schema/dss.ri
EOF
```

### TPC-DS (25 tables)
```bash
duckdb tpcds.db <<EOF
.read OUTPUT/TPC-DS/schema/tpcds.sql

-- See SETUP-GUIDE.md for full list of 25 COPY commands
COPY call_center FROM 'OUTPUT/TPC-DS/data/call_center.dat' (DELIMITER '|');
COPY catalog_page FROM 'OUTPUT/TPC-DS/data/catalog_page.dat' (DELIMITER '|');
-- ... (23 more tables)
EOF
```

## Data Size Guidelines

| --data-size | Actual Size | Use Case |
|-------------|-------------|----------|
| 1           | 1MB         | Fast testing (TPC-H only) |
| 10          | 10MB        | Development (default) |
| 100         | 100MB       | Integration testing |
| 1000        | 1GB         | Performance testing |

**Note:** TPC-DS minimum scale is 10 (generates ~11GB data).

## Current Status

### ✅ Working
- TPC-H: Full generation (queries + schema + data)
- TPC-DS: Full generation (queries + schema + data)
- Compilation on macOS
- Directory structure and organization

### 📋 Next Steps
1. Test complex queries with LLM agents
2. Compare TPC-H vs TPC-DS agent performance
3. Document test results

## Credits

- **TPC-H:** https://www.tpc.org/tpch/
- **TPC-DS:** https://www.tpc.org/tpcds/
- **TPC-DS macOS port:** https://github.com/gregrahn/tpcds-kit

## Getting Help

- **TPC-H issues:** Check `TPC-H-OVERVIEW.md`
- **TPC-DS overview:** Check `TPC-DS-OVERVIEW.md`
- **Setup problems:** Check `SETUP-GUIDE.md`
