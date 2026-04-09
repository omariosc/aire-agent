# Abaqus

Abaqus is a comprehensive suite of software tools for finite element analysis (FEA) and computer-aided engineering. It is widely used in both academia and industry to simulate the behaviour of structures, components, and materials under a range of physical conditions. Abaqus supports advanced modelling capabilities, making it suitable for complex engineering problems in fields such as civil, mechanical, automotive, and aerospace engineering.

## Available versions on Aire

| Version  | Load Command               |
|----------|----------------------------|
| 2022     | `module load abaqus/2022`  |

## Licence Management

Abaqus is a licensed application with a limited number of license tokens. Running an Abaqus analysis requires more than one token. The number of tokens needed (`T`) is given by the formula `T = int(5 x N^0.422)` where `N` is the number of cpu cores. More simply, for common job sizes the numbers are:

  |Number of cores  |Tokens required  |
  |-----------------|-----------------|
  | 1               | 5               |
  | 4               | 8               |
  | 8               | 12              |
  | 12              | 14              |
  | 16              | 16              |
  | 24              | 19              |
  | 32              | 21              |
  | 64              | 28              |

**Good practice** would recommend not to run 5 jobs using 12 CPU cores each (that would require 70 license tokens, i.e. over half the available number of tokens).

For information, Abaqus scales efficiently to 4 processors, relatively well to 8 processors but poorly further. Trying to run a job over more than 8 to 12 CPU cores won't increase the performance (and running over more than the number of CPU cores per node will even decrease the performance).

## How to submit a job

Abaqus is available on Aire for both interactive and batch processing. Users can submit jobs via the command line or through job submission scripts for larger simulations.

To use Abaqus, you need to set up the license environment variable:

```bash
export LM_LICENSE_FILE=port@host
export ABAQUSLM_LICENSE_FILE=$LM_LICENSE_FILE
```

:::{note}
To obtain the correct `port` and `host` values for your group/department, please contact the Client IT Team via <a href="https://leeds.service-now.com/it?id=sc_cat_item&table=sc_cat_item&sys_id=e36fd2230f3c2300a82247ece1050e0a&searchTerm=request" target="_blank">ServiceNow</a>.
:::

### Example script

Below is a sample Slurm script for running an Abaqus job on Aire:

```bash
#!/bin/bash
#SBATCH --job-name=abaqus_job
#SBATCH --time=02:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=8

module load abaqus/2022
export LM_LICENSE_FILE=port@host
export ABAQUSLM_LICENSE_FILE=$LM_LICENSE_FILE

abaqus job=abaqus_job input=my_simulation.inp mp_mode=threads cpus=$SLURM_NTASKS scratch=/mnt/scratch/<username> interactive
```

:::{note}

- Replace `my_simulation` with the name of your input file (without the `.inp` extension).
- Adjust the number of tasks (`--ntasks`) and memory (`--mem`) as required for your simulation.
:::
