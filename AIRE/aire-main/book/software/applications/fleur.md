# Fleur

Fleur is a tool for calculating material properties with density functional theory (DFT) and related methods. It is released under the MIT licence. For further information, including tutorials, please see the [official documentation](https://www.flapw.de/MaX-8.0/)

## Available versions on Aire

| Version                    | Load Command                                                         |
| -------------------------- | -------------------------------------------------------------------- |
| MaX8.0 (no HDF5 support)   | `module load fleur/max8/openmpi-5.0.5-gcc-14.2.0_lapack-3.12.0`      |
| MaX8.0 (with HDF5 support) | `module load fleur/max8_hdf5/openmpi-5.0.5-gcc-14.2.0_lapack-3.12.0` |

Note that there are two versions available on Aire; with and without support for HDF5. For more intensive calculations, it is likely that the HDF5 version will be faster, with the opposite true for simpler runs.


## How to run a job

A fleur job generally runs in two steps. First, an .xml-format input file is generated from a human readable text file, using the input generator. This can be performed on a login node, as it is not computationally intensive. Please see the [tutorial](https://www.flapw.de/MaX-8.0/future/F1/) for further information.
```plaintext
[user@login1[aire] my_folder]$ module load fleur
Loading fleur/max8_hdf5/openmpi-5.0.5-gcc-14.2.0_lapack-3.12.0
  Loading requirement: gcc/14.2.0 lapack/3.12.0 openmpi/5.0.5/gcc-14.2.0
[user@login1[aire] my_folder]$ inpgen -f my_input.txt
      Welcome to FLEUR - inpgen   (www.flapw.de)
      MaX-Release 8.0          (www.max-centre.eu)
...
 Run finished successfully
 Stop message:
   All done
...
[user@login1[aire] my_folder]$
```

Fleur supports distributed-memory parallelism with OpenMPI. To run a Fleur job, call Fleur from the same directory as the generated input file. Below is an example job submission script.

```bash
#!/bin/bash
#SBATCH --job-name=fleur_example
#SBATCH --time=00:20:00         # Request running time
#SBATCH --mem=10G               # Request memory
#SBATCH --nodes=2               # Number of nodes
#SBATCH --ntasks-per-node=3     # Number of tasks per node
#SBATCH --cpus-per-task=1       # Number of CPUs per task

# Load Fleur module and dependencies
module load fleur/max8_hdf5



# Run the job using MPIrun, passing in number of tasks
mpirun -n $SLURM_NTASKS_PER_NODE fleur_MPI
```