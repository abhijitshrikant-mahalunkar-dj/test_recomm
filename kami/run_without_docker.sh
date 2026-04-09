#!/bin/bash
# RecSys Challenge 2024 - Run Without Docker
# Executes the exact commands from README.md section 4

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the script directory (project root)
cd "$SCRIPT_DIR"

echo "============================================================"
echo "RecSys Challenge 2024 - Training and Inference"
echo "Running WITHOUT Docker"
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

# Parse debug flag
DEBUG_FLAG=""
if [ "$1" == "--debug" ]; then
    DEBUG_FLAG="--debug"
    echo "Running in DEBUG mode"
    echo ""
fi

# 1. Create Candidates
echo "============================================================"
echo "1. Create Candidates"
echo "============================================================"
inv create-candidates $DEBUG_FLAG
echo ""

# 2. Feature Extraction
echo "============================================================"
echo "2. Feature Extraction"
echo "============================================================"
inv create-features $DEBUG_FLAG
echo ""

# 3. Create Datasets
echo "============================================================"
echo "3. Create Datasets"
echo "============================================================"
inv create-datasets $DEBUG_FLAG
echo ""

# 4. Train & Inference
echo "============================================================"
echo "4. Train & Inference"
echo "============================================================"
inv train $DEBUG_FLAG
echo ""

echo "============================================================"
echo "✓ COMPLETE!"
echo "============================================================"
echo "Results are in the output/ directory"
