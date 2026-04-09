# Linux User Environment

This page covers some basic information about the user environment on Aire.

```{admonition} New to Linux?
To use Aire successfully, you should have some experience using a Linux-based command line interface (CLI). If you are new to Linux systems, check out [Training](https://arc.leeds.ac.uk/courses/) for courses and other learning resources offered by the [Research Computing](https://arc.leeds.ac.uk) team. 
```

## Environment variables

Aire is built on Linux. The user environment on Linux systems makes heavy use of environment variables. For example this is how the [module system](modules_and_applications.md) works. The modules set up or modify environment variables which affect the environment of your jobs.

In addition to the standard Linux variables, Aire provide some additional ones:

```{list-table}
:header-rows: 1
* - Variable
  - Description
* - `$HOME`
  - User's home directory, a permanent storage location. Equivalent to `~/`.
* - `$SCRATCH`
  - Shared scratch directory, high-performance storage ideal for large files or datasets actively being processed.
* - `$TMP_SHARED`
  - Flash on Lustre, high-performance NVMe storage for temporary data during job execution.
* - `$TMP_LOCAL`
  - User's local storage on compute nodes, for temporary files accessible only during job execution. Equivalent to `$TMPDIR`.
```

:::{note}
When you load a [module](modules_and_applications.md), additional variables are added to your environment.
:::

:::{seealso}
Check out [Storage and Filesystems](storage_filesystem.md) for an overview of the storage system on Aire, or, for more comprehensive user information, check out [File and Data Management](../usage/start.md).
:::

## Tailoring your environment

There are two Linux files which you can use to tailor your environment:

`.bashrc`
: Used exclusively for defining shell functions and sourced for every new shell which is spawned. It should not be used for updates to your environment, or for executing any commands.

`.bash_profile`
: Executed at the start of each new login session, and at the start of each batch job. If you wish to set up a tailored environment just for yourself, this is where you should do it. Any path and environment variable settings in `.bash_profile` will be automatically exported to all the child processes in that particular  job or session.

:::{warning}
**DO NOT** include module load commands in `.bash_profile`. Doing so can cause unintentional conflicts with modules you load in your run scripts.

If you do this and then request support from the [Research Computing](https://arc.leeds.ac.uk/) team, you will be asked to remove them first.
:::
