# OpenFOAM

OpenFOAM is an open-source computational fluid dynamics (CFD) toolbox widely used for simulating fluid flow, turbulence, heat transfer, and other complex physical processes. For more details, refer to the [official OpenFOAM documentation](https://www.openfoam.com/documentation).

## Available Versions on Aire

| Version  | Command                      |
|----------|------------------------------|
| v2412    | `module load openfoam/v2412` |

## How to Submit a Job

Below are examples of job submission scripts for running OpenFOAM on Aire.

### Serial jobs

For small-scale simulations or testing purposes, you can run OpenFOAM in serial mode:

```bash
#!/bin/bash
#SBATCH --job-name=openfoam_serial
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks=1

module load openfoam/v2412

# Generate the mesh
blockMesh > log.blockMesh

# Run your OpenFOAM case
simpleFoam > log.simpleFoam
```

### Parallel jobs

For larger simulations, OpenFOAM can be run in parallel using MPI. Below are examples for running a 16-core job on a single node and a multi-node job.

#### Single-node jobs

For a 16-core job on a single node:

```bash
#!/bin/bash
#SBATCH --job-name=openfoam_parallel
#SBATCH --time=01:00:00
#SBATCH --mem=128G
#SBATCH --nodes=1
#SBATCH --ntasks=16

module load openfoam/v2412

# Decompose the domain for parallel execution
decomposePar

# Run the simulation in parallel
mpirun -np $SLURM_NTASKS simpleFoam -parallel > log.simpleFoam

# Reconstruct the results after the simulation
reconstructPar
```

#### Multi-node jobs

For a multi-node job, adjust the script to request multiple nodes and distribute tasks across them:

```bash
#!/bin/bash
#SBATCH --job-name=openfoam_multi_node
#SBATCH --time=04:00:00
#SBATCH --mem=256G
#SBATCH --nodes=2
#SBATCH --ntasks=64
#SBATCH --ntasks-per-node=32

module load openfoam/v2412

# Decompose the domain for parallel execution
decomposePar

# Run the simulation in parallel across multiple nodes
mpirun -np $SLURM_NTASKS simpleFoam -parallel > log.simpleFoam

# Reconstruct the results after the simulation
reconstructPar
```

:::{note}

- Single-node job: Ensure `--ntasks` matches the number of cores available on the node.
- Multi-node job: Adjust `--nodes`, `--ntasks`, and `--ntasks-per-node` based on the number of nodes and cores per node.
- Ensure your `decomposeParDict` file is configured to match the total number of tasks (`$SLURM_NTASKS`).
:::
