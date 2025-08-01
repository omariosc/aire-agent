# CASTEP

CASTEP is popular software package for calculating electronic properties of matter using density functional theory (DFT) methods. For usage instructions and tutorials, please see the [official documentation](https://castep-docs.github.io/castep-docs/).

## Available versions on Aire

CASTEP 25.12 is available on Aire. There are two builds, depending on whether the user requires serial or parallel (threaded and MPI) execution:

| Version        | Load Command               |
|----------------|----------------------------|
| serial   | `module load castep/25.12/gcc-13.2.0_cuda-12.6.2_fftw-3.3.10_openblas-0.3.28` |
| parallel | `module load castep/25.12/gcc-13.2.0_cuda-12.6.2_fftw-3.3.10_openmpi-5.0.6_openblas-0.3.28` |

## How to submit a job

### Serial jobs

```bash
#!/bin/bash
#SBATCH --job-name=castep_serial_job
#SBATCH --time=01:00:00
#SBATCH --mem=1G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

module load castep/25.12/gcc-13.2.0_cuda-12.6.2_fftw-3.3.10_openblas-0.3.28

# Run the job
castep.serial input_files
```

### Parallel jobs

Requesting 8 cores on a single node:

```bash
#!/bin/bash
#SBATCH --job-name=castep_threaded_job
#SBATCH --time=01:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8

module purge
module load castep/25.12/gcc-13.2.0_cuda-12.6.2_fftw-3.3.10_openmpi-5.0.6_openblas-0.3.28

# Run the job
mpirun castep.mpi input_files
```

Requesting all cores and memory across two nodes:

```bash
#!/bin/bash
#SBATCH --job-name=castep_mpi_job
#SBATCH --time=01:00:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=168

module purge
module load castep/25.12/gcc-13.2.0_cuda-12.6.2_fftw-3.3.10_openmpi-5.0.6_openblas-0.3.28

# Run the job
mpirun castep.mpi input_files
```