#!/usr/bin/env bash
# Push TPC-H and TPC-DS generated outputs to Hugging Face
#
# This script uploads everything in OUTPUT/ directory to HuggingFace datasets.
# Automatically detects username from HF token.
#
# Requirements:
#   - HF_TOKEN set as environment variable or hardcoded below
#   - Python 3 with huggingface_hub installed
#
# Usage:
#   export HF_TOKEN="your_token_here"
#   bash push-to-huggingface.sh

set -e

# Configuration
HF_TOKEN="${HF_TOKEN:-hf_your_token_here}"  # Replace with your token or set env var
REPO_NAME_SUFFIX="tpc-sql-benchmarks"       # Will become: username/tpc-sql-benchmarks
OUTPUT_DIR="OUTPUT"

# Export for Python subprocesses
export HF_TOKEN
export REPO_NAME_SUFFIX
export OUTPUT_DIR

echo "========================================"
echo "Push TPC Benchmarks to Hugging Face"
echo "========================================"
echo ""

# Check if OUTPUT directory exists
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "✗ Error: $OUTPUT_DIR directory not found"
    echo "  Run generate.py and generate_tpcds.py first"
    exit 1
fi

# Check if huggingface_hub is installed
if ! python3 -c "import huggingface_hub" 2>/dev/null; then
    echo "Installing huggingface_hub..."
    pip install -q huggingface_hub
    echo "✓ Installed huggingface_hub"
fi

# Get username and create repo
echo "Step 1/3: Setting up HuggingFace repository..."
python3 - << 'SETUP_REPO'
import os
import sys
from huggingface_hub import HfApi

token = os.environ.get("HF_TOKEN")
if not token or token == "hf_your_token_here":
    print("✗ Error: HF_TOKEN not set or using placeholder")
    print("  Set it with: export HF_TOKEN='your_token_here'")
    print("  Or edit the script to hardcode your token")
    sys.exit(1)

api = HfApi(token=token)

# Get username from token
try:
    user_info = api.whoami(token=token)
    username = user_info['name']
    print(f"  ✓ Logged in as: {username}")
except Exception as e:
    print(f"✗ Error getting user info: {e}")
    sys.exit(1)

# Create repo name
repo_suffix = os.environ.get("REPO_NAME_SUFFIX", "tpc-sql-benchmarks")
repo_id = f"{username}/{repo_suffix}"

# Create or get repo
try:
    api.create_repo(
        repo_id=repo_id,
        repo_type="dataset",
        exist_ok=True,
        private=False
    )
    print(f"  ✓ Repository: {repo_id}")
except Exception as e:
    print(f"  Note: {e}")
    print(f"  ✓ Using existing repository: {repo_id}")

# Save repo_id for next step
with open("/tmp/hf_repo_id.txt", "w") as f:
    f.write(repo_id)

print("")
SETUP_REPO

if [ $? -ne 0 ]; then
    echo "✗ Setup failed"
    exit 1
fi

REPO_ID=$(cat /tmp/hf_repo_id.txt)
rm /tmp/hf_repo_id.txt

# Export for Python subprocess
export REPO_ID
export OUTPUT_DIR
export HF_TOKEN

# Upload files
echo "Step 2/3: Uploading TPC-H and TPC-DS files..."
python3 - << 'UPLOAD_FILES'
import os
from pathlib import Path
from huggingface_hub import HfApi

token = os.environ["HF_TOKEN"]
repo_id = os.environ["REPO_ID"]
output_dir = os.environ["OUTPUT_DIR"]

api = HfApi(token=token)

print(f"  Uploading from: {output_dir}/")
print(f"  Uploading to: https://huggingface.co/datasets/{repo_id}")
print("")

# Upload entire OUTPUT directory
try:
    api.upload_folder(
        folder_path=output_dir,
        repo_id=repo_id,
        repo_type="dataset",
        path_in_repo=".",  # Upload to root of repo
        ignore_patterns=["*.pyc", "__pycache__", ".DS_Store"]
    )
    print("  ✓ Upload complete!")
except Exception as e:
    print(f"  ✗ Upload failed: {e}")
    import sys
    sys.exit(1)

UPLOAD_FILES

if [ $? -ne 0 ]; then
    echo "✗ Upload failed"
    exit 1
fi

# Create README
echo ""
echo "Step 3/3: Creating README..."
python3 - << 'CREATE_README'
import os
from huggingface_hub import HfApi
from datetime import datetime

token = os.environ["HF_TOKEN"]
repo_id = os.environ["REPO_ID"]

readme_content = f"""# TPC SQL Benchmarks

Generated TPC-H and TPC-DS benchmark data for testing SQL query complexity.

## Contents

### TPC-H (Simple Queries)
- **Queries:** 22 SQL files (20-50 lines each)
- **Tables:** 8 tables
- **Schema:** `TPC-H/schema/`
- **Data:** `TPC-H/data/` (pipe-delimited .tbl files)

### TPC-DS (Complex Queries)
- **Queries:** 99 SQL files (20-217 lines each)
- **Tables:** 25 tables
- **Schema:** `TPC-DS/schema/`
- **Data:** `TPC-DS/data/` (pipe-delimited .dat files)

## Query Complexity

**TPC-H:** Baseline queries for simple SQL testing
- Single-level queries
- 2-5 table joins
- Basic aggregations

**TPC-DS:** Complex queries for LLM agent testing
- Multi-level CTEs (5-15 per query)
- Window functions (RANK, ROW_NUMBER)
- Deep joins (10-15 tables)
- Correlated subqueries

## Usage

```python
from datasets import load_dataset

# Load the dataset
dataset = load_dataset("{repo_id}")

# Access files
tpch_queries = dataset["TPC-H/queries"]
tpcds_queries = dataset["TPC-DS/queries"]
```

## Generation

Generated using:
- **TPC-H:** Official TPC-H toolkit v3.0.1
- **TPC-DS:** gregrahn/tpcds-kit (patched for macOS)
- **Scale Factor:** 1 (minimum for testing)

## Credits

- TPC-H: https://www.tpc.org/tpch/
- TPC-DS: https://www.tpc.org/tpcds/
- Toolkit: https://github.com/gregrahn/tpcds-kit

---

*Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*
"""

api = HfApi(token=token)

# Create README
readme_path = "/tmp/README.md"
with open(readme_path, "w") as f:
    f.write(readme_content)

try:
    api.upload_file(
        path_or_fileobj=readme_path,
        path_in_repo="README.md",
        repo_id=repo_id,
        repo_type="dataset",
    )
    print("  ✓ README created")
except Exception as e:
    print(f"  Note: README creation failed: {e}")

os.remove(readme_path)

CREATE_README

echo ""
echo "========================================"
echo "✓ UPLOAD COMPLETE!"
echo "========================================"
echo ""
echo "Repository: $REPO_ID"
echo "View at: https://huggingface.co/datasets/$REPO_ID"
echo ""
echo "Contents uploaded:"
echo "  • TPC-H: 22 queries + schema + data"
echo "  • TPC-DS: 99 queries + schema + data"
echo ""
