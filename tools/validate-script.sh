#!/usr/bin/env bash
# validate-script.sh - Validate SBATCH job scripts for common errors
# Usage: validate-script.sh [--json] [--help] <script.sh>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# ── Defaults ───────────────────────────────────────────────────────────────────
JSON_OUTPUT=false
ERRORS=()
WARNINGS=()

# ── Functions ──────────────────────────────────────────────────────────────────

show_help() {
    cat <<'EOF'
Usage: validate-script.sh [OPTIONS] <script.sh>

Validate an SBATCH job script for common errors and best practices.

Options:
  --json    Output results as JSON
  --help    Show this help message

Checks performed:
  - --time is present (REQUIRED)
  - --partition=gpu and --gres=gpu:N are used together
  - GPU count <=3 per node (if single node)

Warnings (non-fatal):
  - Missing email notifications (--mail-user / --mail-type)
  - Missing seff at end of script

Exit codes:
  0  Script is valid
  1  Script has errors
EOF
    exit 0
}

add_error() {
    ERRORS+=("$1")
}

add_warning() {
    WARNINGS+=("$1")
}

output_results() {
    local script_path="$1"

    if $JSON_OUTPUT; then
        local errors_json="["
        for i in "${!ERRORS[@]}"; do
            [[ $i -gt 0 ]] && errors_json+=","
            errors_json+="\"${ERRORS[$i]}\""
        done
        errors_json+="]"

        local warnings_json="["
        for i in "${!WARNINGS[@]}"; do
            [[ $i -gt 0 ]] && warnings_json+=","
            warnings_json+="\"${WARNINGS[$i]}\""
        done
        warnings_json+="]"

        local valid="true"
        [[ ${#ERRORS[@]} -gt 0 ]] && valid="false"

        cat <<EOF
{
  "file": "$script_path",
  "valid": $valid,
  "errors": $errors_json,
  "warnings": $warnings_json
}
EOF
    else
        if [[ ${#ERRORS[@]} -gt 0 ]]; then
            echo "ERRORS in $script_path:"
            for err in "${ERRORS[@]}"; do
                echo "  [ERROR] $err"
            done
        fi

        if [[ ${#WARNINGS[@]} -gt 0 ]]; then
            echo "WARNINGS in $script_path:"
            for warn in "${WARNINGS[@]}"; do
                echo "  [WARN]  $warn"
            done
        fi

        if [[ ${#ERRORS[@]} -eq 0 ]]; then
            echo "VALID: $script_path passes all checks"
        fi
    fi
}

# ── Parse arguments ────────────────────────────────────────────────────────────

SCRIPT_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help)
            show_help
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
        *)
            SCRIPT_PATH="$1"
            shift
            ;;
    esac
done

if [[ -z "$SCRIPT_PATH" ]]; then
    echo "Error: No script path provided" >&2
    echo "Usage: validate-script.sh [--json] <script.sh>" >&2
    exit 1
fi

if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "Error: Script not found: $SCRIPT_PATH" >&2
    exit 1
fi

# ── Extract SBATCH directives ─────────────────────────────────────────────────

DIRECTIVES=$(grep -E '^#SBATCH' "$SCRIPT_PATH" || true)
SCRIPT_BODY=$(grep -v '^#' "$SCRIPT_PATH" || true)

# Extract specific values
HAS_TIME=$(echo "$DIRECTIVES" | grep -c -- '--time' || true)
HAS_GPU_PARTITION=$(echo "$DIRECTIVES" | grep -c -- '--partition=gpu' || true)
HAS_GRES=$(echo "$DIRECTIVES" | grep -c -- '--gres=gpu' || true)
HAS_MAIL_USER=$(echo "$DIRECTIVES" | grep -c -- '--mail-user' || true)
HAS_MAIL_TYPE=$(echo "$DIRECTIVES" | grep -c -- '--mail-type' || true)
HAS_SEFF=$(echo "$SCRIPT_BODY" | grep -c 'seff' || true)

# Extract GPU count from --gres=gpu:N
GPU_COUNT=0
if [[ $HAS_GRES -gt 0 ]]; then
    GPU_COUNT=$(echo "$DIRECTIVES" | grep -oE -- '--gres=gpu:[0-9]+' | head -1 | grep -oE '[0-9]+$' || echo "0")
fi

# Extract node count (default 1)
NODE_COUNT=1
if echo "$DIRECTIVES" | grep -qE -- '--nodes=[0-9]+'; then
    NODE_COUNT=$(echo "$DIRECTIVES" | grep -oE -- '--nodes=[0-9]+' | head -1 | grep -oE '[0-9]+$')
fi

# ── Validation checks ─────────────────────────────────────────────────────────

# 1. --time is required
if [[ $HAS_TIME -eq 0 ]]; then
    add_error "Missing --time directive. All jobs must specify a time limit."
fi

# 2. --partition=gpu requires --gres=gpu:N
if [[ $HAS_GPU_PARTITION -gt 0 && $HAS_GRES -eq 0 ]]; then
    add_error "partition=gpu requires --gres=gpu:N to allocate GPUs."
fi

# 3. --gres=gpu:N requires --partition=gpu
if [[ $HAS_GRES -gt 0 && $HAS_GPU_PARTITION -eq 0 ]]; then
    add_error "GPU resources (--gres) require --partition=gpu to be set."
fi

# 4. GPU count <=3 per node (single node)
if [[ $HAS_GRES -gt 0 && $NODE_COUNT -eq 1 && $GPU_COUNT -gt 3 ]]; then
    add_error "Maximum 3 GPUs per node. Requested $GPU_COUNT on single node. Use --nodes=\$(ceil($GPU_COUNT/3)) for multi-node."
fi

# ── Warnings (non-fatal) ──────────────────────────────────────────────────────

if [[ $HAS_MAIL_USER -eq 0 || $HAS_MAIL_TYPE -eq 0 ]]; then
    add_warning "Missing email notifications. Add --mail-user and --mail-type for job status alerts."
fi

if [[ $HAS_SEFF -eq 0 ]]; then
    add_warning "Missing 'seff \$SLURM_JOB_ID' at end of script for resource usage reporting."
fi

# ── Output results ─────────────────────────────────────────────────────────────

output_results "$SCRIPT_PATH"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
    exit 1
fi

exit 0
