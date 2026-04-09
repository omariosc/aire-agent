#!/bin/bash
#SBATCH --job-name=cpu-threaded
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

# ── Load conda ──────────────────────────────────────────────────────────────
module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

# ── OpenMP configuration ────────────────────────────────────────────────────
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
export OMP_PLACES=cores
export OMP_PROC_BIND=close

echo "Job started on $(hostname) at $(date)"
echo "Working directory: $(pwd)"
echo "OMP_NUM_THREADS: ${OMP_NUM_THREADS}"

# ── Run ─────────────────────────────────────────────────────────────────────
# TODO: Add your commands here
# python my_threaded_script.py

echo "Job finished at $(date)"

# ── Resource usage report ───────────────────────────────────────────────────
seff $SLURM_JOB_ID
