# Job Examples

By default, jobs are automatically assigned default resources:

- 1 CPU core
- 1GB memory
- Execution on the standard compute node pool

Users must always specify a time limit, either at submission or in their job script. The [official Slurm documentation](https://slurm.schedmd.com/documentation.html) is maintained by SchedMD, the developers of Slurm, and so provides a good starting point for anyone who wants to explore the topic in more depth.

In the following examples, we demonstrate job scripts for running jobs on various configurations of resources.

## Serial jobs

The following script requests 1 CPU, 1 hour of runtime, and 1GB memory, specifying the job name as `serial_job`. Here we explicitly set the number of tasks and the number of cores to 1, but this is not strictly necessary as they are the default settings.

```bash
#!/bin/bash
#SBATCH --job-name=serial_job
#SBATCH --time=01:00:00
#SBATCH --mem=1G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

# Load any necessary modules
module load <module_name>

# Run the job
./example.bin
```

This script demonstrates how to request 1 CPU, 1 day of runtime, and 32GB of memory for a serial job. It also specifies the locations for the output and error files, which is helpful for troubleshooting. The variable `%j` is automatically replaced with the job ID, making it easier to organise output and error files for multiple jobs.

```bash
#!/bin/bash
#SBATCH --job-name=serial_job         # Descriptive job name
#SBATCH --output=output_%j.out        # Output file (%j = job ID)
#SBATCH --error=error_%j.err          # Error file (%j = job ID)
#SBATCH --time=1-00:00:00             # Request 1 day of runtime
#SBATCH --mem=32G                     # Request 32GB of memory

# Load any necessary modules
module load <module_name>

# Run the job
./example.bin
```

## Parallel jobs

Parallel jobs include those run over multiple cores within the same node (SMP, typically via OpenMP) or across multiple nodes via a message passing interface (MPI) such as Open MPI.

:::{note}
Note that in order to use more than one CPU (or core), your program must be specifically written to use a parallel programming model. Just requesting more CPUs in Slurm will not make the program use more than 1 CPU; the extra CPUs you reserved will sit idle.
:::

### Threaded

Here we request 16 cores within a single node for 2 hours. Note that jobs will need to be compiled for execution on multiple threads (e.g., via OpenMP) or run on multithreading-capable software; the below example is for a binary compiled for OpenMP.

```bash
#!/bin/bash
#SBATCH --job-name=threaded_job
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1          # Number of tasks for OpenMP
#SBATCH --cpus-per-task=16  # Number of CPU cores per task

# Load any necessary modules
module load <module_name>

# Tell OpenMP how many resources it has been given
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# Run the job
./example.bin
```

:::{note}
To optimise performance, it is sometimes worth exploring additional OpenMP options such as:

    export OMP_PLACES=cores
    export OMP_PROC_BIND=close

These settings can help improve thread placement and binding, potentially speeding up your code.
:::

### MPI

These are jobs that run across multiple nodes using a Message Passing Interface (MPI). In the following example, we request 256 MPI processes across 2 nodes, with 128 tasks per node:

```bash
#!/bin/bash
#SBATCH --job-name=MPI_job
#SBATCH --time=04:00:00
#SBATCH --mem=256G              # Request 256GB memory per node
#SBATCH --ntasks=256            # Number of MPI processes
#SBATCH --nodes=2               # Number of nodes
#SBATCH --ntasks-per-node=128   # Number of tasks per node

# Load any necessary modules, e.g. MPI
module load openmpi

# Run the job
mpirun ./example.bin
```

## AI/ML jobs on GPU

This example shows how to run a PyTorch job in a Conda environment on Aire, which uses Miniforge as the Conda installer. To request GPUs, make sure to specify the gpu partition in your Slurm script with `#SBATCH --partition=gpu`. Then, request the number of GPUs you need using `#SBATCH --gres=gpu:N`, where `N` is the number of GPUs; for instance, `#SBATCH --gres=gpu:1` for one GPU or `#SBATCH --gres=gpu:2` for two GPUs.

```bash
#!/bin/bash
#SBATCH --job-name=ml_job          # Job name
#SBATCH --time=01:00:00            # Request runtime (hh:mm:ss)
#SBATCH --partition=gpu            # Request GPU partition
#SBATCH --gres=gpu:1               # Request 1 GPU

# Load any necessary modules, e.g. Miniforge
# Activate conda environment
module load miniforge
conda activate my_ML_environment

# Run the job
python my_ML_script.py
```

```{tip}
Requesting 1 GPU defaults to using 1 CPU core and 1GB memory for your job. If you need more CPU cores and memory, you need to request them separately using additional SBATCH directives. On one GPU node, there are 24 CPU cores and 256GB memory total, with resources divided among 3 GPUs (approximately 8 cores and 85GB memory available per GPU). For example, to request 8 CPU cores with 8GB memory per core (32GB total):

    #SBATCH --cpus-per-task=4          # Request 4 CPU cores
    #SBATCH --mem-per-cpu=8G           # Request 8GB memory per CPU core
```

```{admonition} Using the Flash storage
Aire provides temporary Flash storage (`$TMP_SHARED`) for high I/O performance during job execution. This NVMe storage has a quota of 1TB and 1.5M files per job, making it ideal for I/O-intensive workloads like ML/AI. Data is automatically purged when the job ends. Request Flash storage in your job script:

    #!/bin/bash
    #SBATCH --job-name=gpu_flash       # Job name
    #SBATCH --time=01:00:00            # Request runtime (hh:mm:ss)
    #SBATCH --partition=gpu            # Request GPU partition
    #SBATCH --gres=gpu:1               # Request 1 GPU
    #SBATCH --cpus-per-task=4          # Request 4 CPU cores
    #SBATCH --mem-per-cpu=8G           # Request 8GB memory per CPU core

    # Flash storage path is automatically set as $TMP_SHARED
    echo "Flash storage path: $TMP_SHARED"

    # Copy input data to Flash storage
    cp -r /path/to/input/data $TMP_SHARED/

    # Load GPU environment
    module load miniforge
    conda activate my_ML_environment

    # Run GPU job using local data
    python my_ML_script.py --data $TMP_SHARED/data

    # Copy results back to permanent storage
    cp -r $TMP_SHARED/results /path/to/permanent/storage/

    # Flash storage ($TMP_SHARED) is automatically cleaned after the job ends
```

## Large-memory jobs

Here we request use of a high-memory node to run threaded application via OpenMP. Note that the option `--mem` applies to the amount of memory requested *per node*.

```bash
#!/bin/bash
#SBATCH --job-name=large_memory_job
#SBATCH --time=01:00:00
#SBATCH --partition=himem   # Request high-memory node
#SBATCH --mem=160G          # Request 160GB memory (10GB per core)
#SBATCH --nodes=1
#SBATCH --ntasks=1          # Number of tasks for OpenMP
#SBATCH --cpus-per-task=16  # Number of CPU cores per task

# Tell OpenMP how many resources it has been given
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# Run the job
./example.bin
```

## Job arrays

Job arrays let you run a set of independent jobs with a single submission. Slurm creates multiple instances of the job, and each instance can use different parameters or data. The example script below runs 100 jobs in a Conda environment, with input and output files determined by the array index `$SLURM_ARRAY_TASK_ID`. Job arrays are compatible with many workflows, making them a flexible option for parameter sweeps or batch processing.

```bash
#!/bin/bash
#SBATCH --job-name=task_array_job
#SBATCH --time=01:00:00
#SBATCH --array=1-100%10             # Run job array with indices 1 to 100, allowing up to 10 jobs to run concurrently
#SBATCH --output=arrayjob_%A_%a.out  # Save output to a file named with job ID (%A) and array index (%a)


# Load any necessary modules
# e.g. using a conda environment
module load miniforge
conda activate my_environment

# Run the job, passing in the input and output filenames
python -i $SCRATCH/input/input.$SLURM_ARRAY_TASK_ID -o $SCRATCH/results/out.$SLURM_ARRAY_TASK_ID
```

## Task arrays (multiple tasks in one job)
Unlike job arrays, which submit many independent jobs, a task array refers to running multiple tasks within a single Slurm job allocation. This is common for MPI jobs or parallel programs where tasks need to communicate.

Slurm uses the `--ntasks` option to specify the number of tasks. All tasks share the same environment and resources, making this ideal for tightly coupled workloads.

```bash
#!/bin/bash
#SBATCH --job-name=task_example
#SBATCH --output=task_%j.out
#SBATCH --error=task_%j.err
#SBATCH --ntasks=10 # 10 tasks in one job
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH --mem=20G

module load openmpi
echo "Running MPI job with $SLURM_NTASKS tasks"
srun ./my_mpi_program
```
