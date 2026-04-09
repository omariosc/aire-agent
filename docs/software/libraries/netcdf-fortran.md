# NetCDF-Fortran

This library contains a Fortran interface for accessing NetCDF data. It depends on the C-based NetCDF library, which is loaded as a dependency via Aire's module system. For further information, please see the [official documentation](https://docs.unidata.ucar.edu/netcdf-fortran/current/).

## The NetCDF-Fortran module on Aire

| Version |  Command                    |
|---------|-----------------------------|
| 4.6.1   | `module load netcdf-fortran/4.6.1/gcc-14.2.0_openmpi-5.0.6` |

Note that the correct GCC, OpenMPI and HDF5 dependencies are loaded automatically via the module system.
