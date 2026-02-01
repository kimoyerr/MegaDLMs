# Protein Data Preprocessing Guide

This guide explains how to prepare your protein CSV data for training with the DLM.

## Overview

The training pipeline requires **pre-tokenized binary data** (`.bin` and `.idx` files). Your CSV data goes through this pipeline:

```
CSV → JSONL → Binary (.bin/.idx)
```

## Quick Start

### Option 1: Automated Pipeline (Recommended)

Run the complete pipeline with one command:

```bash
./data/preprocess_protein_pipeline.sh \
    /path/to/your/protein_data.csv \
    $DATASETS_DIR/protein \
    sequence
```

**Arguments:**
1. Path to your CSV file
2. Output directory (where preprocessed files will be saved)
3. Name of the column containing protein sequences (default: "sequence")

**Optional Environment Variables:**
- `MIN_LENGTH`: Minimum sequence length to keep (e.g., `MIN_LENGTH=10`)
- `MAX_LENGTH`: Maximum sequence length to keep (default: 1024)
- `WORKERS`: Number of preprocessing workers (default: 32)

**Example:**
```bash
MAX_LENGTH=512 MIN_LENGTH=20 WORKERS=64 \
./data/preprocess_protein_pipeline.sh \
    /data/uniref50_sequences.csv \
    $DATASETS_DIR/protein \
    sequence
```

### Option 2: Step-by-Step

#### Step 1: Convert CSV to JSONL

```bash
python data/prepare_protein_data.py \
    --input-csv /path/to/protein_data.csv \
    --output-jsonl /path/to/output/sequences.jsonl \
    --sequence-column sequence \
    --max-length 1024 \
    --min-length 10
```

#### Step 2: Preprocess to Binary Format

```bash
python tools/preprocess_data.py \
    --input sequences.jsonl \
    --output-prefix $DATASETS_DIR/protein/train_data \
    --tokenizer-type HuggingFaceTokenizer \
    --tokenizer-model facebook/esm2_t33_650M_UR50D \
    --workers 32 \
    --append-eod \
    --json-keys text
```

## Expected CSV Format

Your CSV should have at least one column with protein sequences:

```csv
sequence
MKTAYIAKQRQISFVKSHFSRQ
VLSPADKTNVKAAWGKVGAHAG
MTEITAAMVKELRESTGAGMMD
```

Additional columns are fine - they will be ignored:

```csv
id,sequence,description
P12345,MKTAYIAKQRQISFVKSHFSRQ,Example protein 1
P67890,VLSPADKTNVKAAWGKVGAHAG,Example protein 2
```

## Output Files

After preprocessing, you'll have:

```
$DATASETS_DIR/protein/
├── train.jsonl                          # Intermediate JSONL (90% of data)
├── valid.jsonl                          # Intermediate JSONL (10% of data)
├── train_data_text_document.bin         # Binary training data
├── train_data_text_document.idx         # Index for training data
├── valid_data_text_document.bin         # Binary validation data
└── valid_data_text_document.idx         # Index for validation data
```

## Update Your Training Script

After preprocessing, update the paths in `dlm_pretrain_1.7b_protein.sh`:

```bash
train_data_prefix="$DATASETS_DIR/protein/train_data_text_document"
valid_data_prefix="$DATASETS_DIR/protein/valid_data_text_document"
```

**Note:** Don't include the `.bin` or `.idx` extension - the code adds it automatically.

## Tokenization Details

- **Tokenizer**: ESM2 (facebook/esm2_t33_650M_UR50D)
- **Vocab size**: 33 tokens
  - 20 standard amino acids
  - Special tokens: `<cls>`, `<pad>`, `<eos>`, `<unk>`, `<mask>`, etc.
- **Mask token ID**: 32
- **EOD token**: Appended to each sequence with `--append-eod`

## Troubleshooting

### "Column 'sequence' not found"
Your CSV uses a different column name. Specify it:
```bash
./data/preprocess_protein_pipeline.sh data.csv output_dir "protein_seq"
```

### Out of memory during preprocessing
Reduce the number of workers:
```bash
WORKERS=8 ./data/preprocess_protein_pipeline.sh ...
```

### Sequences too long
Set a maximum length:
```bash
MAX_LENGTH=512 ./data/preprocess_protein_pipeline.sh ...
```

## Verifying Your Data

After preprocessing, verify the token counts:

```bash
python tools/count_tokens.py \
    --weighted-prefix "1.0 $DATASETS_DIR/protein/train_data_text_document"
```

This will show you:
- Total number of tokens
- Number of documents
- Average tokens per document
