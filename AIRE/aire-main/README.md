# Aire Documentation

This is the repository for the documentation for the University of Leeds Aire HPC system. It is managed by the University of Leeds [Research Computing Team.](https://arc.leeds.ac.uk/profile_type/team/)

## Contributing to the documentation
We welcome all contributions to this project via GitHub issues and pull requests. Please follow the guidelines on the [`CONTRIBUTING.md` file](CONTRIBUTING.md) to make sure your contributions can be easily integrated in the project. Edits must be approved by at least one user from the arcdocs group (generally RSEs & RIEs at Leeds). For larger issues that can't be solved quickly, or require greater input, please raise an Issue in the "Issues" tab. 

There are two main ways to update the documentation; via GitHub codespaces (recommended) or locally on your own machine.

### Option 1: Working with this project via GitHub Codespaces

GitHub's codespace feature provides a cloud-based development environment that you can run from the repository's main page. To get started, switch to a new branch, then under the "Code" dropdown menu, select "Codespaces", then "Create codespace on \<branch-name>". The codespace will then launch in a new window, and will be ready to use after a few minutes of setup.

Instructions for using the codespace are in the [codespace readme file](.devcontainer/CODESPACE_WELCOME.md); this will open automatically when you build the codespace.

### Option 2: Working with this project locally

> **_NOTE:_**  This documentation is based on jupyter-book, which does not support Windows. If you are working on a Windows machine, you are recommended to use Windows Subsystem for Linux 2 (WSL2).

In a shell with git and conda available (we recommend Miniforge):

```{bash}

# clone repository and navigate to root
$ git clone https://github.com/arcdocs/aire.git
$ cd aire

# create environment
$ conda env create -f environment.yml
```

To build the html content locally you can use the `jupyter-book` command line tool:

```{bash}
# activate the conda environment 
$ conda activate arcdocs-aire-jb

# build book
$ jupyter-book build book/


# if necessary, old files can be removed by running:
$ jupyter-book clean book/
```

To preview the built html locally, you can open up a basic Python server:

```bash
python -m http.server -d book/_build/html
```




