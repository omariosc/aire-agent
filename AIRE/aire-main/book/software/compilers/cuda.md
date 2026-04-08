# CUDA
<!-- Brief introduction -->
NVIDIA® CUDA® is a general purpose parallel computing architecture introduced by NVIDIA. It includes the CUDA Instruction Set Architecture (ISA) and the parallel compute engine in the GPU. To program to the CUDA architecture, developers can use C, one of the most widely used high-level programming languages, which can then be run at great performance on a CUDA-enabled processor

The NVIDIA® CUDA® Toolkit provides a comprehensive development environment for C and C++ developers building GPU-accelerated
applications. The CUDA Toolkit includes a compiler for NVIDIA GPUs, math libraries, and tools for debugging and optimizing the performance of your applications.  You’ll also find programming guides, user manuals, API reference, and other documentation to help you get started quickly accelerating your application with GPUs.

[Official Documentation](http://developer.nvidia.com/cuda/cuda-toolkit)

## The CUDA modules on Aire

| Version  |  Command                     |
|----------|------------------------------|
| 12.4.1   | `module load cuda/12.4.1`    |
| 12.6.2   | `module load cuda/12.6.2`    |

## Licensing

This package is made available subject to the following license(s):

```NONFREE - NVIDIA Software License/CUDPP License```

For NVIDIA Software License details, see
[http://www.nvidia.co.uk/object/nv_swlicense.html](http://www.nvidia.co.uk/object/nv_swlicense.html).

For CUDPP Licese details, see
[http://www.gpgpu.org/static/developer/cudpp/rel/cudpp_1.0a/html/license.html](http://www.gpgpu.org/static/developer/cudpp/rel/cudpp_1.0a/html/license.html).

## Note

This module does **not** set the `CPATH` environment variable.
This is intentional to avoid affecting non-CUDA compilations, as
`CPATH` applies globally to all builds. If you need to include CUDA
headers in your compilation, please use:

```-I$CUDA_HOME/include```

This ensures your build system explicitly includes CUDA headers only
when needed, keeping your environment clean and predictable.




<!-- Optional: If there is any other useful advice, such as profiling and performance tuning, please include them here as a separate section. -->