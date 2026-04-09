# CFX

Ansys CFX is a high-performance, general purpose fluid dynamics application. For detailed information and training resources, please visit:

- [Ansys CFX Documentation](https://www.ansys.com/en-GB/Products/Fluids/ANSYS-CFX)
- [Ansys Training Center](https://www.ansys.com/Services/Training-Center)

## Running CFX

### Interactive usage

For development and testing with graphical interface (requires X11 forwarding), on the login node:

```bash
module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host
cfx5
```

### Batch jobs

For production runs, create a job script:

```bash
#!/bin/bash
#SBATCH --job-name=cfx
#SBATCH --time=01:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=8

module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host

cfx5solve -def simulation.def -par-local -part $SLURM_NTASKS
```

:::{note}
For optimal performance, adjust the number of tasks (`--ntasks`) and memory (`--mem`) based on your simulation requirements.
:::
