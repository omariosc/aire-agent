# Data Transfer

This page provides an overview of data transfer on Aire along with support for our preferred data transfer methods, Globus and scp.

## Overview

+ The login nodes on Aire are powerful and have fast connections to the campus network and onward to the JANET network and other universities.
+ The standard Linux tools are available on the login nodes to transfer data to and from the HPC system.
+ Useful commands are `scp` and `rsync`.
+ You can transfer single files or sets of files. While directories can be copied, it can be better to compress files into a single file and transfer that file. This can be achieved using the `zip` command.
+ The login nodes also accept inbound connections for these utilities from other machines on campus (wired connection), such as your desktop or workstation or departmental servers and storage.

:::{important}
 You should make sure any input data required is on your scratch directory before the job starts. If you need to transfer data elsewhere after a job completes, the job should save the data in the scratch directory, and then you can transfer it as a separate task after the job finishes.
:::

:::{warning}
 You should not transfer data in and out of Aire from running jobs. This ties up the compute nodes waiting for the network and is inefficient.
:::

For detailed instructions on data transfer, please refer to the following KB article:

+ <a href="https://leeds.service-now.com/it?id=kb_article_view&table=kb_knowledge&sys_kb_id=dfcc76a9fb3b16909eaffefbaeefdc09&searchTerm=KB0018323" target="_blank">KB0018323 - How to transfer data to and from Aire</a>

Note that the above articles require you to log in with your University account to view.

## Globus

:::{note}
 Globus is now our preference for transferring files between OneDrive and Aire, whereas, in the past, users have been advised to use `rclone`. We'd also encourage you to use Isilon `/resstore` more than OneDrive or N:\ drive for research data files.
 Visit the Library's <a href="https://library.leeds.ac.uk/info/14062/research-data-management/65/storing-and-handling-data/3">Storing and handling data</a> section for more information about different storage services.
 Refer to [KB0017543](https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0017543) for help with data transfer between University storage systems and Globus connection points.
:::

Globus enables you to quickly, securely and reliably move your data (in particular, large files) to and from locations you have access to, using GridFTP protocol optimized for high-bandwidth wide-area networks. We are currently working to add Globus centrally to Aire.

Globus Personal provides an effective interim solution for file transfers to/from Aire to locations such as University-managed Research IT Storage (`resstore`: <a href="https://it.leeds.ac.uk/it?id=kb_article&sysparm_article=KB0018026" target="_blank">Research Data Storage Service Provision</a>)  while we work towards enabling the central Globus client infrastructure. The personal client allows users to make both their Aire home directory and `$SCRATCH` visible to Globus, enabling efficient data transfers between Aire and Globus-enabled endpoints such as `resstore`.

:::{warning}
You cannot transfer files between two instances of Globus personal without a subscription; you must connect between an instance of Globus personal and a Globus client endpoint.

This means that at the moment (until we have the central client enabled on Aire):

- You can transfer files between Globus Personal on Aire and Globus endpoints such as `resstore`;
- You can transfer files between Globus Personal on Aire and Globus endpoints such as OneDrive;
- You *cannot* transfer files between Globus Personal on Aire and Globus Personal on your PC or laptop (without a subscription);
- You can transfer files between Globus Personal on Aire and Globus endpoints such as OneDrive/`resstore`, and then between OneDrive/`resstore`; and Globus Personal on your PC or laptop.
:::

:::{note}
 If you want to connect Globus to your OneDrive account, you will need to request approval. Refer to the 
<a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0018501" target="_blank">KB0018501 article.</a>
:::

In addition to the specific installation instructions provided below for Aire, you will also find the Knowledge Base articles linked below useful for setting up Globus and accessing your storage.

### Installing Globus Personal on Aire

The following guidance has been adapted from the [Globus documentation (Linux installation instructions)](https://docs.globus.org/globus-connect-personal/install/linux/):

1. After logging in to Aire, download Globus:
   ```bash
   $ wget https://downloads.globus.org/globus-connect-personal/linux/stable/globusconnectpersonal-latest.tgz
   ```
2. Extract the tarball:
   ```bash
   $ tar xzf globusconnectpersonal-latest.tgz
   # this will produce a versioned globusconnectpersonal directory
   # replace `x.y.z` in the line below with the version number you see
   $ cd globusconnectpersonal-x.y.z
   ```
3. Run Globus personal to complete set-up without a GUI:
   ```bash
   $ ./globusconnectpersonal -setup --no-gui
   ```
   This will launch Globus, and your terminal should provide you with a URL to visit on your local machine to complete set-up (including University of Leeds SSO); you will then receive a key to copy and past back into the command line on Aire. Please see the [Globus documentation](https://docs.globus.org/globus-connect-personal/install/linux/#running_with_no_gui) for further details.
4. You can close Globus once set-up is complete.
5. Modify or create the file `config-paths` (assuming you are still in the folder `globusconnectpersonal-x.y.z`) with your favourite text editor (this command will create the file if it doesn't already exist):
   ```bash
   $ nano ~/.globusonline/lta/config-paths
   ```
   This allows us to edit Globus permissions to various file paths. The `config-paths` file is a headerless CSV with the following content:
   ```bash
   <path>,<sharing flag>,<R/W flag>
   ```

   In your file, you'll see: 
   ```bash
   ~/,0,1
   ```
   Which provides access to your home directory (`~/`), doesn't allow sharing (`0` as the sharing flag), and and allows read/write access (`1` as the R/W flag).

   You can add `$SCRATCH` with the same permissions by adding the following line to the file and saving:
   ```bash
   $SCRATCH,0,1
   ```

   Read more about [Managing Globus Connect Personal Directory Permissions via the Config File in the official documentation](https://docs.globus.org/globus-connect-personal/install/linux/#config-paths).


### Running Globus Personal on Aire

1. Please read the [Globus webapp documentation](https://docs.globus.org/guides/tutorials/manage-files/transfer-files/) and ensure your Globus endpoints are visible under "Connections" from the [webapp](https://app.globus.org/). Your newly configured Aire collection should also be present, but will show the status "offline".
2. From Aire, run Globus with `nohup`:
   ```bash
   $ ./globusconnectpersonal -start &
   ```
   If you refresh the [webapp](https://app.globus.org/), you should now see your Aire collection as "online". Because we used `&`, this will continue to run even when you log out of Aire, making disruption-free transfers easier. Note that if you edit any configuration etc. you will need to stop and restart Globus:
   ```bash
   $ ./globusconnectpersonal -stop
   $ ./globusconnectpersonal -start &
   ```
3. Using the "File Manager" tab on the left of the screen, select Aire as a collection. By default, the path is to your home directory, however if you made `$SCRATCH` visible as per the installation instructions, you can also enter a path to a directory in this space: `/mnt/scratch/<USERNAME>/some_directory`.
4. Using the UI, you can now transfer data across between Aire and another endpoint.

### Relevant Globus Knowledge Base Articles

- <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0017543" target="_blank">Data transfer between Globus Collections, OneDrive, Microsoft Teams and SharePoint sites</a>: how to connect various University storage with Globus.
- <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0015444" target="_blank">Getting started with Globus data transfer service</a>: this article introduces Globus and signposts Globus documentation. This KB article also links to the Globus Data Transfer Service request form, to enable Globus on pre-existing University Storage.
- <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0015522" target="_blank">How to log into Globus</a>: this article shows you how to authorise Globus Web to use your University of Leeds account.
- <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0018026" target="_blank">Information about Research Data Storage Service Provision</a>:available research storage (Globus enabled).

## SCP

Due to the authentication methods required to access Aire, some standard scp clients can be cumbersome as they require repeated authentication during transfer. For a smoother experience, we recommend using MobaXterm on Windows, or CyberDuck or ForkLift on Mac, which handle authentication more efficiently and provide user-friendly interfaces for file transfers. For Linux, using the `scp` command via the terminal is the most straightforward. Refer to the <a href="https://leeds.service-now.com/it?id=kb_article_view&sysparm_article=KB0018323" target="_blank">KB0018323 article</a> for further information on using scp on Aire.
