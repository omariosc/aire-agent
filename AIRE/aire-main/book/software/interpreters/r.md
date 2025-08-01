# R
<!-- Brief introduction -->
R is a programming language and free software environment for statistical computing and graphics. [Official Documentation](link_to_official_documentation)

## Available versions on Aire
<!-- List the available versions of R on Aire in a table format -->
| Version | Load Command                |
|---------|-----------------------------|
| X.Y.Z   | `module load r/X.Y.Z`       |
| A.B.C   | `module load r/A.B.C`       |

:::{note}
Users can install different R versions with a Conda environment. See the [Dependency Management](../../usage/dependency_management.md) section for more details.
:::

## Launching R on the front end
<!-- Instructions on how to launch R on the front end and how to quit it -->
To launch R on the front end, use the following command:

```bash
R
```

To quit R, use the following command within the R console:

```bash
q()
```

## Running R through an interactive shell
<!-- Instructions on how to run R through an interactive shell -->
To run R through an interactive shell, use the following command:

```bash
srun --time=01:00:00 --mem=4G --pty bash
module load r/X.Y.Z
R
```
<!-- Review this. -->

## Submitting a job with R
<!-- Instructions on how to submit a job using R -->
To submit a job using R, use the following Slurm job script:

```bash
#!/bin/bash
#SBATCH --job-name=r_job
#SBATCH --output=output.log
#SBATCH --error=error.log
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8

module load r/X.Y.Z

# Run your R script
Rscript my_script.R
```

## Installing R packages within R
<!-- Instructions on how to install R packages within R -->
To install R packages within R, use the following command within the R console:

```bash
install.packages("package_name")
```

This will install the package and any dependencies that are required. It will do this by creating a local library (in your home directory by default) where it saves the package binaries and archives. The package should then be accessible from subsequent R interactive sessions and batch jobs.

If you’re using a conda installed version of R, these will install into your conda environment instead.
<!-- Review this. -->