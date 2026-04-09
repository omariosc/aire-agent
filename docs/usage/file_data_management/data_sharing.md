# Data Sharing
<!-- Original title: File permissions and access control -->

It is important that you understand how the Linux system for controlling access to files works and if you need to share files with another user, how to do this safely and not open up access to people you don’t want to. This area is one of the most common areas which people have problems with in Linux, so we have a guide to this area.

There are 3 permissions: read (r), write (w) and execute (x). There are 3 levels of permission: owner, group and all. The default permissions on ARC3 are different to ARC4: On ARC3 group and all have read and execute permissions on new files, whereas on ARC4 group and all have no permissions. Permissions, group and ownership can be changed with `chmod`, `chgrp` and `chown` commands.

Users belong to groups, the `groups` command can be used to check what groups a user is in. File/directory permissions can be organised for groups. Only system administrators can create new groups and add users to groups.

Users can share files and directories with other users and specify permissions using the `setfacl` command.

The `getfacl` command can be used to report the access controls for specific files/directories.

The `setfacl` command can be run to recurse through subdirectories and can be used to set default access controls on directories created.

If you want other users to read and execute files in your scratch directory, you can use the following commands:

```bash
cd /mnt/scratch/<username>
setfacl -m u:<target-username>:r-x .
```

(Replace `<target-username>` with the USERNAME of the user that you want to share the directory with.)

You can check what access controls there are using:

```bash
cd /mnt/scratch/<username>
getfacl .
```

If there is an existing directory with subdirectories and you want to set the access control to recurse and provide also write permissions in subdirectories, use the following:

```bash
cd /mnt/scratch/<username>
setfacl --recursive -m u:<target-username>:rwx .
```

To change the default so that any new files and directories also have these permissions, use the following:

```bash
cd /mnt/scratch/<username>
setfacl --recursive -m u:<target-username>:rwx,d:u:<target-username>:rwx .
```

For more detailed examples and explanations of Linux file permissions, you can refer to this [Linux File Permissions Guide](https://www.redhat.com/en/blog/linux-file-permissions-explained).
