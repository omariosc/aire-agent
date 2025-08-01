# NetCDF

NetCDF (Network Common Data Form) is a set of software libraries and machine-independent data formats that support the creation, access, and sharing of array-oriented scientific data. It is also a community standard for sharing scientific data. This version, available on Aire, is for the C programming language. For further information and usage help, please see the [official documentation](https://docs.unidata.ucar.edu/netcdf-c/current/).

## The NetCDF module on Aire

Aire currently offers three versions of NetCDF, for different versions of OpenMPI (or built without OpenMPI support):

| Version                 |  Command                                                        |
|-------------------------|-----------------------------------------------------------------|
| 4.9.2 (no OpenMPI)      | `module load netcdf/4.9.2/gcc-14.2.0_hdf5-1.14.5`               |
| 4.9.2 (OpenMPI 5.0.6)   | `module load netcdf/4.9.2/gcc-14.2.0_openmpi-5.0.6_hdf5-1.14.5` |

<!-- Optional: If there is any other useful advice, such as profiling and performance tuning, please include them here as a separate section. -->