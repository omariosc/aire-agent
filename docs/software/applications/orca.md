# ORCA

ORCA is a powerful and flexible quantum chemistry software package widely used for electronic structure calculations, including density functional theory (DFT), semi-empirical methods, and ab initio calculations. It supports a broad range of molecular systems and advanced features such as spectroscopy simulations and transition metal chemistry.

## Available versions on Aire

| Version  | Load Command               |
|----------|----------------------------|
| 6.0.1    | `module load orca/6.0.1`   |

## How to submit a job

ORCA can be run in both serial and parallel modes on Aire. While serial jobs are uncommon (typically used for short tests or calibration), parallel execution is recommended for production runs. Below are example Slurm scripts for each mode.

### Serial jobs

```bash
#!/bin/bash
#SBATCH --job-name=orca_serial
#SBATCH --time=01:00:00
#SBATCH --mem=64G

module load orca/6.0.1

ORCA=$(which orca)

$ORCA /path/to/your/input.inp > my_output.out
```

### Parallel jobs (OpenMP)

```bash
#!/bin/bash
#SBATCH --job-name=orca_openmp
#SBATCH --time=02:00:00
#SBATCH --mem=128G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64

module load orca/6.0.1

ORCA=$(which orca)

$ORCA /path/to/your/input.inp > my_output.out
```

### Parallel jobs (MPI)

```bash
#!/bin/bash
#SBATCH --job-name=orca_mpi
#SBATCH --time=02:00:00
#SBATCH --mem=128G
#SBATCH --nodes=2
#SBATCH --ntasks=128
#SBATCH --cpus-per-task=1

module load orca/6.0.1

ORCA=$(which orca)

$ORCA /path/to/your/input.inp > my_output.out
```

```{admonition} Notes on the parallelisation
- The number of MPI parallel processes (`NPROCS`) must be specified in your ORCA input file and should match the total number of processes requested in your Slurm script (`nodes × ntasks-per-node`).  
- Set `%MaxCore` in your ORCA input to match the memory per core. For example, if you request 256GB of memory and 64 cores, use `%MaxCore 4000` (256GB / 64 cores = 4000 MB per core).
```
