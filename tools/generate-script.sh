#!/usr/bin/env bash
# generate-script.sh - Generate SBATCH job scripts
# Usage: generate-script.sh --time TIME [OPTIONS]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# ── Defaults ───────────────────────────────────────────────────────────────────
GPU_COUNT=0
TIME_RAW=""
CPUS=""
MEM=""
NODES=""
PARTITION=""
FRAMEWORK="none"
JOB_NAME="job"
EMAIL=""
ARRAY=""
OUTPUT_FILE=""

# ── Functions ──────────────────────────────────────────────────────────────────

show_help() {
    cat <<'EOF'
Usage: generate-script.sh --time TIME [OPTIONS]

Generate a complete SBATCH job script.

Required:
  --time TIME         Wall time (e.g., 1h, 4h, 1d, 01:00:00)

Options:
  --gpu N             Number of GPUs (default: 0, CPU job)
  --cpus N            CPUs per task (auto: 8/GPU for GPU, 1 for CPU)
  --mem SIZE          Memory (auto: --mem-per-cpu=8G for GPU, --mem=4G for CPU)
  --nodes N           Number of nodes (auto-calculated for >3 GPUs)
  --partition NAME    Partition name (auto: gpu if --gpu >0, cpu otherwise)
  --framework NAME    pytorch|tensorflow|none (default: none)
  --job-name NAME     Job name (default: job)
  --email ADDRESS     Email for notifications
  --array RANGE       Array job range (e.g., 1-10, 1-100%5)
  --output FILE       Write script to file instead of stdout
  --help              Show this help message

Examples:
  generate-script.sh --time 4h --gpu 1 --framework pytorch
  generate-script.sh --time 1h --cpus 4 --mem 8G
  generate-script.sh --time 8h --gpu 6 --framework pytorch
EOF
    exit 0
}

# Normalize time formats: "1h" -> "01:00:00", "4h" -> "04:00:00", "1d" -> "1-00:00:00"
normalize_time() {
    local raw="$1"

    # Already in HH:MM:SS or D-HH:MM:SS format
    if [[ "$raw" =~ ^[0-9]+-[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] || \
       [[ "$raw" =~ ^[0-9]{1,3}:[0-9]{2}:[0-9]{2}$ ]]; then
        echo "$raw"
        return
    fi

    # Hours: "1h", "4h", "24h"
    if [[ "$raw" =~ ^([0-9]+)h$ ]]; then
        local hours="${BASH_REMATCH[1]}"
        if [[ $hours -ge 24 ]]; then
            local days=$((hours / 24))
            local rem=$((hours % 24))
            printf "%d-%02d:00:00" "$days" "$rem"
        else
            printf "%02d:00:00" "$hours"
        fi
        return
    fi

    # Days: "1d", "3d"
    if [[ "$raw" =~ ^([0-9]+)d$ ]]; then
        local days="${BASH_REMATCH[1]}"
        printf "%d-00:00:00" "$days"
        return
    fi

    # Minutes: "30m", "90m"
    if [[ "$raw" =~ ^([0-9]+)m$ ]]; then
        local mins="${BASH_REMATCH[1]}"
        local h=$((mins / 60))
        local m=$((mins % 60))
        printf "%02d:%02d:00" "$h" "$m"
        return
    fi

    # Fallback: return as-is
    echo "$raw"
}

# Ceiling division
ceil_div() {
    local num=$1
    local den=$2
    echo $(( (num + den - 1) / den ))
}

# ── Parse arguments ────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --gpu)      GPU_COUNT="$2"; shift 2 ;;
        --time)     TIME_RAW="$2"; shift 2 ;;
        --cpus)     CPUS="$2"; shift 2 ;;
        --mem)      MEM="$2"; shift 2 ;;
        --nodes)    NODES="$2"; shift 2 ;;
        --partition) PARTITION="$2"; shift 2 ;;
        --framework) FRAMEWORK="$2"; shift 2 ;;
        --job-name) JOB_NAME="$2"; shift 2 ;;
        --email)    EMAIL="$2"; shift 2 ;;
        --array)    ARRAY="$2"; shift 2 ;;
        --output)   OUTPUT_FILE="$2"; shift 2 ;;
        --help)     show_help ;;
        *)
            echo "Error: Unknown option '$1'" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# ── Validate required arguments ────────────────────────────────────────────────

if [[ -z "$TIME_RAW" ]]; then
    echo "Error: --time is required" >&2
    echo "Use --help for usage information" >&2
    exit 1
fi

TIME=$(normalize_time "$TIME_RAW")

# ── Auto-detect settings ──────────────────────────────────────────────────────

# Partition auto-detection
if [[ -z "$PARTITION" ]]; then
    if [[ $GPU_COUNT -gt 0 ]]; then
        PARTITION="gpu"
    else
        PARTITION="cpu"
    fi
fi

# Nodes: auto-calculate for >3 GPUs (max 3 per node)
GPUS_PER_NODE=3
if [[ -z "$NODES" ]]; then
    if [[ $GPU_COUNT -gt 3 ]]; then
        NODES=$(ceil_div "$GPU_COUNT" "$GPUS_PER_NODE")
    else
        NODES=1
    fi
else
    NODES="$NODES"
fi

# Recalculate actual GPUs per node for multi-node
if [[ $NODES -gt 1 ]]; then
    GPUS_PER_NODE=$(ceil_div "$GPU_COUNT" "$NODES")
fi

# CPUs: auto-set (8 per GPU for GPU, or specified/default for CPU)
if [[ -z "$CPUS" ]]; then
    if [[ $GPU_COUNT -gt 0 ]]; then
        if [[ $NODES -gt 1 ]]; then
            CPUS=$((8 * GPUS_PER_NODE))
        else
            CPUS=$((8 * GPU_COUNT))
        fi
    else
        CPUS=1
    fi
fi

# Memory auto-set
if [[ -z "$MEM" ]]; then
    if [[ $GPU_COUNT -gt 0 ]]; then
        MEM="mem-per-cpu=8G"
    else
        MEM="mem=4G"
    fi
else
    MEM="mem=$MEM"
fi

# Email: default placeholder if not set
if [[ -z "$EMAIL" ]]; then
    EMAIL="YOUR_EMAIL@leeds.ac.uk"
fi

# ── Generate script ───────────────────────────────────────────────────────────

generate() {
    # Shebang
    echo "#!/bin/bash"

    # SBATCH directives
    echo "#SBATCH --job-name=$JOB_NAME"
    echo "#SBATCH --partition=$PARTITION"
    echo "#SBATCH --nodes=$NODES"

    if [[ $NODES -gt 1 ]]; then
        echo "#SBATCH --ntasks-per-node=1"
    else
        echo "#SBATCH --ntasks=1"
    fi

    echo "#SBATCH --cpus-per-task=$CPUS"
    echo "#SBATCH --$MEM"

    if [[ $GPU_COUNT -gt 0 ]]; then
        if [[ $NODES -gt 1 ]]; then
            echo "#SBATCH --gres=gpu:$GPUS_PER_NODE"
        else
            echo "#SBATCH --gres=gpu:$GPU_COUNT"
        fi
    fi

    echo "#SBATCH --time=$TIME"
    echo "#SBATCH --output=logs/%x_%j.out"
    echo "#SBATCH --error=logs/%x_%j.err"
    echo "#SBATCH --mail-user=$EMAIL"
    echo "#SBATCH --mail-type=BEGIN,END,FAIL"

    if [[ -n "$ARRAY" ]]; then
        echo "#SBATCH --array=$ARRAY"
    fi

    echo ""
    echo "mkdir -p logs"
    echo ""

    # Modules
    echo "# -- Load modules ---------------------------------------------------------------"
    if [[ $GPU_COUNT -gt 0 ]]; then
        echo "module load cuda/12.6.2"
    fi
    echo "module load miniforge/24.7.1"
    echo 'source $(conda info --base)/etc/profile.d/conda.sh'
    echo "conda activate YOUR_ENV"
    echo ""

    # Framework-specific environment
    if [[ "$FRAMEWORK" == "pytorch" && $GPU_COUNT -gt 0 ]]; then
        echo "# -- PyTorch environment variables -----------------------------------------------"
        echo "export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True"
        echo "export TORCH_CUDNN_V8_API_ENABLED=1"
        echo "export CUDNN_BENCHMARK=1"
        echo "export CUDA_LAUNCH_BLOCKING=0"
        echo ""
    fi

    if [[ "$FRAMEWORK" == "tensorflow" && $GPU_COUNT -gt 0 ]]; then
        echo "# -- TensorFlow environment variables -------------------------------------------"
        echo "export TF_GPU_ALLOCATOR=cuda_malloc_async"
        echo "export TF_FORCE_GPU_ALLOW_GROWTH=true"
        echo ""
    fi

    # Multi-node setup
    if [[ $NODES -gt 1 && $GPU_COUNT -gt 0 ]]; then
        echo "# -- Multi-node setup -----------------------------------------------------------"
        echo 'export MASTER_ADDR=$(scontrol show hostnames ${SLURM_JOB_NODELIST} | head -n 1)'
        echo "export MASTER_PORT=29500"
        echo 'export WORLD_SIZE=$((SLURM_NNODES * '"$GPUS_PER_NODE"'))'
        echo ""
        echo 'echo "Job started at $(date)"'
        echo 'echo "MASTER_ADDR: ${MASTER_ADDR}"'
        echo 'echo "MASTER_PORT: ${MASTER_PORT}"'
        echo 'echo "WORLD_SIZE: ${WORLD_SIZE} (${SLURM_NNODES} nodes x '"$GPUS_PER_NODE"' GPUs)"'
        echo 'echo "Nodes: ${SLURM_JOB_NODELIST}"'
    else
        echo 'echo "Job started on $(hostname) at $(date)"'
        echo 'echo "Working directory: $(pwd)"'
    fi
    echo ""

    # GPU check
    if [[ $GPU_COUNT -gt 0 ]]; then
        echo "# -- GPU check ------------------------------------------------------------------"
        echo 'echo "=== GPU Information ==="'
        if [[ $NODES -gt 1 ]]; then
            echo "srun --ntasks-per-node=1 nvidia-smi"
        else
            echo "nvidia-smi"
        fi
        echo 'echo "======================="'
        echo ""
    fi

    # Run section
    echo "# -- Run ------------------------------------------------------------------------"
    echo "# TODO: Add your commands here"

    if [[ "$FRAMEWORK" == "pytorch" && $GPU_COUNT -gt 0 ]]; then
        if [[ $NODES -gt 1 ]]; then
            cat <<TORCHRUN
srun torchrun \\
    --nnodes=\${SLURM_NNODES} \\
    --nproc_per_node=$GPUS_PER_NODE \\
    --rdzv_id=\${SLURM_JOB_ID} \\
    --rdzv_backend=c10d \\
    --rdzv_endpoint=\${MASTER_ADDR}:\${MASTER_PORT} \\
    train.py
TORCHRUN
        elif [[ $GPU_COUNT -gt 1 ]]; then
            echo "torchrun --nproc_per_node=$GPU_COUNT train.py"
        else
            echo "# python train.py"
        fi
    elif [[ "$FRAMEWORK" == "tensorflow" && $GPU_COUNT -gt 0 ]]; then
        echo "# python train.py"
    else
        echo "# python my_script.py"
    fi

    echo ""
    echo 'echo "Job finished at $(date)"'
    echo ""

    # Resource usage report
    echo "# -- Resource usage report -------------------------------------------------------"
    echo 'seff $SLURM_JOB_ID'
}

# ── Output ─────────────────────────────────────────────────────────────────────

if [[ -n "$OUTPUT_FILE" ]]; then
    generate > "$OUTPUT_FILE"
    chmod +x "$OUTPUT_FILE"
    echo "Script written to: $OUTPUT_FILE"
else
    generate
fi
