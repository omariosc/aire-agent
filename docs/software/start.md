# Software on Aire

:::{note}
The Research Computing team is actively installing modules on Aire and working on the documentation for each module. We will gradually release the documentation for each module. If you have any queries at this moment, please do not hesitate to contact us.

We appreciate your patience during this time. Please stay tuned for updates.
:::

:::{note}
It is permitted - and encouraged - for Aire users to install their own software in their home (~) areas. If you think that a certain piece of software should be installed as a centrally managed module, then please refer to the [Requesting new software](../getting_started/request_software.md) section for guidance.
:::

We provide a variety of software on Aire, available through the module system, which allows users to load the specific software they need for their work.

On Aire, software is categorised into five groups:

- [Applications](./applications/start) - Software applications for various tasks
- [Compilers](./compilers/start) - Compilers for a range of programming languages
- [Interpreters](./interpreters/start) - Interpreters for running scripts and programs
- [Libraries](./libraries/start) - Libraries for enhancing functionality and performance
- [Tools](./tools/start) - Useful system utilities and tools

## Modules

Popular and common application programs are centrally installed and managed by the module system. This saves users time and effort, and ensures applications are optimised for our hardware, providing the best performance.

The module system allows multiple applications to coexist without conflicts and supports different versions of the same application. This flexibility lets users transition to new versions at their own pace and use different versions for different projects simultaneously.

To see the available applications, use the `module avail` command. To use a centrally installed application, load it with the `module load <modulename>` command, e.g., `module load gcc`. This sets up the necessary paths and environment variables for the application. Include the appropriate module command in every job script that requires it, as settings do not persist between jobs or sessions.

:::{warning}
Do not include module commands in your `.profile` or `.bashrc` files. Instead, place them in your job script to avoid conflicts and allow flexibility in choosing different applications and versions for different jobs. We cannot support queries from users who load modules this way.
:::

Each module can have several versions. The default version is usually the most current and stable. Use the default version with `module load <modulename>`. To use a specific version, specify it explicitly, e.g., `module load gcc/14.2.0`.

You can update your job script to use a new version by changing the module load command. The application name and associated files typically remain the same across versions.

Many HPC users have their own code or work with code managed by their research group. We provide all necessary programming tools and environments through the module system. Load the required modules according to your needs. For example:

```bash
module load openmpi
```

This command will load the Open MPI library and its associated compilers, enabling you to compile and run your MPI code. Sometimes you may need to load additional libraries as well:

```bash
module load openmpi hdf5 netcdf
```

Ensure you load the same modules in your run script as you did when compiling your code to avoid version conflicts. Check the application-specific section of this documentation for appropriate combinations.
