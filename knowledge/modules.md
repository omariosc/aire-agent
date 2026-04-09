# AIRE Module Reference

> Last updated: auto-synced from AIRE

Complete list of software modules available on AIRE, organized by category.

## Module Commands

| Command | Description |
|---------|-------------|
| `module avail` | List all available modules |
| `module list` | Show currently loaded modules |
| `module load <name>` | Load a module |
| `module unload <name>` | Unload a module |
| `module purge` | Unload all modules |
| `module show <name>` | Show what a module does (paths, env vars) |

## Compilers

| Module | Load Command |
|--------|-------------|
| CUDA 12.4.1 | `module load cuda/12.4.1` |
| CUDA 12.6.2 | `module load cuda/12.6.2` |
| GCC 13.2.0 | `module load gcc/13.2.0` |
| GCC 14.2.0 | `module load gcc/14.2.0` |
| Intel Compilers (Classic) | `module load intel-compilers` |
| Intel MKL | `module load intel-mkl` |
| Intel MPI | `module load intel-mpi` |
| Intel DNNL | `module load intel-dnnl` |
| Java JDK 21.0.6 | `module load java/jdk-21.0.6` |

## Libraries

| Module | Load Command |
|--------|-------------|
| FFTW | `module load fftw` |
| HDF5 (serial) | `module load hdf5` |
| HDF5 (parallel) | `module load hdf5-parallel` |
| LAPACK | `module load lapack` |
| NetCDF (C) | `module load netcdf` |
| NetCDF (Fortran) | `module load netcdf-fortran` |
| NetCDF (parallel) | `module load netcdf-parallel` |
| OpenBLAS | `module load openblas` |
| OpenBLAS (OpenMP) | `module load openblas-openmp` |
| OpenMPI | `module load openmpi` |
| OpenMPI + CUDA | `module load openmpi-cuda` |
| PyTorch 2.5.1 | `module load pytorch/2.5.1` |
| VTK | `module load vtk` |
| VTK (MPI) | `module load vtk-mpi` |

## Interpreters

| Module | Load Command |
|--------|-------------|
| Miniforge 24.7.1 | `module load miniforge/24.7.1` |
| Python 3.13.0 | `module load python/3.13.0` |
| Julia 1.11.3 | `module load julia/1.11.3` |

## Tools

| Module | Load Command |
|--------|-------------|
| Apptainer 1.3.6 | `module load apptainer/1.3.6` |
| Spack 0.23 | `module load spack/0.23` |
| TeX Live 2025 | `module load texlive/2025` |
| Pixi 0.41.4 | `module load pixi/0.41.4` |

## Applications

| Module | Load Command |
|--------|-------------|
| Abaqus 2022 | `module load abaqus/2022` |
| ANSYS 2024R2 | `module load ansys/2024R2` |
| CASTEP | `module load castep` |
| COMSOL 6.2 | `module load comsol/6.2` |
| GROMACS | `module load gromacs` |
| GROMACS (GPU) | `module load gromacs-gpu` |
| MATLAB R2023a | `module load matlab/R2023a` |
| NAMD | `module load namd` |
| NAMD (GPU) | `module load namd-gpu` |
| OpenFOAM | `module load openfoam` |
| ORCA 6.0.1 | `module load orca/6.0.1` |
| ParaView | `module load paraview` |
| ParaView (MPI) | `module load paraview-mpi` |
| Stata 19 | `module load stata/19` |

## Quick Reference

Load a common ML stack:
```bash
module load cuda/12.6.2
module load miniforge/24.7.1
```

Load a common HPC/simulation stack:
```bash
module load gcc/14.2.0
module load openmpi
module load hdf5-parallel
module load fftw
```

Check what a module sets:
```bash
module show cuda/12.6.2
# Shows: PATH, LD_LIBRARY_PATH, CUDA_HOME, etc.
```
