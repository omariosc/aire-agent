# Gaussian

Gaussian is a computational chemistry package for electronic structure modelling. For further information, see the [official documentation](https://gaussian.com/man/).

## Available versions on Aire

| Version | Load Command                              |
| ------- | ----------------------------------------- |
| 16 C.02 | `module load applications/gaussian/16c02` |

## Setting up the licence

Gaussian is licensed software. Access on Aire is restricted to members of the `gaussian` group.

To request access, please contact IT specifying the following statement:

> I agree to abide by the licensing conditions for academic use and citation as published by Gaussian Inc. and which may be varied from time to time.

Our licence allows use **only for academic research**. It is not permitted to use Gaussian for commercial purposes or to benchmark against competitor products. Source code and binaries may not be shared outside the University.

All academic work created using Gaussian must include the proper citation, as described on the [Gaussian citation page](https://gaussian.com/citation/).

**Note:** *GaussView*, the graphical interface for building molecules and visualising results, is licensed separately and is **not available on Aire**. Users should prepare input files and analyse outputs using other tools.

## Scratch space

Gaussian creates large temporary files during execution.

* On compute nodes, the module automatically sets `GAUSS_SCRDIR` to the node-local `$TMPDIR` provided by Slurm. This directory is fast, job-private, and deleted when the job ends.
* For interactive shells (outside a batch job), the module sets `GAUSS_SCRDIR` to `/mnt/scratch/$USER/g16_scratch` and will create this directory if missing.

**Best practice:**

* You usually only need to keep the `.chk` checkpoint file.
* Other files (e.g. `.rwf`, `.int`, `.d2e`) can be discarded.
* If you want them deleted automatically at the end of a job, include `%NoSave` in the Link 0 section of your input file.

Make sure you monitor the size of your scratch use: Gaussian can generate very large scratch files.

## How to submit a job

Gaussian runs in shared memory parallel mode. The number of cores requested in Slurm must match the `%NProcShared` setting in the Gaussian input file. Always set `OMP_NUM_THREADS=1`.

Example batch job requesting 8 cores and 32 GB of memory:

```bash
#!/bin/bash
#SBATCH --job-name=gaussian_example
#SBATCH --time=05:00:00
#SBATCH --mem=32G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8   # Number of CPU cores required

module load applications/gaussian/16c02

export OMP_NUM_THREADS=1

# Run Gaussian
g16 < input.com > output.log
```

And in the Gaussian input file include matching directives:

```
%NProcShared=8
%Mem=28GB
```

This ensures Slurm’s resource allocation and Gaussian’s internal settings are consistent.

## Performance notes

* Testing on Aire shows Gaussian runs quickly with **16 CPUs / 32 GB** and **32 CPUs / 64 GB**, which are expected to be common choices.
* Scaling beyond approximately 32 cores is poor and usually offers little benefit.
* For many jobs, 4–8 cores already give near-optimal performance.