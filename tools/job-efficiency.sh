#!/usr/bin/env bash
set -euo pipefail

JSON_MODE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <job_id>

Show efficiency report for a completed Slurm job.

Arguments:
  job_id          The job ID to query

Options:
  --json          Output result as JSON
  --help          Show this help message

Examples:
  $(basename "$0") 12345
  $(basename "$0") --json 12345
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
    echo "Error: Missing required job ID argument." >&2
    usage >&2
    exit 1
fi

JOB_ID="${POSITIONAL_ARGS[0]}"

# Query job efficiency
OUTPUT=$(seff "$JOB_ID" 2>&1)
SEFF_EXIT=$?

if [[ $SEFF_EXIT -ne 0 ]]; then
    if [[ "$JSON_MODE" == true ]]; then
        echo "{\"error\": \"Failed to get efficiency for job $JOB_ID\", \"details\": \"$OUTPUT\"}"
    else
        echo "Error: Failed to get efficiency for job $JOB_ID" >&2
        echo "$OUTPUT" >&2
    fi
    exit 1
fi

if [[ "$JSON_MODE" == true ]]; then
    # Parse seff output into JSON key-value pairs
    echo "{"
    echo "  \"job_id\": \"$JOB_ID\","
    FIRST=true
    while IFS=':' read -r key value; do
        [[ -z "$key" ]] && continue
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        if [[ "$FIRST" == true ]]; then
            FIRST=false
        else
            echo ","
        fi
        printf '  "%s": "%s"' "$key" "$value"
    done <<< "$OUTPUT"
    echo ""
    echo "}"
else
    echo "=== Job $JOB_ID Efficiency Report ==="
    echo "$OUTPUT"
fi
