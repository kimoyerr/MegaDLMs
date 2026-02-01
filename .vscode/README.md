# VS Code Configuration for Protein Data Preprocessing

This directory contains VS Code configurations to make it easy to run and debug protein data preprocessing scripts.

## Files

- **[launch.json](launch.json)** - Debug configurations for Python scripts
- **[tasks.json](tasks.json)** - Build tasks for running preprocessing pipeline

## Quick Start

### Using Debug Configurations (F5)

1. Open VS Code
2. Press `F5` or go to Run & Debug (Ctrl+Shift+D)
3. Select a configuration from the dropdown:

#### Available Debug Configurations

| Configuration | Description |
|--------------|-------------|
| **Prepare Protein Data - Basic** | Convert CSV to JSONL with default settings |
| **Prepare Protein Data - With Length Filters** | Convert CSV with min/max length filtering |
| **Prepare Protein Data - Custom Column** | Use custom column name instead of "sequence" |
| **Prepare Protein Data - Prompt for Args** | Interactive mode - prompts for all arguments |
| **Preprocess Data - Train (ESM2)** | Tokenize training data with ESM2 |
| **Preprocess Data - Validation (ESM2)** | Tokenize validation data with ESM2 |
| **Count Tokens - Training Data** | Count tokens in preprocessed training data |

### Using Tasks (Ctrl+Shift+B)

Tasks allow you to run the complete pipeline or individual steps.

#### How to Run Tasks

1. Press `Ctrl+Shift+P` (Command Palette)
2. Type "Tasks: Run Task"
3. Select a task:

#### Available Tasks

| Task | Description |
|------|-------------|
| **Prepare Protein Data - Full Pipeline** | 🚀 Complete pipeline: CSV → JSONL → Binary (DEFAULT) |
| **CSV to JSONL Only** | Convert CSV to JSONL format |
| **Tokenize JSONL - Training** | Tokenize training JSONL to binary format |
| **Tokenize JSONL - Validation** | Tokenize validation JSONL to binary format |
| **Count Tokens - Training Data** | Verify training data token counts |
| **Count Tokens - Validation Data** | Verify validation data token counts |
| **Make Scripts Executable** | Set execute permissions on scripts |

#### Default Build Task

Press `Ctrl+Shift+B` to run the default build task:
- **Prepare Protein Data - Full Pipeline** - Runs the complete preprocessing pipeline

## Configuration Details

### Launch Configurations

Edit the `args` array in [launch.json](launch.json) to customize parameters:

```json
"args": [
    "--input-csv", "/path/to/your/data.csv",
    "--output-jsonl", "/path/to/output.jsonl",
    "--sequence-column", "sequence",
    "--min-length", "20",
    "--max-length", "1024"
]
```

### Task Inputs

Both launch and task configurations use input variables for flexibility. When you run a configuration with `${input:...}`, VS Code will prompt you for values.

**Example inputs:**
- `${input:inputCsvPath}` - Path to your CSV file
- `${input:sequenceColumn}` - Column name (default: "sequence")
- `${input:maxLength}` - Maximum sequence length (default: 1024)
- `${input:minLength}` - Minimum sequence length

### Environment Variables

Some configurations use environment variables:
- `${env:DATASETS_DIR}` - Root directory for datasets
- `${workspaceFolder}` - VS Code workspace root

Make sure `DATASETS_DIR` is set in your environment:
```bash
export DATASETS_DIR=/path/to/datasets
```

## Example Workflows

### Workflow 1: Debug CSV Conversion

1. Set a breakpoint in [data/prepare_protein_data.py](../data/prepare_protein_data.py)
2. Press `F5`
3. Select "Prepare Protein Data - Prompt for Args"
4. Enter your CSV path, output path, and column name
5. Step through the code with the debugger

### Workflow 2: Run Complete Pipeline

1. Press `Ctrl+Shift+B`
2. Task will prompt for:
   - Input CSV path
   - Output directory
   - Sequence column name
   - Max/min lengths
3. Wait for completion

### Workflow 3: Verify Preprocessed Data

1. After preprocessing, press `F5`
2. Select "Count Tokens - Training Data"
3. View token statistics in the terminal

## Customizing Configurations

### Adding a New Debug Configuration

Edit [launch.json](launch.json):

```json
{
    "name": "My Custom Config",
    "type": "debugpy",
    "request": "launch",
    "program": "${workspaceFolder}/data/prepare_protein_data.py",
    "console": "integratedTerminal",
    "args": [
        "--input-csv", "/my/custom/path.csv",
        "--output-jsonl", "/my/output/path.jsonl",
        "--sequence-column", "my_column"
    ],
    "cwd": "${workspaceFolder}"
}
```

### Adding a New Task

Edit [tasks.json](tasks.json):

```json
{
    "label": "My Custom Task",
    "type": "shell",
    "command": "python",
    "args": [
        "${workspaceFolder}/data/prepare_protein_data.py",
        "--input-csv", "${input:inputCsvPath}"
    ],
    "options": {
        "cwd": "${workspaceFolder}"
    }
}
```

## Troubleshooting

### "debugpy" not found
Install the Python debugger:
```bash
pip install debugpy
```

### Environment variable not set
Make sure to set required environment variables before starting VS Code:
```bash
export DATASETS_DIR=/path/to/datasets
code .
```

Or add them to your shell profile (~/.bashrc or ~/.zshrc)

### Task fails immediately
Check that scripts are executable:
```bash
chmod +x data/prepare_protein_data.py
chmod +x data/preprocess_protein_pipeline.sh
```

Or run the "Make Scripts Executable" task.

## Tips

1. **Keyboard Shortcuts:**
   - `F5` - Start debugging with selected configuration
   - `Ctrl+Shift+B` - Run default build task
   - `Ctrl+Shift+P` → "Tasks: Run Task" - Select any task

2. **Terminal Output:**
   - All configurations use `integratedTerminal` for better output visibility
   - Tasks open in new panels to avoid conflicts

3. **Breakpoints:**
   - Set breakpoints in Python files by clicking in the gutter (left of line numbers)
   - Conditional breakpoints: Right-click on a breakpoint → Edit Breakpoint

4. **Interactive Debugging:**
   - Use the Debug Console to evaluate expressions
   - Inspect variables in the Variables pane
   - View call stack in the Call Stack pane