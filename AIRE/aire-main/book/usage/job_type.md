# Job Types

## Batch jobs

The vast majority of jobs that run on Aire will be batch jobs. These are submitted via a job script, which is a shell script (file ending `.sh`), containing the commands to run your job, alongside instructions for the job scheduler (Slurm), detailing the resources required. Slurm will then allocate that job in a position in the job queue, depending on a fair share policy. This policy is not first-come-first-served; resources are allocated fairly between different faculties and users. At a bare minimum, the job script must specify how long the job needs to run for. Unless otherwise directed, Slurm will default to the following settings:

- 1 CPU core
- 1GB memory
- Use of standard compute node pool (No GPU access)

### Writing job scripts

We encourage users to write their job submission scripts using text editor tools available on Aire such as:

- `nano` (recommended for beginners)
- `vim`
- `emacs`

The basic approach to create a new job submission file on HPC would be ```nano job_submit.sh``` or `vim job_submit.sh`. This opens the new empty file in the text editor ready for you to write its contents.

:::{warning}
Job scripts written on Windows computers contain different invisible line ending characters that lead to job submission failures such as `/bin/bash^M: bad interpreter: No such file or directory`.
You can use the command `dos2unix job_script.sh` on Aire to convert your script to the correct line endings.
:::

The [Job Examples](../usage/job_example.md) section contains a collection of job scripts for a range of uses, but a simple demonstration script is provided below. In this example named `job_script1.sh` we are requesting an hour of time, 1GB of memory, and a single CPU core to run an example binary file `example.bin` in the current directory.

```bash
#!/bin/bash
#SBATCH --job-name=simple_job   # Job name
#SBATCH --time=01:00:00         # Request runtime (hh:mm:ss)
#SBATCH --mem=1G                # Request memory
#SBATCH --ntasks=1              # Number of tasks
#SBATCH --cpus-per-task=1       # Number of cores per task

# Load any necessary modules
module load <module_name>

# Execute your application
./example.bin
```

The job script specified above includes a number of lines that request some amount of compute resource for our job. This is defined by the syntax `#SBATCH <option>`. These lines are commented out of the shell script but are read by the scheduler to determine how much compute resource is required and thus how to fit the job into the queue. A {ref}`submission-options` is available below, and at the [Job Examples](../usage/job_example.md) page.

### Using the queue

To submit the job script, we use the command `sbatch`:

```bash
$ sbatch job_script1.sh
Submitted batch job 42
```

This returns some text to confirm our job has been submitted and provides us with the job's unique ID number (in this case 42). Arguments can be submitted to Slurm upon job submission, for example:

```bash
$ sbatch -t 1:00:00 job_script1.sh
Submitted batch job 42
```

Commands passed to Slurm in this way will override those in the job script.

We can view the queue status using `squeue`. Use the option `--me` to filter for your own jobs:

```bash
$ squeue --me
JOBID   PARTITION   NAME        USER     ST  TIME NODES  NODELIST(REASON)
42      nodes       simple_job  exuser   R   0:25 10     node[01-10]
43      nodes       other_job   exuser   PD  0:00 16     (resources)
```

Currently running jobs are identified with an `R`; jobs still in the queue show `PD`.

Jobs can be cancelled using `scancel <JOBID>` (in our case, `scancel 42`). Users are only able to cancel their own jobs.

## Task arrays

### When to use task arrays

Situations often arise when you want to run many almost identical jobs simultaneously, perhaps running the same program many times but changing the input data or some argument or parameter. One possible solution is to write a Python or Perl script to create all the job scripts, and then write a BASH script to execute them. This is very time consuming and might end up submitting many more jobs to the queue than you actually need to. Thankfully, this problem is made much easier via Slurm's task array feature:

- Only a single `sbatch` command is issued, and only a single `scancel` command would be required to cancel all jobs
- Only a single entry appears after checking `squeue`
- It is much easier for the user to keep track of their jobs

### How to use task arrays

The easiest way to think of a task array is as a job script with a built-in FOR loop. It makes use of an environment variable created by Slurm - `$SLURM_ARRAY_TASK_ID`. Consider the following job submission script (`task_array_script.sh`) using a Conda environment:

```bash
#!/bin/bash 
# Request 1 hour runtime
#SBATCH --time=01:00:00

# Tell Slurm that this is an array job, with tasks numbered from 1 to 100
#SBATCH --array=1-100

# Load any necessary modules
# e.g. using a conda environment
module load miniforge
conda activate my_environment

# Run the job, passing in the input and output filenames
python –i $SCRATCH/input/input.$SLURM_ARRAY_TASK_ID –o $SCRATCH/results/out.$SLURM_ARRAY_TASK_ID
```

This array job would be submitted as normal using `sbatch task_array_script.sh`.

In this example, input files would be read from the `input` directory, and take the form input.1, input.2, input.3 etc. The program would create output files out.1, out.2, out.3 etc in the `results` directory.

## Interactive jobs

It is also possible to runs jobs in interactive mode on Aire. This means rather than queueing for your job to run on the batch system you request resource for an interactive sessions via the shell.

:::{warning}
We strongly discourage users from using interactive sessions for interactive code development using platforms like jupyter, spyder or Rstudio. Code development should be done before deploying code on the HPC.
:::

Interactive jobs can be started using the `srun` command, as follows:

```bash
[username@login1[aire] ~]$ srun -t 01:00:00 --pty /bin/bash
[username@node016[aire] ~]$
```

Note that it is required to specify a requested runtime, but the scheduler will otherwise adopt the same default resources as for batch jobs. If the requested resources are available, the session will start immediately. If not, the session will immediately exit. Note that once the session has started the prompt changes to show that the interactive session is now running on a specific compute node (in this case, `node016`).

:::{note}
If you have made changes to your environment on the login nodes these will not be preserved when connecting to an interactive session and you will be required to rerun `module load` commands. Connecting to an interactive session creates a new login shell, which means any commands in your .bashrc are executed when you connect.
:::

## GPU

Aire includes general-purpose GPU facilities for GPU-accelerated code. Aire has 17 dedicated GPU nodes, each with 3 NVIDIA L40S GPUs. Login nodes are equipped with entry-level NVIDIA A2 GPUs, which is useful for configuration purposes - note that login nodes should not be used to run jobs in order to skip the queue or work around restrictions for interactive jobs.

### Requesting use of GPU nodes

GPUs can be requested with: `--partition=gpu` and `--gres=gpu:<number>`. For example, a basic submission script requesting a single GPU might look like:

```bash
#!/bin/bash 
#SBATCH --time=01:00:00     # Request runtime (hh:mm:ss)             
#SBATCH --partition=gpu     # Request the GPU partition
#SBATCH --gres=gpu:1        # Request a single GPU

# Load any necessary modules
# module load <module_name>

# Run the job
./example.bin
```

GPUs are also available in interactive mode. For example, requesting an interactive session with two GPUs:

```bash
[username@login1[aire] ~]$ srun -t 01:00:00 -p gpu --gres=gpu:2 --pty /bin/bash
[username@gpu007[aire] ~]$
```

Here, note again that the prompt has changed to tell us that we are now running on a dedicated GPU node.

To use the GPU hardware you will need to ensure the NVIDIA CUDA toolkit module is loaded into your environment, *before* compiling or running code. This can be done explicitly with `module load cuda`, or via an environment manager such as conda (via miniforge on Aire). Again note that changes made to the environment on login nodes will not carry over to compute nodes, so this will be need to be done in the job submission script or after starting an interactive session.

## Large-memory jobs

In extreme cases, it may be required to use more memory than is available on the standard compute nodes (4601 MB per core, or around 773GB total across 168 cores). Aire is equipped with two high-memory nodes for such situations; each node is equipped with 2.32 TB of memory across 168 cores (13.8GB per core).

High-memory nodes are requested in a similar manner to GPU nodes, by using: `--partition=himem`. For example:

```bash
#!/bin/bash
#SBATCH --time=01:00:00       # Request runtime (hh:mm:ss)          
#SBATCH --partition=himem     # Request high-memory node

# Load any necessary modules
module load <module_name>

# Run the job
./example.bin                 
```

(submission-options)=

## List of Slurm submission options

Below is a list of currently available options for submissions to Slurm on Aire. This list is likely to grow as we add and update functionality. Please see the [Job Examples](../usage/job_example.md) page for demonstrations of these options in use.

| Option | Description | Default |
| :---- | :--- | :---- |
| `--time=d-hr:min:s`<br>`-t d-hr:min:s` | The requested wall clock time (amount of real time needed by the job). Failure to include this parameter will result in an error message. | Required |
| `--mem-per-cpu=<size>[units]` | Amount of memory requested **per CPU**. Units are specified with K, M, G, i.e., request 1GB with `--mem=1G`. | 1GB |
| `--mem=<size>[units]` | Total amount of memory allocated **per node**. If the job spans multiple nodes, this value is applied to each node individually. For example, if `--mem=32G` is specified and the job uses 2 nodes, each node will be allocated 32GB of memory, resulting in a total of 64GB across the job. | |
| `--cpus-per-task=<number>`<br>`-c <number>` | Request a number of CPU cores per task, for threaded applications. By default, Slurm will allocate a single processor per task. | 1 |
| `--nodes=<number>`<br>`-N <number>` | Number of nodes requested (for MPI jobs) | 1 |
| `--ntasks=<number>`<br>`-n <number>` | Specifies the total number of tasks (processes) to be launched for the job, typically for MPI-based applications. Each task usually corresponds to an MPI process. For example, `--ntasks=8` will launch 8 processes across the allocated resources. | 1 |
| `--ntasks-per-node=<number>` | Requests a number of tasks to be executed on each node. If used with `--ntasks`, `--ntasks` will take precedence, and `--ntasks-per-node` will be treated as a *maximum* count of tasks per node. | Must be specified for MPI jobs |
| `--job-name=<jobname>`<br>`-J <jobname>` | Specify a job name. | Name of the submission script. |
| `--partition=<name>`<br>`-p <name>` | Requests use specific partitions, for example, `gpu` and `himem`. | |
| `--gres=gpu:<num-gpus>` | Requests the use of GPU nodes and specifies the number of requested GPUs. Aire has 14 GPU nodes, each with 3 cards. This needs to be used with the GPU partition. | |
| `--array=<start>-<stop>`<br>`-a <start>-<stop>` | Produce an array of sub-tasks (loop) from `<start>` to `<stop>`, using the `$SLURM_ARRAY_TASK_ID` variable to identify the individual sub-tasks.  | |
| `--mail-type=BEGIN,END` | Request an email to be sent at the beginning and end of a job to the owner. | |
| `--mail-user=username@leeds.ac.uk` | Specify user email for `--mail-type` option. | User's email address |
| `--help`<br>`-h`| Display a list of help information, then exit. | |
