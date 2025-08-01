<!--remember to link to dependency management bit here -->
# Miniforge
<!-- Brief introduction -->
Miniforge contains minimal versions of the conda and mamba environment and package managers, with specificity to conda-forge. It allows users to create and manage virtual environments with packages from the conda-forge repository. Documentation for the conda-forge project is available [here](https://conda-forge.org/docs/) and a reference for the conda package manager is [here.](https://docs.conda.io/en/latest/index.html)

:::{note}
Please see the creating environments section of the [dependency management](dependency-management) article for further instructions and advice on how to create conda environments using Miniforge, including Python and R enviroments
:::

## Available versions on Aire
<!-- List the available versions of Miniforge on Aire in a table format -->
| Version  | Load Command                     |
|----------|----------------------------------|
| 24.7.1   | `module load miniforge/24.7.1`   |

## Creating a new environment
<!-- Instructions on how to create a new environment using Miniforge -->
To create an environment from a pre-defined `.yml` file, use the following command:

```bash
conda env create -f environment.yml
```

Please see the [creating environments](creating-environment) section of the dependency management article for further instructions and advice on how to create conda environments using miniforge. 

## Activating an environment
<!-- Instructions on how to activate an environment -->
To activate an environment (`myenv`, in this example), use the following command:

```bash
conda activate myenv
```

## Deactivating an environment
<!-- Instructions on how to deactivate an environment -->
To deactivate an environment, use the following command:

```bash
conda deactivate myenv
```

## Submitting a job with Miniforge
<!-- Instructions on how to submit a job using a Miniforge managed conda environment -->
The below job script requests 8 CPU cores for a Python script run within the conda environment `myenv`. 

```bash
#!/bin/bash
#SBATCH --job-name=miniforge_job
#SBATCH --output=output_%j.out
#SBATCH --error=error_%j.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8

module load miniforge/24.7.1
conda activate myenv

# Run your application
python my_script.py
```





