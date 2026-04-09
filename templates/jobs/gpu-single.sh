#!/bin/bash
#SBATCH --job-name=gpu-single
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
#SBATCH --gres=gpu:1
#SBATCH --time=04:00:00
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

echo "Job started on $(hostname) at $(date)"
echo "Working directory: $(pwd)"

# ── GPU check ───────────────────────────────────────────────────────────────
echo "=== GPU Information ==="
nvidia-smi
echo "======================="

# ── Run ─────────────────────────────────────────────────────────────────────
# TODO: Add your commands here
# python train.py

echo "Job finished at $(date)"

# ── Resource usage report ───────────────────────────────────────────────────
seff $SLURM_JOB_ID
