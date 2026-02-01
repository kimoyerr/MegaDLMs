#!/usr/bin/env python3
"""
Convert protein CSV data to JSONL format for preprocessing.
Reads CSV with 'sequence' column and outputs JSONL for Megatron preprocessing.
"""

import argparse
import json
import pandas as pd
from pathlib import Path


def convert_csv_to_jsonl(csv_path, output_path, sequence_column='sequence',
                         max_length=None, min_length=None):
    """
    Convert CSV with protein sequences to JSONL format.

    Args:
        csv_path: Path to input CSV file
        output_path: Path to output JSONL file
        sequence_column: Name of column containing protein sequences
        max_length: Optional maximum sequence length (longer sequences will be skipped)
        min_length: Optional minimum sequence length (shorter sequences will be skipped)
    """
    print(f"Reading CSV from {csv_path}...")
    df = pd.read_csv(csv_path)

    if sequence_column not in df.columns:
        raise ValueError(f"Column '{sequence_column}' not found in CSV. Available columns: {list(df.columns)}")

    print(f"Found {len(df)} sequences in CSV")

    # Filter by length if specified
    if max_length is not None or min_length is not None:
        original_len = len(df)
        if min_length is not None:
            df = df[df[sequence_column].str.len() >= min_length]
        if max_length is not None:
            df = df[df[sequence_column].str.len() <= max_length]
        print(f"After length filtering: {len(df)} sequences (removed {original_len - len(df)})")

    # Remove any rows with null sequences
    df = df.dropna(subset=[sequence_column])
    print(f"After removing nulls: {len(df)} sequences")

    # Convert to JSONL
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Writing JSONL to {output_path}...")
    with open(output_path, 'w') as f:
        for idx, row in df.iterrows():
            sequence = row[sequence_column].strip()
            if sequence:  # Only write non-empty sequences
                json_obj = {"text": sequence}
                f.write(json.dumps(json_obj) + '\n')

    print(f"Successfully wrote {len(df)} sequences to {output_path}")

    # Print some statistics
    seq_lengths = df[sequence_column].str.len()
    print(f"\nSequence length statistics:")
    print(f"  Min: {seq_lengths.min()}")
    print(f"  Max: {seq_lengths.max()}")
    print(f"  Mean: {seq_lengths.mean():.2f}")
    print(f"  Median: {seq_lengths.median():.2f}")


def main():
    parser = argparse.ArgumentParser(description='Convert protein CSV to JSONL for preprocessing')
    parser.add_argument('--input-csv', type=str, required=True,
                        help='Path to input CSV file')
    parser.add_argument('--output-jsonl', type=str, required=True,
                        help='Path to output JSONL file')
    parser.add_argument('--sequence-column', type=str, default='sequence',
                        help='Name of column containing protein sequences (default: sequence)')
    parser.add_argument('--max-length', type=int, default=None,
                        help='Maximum sequence length (optional)')
    parser.add_argument('--min-length', type=int, default=None,
                        help='Minimum sequence length (optional)')

    args = parser.parse_args()

    convert_csv_to_jsonl(
        csv_path=args.input_csv,
        output_path=args.output_jsonl,
        sequence_column=args.sequence_column,
        max_length=args.max_length,
        min_length=args.min_length
    )


if __name__ == '__main__':
    main()
