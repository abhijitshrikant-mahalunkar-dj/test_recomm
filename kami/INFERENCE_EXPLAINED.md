# Inference Stage Explained

## Overview: **Full Batch Inference** (Not Single User)

The inference processes **ALL test data at once** in batches, not individual users. It's designed for offline batch prediction, not real-time serving.

---

## Input Format

### **Input: Pre-computed Feature Dataset**

**File:** `output/preprocess/dataset067/large/test_dataset.parquet`

**Structure:** One row per (user, article, impression) combination
```
┌──────────────┬─────────┬────────────┬────────────┬──────────────┬─────┐
│ impression_id│ user_id │ article_id │ feature_1  │ feature_2    │ ... │
├──────────────┼─────────┼────────────┼────────────┼──────────────┼─────┤
│ 12345        │ U001    │ A001       │ 0.5        │ 1.2          │ ... │
│ 12345        │ U001    │ A002       │ 0.3        │ 0.8          │ ... │
│ 12345        │ U001    │ A003       │ 0.7        │ 1.5          │ ... │
│ 12346        │ U002    │ A001       │ 0.4        │ 0.9          │ ... │
│ ...          │ ...     │ ...        │ ...        │ ...          │ ... │
└──────────────┴─────────┴────────────┴────────────┴──────────────┴─────┘
```

**Key Points:**
- **Not user-centric:** Each row is a candidate article for an impression
- **Pre-computed features:** All 26 feature sets already merged
- **Multiple rows per impression:** Each impression has N candidate articles
- **Size:** Millions of rows (all users × all candidate articles)

---

## Inference Pipeline

### **Step 1: Load Full Test Dataset**

```python
test_df = pl.read_parquet("test_dataset.parquet")
# Loads ALL test data into memory
# Shape: (~10M rows × ~200 features) for large dataset
```

**Memory:** 80-120 GB (loads entire test set)

---

### **Step 2: Process Features**

```python
test_df = process_df(cfg, test_df)
```

**What it does:**
- Feature engineering (multiply/divide columns)
- Select only needed columns
- Drop metadata columns (impression_id, user_id, article_id, label)

**Output:** Clean feature matrix ready for model

---

### **Step 3: Batch Prediction**

```python
def predict(cfg, bst, test_df, num_iteration):
    feature_cols = [col for col in test_df.columns if col not in unuse_cols]
    batch_size = 100000  # Process 100K rows at a time
    y_pred = np.zeros(len(test_df))

    for i in tqdm(range(0, len(test_df), batch_size)):
        y_pred[i:i+batch_size] = bst.predict(
            test_df[feature_cols][i:i+batch_size],
            num_iteration=num_iteration
        )
    return y_pred
```

**Key Details:**
- **Batch size:** 100,000 rows per prediction call
- **Purpose:** Reduce memory spikes during inference
- **Not real-time:** Processes full dataset sequentially
- **Output:** Raw prediction scores (float) for each row

**Example:**
```
Input:  10,000,000 rows × 180 features
Output: 10,000,000 prediction scores
Time:   ~15-30 minutes
```

---

### **Step 4: Post-Processing (Ranking)**

```python
def make_result_df(df, pred):
    return (
        df.select(["impression_id", "user_id", "article_id"])
        .with_columns(pl.Series(name="pred", values=pred))
        .with_columns(
            pl.col("pred")
            .rank(method="ordinal", descending=True)
            .over(["impression_id", "user_id"])  # Rank within each impression
            .alias("rank")
        )
        .group_by(["impression_id", "user_id"], maintain_order=True)
        .agg(pl.col("rank"), pl.col("pred"))
        .select(["impression_id", "rank", "pred"])
    )
```

**What it does:**
1. **Adds predictions** to original DataFrame
2. **Ranks articles** within each impression (descending by score)
3. **Groups by impression** to create ranked lists
4. **Returns:** One row per impression with ranked article lists

**Example:**
```
Before ranking (3 articles for impression 12345):
┌──────────────┬─────────┬────────────┬──────┐
│ impression_id│ user_id │ article_id │ pred │
├──────────────┼─────────┼────────────┼──────┤
│ 12345        │ U001    │ A001       │ 0.7  │
│ 12345        │ U001    │ A002       │ 0.3  │
│ 12345        │ U001    │ A003       │ 0.5  │
└──────────────┴─────────┴────────────┴──────┘

After ranking (grouped by impression):
┌──────────────┬──────────┬──────────┐
│ impression_id│ rank     │ pred     │
├──────────────┼──────────┼──────────┤
│ 12345        │ [1,3,2]  │ [0.7,0.5,0.3] │
└──────────────┴──────────┴──────────┘
```

---

### **Step 5: Save Results**

```python
# Save as parquet
test_result_df.write_parquet("test_result_first.parquet")

# Save as submission format
write_submission_file(
    impression_ids=test_result_df["impression_id"].to_list(),
    prediction_scores=test_result_df["rank"].to_list(),
    path="predictions.txt",
    filename_zip="predictions_large.zip"
)
```

**Outputs:**
1. `test_result_first.parquet` - Full results with scores
2. `predictions.txt` - Submission format (impression_id + ranked list)
3. `predictions_large.zip` - Compressed submission

---

## Output Format

### **Submission File Example:**

```txt
12345 [1,3,2,4,5]
12346 [2,1,3]
12347 [1,4,2,3]
...
```

**Format:** `impression_id [ranked_article_positions]`

Where positions refer to the order in the original candidate list.

---

## Inference Characteristics

| Aspect | Details |
|--------|---------|
| **Type** | Offline batch inference |
| **Granularity** | Full dataset at once |
| **Input** | Pre-computed feature parquet file |
| **Batch Size** | 100,000 rows per prediction call |
| **Memory** | 150-250 GB peak |
| **Time** | 15-30 minutes for large dataset |
| **Parallelization** | Sequential batches (not parallel) |
| **Output** | Ranked article lists per impression |

---

## Single User Inference (How to Adapt)

**Current code does NOT support single-user inference.** To adapt:

### **What you'd need to change:**

1. **Feature Computation:**
   ```python
   # Instead of loading pre-computed features:
   user_features = compute_user_features(user_id)
   candidate_features = compute_candidate_features(article_ids)
   features = merge_features(user_features, candidate_features)
   ```

2. **Model Loading:**
   ```python
   # Load model once (not per request)
   bst = pickle.load(open("model_dict_first_stage.pkl", "rb"))["model"]
   ```

3. **Single Prediction:**
   ```python
   # For one user with N candidate articles
   scores = bst.predict(features)  # N scores
   ranked_articles = np.argsort(scores)[::-1]  # Rank descending
   ```

4. **Serving Infrastructure:**
   - API endpoint (FastAPI/Flask)
   - Feature store for real-time feature computation
   - Model serving (e.g., TorchServe, SageMaker endpoint)
   - ONNX model for faster inference

**Why current code is batch-only:**
- Features pre-computed offline (takes 8-15 hours!)
- Loads entire dataset into memory
- No API/serving layer
- Designed for Kaggle competition submission

---

## Summary

✅ **Full Batch Inference** - Processes all test data at once
✅ **Input:** Single parquet file with all user-article pairs
✅ **Processing:** Batches of 100K rows for memory efficiency
✅ **Output:** Ranked article lists for all impressions
❌ **NOT** single-user real-time inference
❌ **NOT** suitable for production API serving

**Use Case:** Offline evaluation, competition submissions, batch recommendations
**Not Suitable For:** Real-time user requests, online serving
