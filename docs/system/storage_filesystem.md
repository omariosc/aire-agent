(page:storage-overview)=
# Storage and Filesystems

Aire offers versatile storage solutions to support diverse research workflows. This guide explains the available storage options, their key features, and best practices for efficient data and quota management. Use the information below to make informed decisions and optimise your HPC work.

## Summary of storage types

The table below provides a high‑level comparison of each storage option. Note that the associated environment variables (e.g., `$HOME`, `$SCRATCH`) simplify navigation in your workflows by automatically pointing to the correct directories.

| **Storage Type**                   | **Details**                   |
|------------------------------------|-------------------------------|
| **Home Folder**                    | **Path:** `/users/<username>`<br>**Env Variable:** `$HOME`<br>**Quota:** 65GB, 1.5 million files<br>**Backup:** ✅ Yes<br>**Automatic Deletion:** ❌ No<br>**Best For:** Persistent small files (scripts, notes, configs)                                                     |
| **Scratch on Lustre (Disk‑based)** | **Path:** `/mnt/scratch/<username>`<br>**Env Variable:** `$SCRATCH`<br>**Quota:** 1TB, 1.5 million files<br>**Backup:** ❌ No<br>**Automatic Deletion:** ❌ No<br>**Best For:** Large datasets                                                                       |
| **Flash on Lustre (NVMe‑based)**   | **Path:** `/mnt/flash/tmp/job.<JOB-ID>`<br>**Env Variable:** `$TMP_SHARED`<br>**Quota:** 1TB, 1.5M files<br>**Backup:** ❌ No<br>**Automatic Deletion:** ✅ Yes<br>**Best For:** I/O‑intensive tasks                  |
| **Scratch on compute nodes**        | **Path:** `/tmp/job.JOB-ID`<br>**Env Variable:** `$TMP_LOCAL`, `$TMPDIR`<br>**Quota:** None, subject to node storage availability<br>**Backup:** ❌ No<br>**Automatic Deletion:** ✅ Yes<br>**Best For:** Single‑node jobs needing fast, localised storage |

> **Key Information**  
>
> - **Temporary Data**: Data in `$TMP_SHARED`, `$TMP_LOCAL`, and `$TMPDIR` is automatically deleted when a job completes.  
> - **No Backups**: Data in `$SCRATCH`, `$TMP_SHARED`, `$TMP_LOCAL`, and `$TMPDIR` is not backed up. Archive critical files to your Home Folder or external storage.

## Detailed storage descriptions

### Home Directory

- **Path & Environment**:  
  - Directory: `/users/<username>`  
  - Accessible via the `$HOME` variable and via the `~` shortcut.
- **Quota**: 65GB and up to 1.5 million files.
- **Backup**: Yes (with periodic backups – external archiving recommended for critical data).
- **Automatic Deletion**: No.
- **Usage**:  
  Appropriate for persistent, small files such as scripts, documentation, and configuration files. Not appropriate for high I/O operations.

### Scratch on Lustre (Disk‑based)

- **Path & Environment**:  
  - Directory: `/mnt/scratch/<username>`  
  - Accessible via the `$SCRATCH` variable.
  - Symlink: `/scratch` -> `/mnt/scratch`
- **Quota**: 1TB and up to 1.5 million files.
- **Backup**: No.
- **Automatic Deletion**: No.
- **Usage**:  
  Designed for large datasets and active job data. Manual cleanup is essential to avoid exceeding quotas.

### Flash on Lustre (NVMe‑based)

- **Path & Environment**:  
  - Directory: `/mnt/flash/tmp/job.<JOB-ID>`  
  - Accessible via the `$TMP_SHARED` variable.
  - Symlink: `/flash` -> `/mnt/flash`
- **Quota**: 1TB per job and up to 1.5 million files per job.
- **Backup**: No.
- **Automatic Deletion**: Yes—files are purged upon job completion.
- **Usage**:  
  Optimised for I/O‑intensive operations such as simulations. Ideal for tasks that require high performance during the job period.

### Scratch on compute nodes

- **Path & Environment**:  
  - Directory: `/tmp`
  - Accessible via `$TMP_LOCAL` and `$TMPDIR`.
- **Quota**: None, subject to node storage availability
- **Backup**: No.
- **Automatic Deletion**: Yes—data is purged after job completion.
- **Usage**:  
  Best for fast, node‑local storage during single‑node jobs. Note that data cannot be shared between nodes and is local.

:::{seealso}
For detailed guidance on best practices for using storage and filesystems, please refer to the [File and Data Management](../usage/file_data_management/start.md) section.
:::

## Storage Capacity and Limits

As explained above, Aire provides several shared storage areas. Each has a finite capacity, and usage is managed collectively across all users:

| Filesystem                          | Total Space | Total Inode   |
| ----------------------------------- | ----------- | ------------- |
| Home Folder (`$HOME`)               | 106 TB        | 2,269,138,752 |
| Scratch on Lustre (`$SCRATCH`)      | 3.7 PB        | 2,997,485,568 |
| Flash on Lustre (`$TMP_SHARED`)     | 139 TB        | 293,022,729   |
| Scratch on compute nodes (`TMPDIR`) | 372 GB*       | 24,838,144*   |

*\* Quantities available per node*

### When a Filesystem Becomes Full

While the quota system helps manage individual usage, it doesn’t guarantee that the overall filesystem won’t fill up. Quotas are intentionally **oversubscribed** to maximise usable space — most users don’t use their full quota all the time. However, this means it’s possible for the filesystem itself to become critically full.

When a filesystem reaches **90% capacity**, performance starts to degrade significantly:

- **Jobs may run slower** due to fragmentation or allocation delays.
- **Write operations may fail**, leading to job crashes or incomplete output.
- **Files may become corrupted** if writes are interrupted mid-operation.

At **100% usage**, the consequences are severe:

- Any process attempting to write data will receive a `No space left on device` error.
- Files being written may be **truncated or corrupted** — data loss is likely.
- Running jobs will fail.
- New jobs cannot start reliably.

At this stage, to protect system integrity and avoid cascading failures, we take the following immediate actions when a filesystem becomes critically full:

1. **Job scheduling will be suspended.** No new jobs will start until space is recovered.
2. **A site-wide email will be sent** to all users asking for urgent data cleanup.
3. **Files will be proactively deleted without warning** to relieve the space shortage.
4. **System reboot may be required** to restore stability.

:::{warning}
Rebooting the system means **all users lose access** temporarily. This also carries a small risk of hardware issues or service delays during the recovery.
:::

### A Community Responsibility

The HPC system is a shared resource. Although we monitor usage closely and take preemptive action when possible, **the majority of data is managed by users**, not system administrators.

For this reason, we ask everyone to:

- Regularly review and clean up your data.
- Follow our [Best Practices](page:best-practices) for data management and storage usage.
- Understand and respect your [Filesystem Quotas](page:quotas), and monitor them regularly.
- Comply with the [Rules and Regulations for using Aire](page:rules).
- Respond promptly to any system alerts or emails — early action can prevent disruption for the entire community.

By following these guidelines, you help protect not only your work, but also the reliability of the HPC platform as a whole.

:::{warning}
In emergency situations, we may take **immediate and irreversible actions without warning** to protect the system and ensure continued access for the wider community.
:::
