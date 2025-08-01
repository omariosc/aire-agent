# Ansys CLI

Once the license and module have been set up correctly, Ansys Command-Line Interface (CLI) can be run both in serial and in parallel.

## Running Ansys CLI in serial

There are three ways in which to launch Ansys CLI in serial:

- On login nodes
- As an interactive session
- As a batch job

### Using on login nodes

:::{warning}
Please note you should not run full experiments on the login nodes. Only use this method for quick tests, or interactive exploring of the tool.
:::

Once the Ansys module is loaded, Ansys can be run using a command with the version number included in the executable name:

```bash
module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host
ansys232 -g
```

If you need to run Ansys 2024R2, replace `ansys232` with `ansys242` and load the corresponding module. This runs the application graphically, so it is essential to enable X11 forwarding to display the graphical interface. You can use tools like MobaXterm or enable X11 forwarding via SSH with the `-Y` option.

### Running through the batch queues

When running through the batch queues, no interactive input is possible. Create a journal file which contains all the commands that would normally be entered within Ansys CLI, similar to how it works with Fluent.

Here's an example job submission script:

```bash
#!/bin/bash
#SBATCH --job-name=ansys_serial
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host

ansys232 -p ANSYS -b -i example.inp -o example.out
```

In this case, we're running the Ansys CLI with:

| Syntax           | Description |
| -----------      | ----------- |
| `-p ANSYS`       | Start using the ANSYS product |
| `-b`             | Run in batch mode             |
| `-i example.inp` | Use example.inp input file    |
| `-o example.out` | Use example.out output file   |

## Running Ansys CLI in parallel

Here's an example parallel job submission script:

```bash
#!/bin/bash
#SBATCH --job-name=ansys_parallel
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1

module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host

ansys232 -np $SLURM_NTASKS -p ANSYS -b -i example.inp -o example.out
```

Submit the job to the queue:

```bash
sbatch ansys.sh
```

## GPU execution using the batch queues

:::{note}
The GPU acceleration with the NVIDIA L40S GPUs is currently under testing for compatibility and performance with Ansys 2023R2 and 2024R2.
:::

<!-- Ansys supports GPU acceleration. Here's an example GPU job submission script:

```bash
#!/bin/bash
#SBATCH --job-name=ansys_gpu
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1

module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host

ansys232 -np $SLURM_NTASKS -acc nvidia -na 1 -p ANSYS -b -i example.inp -o example.out
```

Submit the job to the queue:

```bash
sbatch ansys.sh
```

:::{admonition} GPU performance
You should verify that using GPU acceleration provides significant performance advantages compared to running a standard CPU job. Please share your experiences with GPU acceleration, as performance benefits can vary depending on the specific workload.
::: -->
