# Data transfer

<!-- For security reasons, this section has been taken offline as it contains hostnames that could pose a cybersecurity risk. We need to identify an appropriate method for securely transferring data in and out of Aire. -->

<!-- TODO: >>>>>>Asked Pasquale what utilities (scp, rsync) etc can be used with University Research data storage eg Isilon<<<<<<< -->

You should make sure any input data required is on your scratch directory before the job starts. And if you need to transfer data elsewhere after a job completes, then the job should save the data in the scratch directory and then you can transfer it as a separate task after the job finishes.

:::{warning}
You should not transfer data in and out of Aire from running jobs. This ties up the compute nodes waiting for the network and is inefficient.
:::

The login nodes on Aire are powerful and have fast connections to the campus network and onward to the JANET network and other universities.
The standard Linux tools are available on the login nodes to transfer data to and from the HPC system. Useful commands are `scp` and `rsync`. You can transfer single files or sets of files, whilst directories can be copied, it can be better to compress files into a single file and transfer that file. This can be achieved using the `zip` command.
The login nodes also accept inbound connections for these utilities from other machines on campus (wired connection), such as your desktop or workstation or departmental servers and storage.

## Using a Terminal

### scp

To transfer data to or from your local machine, `scp` must be run on your local machine, such as in a local terminal, as Aire cannot directly access your machine.

The general format of an `scp` command is `scp /path/to/file/to/copy /path/to/location/to/copy/to` where; "/path/to/file/to/copy" is the path of the file to copy, and "/path/to/copy/to" is the path to copy to. To specify a remote path add `username@remote:` at the start of the path - where `username` is the user USERNAME and `remote` is the address of the remote machine. For example, to copy a files to/from `$SCRATCH` on Aire specify `username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username` (where `username` is your USERNAME and the name of the directory on `/mnt/scratch/users/`). Some example `scp` commands are shown below.

:::{Note}
Currently, you have to connect through the jumphost, rash.leeds.ac.uk, to transfer files to Aire from a local machine that is not on a wired campus network (off-campus connection).
:::

1. Copy from your off-campus local machine to your scratch directory on Aire

```bash
# Copy the file test.dat to a file with the same name in your scratch directory
$ scp -J username@rash.leeds.ac.uk test.dat username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username
```

Directories can be copied in the same way but requires the addition of the `-r` option, which copies recursively.

```bash
# Copy the directory test_dir to a directory with the same name in your scratch directory
$ scp -r -J username@rash.leeds.ac.uk test_dir username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username
```

2. Copy from your scratch directory on Aire to your off-compus local machine

```bash
$ scp -J username@rash.leeds.ac.uk username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username/test.dat .

```

Again directories can be copied using the `-r` option.

```bash
$ scp -r -J username@rash.leeds.ac.uk username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username/test_dir/ .
```

3. Copy data from /nobackup on ARC4 to your scratch directory on Aire

This can be done either remotely, by running a command on your local machine, or the `scp` command can be run on the login node of ARC4 (example below). You will prompted for your Aire password.

```bash
# Copy a file, test.dat, from ARC4 to your scratch directory on Aire
$ scp username@arc4.leeds.ac.uk:/nobackup/username/test.dat username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username/
```

```bash
# Copy a directory, test_dir, from ARC4 to your scratch directory on Aire
$ scp -r username@arc4.leeds.ac.uk:/nobackup/username/test_dir username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username/
```

4. Copy a file, `test.dat`, from your scratch directory on Aire to to the `/home/mydirectory/` directory on a local workstation on campus, from the login node:

```bash
$ scp /mnt/scratch/users/username/test.dat <machine_name>.leeds.ac.uk:/home/mydirectory/
```

Note:

1. you maybe prompted for your workstation password
2. if your login name is different on the workstation and Aire, you will need to add it explicitly:

```bash
$ scp /mnt/scratch/users/username/test.dat <login_name>@<machine_name>.leeds.ac.uk:/home/mydirectory/
```

There are many tools on Windows and MacOS which can provide you with a more GUI-style interface to the HPC system to transfer files. They use the same underlying commands like `scp`, and some users may be more comfortable using them rather than the command line.

### rsync

The `rsync` command is another file transfer command. It is more suitable than `scp` for large file transfers as it enables for interrupted transfers to be continued rather than starting them from the beginning.

There are also a number of additional options that can be used with the `rsync` command, inuding `-v` for verbose, `-a` for archive, and `-n` for a "dry run" which allows `rsync` to do a trial run with no changes made (which is useful for testing things will work).

1. Copy from your off-campus local machine to your scratch directory on Aire

```bash
# Copy a file, test.dat, from a local machine to your scratch directory on Aire
rsync -av -e "ssh -J username@rash.leeds.ac.uk" test.dat username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username/
```

Copying directories works in the same way but requires a trailing `/` after the directory you wish to transfer:

```bash
# Copy a directory, test_dir, from a local machine to your scratch directory on Aire
rsync -av -e 'ssh -J username@rash.leeds.ac.uk' test_dir/ username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username/
```

2. Copying from your scratch directory on Aire to your off-campus local machine

```bash
# Copy a file, test.dat, from your scratch directory on Aire to a local machine
$ rsync -e "ssh -J username@rash.leeds.ac.uk" username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username/test.dat /path/to/local/directory/
```

```bash
# Copy a directory, test_dir, from your scratch directory on Aire to a local machine
$ rsync -av -e "ssh -J username@rash.leeds.ac.uk" username@login1.aire.leeds.ac.uk:/mnt/scratch/users/username/test_dir/ /path/to/local/directory/
```

<!-- TODO: add rclone and other data transfer tools -->
