#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

JSON_MODE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <script.sh>

Submit a Slurm batch job.

Arguments:
  script.sh       Path to the job script to submit

Options:
  --json          Output result as JSON
  --help          Show this help message

Examples:
  $(basename "$0") my_job.sh
  $(basename "$0") --json my_job.sh
EOF
}

# Parse arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            usage >&2
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Validate required argument
if [[ ${#POSITIONAL_ARGS[@]} -eq 0 ]]; then
    echo "Error: Missing required script argument." >&2
    usage >&2
    exit 1
fi

SCRIPT_PATH="${POSITIONAL_ARGS[0]}"

# Validate script file exists
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "Error: Script '$SCRIPT_PATH' not found." >&2
    exit 1
fi

# Run validate-script.sh if it exists
VALIDATE_SCRIPT="$SCRIPT_DIR/validate-script.sh"
if [[ -x "$VALIDATE_SCRIPT" ]]; then
    echo "Validating script..."
    if ! "$VALIDATE_SCRIPT" "$SCRIPT_PATH"; then
        echo "Error: Script validation failed." >&2
        exit 1
    fi
fi

# Submit the job
OUTPUT=$(sbatch "$SCRIPT_PATH" 2>&1)
SBATCH_EXIT=$?

if [[ $SBATCH_EXIT -ne 0 ]]; then
    echo "Error: sbatch failed: $OUTPUT" >&2
    exit 1
fi

# Extract job ID from sbatch output (format: "Submitted batch job 12345")
JOB_ID=$(echo "$OUTPUT" | grep -oE '[0-9]+$' || true)

if [[ -z "$JOB_ID" ]]; then
    echo "Error: Could not extract job ID from sbatch output: $OUTPUT" >&2
    exit 1
fi

if [[ "$JSON_MODE" == true ]]; then
    cat <<EOF
{"job_id": "$JOB_ID", "script": "$SCRIPT_PATH", "status": "submitted"}
EOF
else
    echo "Job submitted successfully."
    echo "  Job ID:  $JOB_ID"
    echo "  Script:  $SCRIPT_PATH"
    echo "  Status:  submitted"
fi
