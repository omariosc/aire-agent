# Apptainer

Apptainer is a containerisation platform, and allows users to package up collections of software in a reproducible and portable fashion. Containers built on your work laptop, for instance, can be simply copied over onto the HPC to run there. For usage instructions and further explanations, please see the [official documentaion](https://apptainer.org/docs/user/main/index.html).

## The Apptainer module on Aire
<!-- List the available versions of Apptainer on Aire in a table format -->
| Version | Load Command                    |
|---------|---------------------------------|
| 1.3.6   | `module load apptainer/1.3.6`   |

## Running Apptainer containers
<!-- Instructions on how to run Apptainer containers -->
To run an Apptainer container, use the following command:

```bash
apptainer run my_container.sif
```

For use with MPI, please see the excellent guide in the [official documentation](https://apptainer.org/docs/user/main/mpi.html), which includes examples for use with `Slurm`.

## Building Apptainer containers
<!-- Instructions on how to build Apptainer containers -->
To build an Apptainer container from a definition file, use the following command:

```bash
apptainer build my_container.sif my_definition.def
```

:::{note}
More information regarding containeration and use a container can be found in [HPC2 training course](https://arctraining.github.io/hpc2-software/course/containers.html#).
:::
