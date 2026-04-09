(dependency-management)=

# Dependency Management

```{note}
Research IT has determined that, due to licensing restrictions, Anaconda must no longer be used. Miniforge is the recommended alternative for Python environments on Aire.

This guidance specifically discusses Conda dependency management, which can be used for a range of languages/projects, including Python, R, C/C++, and Rust amongst others.

This does not cover alternative package management and virtual environment solutions like `renv`, `pixi`, or `uv pip`.

For instructions on submitting a job using Miniforge, please see the [Miniforge documentation](https://arcdocs.leeds.ac.uk/aire/software/interpreters/miniforge.html)

```

Good dependency management makes your research computing:

- More reproducible (by recording the exact environment used to generate any set of results);
- More reusable (both by you and by other researchers, by providing a "recipe" to use your code on other systems);
- More robust and unlikely to break due to an update in an imported library.

```{warning}
Please read through this guide even if you use `conda` locally on your machine, or have used it previously on ARC3 or ARC4.

Our guidance has changed: help us to help you make your research more efficient, reproducible, and robust by ensuring you follow the steps below.
```

While there are many options for dependency management for Python, we offer [`miniforge`](https://github.com/conda-forge/miniforge) on Aire as a fast, open-source replacement for Anaconda. The same `conda` commands you are used to using will work, but the default channel for miniforge environments is [`conda-forge`](https://conda-forge.org/docs/), the open source repository, as opposed to the commercial Anaconda repository. The guidance we provide below is specifically for using conda; however, the general principles will also be applicable to other package management systems.

For some packages, you may also need to use `pip`; we detail how this can be done if needed within a conda environment.

## General approach

- **In general, environments should be treated as disposable and rebuildable**: you should be able to tear down and rebuild your environment quickly and easily (of course, some larger environments with complex installations will be an exception to this rule). This means that your `environment.yaml` file should be up-to-date and match your working environment, and should be version-controlled and backed up. We will explain how to effectively use the `.yaml` file below.
- **Export your exact environment as metadata for analysis results**: it is useful to save a snapshot of your environment (into a `.yaml` file) to store along any results or outputs produced in that specific environment. We will show you how to do this below.
- **Environments must be stored in your `home` directory and all research output must be stored in `/mnt/scratch/users`**: misuse of the system can affect performance for **all users** and will lead to your jobs being stopped.

(creating-environment)=
## Create a new environment

In order to create a new conda environment, you need to create an environment YAML file, with the file ending `.yaml`.
A conda `env.yaml` or `environment.yaml` file will look something like this:

```yaml
name: my-env-name

dependencies:
  - python=3.12
  - pytest
  - setuptools
  - blackd
  - isort
  - numpy
  - matplotlib
  - pandas
```

Note that we have pinned `python` in this example, and left the other dependencies free. You can pin as many libraries as you want/need: we will discuss pinned vs. flexible libraries below.

This is then turned into a conda environment with all the listed dependencies installed by calling the following (from the folder containing the `.yaml` file):

```bash
conda env create -f environment.yaml
```

You can then activate this environment (or use it in a job submission script):

```bash
conda activate my-env-name
```

### R Environments

Conda is not only useful for Python, is can also be used for R scripts.

```{admonition} R environment creation
When using conda to install R packages, add r- before the R package name. For instance, to install rbokeh, use `r-rbokeh`. To install rJava, use conda `r-rjava`.
```

If you are creating an R environment, your  file might look like this:

```
name: my-env-name

dependencies:
  - r-base
  - r-tidyverse
```

Please follow all the other general instructions; creating an R environment is otherwise identical.

### `pip` dependencies

If you need to include Python `pip` dependencies in your Conda environment, you can add these to your environment YAML file as follows:

```yaml

name: env-with-pip-dependencies

dependencies:
  - python=3.12
  - numpy
  - matplotlib
  - pandas
  - pip
  - pip:
    - black

```

## Updating an environment or adding new packages

If you want to add a new package that you didn't include in your original `environment.yaml` file, or pin a package to a specific version, you can go and do so within the `environment.yaml` file. Just add any new packages to the list of dependencies, and pin libraries with the `=` notation as in the first example.

Once your `environment.yaml` file is up to date, you can apply the changes to your conda environment:

```bash
conda env update --file environment.yaml --prune
```

The `--prune` argument here clears out old unused libraries and is key to keeping your `.conda` folder a reasonable size. **Please ensure you use the prune command to prevent environment bloat**.

Whereas running `conda install package-name` from within your environment can lead to dependency conflicts (say your env has an older version of `numpy` and you've tried to `conda install` another package that can't support this), updating the environment from the `.yaml` file allows the solver to work through the dependencies at the same time. There may still be conflicts, but many easily avoidable issues will disappear. It also ensures you can rebuild your conda env easily from the file, instead of trying to remember what you installed.

## Exporting a snapshot of your conda environment

Recording dependencies is crucial for reproducibility.
In order to record the exact versions of all dependencies used in your project, from inside your active conda environment, you can run the following export command:

```bash
conda env export > env-record.yaml
```

This can be run as part of a batch job and included in your submission script; please ensure your output files are being saved to `mnt/scratch/users/<your-user-name>/` alongside your other output data files:

```bash
conda env export > /mnt/scratch/users/your-user-name/env-record.yaml
```

**This exported environment file is mainly useful as a record for the sake of reproducibility, not for *reusability*. Your `environment.yaml` file is a far better basis for rebuilding or sharing environments.**

This record will include background library dependencies (libraries you did not explicitly install, that were loaded automatically) and details of builds. This file, while technically an `environment.yaml` file, will likely not be able to rebuild your environment on a machine other than the machine it was created on.

## Exporting your environment for sharing

**If you follow the above steps for building your conda environment from a YAML file, this step should not be necessary. However, if you want to salvage a poorly-maintained environment that you built using repeated `conda install package-name` commands, this allows you to create an `environment.yaml` file.**

From inside your activated environment, you can run the following:

```bash
conda env export --from-history > environment_export.yaml
```

This will export a list of only the libraries that you explicitly installed (and not all the background dependencies), and only the pinned versions you requested. This is not useful as a record of your exact environment, but is a good backup for rebuilding or sharing your environment. **Note that this will not add any pip dependencies.**

To export pip libraries, we need to add some lines of code. Modified from this [conversation on GitHub](https://github.com/conda/conda/issues/9628#issuecomment-1608913117), this code snippet will export your conda and pip dependencies without version numbers (so that the `environment.yaml` file can be used to build a new environment):

```bash
# Extract installed pip packages
pip_packages=$(conda env export | grep -A9999 ".*- pip:" | grep -v "^prefix: " | cut -f1 -d"=")

# Export conda environment without builds, and append pip packages
conda env export --from-history | grep -v "^prefix: " > new-environment.yaml
echo "$pip_packages" >> new-environment.yaml
```

This *should* export a list of your pip dependencies, without pinned version numbers, and add them on to your `--from-history` conda dependencies.
But remember: it is better to keep your `environment.yaml` file current, and update your conda env *from* this file, as opposed to adding packages using `conda install` and then trying to export details to your environment file to track these changes. All of this section can be avoided if you correctly use your `environment.yaml` file to create and update your conda environments.

## Quick conda FAQs

### Are conda `environment.yaml` files an overly prescriptive approach?

Not unless you are misusing them, and have only ever encountered an `environment.yaml` file produced with the `export` function.

Environment YAML files are exactly as prescriptive as you want them to be: you can pin versions of certain libraries, and leave others flexible.

### Why can't I just use `conda install` to add packages? Why use a YAML file?

You *can*, but there are a few reasons why you *shouldn't*.

1. Things you install later will be pinned by the versions of libraries installed at an earlier stage, which can lead to dependency conflicts.
2. You can end up with a lot of crud and old unneeded libraries that you no longer use bloating your environment.
3. It is that much harder to rebuild your conda environment, and your `environment.yaml` isn't a true record of the environment. You have to remember to export a flexible `--from-history` version of it any time you make a change.

### Updating from my YAML file with the `--prune` flag might change versions of packages in my library - isn't this bad for reproducibility?

Yes, updating the entire environment with your `.yaml` file absolutely can update all the libraries, not just the ones you are adding. A few points to this:

1. You should pin any libraries that *must not* change, for example if there is a breaking change or change in behaviour in a newer/older version of one of the libraries.
2. Reproducibility absolutely does not mean repeatedly using the exact same environment pinned to a specific version in perpetuity. Recording a snapshot of your environment along with any results produced by the environment in that state, along with robust tests, ensure reproducibility without trapping you with stale and potentially insecure packages, which leads us to point three...
3. A robust test suite is **essential** for any computational research work, and lets you update packages safely while ensuring your code still produces robust and accurate results.

### Conda environments are big, what do I do if I run out of space in my home directory?

Conda environments can become big quickly. On ARC3 and ARC4, due to limitations in home directory size, we advised you to move your `.conda` directory over to `/nobackup` if you ran out of room; however, this is an inefficient use of HPC storage and can lead to performance issues. **On Aire, it is essentially that your conda environments live in your home directory, and that *all* research output files are stored on `/mnt/scratch/users` and not in the home directory. Misuse of the home directory for storing job output can cause sluggish behaviour and affect other users, and could lead to your account being suspended.**

There are three steps to solving your conda environment overtaking your home directory storage space:

1. Ensure you are using `--prune` when you update your conda environments to shrink them and remove unnecessary content.
2. Delete environments that are not in active or current use: if you have followed our guidance on building from an `environment.yaml` file, rebuilding at a later point should not be difficult.
3. Request more space: you can ask us to increase your home directory quota. Note however that we will audit your conda usage, and you will not be granted extra space if you haven't followed the guidelines presented here.
