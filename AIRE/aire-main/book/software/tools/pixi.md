# pixi
<!-- Brief introduction and a link to its official documentation -->
Pixi is a tool for managing software dependencies and environments. [Official Documentation](link_to_official_documentation)

:::{note}
For advice on managing dependencies for your code, please see the [Dependency Management](../../usage/dependency_management.md) section for more details.
:::

## The Pixi module on Aire
<!-- List the available versions of Apptainer on Aire in a table format -->
| Version | Load Command                    |
|---------|---------------------------------|
| X.Y.Z   | `module load pixi/X.Y.Z`        |

## Using Pixi
<!-- How to use Pixi to manage packages -->
To use Pixi to manage your packages, follow these steps:

Load the Pixi module:

```bash
module load pixi/X.Y.Z
```

Use Pixi commands to manage your packages:

```bash
pixi install package_name
pixi list
pixi remove package_name
```
<!-- Review this. -->

<!-- Optional: If there is any other useful advice, such as profiling and performance tuning, please include them here as a separate section. -->
