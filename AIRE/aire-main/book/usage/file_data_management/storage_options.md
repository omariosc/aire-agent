# Storage Options

For comprehensive details about the storage systems available on Aire, please refer to the [Storage and Filesystem](page:storage-overview) section.

## Using Flash on Lustre (NVMe‑based)

Flash on Lustre provides high-performance, NVMe-based temporary storage, ideal for I/O‑intensive workloads and jobs requiring rapid access to large datasets across multiple nodes. The path to this storage is set automatically in your job as the environment variable `$TMP_SHARED`, and typically points to `/mnt/flash/tmp/job.<JOB-ID>`.

To utilise Flash storage in your job, reference `$TMP_SHARED` in your submission script. For example:

```bash
#!/bin/bash
#SBATCH --job-name=example
#SBATCH --time=01:00:00

Flash storage path is automatically set as $TMP_SHARED
echo "Flash storage path: $TMP_SHARED"

Copy input data to Flash storage
cp -r /path/to/input/data $TMP_SHARED/

./example.bin --data $TMP_SHARED/data

Copy results back to permanent storage
cp -r $TMP_SHARED/results /path/to/permanent/storage/
```

:::{Note}
Data stored in Flash is automatically purged when the job finishes. Always copy important results back to permanent storage before your job ends.
:::

## Using Scratch on compute nodes

Scratch storage on compute nodes is accessed via the environment variables `$TMP_LOCAL` or `$TMPDIR`, which typically point to `/tmp/job.<JOB-ID>`. This storage is ideal for single-node jobs that require fast, localised access to temporary data.

To utilise it, reference `$TMP_LOCAL` or `$TMPDIR` in your submission script. For example:

```bash
#!/bin/bash
#SBATCH --job-name=example
#SBATCH --time=01:00:00

# Local scratch storage path is set as $TMP_LOCAL or $TMPDIR
echo "Local scratch path: $TMP_LOCAL"

# Copy input data to local scratch
cp -r /path/to/input/data $TMP_LOCAL/

./example.bin --data $TMP_LOCAL/data

# Copy results back to permanent storage
cp -r $TMP_LOCAL/results /path/to/permanent/storage/
```

:::{Note}
Data stored in `$TMP_LOCAL` or `$TMPDIR` is automatically deleted when the job ends. Ensure you copy any important results back to permanent storage before your job completes.
:::
