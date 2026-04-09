#!/usr/bin/env bash
set -euo pipefail

JSON_MODE=false
ALL_USERS=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check the Slurm job queue.

Options:
  --all           Show jobs for all users (default: current user only)
  --json          Output result as JSON
  --help          Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --all
  $(basename "$0") --json
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --all)
            ALL_USERS=true
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
            echo "Error: Unexpected argument '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# Build squeue command
SQUEUE_CMD=(squeue)
if [[ "$ALL_USERS" == false ]]; then
    SQUEUE_CMD+=(--me)
fi

if [[ "$JSON_MODE" == true ]]; then
    # Use squeue with specific format for JSON parsing
    SQUEUE_CMD+=(--format="%i|%j|%T|%M|%l|%D|%R" --noheader)
    OUTPUT=$("${SQUEUE_CMD[@]}" 2>&1) || {
        echo "{\"error\": \"squeue failed: $OUTPUT\"}" >&2
        exit 1
    }

    echo "["
    FIRST=true
    while IFS='|' read -r jobid name state time timelimit nodes reason; do
        # Skip empty lines
        [[ -z "$jobid" ]] && continue
        # Trim whitespace
        jobid=$(echo "$jobid" | xargs)
        name=$(echo "$name" | xargs)
        state=$(echo "$state" | xargs)
        time=$(echo "$time" | xargs)
        timelimit=$(echo "$timelimit" | xargs)
        nodes=$(echo "$nodes" | xargs)
        reason=$(echo "$reason" | xargs)

        if [[ "$FIRST" == true ]]; then
            FIRST=false
        else
            echo ","
        fi
        printf '  {"job_id": "%s", "name": "%s", "state": "%s", "time": "%s", "time_limit": "%s", "nodes": "%s", "reason": "%s"}' \
            "$jobid" "$name" "$state" "$time" "$timelimit" "$nodes" "$reason"
    done <<< "$OUTPUT"
    echo ""
    echo "]"
else
    "${SQUEUE_CMD[@]}" 2>&1
fi
