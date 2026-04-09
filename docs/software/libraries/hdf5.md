# HDF5

Hierarchical Data Format version 5 (HDF5) is a file format used for portable, accessible storage of large amounts of data in a hierarchical, filesystem-like format. The HDF5 libraries available on Aire support C, C++, Fortran and Java. More information is available in the [official documentation](https://support.hdfgroup.org/documentation/hdf5/latest/).

## The HDF5 module on Aire

Aire offers three versions of HDF5; one base versions, and two compiled for use on top of different versions of OpenMPI:

| Version |  Command                    |
|---------|-----------------------------|
| hdf5/1.14.5/gcc-14.2.0 | `module load hdf5/1.14.5/gcc-14.2.0` |
| hdf5/1.14.5/gcc-14.2.0_openmpi-5.0.5 | `module load hdf5/1.14.5/gcc-14.2.0_openmpi-5.0.5` |
| hdf5/1.14.5/gcc-14.2.0_openmpi-5.0.6 | `module load hdf5/1.14.5/gcc-14.2.0_openmpi-5.0.6` |

<!-- Optional: If there is any other useful advice, such as profiling and performance tuning, please include them here as a separate section. -->
