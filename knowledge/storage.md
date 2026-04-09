# AIRE Storage Reference

## Storage Areas

| Area | Path | Env Var | Quota | File Limit | Backed Up | Auto-Delete | Shared Between Nodes |
|---|---|---|---|---|---|---|---|
| Home | `/users/<user>` | `$HOME` | 65 GB | 1.5M files | Yes | No | Yes |
| Scratch | `/mnt/scratch/<user>` | `$SCRATCH` | 1 TB | 1.5M files | **No** | Manual cleanup | Yes |
| Flash (shared tmp) | `/mnt/flash/tmp/job.<ID>` | `$TMP_SHARED` | 1 TB/job | -- | **No** | **Yes, when job ends** | Yes |
| Node-local tmp | `/tmp/job.<ID>` | `$TMPDIR` | Node-dependent | -- | **No** | **Yes, when job ends** | **No** |

## Storage Details

### $HOME (`/users/<user>`)

- **Quota:** 65 GB, 1.5M files
- **Backed up:** Yes
- **Use for:** Source code, scripts, small config files, conda environments
- **IMPORTANT:** NOT for high I/O workloads. Do not read/write large datasets from $HOME during jobs.

### $SCRATCH (`/mnt/scratch/<user>`)

- **Quota:** 1 TB, 1.5M files
- **Backed up:** No
- **Auto-delete:** No (manual cleanup required)
- **Use for:** Datasets, model checkpoints, intermediate results, job working directories
- **IMPORTANT:** Not backed up. Maintain your own copies of critical data.

### $TMP_SHARED (`/mnt/flash/tmp/job.<ID>`)

- **Quota:** 1 TB per job
- **Storage type:** NVMe flash (fast I/O)
- **Backed up:** No
- **Auto-delete:** Yes, deleted automatically when job ends
- **Shared:** Yes, accessible from all nodes in a multi-node job
- **Use for:** Fast temporary I/O during jobs, staging data for processing
- **CRITICAL:** Copy results to $SCRATCH or $HOME before job ends. All data is lost when the job completes.

### $TMPDIR (`/tmp/job.<ID>`)

- **Storage type:** Node-local disk
- **Backed up:** No
- **Auto-delete:** Yes, deleted automatically when job ends
- **Shared:** No, only accessible on the local node (not shared between nodes in multi-node jobs)
- **Use for:** Node-local scratch space, small temporary files

## System Capacity

| Filesystem | Total Capacity |
|---|---|
| HOME | 106 TB |
| SCRATCH | 3.7 PB |
| FLASH | 139 TB |
| TMPDIR | 372 GB/node |

## Capacity Warnings

| Threshold | Impact |
|---|---|
| 90% full | Performance degradation begins |
| 100% full | **CRITICAL:** Catastrophic impact -- jobs fail, login may break |

**Emergency actions at high capacity:**
- Delete unneeded files from $SCRATCH
- Clear conda package caches: `conda clean --all`
- Remove old job outputs and logs
- Compress large files

## Best Practices

1. **Store datasets on $SCRATCH**, not $HOME
2. **Use $TMP_SHARED for fast I/O** during jobs (NVMe-backed)
3. **Copy results before job ends** -- $TMP_SHARED and $TMPDIR are auto-deleted
4. **Keep $HOME clean** -- it has limited quota and is for code/configs, not data
5. **Monitor your usage:** `quota` or `df -h`
6. **Back up critical data** -- $SCRATCH is not backed up

## Data Transfer

| Method | Use Case | Command |
|---|---|---|
| rsync | Files < 100 GB | `rsync -avz local/path user@login1.aire.leeds.ac.uk:/mnt/scratch/user/` |
| Globus | Files > 100 GB | Use Globus web interface or CLI |

### rsync Examples

```bash
# Upload to AIRE
rsync -avz ./data/ USERNAME@login1.aire.leeds.ac.uk:/mnt/scratch/USERNAME/data/ \
  -e "ssh -J USERNAME@rash.leeds.ac.uk"

# Download from AIRE
rsync -avz USERNAME@login1.aire.leeds.ac.uk:/mnt/scratch/USERNAME/results/ ./results/ \
  -e "ssh -J USERNAME@rash.leeds.ac.uk"
```

### Job Script Pattern: Stage Data to Fast Storage

```bash
# Copy data to fast NVMe at job start
cp -r $SCRATCH/dataset $TMP_SHARED/dataset

# Run computation using fast storage
python train.py --data-dir $TMP_SHARED/dataset --output-dir $TMP_SHARED/output

# Copy results back before job ends
cp -r $TMP_SHARED/output $SCRATCH/results/job_${SLURM_JOB_ID}
```
