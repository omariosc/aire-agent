# MATLAB
<!-- Brief introduction -->
MATLAB is a programming language and numerical computing environment for data analysis and visualisation. For usage instructions, please see the [official documentation](https://uk.mathworks.com/help/matlab/index.html?s_tid=CRUX_lftnav).

## Available versions on Aire
<!-- List the available versions of this module on Aire -->
<!-- Instructions on how to load this module -->
<!-- If there are additional modules required, please mention them. -->
| Version |  Command                     |
|---------|------------------------------|
| R2023a  | `module load matlab/R2023a`  |

## How to submit a job
<!-- List of job submission scripts for different types of jobs -->

### Serial jobs

Below is an example job, requesting a single CPU core and 2 GB of memory.

```bash
#!/bin/bash
#SBATCH --job-name=matlab_serial_job
#SBATCH --time=00:30:00
#SBATCH --mem=2G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

module load matlab

# Run the job
matlab -r input_script.m
```

### Parallel jobs

An example job, requesting 16 CPU cores.

```bash
#!/bin/bash
#SBATCH --job-name=matlab_threaded_job
#SBATCH --time=05:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=1          
#SBATCH --cpus-per-task=16  # Number of CPU cores required

module load matlab/R2023a

# Run the job
matlab -r input_script.m
```

## Interactive usage

 Some software can be launched interactively on either the login or compute nodes. Users should never run computationally intensive jobs on the login node; it is only for quick testing. We recommend using the `srun` command to run interactive jobs on the compute nodes.

 The below example shows an interactive session, requesting 30 minutes of time with 4 CPUs then loading and launching the MATLAB interpreter.

 ```bash
[username@login1[aire] ~]$ srun -t 00:30:00 --nodes=1 --ntasks=1 --cpus-per-task=4 --pty /bin/bash
[username@node048[aire] ~]$ module load matlab
[username@node048[aire] ~]$ matlab

  < M A T L A B (R) >
                              Copyright 1984-2023 The MathWorks, Inc.
                         R2023a Update 7 (9.14.0.2674353) 64-bit (glnxa64)
                                           July 16, 2024


To get started, type doc.
For product information, visit www.mathworks.com.

>>
```

<!-- Optional: If there is any other useful advice, such as profiling and performance tuning, please include them here as a separate section. -->
