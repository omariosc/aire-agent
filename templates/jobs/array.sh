#!/bin/bash
#SBATCH --job-name=array
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --array=1-100
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

# ── Load conda ──────────────────────────────────────────────────────────────
module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

echo "Job started on $(hostname) at $(date)"
echo "Working directory: $(pwd)"
echo "Array Job ID: ${SLURM_ARRAY_JOB_ID}"
echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"

# ── Run ─────────────────────────────────────────────────────────────────────
# Use $SLURM_ARRAY_TASK_ID to select data, configs, or parameters
# Example: python process.py --task-id ${SLURM_ARRAY_TASK_ID}

# TODO: Add your commands here
# python my_script.py --index ${SLURM_ARRAY_TASK_ID}

echo "Job finished at $(date)"

# ── Resource usage report ───────────────────────────────────────────────────
seff $SLURM_JOB_ID
