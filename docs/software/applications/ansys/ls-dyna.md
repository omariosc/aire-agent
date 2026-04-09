# LS-DYNA

Ansys LS-DYNA is the industry-leading explicit simulation software used for applications like drop tests, impact and penetration, smashes and crashes, occupant safety, and more. More information about LS-DYNA can be found on the [LS-DYNA website](https://www.ansys.com/en-gb/products/structures/ansys-ls-dyna).

## Running LS-DYNA

LS-DYNA can be run in two modes: **SMP (Shared Memory Processing)** and **MPP (Massively Parallel Processing)**. The choice of mode depends on the size and complexity of your simulation. SMP is suitable for smaller problems that can efficiently utilise up to 8 cores on a single node, while MPP is designed for larger problems that require distributed memory and can scale across multiple nodes.

Guidance provided by Oasys suggests that SMP can scale to ~8 cores, and that the MPP version should be used for larger problems.

Remember to replace `port@host` with the appropriate license server details.

### SMP single precision

```bash
#!/bin/bash
#SBATCH --job-name=lsdyna_smp_sp
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4

module add ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host
export LSTC_LICENSE=ANSYS

lsdyna i=example.k ncpu=$SLURM_CPUS_PER_TASK
```

### SMP double precision

```bash
#!/bin/bash
#SBATCH --job-name=lsdyna_smp_dp
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4

module add ansys/2023R1
export ANSYSLMD_LICENSE_FILE=port@host
export LSTC_LICENSE=ANSYS

lsdyna -dp i=example.k ncpu=$SLURM_CPUS_PER_TASK
```

<!-- ### MPP single precision

```bash
#!/bin/bash
#SBATCH --job-name=lsdyna_mpp_sp
#SBATCH --time=04:00:00
#SBATCH --mem=256G
#SBATCH --nodes=1
#SBATCH --ntasks=168

module add ansys/2023R1
export ANSYSLMD_LICENSE_FILE=port@host
export LSTC_LICENSE=ANSYS

lsdyna -dis -np $SLURM_NTASKS -lsdynampp i=example.k
``` -->

### MPP

```bash
#!/bin/bash
#SBATCH --job-name=lsdyna_mpp
#SBATCH --time=04:00:00
#SBATCH --mem-per-cpu=4G
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1

module add ansys/2023R2

export ANSYSLMD_LICENSE_FILE=port@host
export LSTC_LICENSE=ANSYS

export PATH=$ANSYSDIR/ansys/bin/linx64:$PATH
export PATH=$ANSYSDIR/commonfiles/MPI/Intel/2021.8.0/linx64/bin:$PATH

SOLVER=lsdyna_dp_mpp.e
INPUT=main.k

mpirun $SOLVER i=$INPUT memory=1000m
```

:::{note}
For optimal performance:

- Use the SMP version for smaller problems that can efficiently utilise up to 8 cores on a single node.
- Use the MPP version for larger problems that require distributed memory and can scale across multiple cores or nodes.
- Adjust the number of CPUs (`--cpus-per-task`), memory (`--mem`), and tasks (`--ntasks`) based on your simulation requirements.
:::
