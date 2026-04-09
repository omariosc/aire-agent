#!/usr/bin/env bash
# log-experiment.sh — Log an experiment run to JSONL
# Part of aire-agent experiment tracking tools
set -euo pipefail

AIRE_AGENT_DIR="${AIRE_AGENT_DIR:-$HOME/.aire-agent}"
EXPERIMENTS_DIR="$AIRE_AGENT_DIR/experiments"
LOG_FILE="$EXPERIMENTS_DIR/experiments.jsonl"

usage() {
    cat <<'EOF'
Usage: log-experiment.sh --name NAME [OPTIONS]

Log an experiment run to the local experiment tracker.

Required:
  --name NAME          Experiment name (e.g., "bert_finetune_v2")

Optional:
  --job JOB_ID         Job ID (defaults to $SLURM_JOB_ID)
  --metrics JSON       Metrics as JSON string, e.g. '{"loss": 0.5, "acc": 0.92}'
  --params JSON        Hyperparameters as JSON string, e.g. '{"lr": 0.001}'
  --notes TEXT          Free-text notes about this run
  --help               Show this help message

Environment:
  AIRE_AGENT_DIR       Base directory (default: ~/.aire-agent)
  SLURM_JOB_ID         Auto-detected job ID
  SLURMD_NODENAME      Auto-detected node name
  SLURM_GPUS_ON_NODE   Auto-detected GPU count

Examples:
  log-experiment.sh --name "resnet50_lr_sweep" --metrics '{"val_loss": 0.32}' --params '{"lr": 0.001, "batch": 64}'
  log-experiment.sh --name "debug_run" --notes "Testing new data pipeline"
EOF
}

# Parse arguments
NAME=""
JOB_ID="${SLURM_JOB_ID:-}"
METRICS="{}"
PARAMS="{}"
NOTES=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            NAME="$2"
            shift 2
            ;;
        --job)
            JOB_ID="$2"
            shift 2
            ;;
        --metrics)
            METRICS="$2"
            shift 2
            ;;
        --params)
            PARAMS="$2"
            shift 2
            ;;
        --notes)
            NOTES="$2"
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

# Validate required arguments
if [[ -z "$NAME" ]]; then
    echo "Error: --name is required. Use --help for usage." >&2
    exit 1
fi

# Ensure experiments directory exists
mkdir -p "$EXPERIMENTS_DIR"

# Get git commit if in a repo
GIT_COMMIT=""
if command -v git &>/dev/null && git rev-parse --short HEAD &>/dev/null 2>&1; then
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "")
fi

# Get node name
NODE="${SLURMD_NODENAME:-$(hostname 2>/dev/null || echo "unknown")}"

# Get GPU count
GPUS="${SLURM_GPUS_ON_NODE:-0}"

# Generate timestamp
TIMESTAMP=$(python3 -c "from datetime import datetime, timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))")

# Build and append JSON entry using python3 for reliable formatting
python3 -c "
import json, sys

entry = {
    'timestamp': sys.argv[1],
    'name': sys.argv[2],
    'job_id': sys.argv[3],
    'metrics': json.loads(sys.argv[4]),
    'params': json.loads(sys.argv[5]),
    'git_commit': sys.argv[6],
    'node': sys.argv[7],
    'gpus': int(sys.argv[8]),
    'notes': sys.argv[9]
}

with open(sys.argv[10], 'a') as f:
    f.write(json.dumps(entry) + '\n')
" "$TIMESTAMP" "$NAME" "$JOB_ID" "$METRICS" "$PARAMS" "$GIT_COMMIT" "$NODE" "$GPUS" "$NOTES" "$LOG_FILE"

echo "Experiment logged: $NAME ($TIMESTAMP)"
