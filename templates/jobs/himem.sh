#!/bin/bash
#SBATCH --job-name=himem
#SBATCH --partition=himem
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=500G
#SBATCH --time=04:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

# ── Load conda ──────────────────────────────────────────────────────────────
module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

echo "Job started on $(hostname) at $(date)"
echo "Working directory: $(pwd)"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Memory requested: 500G"

# ── Run ─────────────────────────────────────────────────────────────────────
# TODO: Add your commands here
# python my_memory_intensive_script.py

echo "Job finished at $(date)"

# ── Resource usage report ───────────────────────────────────────────────────
seff $SLURM_JOB_ID
