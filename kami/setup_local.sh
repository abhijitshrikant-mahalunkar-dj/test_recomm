#!/bin/bash
# Setup script for running RecSys Challenge 2024 locally without Docker
# This replaces the Docker setup with a Python virtual environment

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the script directory (project root)
cd "$SCRIPT_DIR"

echo "============================================================"
echo "RecSys Challenge 2024 - Local Setup (No Docker)"
echo "============================================================"
echo "Working directory: $SCRIPT_DIR"

# Check Python version
echo ""
echo "Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo "Found Python $PYTHON_VERSION"

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo ""
    echo "Creating virtual environment..."
    python3 -m venv .venv
    echo "✓ Virtual environment created"
else
    echo ""
    echo "✓ Virtual environment already exists"
fi

# Activate virtual environment
echo ""
echo "Activating virtual environment..."
source .venv/bin/activate

# Upgrade pip
echo ""
echo "Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo ""
echo "Installing dependencies from requirements.txt..."
pip install -r requirements.txt

echo ""
echo "============================================================"
echo "✓ Setup Complete!"
echo "============================================================"
echo ""
echo "To use this environment:"
echo "  1. Activate: source .venv/bin/activate"
echo "  2. Run pipeline: python run_full_pipeline.py --mode=candidates --size=large"
echo "  3. Deactivate: deactivate"
echo ""
echo "Available commands:"
echo "  - python run_full_pipeline.py --mode=full --size=large"
echo "  - python run_full_pipeline.py --mode=candidates --size=large"
echo "  - python run_full_pipeline.py --mode=features --size=large"
echo "  - inv create-candidates  (if invoke is installed)"
echo ""
echo "For SageMaker deployment:"
echo "  python deploy_sagemaker.py --mode full --s3-bucket YOUR_BUCKET"
echo ""
