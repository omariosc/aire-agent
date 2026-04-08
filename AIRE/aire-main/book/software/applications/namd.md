# NAMD

NAMD is a molecular dynamics application designed for large biomolecular systems (proteins, nucleic acids, lipid bilayers). On Aire, NAMD 2.14 is available via the module system and runs under MPI.

## Available versions on Aire
<!-- List the available versions of this module on Aire -->
<!-- Instructions on how to load this module -->
<!-- If there are additional modules required, please mention them. -->

| Version      | Load Command                                     |
|--------------|--------------------------------------------------|
| 2.14         | `module load namd/2.14/gcc-14.2.0_openmpi-5.0.6` |


NAMD documentation: [NAMD website](https://www.ks.uiuc.edu/Research/namd/)

## Licensing
NAMD is distributed under a non-commercial license by the University of Illinois (TCBG). For license terms, see [NAMD license](https://www.ks.uiuc.edu/Research/namd/)

## How to submit a job

### Download the ApoA1 benchmark

```bash
cd ~
wget https://www.ks.uiuc.edu/Research/namd/utilities/apoa1.tar.gz
tar -zxvf apoa1.tar.gz
```

### Submit a CPU MPI job
```bash
#!/bin/bash
#SBATCH --job-name=namd2_mpi
#SBATCH --output=%x_%j.log
#SBATCH --error=%x_%j.log
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --time=01:00:00

module purge
module load namd/2.14/gcc-14.2.0_openmpi-5.0.6

# Note: To reduce CPU usage while waiting on messages, you can enable Charm++ idle polling:
#       Add '+idelpoll' to the NAMD command. This may improve system responsiveness on shared nodes,
#       but can slightly reduce performance on tightly coupled parallel jobs.
# Example:
# mpirun -np 4 namd2 +idelpoll ~/apoa1/apoa1.namd

mpirun -np 4 namd2 ~/apoa1/apoa1.namd

```

### Generate structure files with psfgen

```bash
#!/bin/bash
#SBATCH --job-name=namd2_psfgen
#SBATCH --output=%x_%j.log
#SBATCH --time=00:05:00

module purge
module load namd/2.14/gcc-14.2.0_openmpi-5.0.6
cd ~/apoa1

psfgen << EOF
resetpsf
readpsf apoa1.psf
coordpdb apoa1.pdb
writepsf apoa1_test.psf
writepdb apoa1_test.pdb
EOF

```

### Notes
Replace file names to match your input files. Adjust ntasks and time limits based on your workload. 


