# Aire Documentation

This is the repository for the documentation for the University of Leeds Aire HPC system. It is managed by the University of Leeds [Research Computing Team.](https://arc.leeds.ac.uk/profile_type/team/)

## Updating the documentation
To update the documentation, please feel free to submit a pull request against the main branch. Edits must be approved by at least one other user from the arcdocs group (generally RSEs & RIEs at Leeds). For larger issues that can't be solved quickly, or require greater input, please raise an Issue in the "Issues" tab.

## Working with this project locally

You can get this project working locally by using the environment.yml file to create a conda environment that contains all the dependencies required to get started.

```{bash}
$ git clone https://github.com/arcdocs/aire.git

$ conda env create -f environment.yml
```

To build the html content locally you can use the `jupyter-book` command line tool:

```{bash}
# navigate to the repository root
$ cd aire 
# activate the conda environment 
$ conda activate arcdocs-aire-jb
# sometimes worth running jupyter-book clean book/ to remove old files
# build book
$ jupyter-book build book/
```
### Windows
There are issues with running JupyterBook on [Windows](https://jupyterbook.org/en/stable/advanced/windows.html) and the official documentation recommends using Windows Subsystem for Linux 2 (WSL2). Another workaround is to use virtualisation & vagrant; to aid with this we have created a `Vagrantfile` that can allow Windows users who have a virtualisation provider installed (such as [VirtualBox](https://www.virtualbox.org/)) and [Vagrant](https://www.vagrantup.com/) installed to create a headless virtual Linux machine that will build the jupyter book. You can do this with the following steps once you've installed a virtualisation provider and vagrant:
```
# within git-bash or powershell
$ cd template-jb-docs
$ vagrant up

# to rebuild the site after changes with the vagrant box running
$ vagrant reload --provision

# don't forget to destroy the box when you're done
$ vagrant destroy
```

This will build the jupyter-book html files on your Windows file system (by navigating via /vagrant) so your local build will still persist after you've destroyed your vagrant box.
