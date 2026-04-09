# Running Without Docker

This guide shows how to run the exact same commands from `README.md` without Docker.

## Original README Commands (Section 4)

**With Docker:**
```bash
docker compose -f compose.cpu.yaml build
docker compose -f compose.cpu.yaml run --rm kaggle bash

# Inside container:
inv create-candidates
inv create-features
inv create-datasets
inv train
```

**Without Docker:**
```bash
./setup_local.sh                    # One-time setup
source .venv/bin/activate           # Activate environment
./run_without_docker.sh             # Run all commands
```

## Setup (One-Time)

```bash
./setup_local.sh
```

This creates a virtual environment and installs all dependencies from `requirements.txt`.

## Run Pipeline

### **Option 1: Smart Run (Recommended - Skips completed steps)**

```bash
# Activate environment
source .venv/bin/activate

# Smart run - skips steps if outputs already exist
./run_without_docker_smart.sh

# Force re-run everything
./run_without_docker_smart.sh --force

# Debug mode with small dataset
./run_without_docker_smart.sh --debug
```

**Smart run checks:**
- ✅ Skips candidates if `output/preprocess/make_candidate/large/` exists
- ✅ Skips features if 78+ feature parquet files exist
- ✅ Skips datasets if `output/preprocess/dataset067/large/` exists
- ✅ Always runs training (the main goal)

**Saves 8-15 hours** if you're just re-training with different hyperparameters!

### **Option 2: Always Run Everything**

```bash
# Activate environment
source .venv/bin/activate

# Run all 4 steps from README.md (no skipping)
./run_without_docker.sh

# Or with debug mode
./run_without_docker.sh --debug
```

### **Option 3: Run Individual Steps**

```bash
# Only train (if features already exist)
inv train

# Only re-run features
inv create-features

# Only re-run specific step
inv create-datasets
```

**Important**: Always run from the project root directory (where this script is located).

## What It Does

Runs the exact 4 commands from README.md section 4:

1. `inv create-candidates`
2. `inv create-features`
3. `inv create-datasets`
4. `inv train`

## Requirements

- Python 3.11+
- 64GB+ RAM (768GB recommended for large dataset)
- 500GB+ disk space

## Output Files

After training completes, you'll find in `output/experiments/`:

**Model Files:**
- `model_dict_first_stage.pkl` - Pickled model (Python)
- `model_dict_second_stage.pkl` - Pickled model (Python)
- `model_dict_third_stage.pkl` - Pickled model (Python)
- `model_first_stage.onnx` - ONNX format model (cross-platform)
- `model_second_stage.onnx` - ONNX format model (cross-platform)
- `model_third_stage.onnx` - ONNX format model (cross-platform)
- `importance_first_stage.png` - Feature importance plot
- `predictions.txt` - Final predictions

**Both LightGBM (experiment 015) and CatBoost (experiment 016) models are exported to ONNX format automatically.**

## Files Created

- `setup_local.sh` - Setup script (replaces Docker build)
- `run_without_docker.sh` - Run script (replaces Docker run)
- `requirements.txt` - Dependencies (replaces Dockerfile)

All original code in `preprocess/`, `features/`, `experiments/` unchanged.
