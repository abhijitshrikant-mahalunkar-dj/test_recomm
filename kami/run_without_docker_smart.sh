#!/bin/bash
# RecSys Challenge 2024 - Smart Run (Skips completed steps)
# Only runs steps if their outputs don't exist

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the script directory (project root)
cd "$SCRIPT_DIR"

echo "============================================================"
echo "RecSys Challenge 2024 - Smart Training Pipeline"
echo "Running WITHOUT Docker (skips completed steps)"
echo "============================================================"
echo "Working directory: $SCRIPT_DIR"
echo ""

# Check if virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
    echo "⚠️  Virtual environment not activated!"
    echo "Please run: source .venv/bin/activate"
    exit 1
fi

# Ensure PYTHONPATH includes current directory
export PYTHONPATH="$SCRIPT_DIR:$PYTHONPATH"

# Parse flags
DEBUG_FLAG=""
FORCE=false
SIZE="large"

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG_FLAG="--debug"
            SIZE="small"
            echo "Running in DEBUG mode (small dataset)"
            shift
            ;;
        --force)
            FORCE=true
            echo "FORCE mode: Will re-run all steps"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--debug] [--force]"
            exit 1
            ;;
    esac
done
echo ""

# 1. Create Candidates
CANDIDATE_OUTPUT="output/preprocess/make_candidate/$SIZE"
if [ -d "$CANDIDATE_OUTPUT" ] && [ "$FORCE" = false ]; then
    echo "============================================================"
    echo "1. Create Candidates - SKIPPED (already exists)"
    echo "============================================================"
    echo "Output found at: $CANDIDATE_OUTPUT"
    echo "Use --force to re-run"
else
    echo "============================================================"
    echo "1. Create Candidates"
    echo "============================================================"
    inv create-candidates $DEBUG_FLAG
fi
echo ""

# 2. Feature Extraction
FEATURES_OUTPUT="output/features"
FEATURE_COUNT=$(find "$FEATURES_OUTPUT" -name "*_feat.parquet" 2>/dev/null | wc -l || echo 0)
EXPECTED_FEATURES=78  # 26 features × 3 datasets (train/val/test)

if [ "$FEATURE_COUNT" -ge "$EXPECTED_FEATURES" ] && [ "$FORCE" = false ]; then
    echo "============================================================"
    echo "2. Feature Extraction - SKIPPED (already exists)"
    echo "============================================================"
    echo "Found $FEATURE_COUNT feature files (expected $EXPECTED_FEATURES)"
    echo "Use --force to re-run"
else
    echo "============================================================"
    echo "2. Feature Extraction"
    echo "============================================================"
    echo "Found $FEATURE_COUNT feature files (expected $EXPECTED_FEATURES)"
    inv create-features $DEBUG_FLAG
fi
echo ""

# 3. Create Datasets
DATASET_OUTPUT="output/preprocess/dataset067/$SIZE"
if [ -d "$DATASET_OUTPUT" ] && [ "$FORCE" = false ]; then
    DATASET_FILES=$(find "$DATASET_OUTPUT" -name "*_dataset.parquet" 2>/dev/null | wc -l || echo 0)
    if [ "$DATASET_FILES" -ge 2 ]; then
        echo "============================================================"
        echo "3. Create Datasets - SKIPPED (already exists)"
        echo "============================================================"
        echo "Output found at: $DATASET_OUTPUT"
        echo "Use --force to re-run"
    else
        echo "============================================================"
        echo "3. Create Datasets"
        echo "============================================================"
        inv create-datasets $DEBUG_FLAG
    fi
else
    echo "============================================================"
    echo "3. Create Datasets"
    echo "============================================================"
    inv create-datasets $DEBUG_FLAG
fi
echo ""

# 4. Train & Inference (always run - this is what we want to do)
echo "============================================================"
echo "4. Train & Inference"
echo "============================================================"
inv train $DEBUG_FLAG
echo ""

echo "============================================================"
echo "✓ COMPLETE!"
echo "============================================================"
echo "Results are in the output/ directory"
echo ""
echo "Output locations:"
echo "  - Candidates: $CANDIDATE_OUTPUT"
echo "  - Features: $FEATURES_OUTPUT"
echo "  - Datasets: $DATASET_OUTPUT"
echo "  - Models: output/experiments/"
