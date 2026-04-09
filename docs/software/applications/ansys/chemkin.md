# Chemkin Pro

ANSYS Chemkin Pro provides tools for fast, accurate combustion and reaction flow simulations. For detailed information and training resources, please visit the [Ansys Chemkin Pro Documentation](https://www.ansys.com/en-gb/products/fluids/ansys-chemkin-pro).

## Running Chemkin

### Interactive usage

For development and testing with graphical interface (requires X11 forwarding), on the login node:

```bash
module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host
run_chemkin.sh Pro
```

### Batch jobs

For production runs, create a job script:

```bash
#!/bin/bash
#SBATCH --job-name=chemkin_job
#SBATCH --time=01:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=8

module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host

# Run your Chemkin simulation
run_chemkin.sh -batch input.inp
```

:::{note}
For optimal performance, adjust the number of tasks (`--ntasks`) and memory (`--mem`) based on your simulation requirements.
:::
