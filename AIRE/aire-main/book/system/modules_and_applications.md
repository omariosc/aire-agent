# Modules and Applications

This page provides an overview of how software applications are managed on Aire.

## Module system explained

Aire uses a *module* system for managing software applications - a common practice in HPC clusters. A module system simplifies the use of different software and different *versions* of the software, which can quickly become complicated and lead to a loss of performance. With a module system, many users can access multiple different versions of a software application safely and conveniently.

## Installing and managing modules

Popular and common software applications are installed and managed centrally by the [Research Computing](https://arc.leeds.ac.uk/) team. This approach not only saves users time and effort, but also makes sure that the installed applications have the correct optimisation for the hardware of the system and do not interfere with each other (different applications often have files or libraries with the same name, for example). It also allows the Research Computing team to limit the availability of some modules to specific user groups - groups using licenced software, for example.

```{admonition} Requesting new modules
:class: note
You can request new modules via the <a href="https://it.leeds.ac.uk/it?id=sc_cat_item&sys_id=48d5a6d70f275f00a82247ece1050ea0" target="_blank">HPC Application Install form</a> giving details about your requirements. Requests will be assessed for suitability to be a shared application. Most open source applications can be incorporated, and commercial applications can be supported with appropriate licenses.
```

## Using modules

Users can list, load and unload modules using the `module` command:

List currently available modules:

```bash
module avail
```

Load a specific module:

```bash
module load <module>
```

Unload a module (useful for avoiding module conflicts and for workflow separation):

```bash
module unload <module>
```

:::{seealso}
For a more complete guide to using modules and managing reproducible environments on Aire, check out [Software on Aire](../software/start.md).
:::
