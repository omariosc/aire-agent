#!/usr/bin/env bash
set -euo pipefail

JSON_MODE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <job_id> [job_id ...]

Cancel one or more Slurm jobs.

Arguments:
  job_id          One or more job IDs to cancel

Options:
  --json          Output result as JSON
  --help          Show this help message

Examples:
  $(basename "$0") 12345
  $(basename "$0") 12345 12346 12347
  $(basename "$0") --json 12345
EOF
}

# Parse arguments
JOB_IDS=()
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
            JOB_IDS+=("$1")
            shift
            ;;
    esac
done

# Validate required argument
if [[ ${#JOB_IDS[@]} -eq 0 ]]; then
    echo "Error: Missing required job ID argument." >&2
    usage >&2
    exit 1
fi

# Cancel each job
ERRORS=()
CANCELLED=()
for JOB_ID in "${JOB_IDS[@]}"; do
    if OUTPUT=$(scancel "$JOB_ID" 2>&1); then
        CANCELLED+=("$JOB_ID")
    else
        ERRORS+=("$JOB_ID: $OUTPUT")
    fi
done

if [[ "$JSON_MODE" == true ]]; then
    echo "{"
    echo "  \"cancelled\": [$(printf '"%s",' "${CANCELLED[@]}" | sed 's/,$//')],";
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo "  \"errors\": [$(printf '"%s",' "${ERRORS[@]}" | sed 's/,$//')],";
    fi
    echo "  \"status\": \"$([ ${#ERRORS[@]} -eq 0 ] && echo 'success' || echo 'partial_failure')\""
    echo "}"
else
    for JOB_ID in "${CANCELLED[@]}"; do
        echo "Cancelled job $JOB_ID"
    done
    for ERR in "${ERRORS[@]}"; do
        echo "Error: $ERR" >&2
    done
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        exit 1
    fi
fi
