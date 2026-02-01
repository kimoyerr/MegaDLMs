#!/bin/bash
# Complete pipeline to preprocess protein data from CSV to binary format

set -e  # Exit on error

# Configuration - UPDATE THESE PATHS
INPUT_CSV="${1:-/path/to/your/protein_data.csv}"
OUTPUT_DIR="${2:-$DATASETS_DIR/protein}"
SEQUENCE_COLUMN="${3:-sequence}"

# Optional: filter sequences by length
MIN_LENGTH="${MIN_LENGTH:-}"  # e.g., 10
MAX_LENGTH="${MAX_LENGTH:-1024}"  # Match your SEQ_LENGTH in training script

# ESM2 tokenizer
TOKENIZER="facebook/esm2_t33_650M_UR50D"

# Number of workers for preprocessing
WORKERS="${WORKERS:-32}"

# Derived paths
TRAIN_JSONL="$OUTPUT_DIR/train.jsonl"
VALID_JSONL="$OUTPUT_DIR/valid.jsonl"
TRAIN_PREFIX="$OUTPUT_DIR/train_data"
VALID_PREFIX="$OUTPUT_DIR/valid_data"

echo "========================================="
echo "Protein Data Preprocessing Pipeline"
echo "========================================="
echo "Input CSV: $INPUT_CSV"
echo "Output directory: $OUTPUT_DIR"
echo "Sequence column: $SEQUENCE_COLUMN"
echo "Max sequence length: $MAX_LENGTH"
echo "Min sequence length: ${MIN_LENGTH:-none}"
echo "========================================="

# Check if input file exists
if [ ! -f "$INPUT_CSV" ]; then
    echo "Error: Input CSV file not found: $INPUT_CSV"
    echo "Usage: $0 <input_csv> [output_dir] [sequence_column]"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 1: Convert CSV to JSONL and split into train/valid
echo ""
echo "Step 1: Converting CSV to JSONL..."

# Build the command with optional parameters
CONVERT_CMD="python data/prepare_protein_data.py \
    --input-csv $INPUT_CSV \
    --output-jsonl $TRAIN_JSONL \
    --sequence-column $SEQUENCE_COLUMN"

if [ -n "$MAX_LENGTH" ]; then
    CONVERT_CMD="$CONVERT_CMD --max-length $MAX_LENGTH"
fi

if [ -n "$MIN_LENGTH" ]; then
    CONVERT_CMD="$CONVERT_CMD --min-length $MIN_LENGTH"
fi

eval $CONVERT_CMD

# Step 2: Create train/validation split
echo ""
echo "Step 2: Creating train/validation split (90/10)..."

TOTAL_LINES=$(wc -l < "$TRAIN_JSONL")
TRAIN_LINES=$((TOTAL_LINES * 90 / 100))

# Split the data
head -n $TRAIN_LINES "$TRAIN_JSONL" > "$OUTPUT_DIR/train_tmp.jsonl"
tail -n +$((TRAIN_LINES + 1)) "$TRAIN_JSONL" > "$VALID_JSONL"
mv "$OUTPUT_DIR/train_tmp.jsonl" "$TRAIN_JSONL"

echo "Train sequences: $TRAIN_LINES"
echo "Validation sequences: $((TOTAL_LINES - TRAIN_LINES))"

# Step 3: Preprocess training data to binary format
echo ""
echo "Step 3: Preprocessing training data to binary format..."

python tools/preprocess_data.py \
    --input "$TRAIN_JSONL" \
    --output-prefix "$TRAIN_PREFIX" \
    --tokenizer-type HuggingFaceTokenizer \
    --tokenizer-model "$TOKENIZER" \
    --workers $WORKERS \
    --append-eod \
    --json-keys text

# Step 4: Preprocess validation data to binary format
echo ""
echo "Step 4: Preprocessing validation data to binary format..."

python tools/preprocess_data.py \
    --input "$VALID_JSONL" \
    --output-prefix "$VALID_PREFIX" \
    --tokenizer-type HuggingFaceTokenizer \
    --tokenizer-model "$TOKENIZER" \
    --workers $WORKERS \
    --append-eod \
    --json-keys text

# Verify outputs
echo ""
echo "========================================="
echo "Preprocessing Complete!"
echo "========================================="
echo ""
echo "Output files created:"
echo "  Training data:"
echo "    - ${TRAIN_PREFIX}_text_document.bin"
echo "    - ${TRAIN_PREFIX}_text_document.idx"
echo "  Validation data:"
echo "    - ${VALID_PREFIX}_text_document.bin"
echo "    - ${VALID_PREFIX}_text_document.idx"
echo ""
echo "Update your training script with these paths:"
echo "  train_data_prefix=\"${TRAIN_PREFIX}_text_document\""
echo "  valid_data_prefix=\"${VALID_PREFIX}_text_document\""
echo ""
echo "========================================="
