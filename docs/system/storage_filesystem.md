(page:storage-overview)=
# Storage and Filesystems

Aire provides several storage options to support a wide range of research workflows. This section summarises the available storage types, their key features, and the best practices for managing quotas and data efficiently.

## Summary of storage types

The table below gives a high-level comparison of each storage option. Environment variables such as `$HOME` and `$SCRATCH` make navigation easier by pointing directly to the correct directories.

| **Storage Type** | **Details** |
| --- | --- |
| **Home Folder** | **Path:** `/users/<username>`<br>**Environment variable:** `$HOME`<br>**Quota:** 65 GB, 1.5 million files<br>**Backup:** ✅ Yes<br>**Automatic deletion:** ❌ No<br>**Best for:** Persistent small files such as scripts, notes, and configuration files |
| **Scratch on Lustre (disk-based)** | **Path:** `/mnt/scratch/<username>`<br>**Environment variable:** `$SCRATCH`<br>**Quota:** 1 TB, 1.5 million files<br>**Backup:** ❌ No<br>**Automatic deletion:** ❌ No<br>**Best for:** Large datasets and active project data |
| **Flash on Lustre (NVMe-based)** | **Path:** `/mnt/flash/tmp/job.<JOB-ID>`<br>**Environment variable:** `$TMP_SHARED`<br>**Quota:** 1 TB, 1.5 million files<br>**Backup:** ❌ No<br>**Automatic deletion:** ✅ Yes<br>**Best for:** I/O-intensive tasks |
| **Scratch on compute nodes** | **Path:** `/tmp/job.JOB-ID`<br>**Environment variable:** `$TMP_LOCAL`, `$TMPDIR`<br>**Quota:** None, subject to node storage availability<br>**Backup:** ❌ No<br>**Automatic deletion:** ✅ Yes<br>**Best for:** Single-node jobs needing fast, local storage |

> **Key information**
>
> - **Temporary data**: Files in `$TMP_SHARED`, `$TMP_LOCAL`, and `$TMPDIR` are automatically deleted when a job completes.
> - **No backups**: Data in `$SCRATCH`, `$TMP_SHARED`, `$TMP_LOCAL`, and `$TMPDIR` is not backed up. Archive critical files to your Home Folder or external storage.

## Detailed storage descriptions

### Home Directory

- **Path and environment**
  - Directory: `/users/<username>`
  - Accessible via the `$HOME` variable and the `~` shortcut.
- **Quota**: 65 GB and up to 1.5 million files.
- **Backup**: Yes, with periodic backups. External archiving is recommended for critical data.
- **Automatic deletion**: No.
- **Usage**: Best for persistent, small files such as scripts, documentation, and configuration files. It is not intended for high I/O workloads.

### Scratch on Lustre (disk-based)

- **Path and environment**
  - Directory: `/mnt/scratch/<username>`
  - Accessible via the `$SCRATCH` variable.
  - Symlink: `/scratch` → `/mnt/scratch`
- **Quota**: 1 TB and up to 1.5 million files.
- **Backup**: No.
- **Automatic deletion**: No.
- **Usage**: Designed for large datasets and active job data. Manual cleanup is essential to avoid exceeding quotas.

### Flash on Lustre (NVMe-based)

- **Path and environment**
  - Directory: `/mnt/flash/tmp/job.<JOB-ID>`
  - Accessible via the `$TMP_SHARED` variable.
  - Symlink: `/flash` → `/mnt/flash`
- **Quota**: 1 TB per job and up to 1.5 million files per job.
- **Backup**: No.
- **Automatic deletion**: Yes. Files are purged when the job completes.
- **Usage**: Optimised for I/O-intensive tasks such as simulations. Ideal for workloads that require high performance during the job period.

### Scratch on compute nodes

- **Path and environment**
  - Directory: `/tmp`
  - Accessible via `$TMP_LOCAL` and `$TMPDIR`.
- **Quota**: None, subject to node storage availability.
- **Backup**: No.
- **Automatic deletion**: Yes. Data is purged after job completion.
- **Usage**: Best for fast, node-local storage during single-node jobs. Data is not shared between nodes and remains local to the node.

:::{seealso}
For detailed guidance on best practices for using storage and filesystems, see the [File and Data Management](../usage/file_data_management/start.md) section.
:::

## Storage Capacity and Limits

As explained above, Aire provides several shared storage areas. Each has a finite capacity, and usage is managed collectively across all users:

| Filesystem                          | Total Space | Total Inode   |
| ----------------------------------- | ----------- | ------------- |
| Home Folder (`$HOME`)               | 106 TB      | 2,269,138,752 |
| Scratch on Lustre (`$SCRATCH`)      | 3.7 PB      | 2,997,485,568 |
| Flash on Lustre (`$TMP_SHARED`)     | 139 TB      | 293,022,729   |
| Scratch on compute nodes (`TMPDIR`) | 372 GB*     | 24,838,144*   |

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
