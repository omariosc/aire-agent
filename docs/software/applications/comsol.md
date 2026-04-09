# COMSOL

COMSOL is a finite element analysis software for a broad range of physical applications. For further information, see the [official documentation](https://www.comsol.com/support/learning-center).

## Available versions on Aire
<!-- List the available versions of this module on Aire -->
<!-- Instructions on how to load this module -->
<!-- If there are additional modules required, please mention them. -->
| Version | Load Command             |
|---------|--------------------------|
| 6.1     | `module load comsol/6.1` |
| 6.2     | `module load comsol/6.2` |

## Setting up the licence

Users need to provide their own licence via the `LMCOMSOL_LICENSE_FILE` environment variable. This can be achieved by running:

```bash
export LMCOMSOL_LICENSE_FILE=port@host
```

Here, `port` and `host` can be obtained from the licence holder.

## How to submit a job

The below example demonstrates running a 16-core job using a fictitious licence server. COMSOL on Aire supports batch mode, using pre-built `.mph` files.

Running COMSOL in command line can often create a large number of temporary files in your home directory. To resolve this we recommend creating a `comsolrecovery` directory in your scratch, then adding the following line to your comsol batch command in your submission script: `-recoverydir $SCRATCH/comsolrecovery`.

```bash
#!/bin/bash
#SBATCH --job-name=comsol_example_job
#SBATCH --time=05:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=1          
#SBATCH --cpus-per-task=16  # Number of CPU cores required

module load comsol/6.2

export LMCOMSOL_LICENSE_FILE=port@host

# Run the job
comsol batch -np $SLURM_CPUS_PER_TASK \
             -tmpdir $TMPDIR \
             -inputfile input.mph \
             -outputfile output.mph \
             -recoverydir $SCRATCH/comsolrecovery
```

## Performance tuning COMSOL

General advice can be found at the [COMSOL website](https://www.comsol.com/support/knowledgebase/1324).
