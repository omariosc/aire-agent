#!/bin/bash
#SBATCH --job-name=cpu-mpi
#SBATCH --partition=cpu
#SBATCH --nodes=2
#SBATCH --ntasks=256
#SBATCH --ntasks-per-node=128
#SBATCH --time=02:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

# ── Load modules ────────────────────────────────────────────────────────────
module load openmpi
module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

echo "Job started on $(hostname) at $(date)"
echo "Working directory: $(pwd)"
echo "Nodes: ${SLURM_JOB_NODELIST}"
echo "Total tasks: ${SLURM_NTASKS}"

# ── Run ─────────────────────────────────────────────────────────────────────
# TODO: Add your commands here
# mpirun -np ${SLURM_NTASKS} python my_mpi_script.py
mpirun python my_mpi_script.py

echo "Job finished at $(date)"

# ── Resource usage report ───────────────────────────────────────────────────
seff $SLURM_JOB_ID
