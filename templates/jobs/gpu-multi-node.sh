#!/bin/bash
#SBATCH --job-name=gpu-multi-node
#SBATCH --partition=gpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --gres=gpu:3
#SBATCH --time=12:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

# ── Load modules ────────────────────────────────────────────────────────────
module load cuda/12.6.2
module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

# ── PyTorch environment variables ───────────────────────────────────────────
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export TORCH_CUDNN_V8_API_ENABLED=1
export CUDNN_BENCHMARK=1
export CUDA_LAUNCH_BLOCKING=0

# ── Multi-node setup ───────────────────────────────────────────────────────
export MASTER_ADDR=$(scontrol show hostnames ${SLURM_JOB_NODELIST} | head -n 1)
export MASTER_PORT=29500
export WORLD_SIZE=$((SLURM_NNODES * 3))

echo "Job started at $(date)"
echo "MASTER_ADDR: ${MASTER_ADDR}"
echo "MASTER_PORT: ${MASTER_PORT}"
echo "WORLD_SIZE: ${WORLD_SIZE} (${SLURM_NNODES} nodes x 3 GPUs)"
echo "Nodes: ${SLURM_JOB_NODELIST}"

# ── GPU check ───────────────────────────────────────────────────────────────
echo "=== GPU Information ==="
srun --ntasks-per-node=1 nvidia-smi
echo "======================="

# ── Run with srun + torchrun (2 nodes x 3 GPUs = 6 total) ──────────────────
# TODO: Add your training script
srun torchrun \
    --nnodes=${SLURM_NNODES} \
    --nproc_per_node=3 \
    --rdzv_id=${SLURM_JOB_ID} \
    --rdzv_backend=c10d \
    --rdzv_endpoint=${MASTER_ADDR}:${MASTER_PORT} \
    train.py

echo "Job finished at $(date)"

# ── Resource usage report ───────────────────────────────────────────────────
seff $SLURM_JOB_ID
