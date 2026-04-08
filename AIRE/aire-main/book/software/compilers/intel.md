# Intel oneAPI
<!-- Brief introduction -->
Intel oneAPI is a unified, open programming model designed by Intel to simplify development across diverse hardware architectures including CPUs, GPUs, FPGAs, and other accelerators. It provides a comprehensive suite of compilers, libraries, analysis tools, and migration utilities optimized for high-performance computing (HPC), artificial intelligence (AI), and data analytics.

Key benefits of Intel oneAPI in HPC environments include:
- **Cross-architecture support**: Write code once and run it on multiple hardware platforms.
- **Performance optimization**: Libraries and tools are tuned for Intel hardware.
- **Open standards**: Based on SYCL and DPC++, avoiding vendor lock-in.
- **Interoperability**: Compatible with existing models like MPI, OpenMP, and CUDA.

## The Official Documentation Links

- [Intel oneAPI Overview](https://www.intel.com/content/www/us/en/developer/tools/oneapi/toolkits.html)
- [Intel Compilers](https://www.intel.com/content/www/us/en/developer/tools/oneapi/compilers.html)
- [Intel MKL](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl.html)
- [Intel MPI](https://www.intel.com/content/www/us/en/developer/tools/oneapi/mpi-library.html)
- [Intel VTune Profiler](https://www.intel.com/content/www/us/en/developer/tools/oneapi/vtune-profiler.html)
- [Intel Advisor](https://www.intel.com/content/www/us/en/developer/tools/oneapi/advisor.html)
- [Intel DPC++ Compatibility Tool](https://www.intel.com/content/www/us/en/developer/tools/oneapi/dpc-compatibility-tool.html)
- [Intel DNNL](https://github.com/intel/mkl-dnn)
- [Intel TBB](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onetbb.html)
- [Intel IPP](https://www.intel.com/content/www/us/en/developer/tools/oneapi/ipp.html)
- [Intel CCL](https://github.com/intel/oneccl)


## The Intel OneAPI modules on Aire

This page documents all Intel oneAPI modules available on the HPC system, including descriptions, official links, usage instructions, and licensing notes.

| Version | Module Load Command | Description |
|---------|----------------------|-------------|
| 2025.0.4 | `module load intel/oneapi/compiler/2025.0.4` | Intel C/C++/Fortran compilers |
| 2025.0.4 | `module load intel/oneapi/compiler-intel-llvm/2025.0.4` | LLVM-based compiler with SYCL/DPC++ support |
| 2025.0.4 | `module load intel/oneapi/compiler-rt/2025.0.4` | Runtime libraries for compiled applications |
| 2025.0 | `module load intel/oneapi/mkl/2025.0` | Math Kernel Library for linear algebra, FFTs, etc. |
| 2021.14 | `module load intel/oneapi/mpi/2021.14` | Intel MPI implementation |
| 2025.0 | `module load intel/oneapi/vtune/2025.0` | Advanced performance profiler |
| 2025.0 | `module load intel/oneapi/advisor/2025.0` | Performance analysis and optimization tool |
| 2025.0.0 | `module load intel/oneapi/debugger/2025.0.0` | Debugging tool for DPC++ and other languages |
| 2025.0.0 | `module load intel/oneapi/dpct/2025.0.0` | CUDA-to-SYCL migration tool |
| 3.6.1 | `module load intel/oneapi/dnnl/3.6.1` | Deep Neural Network Library |
| 2022.7 | `module load intel/oneapi/dpl/2022.7` | Data Parallel STL-like algorithms |
| 2022.0 | `module load intel/oneapi/tbb/2022.0` | Threading Building Blocks |
| 2021.14.0 | `module load intel/oneapi/ccl/2021.14.0` | Collective Communications Library |
| 2025.0.0 | `module load intel/oneapi/dev-utilities/2025.0.0` | Developer utilities |
| 0.9.1 | `module load intel/oneapi/umf/0.9.1` | Unified Memory Framework |
| 2022.0 | `module load intel/oneapi/intel_ipp_intel64/2022.0` | Signal/image processing primitives |
| 2025.0 | `module load intel/oneapi/intel_ippcp_intel64/2025.0` | Cryptographic primitives |



## Licensing

Intel oneAPI toolkits are generally free to use and do not require a license for most components. However, some tools and libraries may have specific licensing terms. For details, refer to:

- [Intel oneAPI Licensing FAQ](https://www.intel.com/content/www/us/en/developer/articles/faq/oneapi-licensing-faq.html)

## Note
Previous versions of Intel oneAPI included both `ifort` and `ifx` compilers. However, starting from the 2025 version, only `ifx` is supported.


<!-- Optional: If there is any other useful advice, such as profiling and performance tuning, please include them here as a separate section. -->
