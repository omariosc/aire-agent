# Job Scheduler

This page offers a more in-depth overview of the job scheduling system. It is recommended that you familiarise yourself with this content before [getting started](../getting_started/start.md) using Aire.

<!-- ```{contents}
:local:
``` -->

## What is a job scheduler?

A job scheduler - also known as a queueing system or workload manager - is a software tool that implements a batch system on an HPC cluster, allowing many users to submit jobs simultaneously.

The two most popular schedulers in HPC are [PBSPro](https://altair.com/pbs-professional) and [Slurm](https://slurm.schedmd.com/), though there are others, such as [LSF](https://www.ibm.com/docs/en/spectrum-lsf/10.1.0?topic=scheduler-about-lsf-session) and [Grid Engine](https://altair.com/grid-engine/).

## Benefits of a job scheduler

Efficient use of resources
: HPC systems are very powerful and have a huge capacity for work. They are expensive to run too, and consume lot of energy. It is important for us to run the systems as efficiently as possible and to maximise the amount of work they can do. Job scheduling systems can help us optimise for energy consumption, as well as throughput.

Saving users time
: Some user tasks take a long time to run - even more than a day. You might want to run a long connected sequence of runs, or run the same task many times with lots of different parameters. Doing this directly from a PC by hand can become very tedious and error prone. A job scheduling system allows us to automate the running of work so that you don't have to monitor your terminal for hours on end, and can set up complex workflows, leaving it to the job scheduling system to keep things moving.

Fair-sharing
: A job scheduler can be configured to allocate compute resources fairly to different users and groups. For example, a user who has recently submitted a large job may need to wait longer for their job to run than another user who has not recently run a job.

## Which job scheduler does Aire use?

Aire uses the Slurm system, which is used in many other UK University HPC centres. The old ARC3 and ARC4 HPC systems used Grid Engine. Fortunately, it is quite easy for users who are familiar with Grid Engine to transition to Slurm.

```{admonition} Used Slurm before?
Slurm is configured differently at different HPC centres, to meet the differing requirements of their users. However, most of the commands and parameters you use on your jobs will be the same or similar.
```

## Submitting a job to the scheduler

To submit a job to the scheduler, you must first create a job script to run your program. In the script, you will specify any particular data or parameters needed to run your program. You can then submit the script to the job scheduling system using Slurm's [`sbatch`](https://slurm.schedmd.com/sbatch.html) command for batch mode or [`srun`](https://slurm.schedmd.com/srun.html) command for interactive jobs. In your script or run command, you will include some information for the scheduling system to inform it about the size and shape of the job, and the resources it will need to run.

Some commonly used parameters are:

```{list-table}
:header-rows: 1
* - Parameter
  - Function
* - `--job-name=<name>`
  - Specifies the job name to be displayed. Use a meaningful name to distinguish between different jobs.
* - `--time=<T>` where `<T>` has format `hh:mm:ss`
  - Specifies the walltime (the amount of time you expect the run to take). Add a small safety margin (e.g., 20% extra) to account for variation. Over-estimating walltime may delay the start of your job.
* - `--cpus-per-task=<ncpus>`
  - Specifies the number of CPUs your job will use. Serial jobs use only 1 CPU, while parallel jobs can use more. It is important to specify this correctly. Slurm defaults to a single CPU if this parameter is omitted.
* - `--mem=<size>[units]`
  - Specifies the total amount of memory required for the job. Avoid over-estimating as it may delay your job and/or deprive other jobs of memory.
* - `--gpus=[type:]<number>`
  - Specifies the number of GPUs required. If your code uses GPUs, you will need to request this.
```

For the full list of options, please refer to the [Slurm documentation](https://slurm.schedmd.com/sbatch.html)

```{seealso}
To learn more about writing job scripts for different types of job, and to see examples, check out [Job Types](../usage/job_type.md) and [Job Examples](../usage/job_example.md).
```

## After a job is submitted

Once it is submitted, Slurm looks for a space to fit your job into, and if space is free, will start the job running immediately. However as many other users will often be using the system too, the job is likely to be placed in a queue, waiting to run when resource become available as other jobs finish.

```{tip}
Check the status of your job using the [`squeue`](https://slurm.schedmd.com/squeue.html) command.
```

The time you wait can vary, depending on how much work there is on the system and how much is waiting to run. Your jobs will be assigned to a partition, which is part of the apparatus used by the scheduler to manage the work. Which partition your job goes into is not important in terms of how quickly the job may run.

When resources become free, Slurm will run your job and when it completes, it will return the output file to your directory.
