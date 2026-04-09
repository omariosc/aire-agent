# Rosetta

Rosetta is a suite of software that computationally models and analyses protein structure to enable for example de novo protein design, enzyme design, ligand docking, and structure prediction of biological macromolecules and macromolecular complexes.

For more details see the [official documentation](https://rosettacommons.org/).

## Available versions on Aire
<!-- List the available versions of this module on Aire -->
<!-- Instructions on how to load this module -->
<!-- If there are additional modules required, please mention them. -->

The suite of software is installed as a container. The latest version of this was downloaded on the 22/08/2025 and this date is given as the version.

| Version      | Load Command                    |
|--------------|---------------------------------|
| 20250822     | `module load rosetta/20250822 ` |

There is a wrapper script to make it easier to use. Run the script as just rosetta, with no flags, to get a list of all the Rosetta commands available.

Run the script with a Rosetta command to use Rosetta, for example `rosetta rosetta_scripts --help`.

The container also holds a copy of the Rosetta database and files from the are automatically picked up.

Containers do not have cannot see all the files on Aire. Rosetta can read and write to your `$HOME`, current working directory and to scratch. This is the scratch on Luster which is disc based, see [our documentation on stage for more information](https://arcdocs.leeds.ac.uk/aire/system/storage_filesystem.html)


## How to submit a job


### A Single Job

```bash
#!/bin/bash
#SBATCH --job-name=rose_node_pdb # create a short name for your job
#SBATCH --cpus-per-task=1 # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem=4G # memory per cpu-core (4G per cpu-core is default)
#SBATCH --nodes=1 # node count
#SBATCH --time=02:00:00 # total run time limit (HH:MM:SS)

## clean environment and load rosetta
module purge
module load rosetta/20250822

echo "Running job"

COMMAND="rosetta relax @min.script"

echo "executing command: $COMMAND"

eval $COMMAND


With: min.script:

-s <your_pdb_file_name>.pdb
-use_input_sc
-ignore_unrecognized_res
-nstruct 20
-score:weights ref2015_cart
-relax:min_type lbfgs_armijo_nonmonotone
## follow directions in [https://docs.rosettacommons.org/docs/latest/cartesian-ddG](https://docs.rosettacommons.org/docs/latest/cartesian-ddG) to create your cart2.script
-relax:script cart2.script
-fa_max_dis 9.0
-rebuild_disulf true


and cart2.script:

switch:cartesian

repeat 2

ramp_repack_min 0.02  0.01     1.0  50
ramp_repack_min 0.250 0.01     0.5  50
ramp_repack_min 0.550 0.01     0.0 100
ramp_repack_min 1     0.00001  0.0 200
accept_to_best
endrepeat
```

### A Job Array
In this example output is written to file within the script. There is a way to use `Slurm` to write the output. This is normally placed near the top of the Slurm script.

```bash
#SBATCH --output=arrayjob_%A_%a.out
```
The `Slurm` job array script is below:
```bash
#!/bin/bash
## Create a short name for your job
#SBATCH --job-name=rose_task_array_job
## Total run time limit (HH:MM:SS)
#SBATCH --time=04:00:00
## Request memory per node
#SBATCH --mem=4G
## Request task array - the 1-1000 is total number and %100 max concurrent ones
#SBATCH --array=1-1000%100


## Load clean module environment and load rosetta
module purge
module load rosetta/20250822


# working directory
#$ -V -cwd


# Specify Job
# Rosetta is able to see the system wide scratch area 
cd /mnt/scratch/<userid>/<users_file_RosettaAutoRelax>


state=$(echo 0000$SGE_TASK_ID | rev | cut -c 1-5 | rev)


echo "
## it should just find the database
##-database /apps/applications/rosetta/3.10/1/default/main/database
-out:suffix _${SLURM_JOB_NAME}_${SLURM_JOB_ID}
-relax:fast
-use_input_sc 
-out:suffix _$state
-out:file:scorefile score.sc


-nstruct 1
-no_nstruct_label
-ex1
-ex2
-use_input_sc
-flip_HNQ
-no_optH false
-flip_HNQ
-score:weights ref2015 " > flag_${SLURM_JOB_NAME}_${SLURM_JOB_ID}.file
rosetta relax.default.linuxgccrelease -in:file:s scLTIIb-cp-topology-sculpt-relax.pdb @flag_${SLURM_JOB_NAME}_${SLURM_JOB_ID}.file
```