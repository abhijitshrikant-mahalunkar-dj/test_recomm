# Pipeline Optimization Guide

## Problem: Redundant Computation

The original pipeline runs all 4 steps every time:
1. Create Candidates (1-3 hours)
2. Feature Extraction (8-15 hours) ⚠️ SLOWEST
3. Create Datasets (0.5-1 hour)
4. Train (3-8 hours)

**Total: 15-30 hours**

If you're just experimenting with model hyperparameters or re-training, you're wasting 12-19 hours re-computing features that haven't changed!

---

## Solution: Smart Pipeline

Use `run_without_docker_smart.sh` which:
- ✅ Checks if each step's output already exists
- ✅ Skips completed steps automatically
- ✅ Always runs training (the goal)
- ✅ Can force re-run with `--force` flag

### Usage:

```bash
source .venv/bin/activate

# First run - does everything
./run_without_docker_smart.sh

# Second run - skips to training!
./run_without_docker_smart.sh
# Saves 12-19 hours

# Force re-run if data changed
./run_without_docker_smart.sh --force
```

---

## When to Re-run Each Step

### **1. Create Candidates**
Re-run if:
- ❌ Input data changed (new ebnerd_large download)
- ❌ Candidate generation logic changed
- ✅ Otherwise: Skip it!

### **2. Feature Extraction** (Most Expensive!)
Re-run if:
- ❌ Input data changed
- ❌ Feature engineering code changed
- ❌ Added/removed features
- ✅ Just tuning model hyperparameters: Skip it!
- ✅ Just re-training: Skip it!

**Time savings: 8-15 hours**

### **3. Create Datasets**
Re-run if:
- ❌ Features changed
- ❌ Dataset merging logic changed
- ✅ Just re-training: Skip it!

### **4. Train**
Always run - this is what you want to do!

---

## Manual Control

### Run only training:
```bash
inv train
```

### Re-run specific steps:
```bash
# Re-generate features only
inv create-features

# Re-generate datasets only
inv create-datasets
```

### Full pipeline (no skipping):
```bash
./run_without_docker.sh
```

---

## File Outputs to Check

| Step | Output Location | Check |
|------|----------------|-------|
| Candidates | `output/preprocess/make_candidate/large/` | Directory exists |
| Features | `output/features/*/` | 78 parquet files (26 features × 3 splits) |
| Datasets | `output/preprocess/dataset067/large/` | `*_dataset.parquet` files |
| Models | `output/experiments/` | `.pkl` and `.onnx` files |

---

## Best Practices

### For Hyperparameter Tuning:
1. Run full pipeline once: `./run_without_docker_smart.sh`
2. Modify `experiments/*/exp/*.yaml` configs
3. Re-train only: `inv train` (saves 12-19 hours!)

### For Feature Engineering:
1. Delete old features: `rm -rf output/features/`
2. Run with force: `./run_without_docker_smart.sh --force`

### For New Data:
1. Update input directory
2. Clean outputs: `rm -rf output/`
3. Run full pipeline: `./run_without_docker.sh`

---

## Time Comparison

| Scenario | Old Script | Smart Script | Savings |
|----------|-----------|--------------|---------|
| First run | 15-30 hours | 15-30 hours | 0 hours |
| Re-training (no data change) | 15-30 hours | 3-8 hours | **12-19 hours** ⚡ |
| Hyperparameter tuning (10 runs) | 150-300 hours | 30-80 hours | **120-220 hours** 🚀 |

---

## Technical Details

The smart script checks:
```bash
# Candidates
[ -d "output/preprocess/make_candidate/large" ]

# Features (counts parquet files)
find "output/features" -name "*_feat.parquet" | wc -l >= 78

# Datasets
[ -d "output/preprocess/dataset067/large" ]
```

If outputs exist and `--force` not used, skips that step.
