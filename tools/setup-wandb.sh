#!/usr/bin/env bash
# setup-wandb.sh — Check and configure Weights & Biases for HPC
# Part of aire-agent experiment tracking tools
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: setup-wandb.sh [OPTIONS]

Check Weights & Biases (wandb) setup and provide HPC configuration guidance.

Options:
  --help    Show this help message

This tool:
  1. Checks if wandb is installed
  2. Shows version and login status
  3. Provides recommended SBATCH configuration for HPC use
EOF
}

# Handle --help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

echo "=== Weights & Biases (wandb) Setup Check ==="
echo

# Check if wandb is installed
if ! python3 -c "import wandb" 2>/dev/null; then
    echo "[!] wandb is NOT installed."
    echo
    echo "To install wandb, run:"
    echo "  pip install wandb"
    echo
    echo "Or in a conda environment:"
    echo "  conda activate your_env && pip install wandb"
    echo
    echo "After installation, log in with:"
    echo "  wandb login"
    exit 0
fi

# wandb is installed — show version
WANDB_VERSION=$(python3 -c "import wandb; print(wandb.__version__)" 2>/dev/null)
echo "[OK] wandb is installed (version: $WANDB_VERSION)"

# Check login status
if python3 -c "import wandb; api = wandb.Api(); print(api.viewer())" 2>/dev/null; then
    echo "[OK] wandb is logged in"
else
    echo "[!] wandb login status unclear — run 'wandb login' if needed"
fi

echo
echo "=== Recommended SBATCH Configuration ==="
echo
cat <<'SBATCH'
Add these to your SBATCH script for HPC wandb usage:

  # -- wandb configuration --
  export WANDB_DIR="${TMPDIR:-/tmp}/wandb"
  export WANDB_MODE=offline
  mkdir -p "$WANDB_DIR"

  # After your training completes, sync the run:
  # wandb sync "$WANDB_DIR/wandb/latest-run"

Key environment variables:
  WANDB_DIR       Where wandb stores run data (use fast local disk)
  WANDB_MODE      Set to 'offline' on compute nodes (no internet)
  WANDB_PROJECT   Your project name
  WANDB_ENTITY    Your team/username
  WANDB_RUN_ID    Unique run ID (for resuming)

Sync offline runs from login node:
  wandb sync /path/to/wandb/run-YYYYMMDD_HHMMSS-RUNID
SBATCH

echo
echo "For more info: https://docs.wandb.ai/guides/track/environment-variables"
