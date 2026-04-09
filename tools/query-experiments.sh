#!/usr/bin/env bash
# query-experiments.sh — Query logged experiments
# Part of aire-agent experiment tracking tools
set -euo pipefail

AIRE_AGENT_DIR="${AIRE_AGENT_DIR:-$HOME/.aire-agent}"
EXPERIMENTS_DIR="$AIRE_AGENT_DIR/experiments"
LOG_FILE="$EXPERIMENTS_DIR/experiments.jsonl"

usage() {
    cat <<'EOF'
Usage: query-experiments.sh [OPTIONS]

Query and display logged experiments.

Options:
  --last N             Show last N experiments (default: 20)
  --json               Output raw JSONL format
  --filter FIELD=VAL   Filter experiments by field value
  --help               Show this help message

Environment:
  AIRE_AGENT_DIR       Base directory (default: ~/.aire-agent)

Examples:
  query-experiments.sh                     # Show last 20 experiments
  query-experiments.sh --last 5            # Show last 5
  query-experiments.sh --json              # Raw JSONL output
  query-experiments.sh --filter name=bert  # Filter by name
EOF
}

LAST=20
JSON_MODE=false
FILTER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --last)
            LAST="$2"
            shift 2
            ;;
        --json)
            JSON_MODE=true
            shift
            ;;
        --filter)
            FILTER="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'. Use --help for usage." >&2
            exit 1
            ;;
    esac
done

# Check if experiments file exists and has content
if [[ ! -f "$LOG_FILE" ]] || [[ ! -s "$LOG_FILE" ]]; then
    echo "No experiments logged yet."
    exit 0
fi

if [[ "$JSON_MODE" == true ]]; then
    # Raw JSONL output — last N lines
    tail -n "$LAST" "$LOG_FILE"
else
    # Formatted output using python3
    python3 -c "
import json, sys

log_file = sys.argv[1]
last_n = int(sys.argv[2])
filter_str = sys.argv[3]

with open(log_file) as f:
    lines = f.readlines()

entries = []
for line in lines:
    line = line.strip()
    if not line:
        continue
    try:
        entries.append(json.loads(line))
    except json.JSONDecodeError:
        continue

# Apply filter if provided
if filter_str:
    field, _, value = filter_str.partition('=')
    entries = [e for e in entries if str(e.get(field, '')) == value or value in str(e.get(field, ''))]

# Take last N
entries = entries[-last_n:]

if not entries:
    print('No experiments logged yet.')
    sys.exit(0)

print(f'Showing {len(entries)} experiment(s):')
print('-' * 80)

for e in entries:
    ts = e.get('timestamp', 'N/A')
    name = e.get('name', 'N/A')
    job_id = e.get('job_id', '')
    metrics = e.get('metrics', {})
    params = e.get('params', {})
    node = e.get('node', '')
    gpus = e.get('gpus', 0)
    notes = e.get('notes', '')
    git = e.get('git_commit', '')

    job_str = f' [job:{job_id}]' if job_id else ''
    git_str = f' git:{git}' if git else ''
    gpu_str = f' gpus:{gpus}' if gpus else ''

    metrics_str = ', '.join(f'{k}={v}' for k, v in metrics.items()) if metrics else 'none'
    params_str = ', '.join(f'{k}={v}' for k, v in params.items()) if params else ''

    print(f'  {ts}  {name}{job_str}{git_str}{gpu_str}')
    print(f'    metrics: {metrics_str}')
    if params_str:
        print(f'    params:  {params_str}')
    if notes:
        print(f'    notes:   {notes}')
    print()
" "$LOG_FILE" "$LAST" "$FILTER"
fi
