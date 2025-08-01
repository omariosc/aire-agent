(page:quotas)=

# Filesystem Quotas

We use quotas on the filesystems to manage the usage of the space fairly among the users and to try to avoid or reduce situations where a filesystem fails. If you believe you have a genuine need for additional storage, a request can be made — but please ensure you have read the full documentation first and confirmed that you are following all recommended practices for managing your current quota.

The quota system tracks two key metrics: the amount of disk space used and the number of inodes.

- The **space quota** limits the total size of your data.
- The **inode quota** limits the number of files and directories you can create.

## Default quotas

By default, all users are assigned storage quotas to ensure fair access to shared resources. These default limits vary depending on the filesystem and are designed to accommodate typical research workloads. The following table outlines the standard quota allocations for each quoted storage filesystem.

| Filesystem                      | Default Space Quota | Default Inode Quota |
| ------------------------------- | ------------------- | ------------------- |
| Home Folder (`$HOME`)           | 65GB                | 1,500,000           |
| Scratch on Lustre (`$SCRATCH`)  | 1TB                 | 1,500,000           |
| Flash on Lustre (`$TMP_SHARED`) | 1TB                 | 1,500,000           |

## Monitoring Your Quota Usage

It's important to regularly check your storage usage to avoid interruptions caused by hitting quota limits. The following table shows how you can monitor both your space and inode quota usage using simple commands.

| Filesystem                      | Command to Check Quota           |
| ------------------------------- | -------------------------------- |
| Home Folder (`$HOME`)           | `quota -s`                       |
| Scratch on Lustre (`$SCRATCH`)  | `lfs quota -h -u $USER /scratch` |
| Flash on Lustre (`$TMP_SHARED`) | `lfs quota -h -u $USER /flash`   |

*Note: The `quota` command is used for network-mounted filesystems like NFS, which is the case for your Home Folder, and the `lfs quota` command is specific to Lustre filesystems, which is the case for shared high-performance filesystems such as Scratch or Flash. The flags `-s` and `-h` displays sizes in a human-readable format.*

If your usage is larger than you were expecting, you should investigate what folder/file is using the extra space. The following command will help you to investigate the space usage:

```bash
$ du -ah --max-depth=1 | sort -rh
```

This command will list all folders and files (`-a`) in current directory (`--max-depth=1`), including hidden objects. The output will be displayed with human readable sizes (`-h`) and with bigger directories/files first (`-r`).

## What Happens If You Hit Your Quota?

When you exceed your storage space or inode quota, the system will block any further attempts to write data. This can lead to a range of issues, including:

- **Job failures**: Jobs that attempt to write to disk may fail, often without clear error messages.
- **Interrupted data transfers**: File uploads or processing steps may stop unexpectedly.
- **Software installation issues**: New packages or modules may fail to install.
- **Slow or failed logins**: Login processes that write temporary files (e.g. shell history or environment configuration) can be delayed or disrupted.
- **Broken workflows**: Scripts that create intermediate files, logs, or checkpoints may no longer function correctly.

## What To Do If You Hit Your Quota

If you’ve hit your quota, it’s important to act quickly to free up space and avoid further disruption. The primary goal is to restore normal system behaviour — such as job execution, file transfers, and login functionality — as soon as possible.

Start by identifying and removing unnecessary data. Common candidates include:

- **Outdated results** and temporary or intermediate files no longer in use.
- **Unused software**: Remove local installations (e.g. from `~/.local`, `conda`, or `pip`) that are no longer needed.
- **Cache folders**, such as `.cache/`, which can silently consume significant space.

:::{admonition} Conda Hidden Files
:class: warning
`conda` can easily accumulate over 5GB of unused packages, tarballs, and cache files.
If you're using `miniforge` and `conda` to manage your software stack, consider running the following periodically:

1. Remove unused environments:

   `conda remove -n envNAME --all`
2. Clean up cache, lock files, unused packages, tarballs, and logs:

   `conda clean --all`
:::

Once you've freed up some space, system functions such as login and file operations should begin to stabilise. From there, you can take more structured actions:

- **Move completed work** to appropriate long-term or project storage.
- **Ensure you're using the right storage tier** for your workload (see our [storage overview](page:storage-overview) and [best practices guide](page:best-practices) for more information).
- **Plan your research in stages**, allowing for regular clean up between cycles to stay within your quota.

:::{admonition} Still need more space?
:class: tip
If, after cleaning up, organising your data, and improving your workflow, you still have a genuine need for more storage, you may request additional quota. See the full guidance below on how to do this.
:::

## Quota Requests: User Guidelines and Policy

The HPC storage systems are shared, finite resources designed exclusively for active computation. This guideline outlines when users may request an increase in their storage quota and the conditions for approval.
All requests will be assessed in the context of overall system availability and fair use.

### Filesystem Overview and Best Practices

Before requesting a quota increase, ensure that you are using the storage filesystems appropriately:

- Follow our [Best Practices](page:best-practices) for data management and storage usage.
- Use appropriate storage areas according our [Storage and Filesystems](page:storage-overview) guidance.
- Understand and respect your [Filesystem Quotas](page:quotas), and monitor them regularly.
- Comply with the [Rules and Regulations for using Aire](page:rules).

### When to Request a Quota Increase

Quota increases are not automatically granted and must be justified. If you require additional space for active research work, you may submit a request. The following explains which scenarios are considered valid and outlines the types of requests that are typically declined.

Valid Reasons:

<ul style="list-style-type: none;">
  <li>✅ Active research or simulation work requiring additional space.</li>
  <li>✅ Quota is insufficient for ongoing, legitimate computational needs.</li>
  <li>✅ Clearly defined workload phases.</li>
  <li>✅ Unnecessary files have been removed</li>
</ul>

Automatically Rejected Requests:

<ul style="list-style-type: none;">
  <li>❌ Vague justifications or unspecified timelines</li>
  <li>❌ Storing inactive data (e.g., old results, duplicate files)</li>
  <li>❌ Inappropriate use of storage filesystems.</li>
  <li>❌ Users with unresolved quota policy violations.</li>
</ul>

### Temporary Nature of Quota Increases

All quota increases are time limited. This section explains how long increases can last and what is expected once the period ends.

- Quota increases are granted for a maximum of 6 months.
- Users must specify an end date when requesting a quota increase.
- Before the period ends, users must remove or transfer the data.
- Once the quota increase period ends, quotas will automatically revert to default levels.
- User can request quota increases as many time as necessary.

### How to Justify a Quota Increase

Successful quota increase requests will be well justified and complete. The steps below guide you through submitting a successful quota increase request:

- Justification for the increase.
- Required size, number of files, and target filesystem.
- Expected end date for the quota increase (max 6 months).
- Plan for removing/transferring data.
- Confirmation that current storage usage follows the best practices outlined in this documentation.

Requests that are detailed, timely, and align with active research activities are more likely to be approved.

:::{admonition} Good Request Example ✅
:class: tip
*I am running a series of large-scale molecular dynamics simulations between June and August 2025. Each job produces around 80 GB of temporary output, and I expect to run 2000 simulations (100 different parameters × 20 simulations per parameter), totalling approximately 160 TB. To manage this, I will divide the workflow into batches: processing 20 simulations at a time (1.6 TB), analysing the results, archiving final outputs to external storage, and then removing the raw data. This batching approach means I don’t need to have all 160TB at the same time. Therefore, I request a temporary increase on **Scratch** from 1 TB to **4.8 TB**, allowing me to work on three batches simultaneously. I don’t generate many **files, so no change** is necessary in this aspect. The requested increase should **expire on 31 July 2025**, by which time all **data will be removed** or transferred following the best practices guidance.*
:::

### What Happens When the Period Ends?

Users must manage their data responsibly during and after a quota increase. This section explains what happens to your storage once the extension period expires. At the end of the agreed period:

- The user’s quota returns to default.
- Data must be deleted or moved beforehand.
- The system has no backup. Data left after the deadline will be permanently deleted.

:::{note}
Users will be unable to create new files until they are back within their quota. Taking early action helps prevent data loss and workflow failures.
:::

### Non-Compliance Policy

You are expected to reduce your filesystem usage to the default quota level before the agreed period ends. Failure to reduce usage by the deadline is a policy violation. Consequences are:

- 30 days post-deadline: Automatic deletion of all data in the user’s filesystem.
- Further violations will prevent you from requesting quota increases in the future.

*Contact the HPC admin team before the deadline if you anticipate delays.*

### How to Request a Quota Increase

Quota Increase requests are made via the <a href="https://it.leeds.ac.uk/it?id=sc_cat_item&sys_id=ca435a961bd5aa1063cf6467b04bcbe6">HPC Quota Increase Form</a> available in the IT website.
