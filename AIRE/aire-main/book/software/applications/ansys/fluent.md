# Fluent

Once the license and module have been set up correctly, Fluent can be run both in serial and in parallel. We generally recommend running Fluent either in serial for short test jobs or in parallel on whole nodes to ensure consistent good performance.

## Running Fluent in serial

### Using on login nodes

Once the Ansys module is loaded and the license has been set up, Fluent can be run by entering its name at the command prompt:

```bash
module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host
fluent
```

This runs the application graphically, so it is essential to enable X11 forwarding to display the graphical interface. You can use tools like MobaXterm or enable X11 forwarding via SSH with the `-Y` option.

### Batch jobs

For production runs, create a journal file (`test.jou`) containing the commands to be executed in Fluent. For example:

```text
file/read-case input.cas
file/read-data input.dat
solve iter 100
/file/write-data output.dat
y
/exit
y
```

Then, create a job submission script as follows:

```bash
#!/bin/bash
#SBATCH --job-name=fluent_serial
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks=1

module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host

fluent 3ddp -g -i test.jou
```

## Running Fluent in parallel

### Batch jobs

For parallel execution, create a journal file (`test_parallel.jou`) to control the run. For example:

```text
file/read-case test_parallel.cas
file/read-data test_parallel.dat
solve iter 500
/file/write-data test_parallel_result.dat
y
/exit
y
```

#### Single-node job

For a 16-core job on a single node, use the following job submission script:

```bash
#!/bin/bash
#SBATCH --job-name=fluent_parallel
#SBATCH --time=01:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=16

module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host

fluent 3ddp -t$SLURM_NTASKS -g -i test_parallel.jou 
```

#### Multi-node jobs

:::{note}
Multi-node job execution for Fluent is currently under evaluation on Aire to ensure compatibility and performance.
:::

<!-- For larger simulations requiring multiple nodes, adjust the script to request multiple nodes and distribute tasks across them:

```bash
#!/bin/bash
#SBATCH --job-name=fluent_multi_node
#SBATCH --time=02:00:00
#SBATCH --mem=128G
#SBATCH --nodes=2
#SBATCH --ntasks=64
#SBATCH --ntasks-per-node=32

module load ansys/2023R2
export ANSYSLMD_LICENSE_FILE=port@host

# Run Fluent in parallel across multiple nodes
fluent 3ddp -t$SLURM_NTASKS -g -i test_parallel.jou
``` -->

```{admonition} Exporting Fluent plots in batch jobs
In batch jobs, Fluent cannot display windows, figures, or animations due to the lack of a display. To export images or animations, include the `-gu` and `-driver null` arguments in your Fluent command. For example:

    fluent 3ddp -t$SLURM_NTASKS -gu -i test.jou -driver null

Set up plots or graphs in your journal file or interactively via the GUI, saving the case file. Use the following command in your journal file to export images:

    /display/hard-copy "output.tif"

Ensure the correct file format is selected, as some formats may not support animations.
```

## GPU execution using the batch queues

:::{note}
The GPU acceleration with the NVIDIA L40S GPUs is currently under testing for compatibility and performance with Ansys 2023R2 and 2024R2.
:::

<!-- Fluent supports GPU acceleration. To submit a GPU job, create a job script (`fluent_gpu.sh`) as follows:

```bash
#!/bin/bash
#SBATCH --job-name=fluent_gpu
#SBATCH --time=01:00:00
#SBATCH --mem=128G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1

module load ansys/2023R2
module load cuda/12.6.2
export ANSYSLMD_LICENSE_FILE=<port>@<host>

# --- Configure GPU settings for Fluent ---
export FLUENT_GPU=1
export CUDA_VISIBLE_DEVICES=0

fluent 3ddp -g -i input.jou -t$SLURM_CPUS_PER_TASK -driver gpu
```

:::{note}
For GPU jobs, ensure you specify the `gpu` partition in Slurm (`--partition=gpu`). Adjust the memory (`--mem`) and GPU resources (`--gres=gpu`) based on your simulation requirements.
::: -->
