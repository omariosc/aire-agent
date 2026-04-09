# Slurm Reference Guide (AIRE)

## Essential Commands

| Command | Purpose | Example |
|---|---|---|
| `sbatch` | Submit a batch job script | `sbatch job.sh` |
| `squeue` | View job queue | `squeue -u $USER` |
| `scancel` | Cancel a job | `scancel 12345` |
| `scontrol` | View/modify job details | `scontrol show job 12345` |
| `seff` | Job efficiency report (after completion) | `seff 12345` |
| `srun` | Run interactive/parallel tasks | `srun --pty bash` |
| `sacct` | Historical job accounting | `sacct -j 12345 --format=JobID,Elapsed,MaxRSS` |

## Default Resources

**IMPORTANT:** Slurm defaults are minimal and almost certainly insufficient for real work.

| Resource | Default | Notes |
|---|---|---|
| CPUs | 1 | Single core |
| Memory | 1 GB | Per job (not per core) |
| GPUs | 0 | Must explicitly request |
| Time | None | **CRITICAL: --time is required, there is no default** |
| Partition | `default` | CPU-only partition |

## Submission Options

| Option | Description | Default | Example |
|---|---|---|---|
| `-J` / `--job-name` | Job name | Script filename | `--job-name=train` |
| `-p` / `--partition` | Partition | `default` | `--partition=gpu` |
| `-t` / `--time` | Wall time limit | **None (required)** | `--time=24:00:00` |
| `-n` / `--ntasks` | Number of tasks (MPI ranks) | 1 | `--ntasks=4` |
| `-c` / `--cpus-per-task` | CPUs per task | 1 | `--cpus-per-task=8` |
| `--mem` | Total memory per node | 1 GB | `--mem=32G` |
| `--mem-per-cpu` | Memory per CPU | -- | `--mem-per-cpu=4G` |
| `-N` / `--nodes` | Number of nodes | 1 | `--nodes=2` |
| `--gres` | Generic resources (GPUs) | None | `--gres=gpu:1` |
| `-o` / `--output` | Stdout file | `slurm-%j.out` | `--output=logs/%j.out` |
| `-e` / `--error` | Stderr file | Merged with stdout | `--error=logs/%j.err` |
| `--mail-type` | Email notifications | None | `--mail-type=END,FAIL` |
| `--mail-user` | Email address | -- | `--mail-user=user@leeds.ac.uk` |
| `-a` / `--array` | Task array | -- | `--array=0-99` |
| `--dependency` | Job dependencies | None | `--dependency=afterok:12345` |
| `--exclusive` | Exclusive node access | No | `--exclusive` |
| `-A` / `--account` | Account/allocation | Default account | `--account=mygroup` |

## Job Type Templates

### Serial (Single-Core) Job

```bash
#!/bin/bash
#SBATCH --job-name=serial
#SBATCH --partition=default
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=logs/%j.out

module load anaconda3
source activate myenv

python script.py
```

### Threaded / OpenMP Job

```bash
#!/bin/bash
#SBATCH --job-name=threaded
#SBATCH --partition=default
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=logs/%j.out

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

module load anaconda3
source activate myenv

python parallel_script.py --threads $SLURM_CPUS_PER_TASK
```

### MPI Job

```bash
#!/bin/bash
#SBATCH --job-name=mpi
#SBATCH --partition=default
#SBATCH --time=08:00:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=168
#SBATCH --mem=0
#SBATCH --output=logs/%j.out

module load openmpi

srun ./mpi_program
```

### Single GPU Job

```bash
#!/bin/bash
#SBATCH --job-name=gpu-single
#SBATCH --partition=gpu
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=logs/%j.out

module load anaconda3
source activate torch_env

python train.py
```

### Multi-GPU Job (Single Node, Max 3)

**CRITICAL: Maximum 3 GPUs per node on AIRE.**

```bash
#!/bin/bash
#SBATCH --job-name=gpu-multi
#SBATCH --partition=gpu
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=256G
#SBATCH --gres=gpu:3
#SBATCH --output=logs/%j.out

module load anaconda3
source activate torch_env

# PyTorch DataParallel / DistributedDataParallel (single node)
torchrun --nproc_per_node=3 train.py
```

### Multi-GPU Multi-Node Job (>3 GPUs)

**Use when you need more than 3 GPUs. Spans multiple nodes.**

```bash
#!/bin/bash
#SBATCH --job-name=gpu-multinode
#SBATCH --partition=gpu
#SBATCH --time=48:00:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=256G
#SBATCH --gres=gpu:3
#SBATCH --output=logs/%j.out

module load anaconda3
source activate torch_env

# Get master address from first node
export MASTER_ADDR=$(scontrol show hostnames $SLURM_NODELIST | head -n 1)
export MASTER_PORT=29500

# Total GPUs = nodes * gpus-per-node = 2 * 3 = 6
srun torchrun \
  --nnodes=$SLURM_NNODES \
  --nproc_per_node=3 \
  --rdzv_id=$SLURM_JOB_ID \
  --rdzv_backend=c10d \
  --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
  train.py
```

### High-Memory Job

```bash
#!/bin/bash
#SBATCH --job-name=himem
#SBATCH --partition=himem
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=1T
#SBATCH --output=logs/%j.out

module load anaconda3
source activate myenv

python large_dataset_processing.py
```

### Task Array Job

```bash
#!/bin/bash
#SBATCH --job-name=array
#SBATCH --partition=default
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --array=0-99
#SBATCH --output=logs/%A_%a.out

# %A = array master job ID, %a = array task index
module load anaconda3
source activate myenv

python process.py --index $SLURM_ARRAY_TASK_ID
```

## Validation Rules

### CRITICAL Constraints

| Rule | Details |
|---|---|
| `--time` is **required** | No default wall time. Jobs without `--time` will be rejected. |
| Partition must match resources | GPU jobs require `--partition=gpu`. High-memory jobs require `--partition=himem`. |
| `--gres=gpu:N` requires `--partition=gpu` | Requesting GPUs on `default` or `himem` will fail. |
| **Max 3 GPUs per node** | `--gres=gpu:4` (or higher) will never schedule. Use multi-node for >3 GPUs. |
| Memory limits per partition | `default`: max 768 GB/node. `gpu`: max 256 GB/node. `himem`: max 2.3 TB/node. |
| CPU limits per partition | `default`/`himem`: max 168 cores/node. `gpu`: max 24 cores/node. |

### IMPORTANT Constraints

| Rule | Details |
|---|---|
| `--mem=0` means all memory on node | Only use with `--exclusive` or when you need the full node. |
| `--cpus-per-task` vs `--ntasks` | Use `--cpus-per-task` for threaded programs, `--ntasks` for MPI. |
| Array jobs share limits | `--array=0-999%50` limits concurrent array tasks to 50. |
| Output directories must exist | Slurm will NOT create output directories. Create `logs/` before submitting. |

## Job States

| Code | State | Meaning |
|---|---|---|
| `PD` | Pending | Waiting for resources |
| `R` | Running | Executing |
| `CG` | Completing | Finishing up (epilog running) |
| `CD` | Completed | Finished successfully (exit code 0) |
| `F` | Failed | Finished with non-zero exit code |
| `CA` | Cancelled | Cancelled by user or admin |
| `TO` | Timeout | Exceeded wall time limit |
| `OOM` | Out of Memory | Killed due to memory limit |

## Slurm Environment Variables

Available inside job scripts:

| Variable | Description | Example Value |
|---|---|---|
| `$SLURM_JOB_ID` | Job ID | `12345` |
| `$SLURM_JOB_NAME` | Job name | `train` |
| `$SLURM_NODELIST` | Allocated node list | `node[01-02]` |
| `$SLURM_NNODES` | Number of nodes | `2` |
| `$SLURM_NTASKS` | Total number of tasks | `4` |
| `$SLURM_CPUS_PER_TASK` | CPUs per task | `8` |
| `$SLURM_GPUS_ON_NODE` | GPUs allocated on this node | `3` |
| `$SLURM_ARRAY_JOB_ID` | Array master job ID | `12300` |
| `$SLURM_ARRAY_TASK_ID` | Array task index | `42` |
| `$SLURM_SUBMIT_DIR` | Directory where sbatch was run | `/mnt/scratch/user/project` |

## Common Errors

| Error | Cause | Fix |
|---|---|---|
| `Invalid account or account/partition combination` | Wrong partition for resource request | Match `--partition` to requested resources (`gpu` for GPUs, `himem` for >768GB) |
| `Requested node configuration is not available` | Requested more resources than a node has | Check limits: 3 GPU/node, 168 cores (default), 24 cores (gpu) |
| `Job violates accounting/QOS policy` | Exceeded group/user limits | Check allocation with `sacctmgr show assoc user=$USER` |
| `slurmstepd: error: Detected 1 oom-kill event(s)` | Program exceeded requested memory | Increase `--mem` or optimize memory usage. Check actual usage with `seff` |
| `CANCELLED AT ... DUE TO TIME LIMIT` | Job exceeded `--time` | Increase wall time or add checkpointing |
| `error: Unable to open file logs/12345.out` | Output directory does not exist | Create `logs/` directory: `mkdir -p logs` |
| `error: Batch job submission failed: Unspecified error` | Various (often bad directives) | Check for typos in `#SBATCH` lines. Run `sbatch --test-only job.sh` |
| Job stuck in `PD` state | Resources unavailable or priority issue | Check reason with `squeue -j JOBID -o "%R"`. Common: `Resources`, `Priority` |
| `Bus error` or `Segmentation fault` on GPU | CUDA/driver version mismatch | Ensure correct CUDA module is loaded. Check with `nvidia-smi` in an interactive session. |

## Useful Command Patterns

```bash
# Interactive session with GPU
srun --partition=gpu --gres=gpu:1 --cpus-per-task=8 --mem=32G --time=01:00:00 --pty bash

# Check job efficiency after completion
seff <JOBID>

# View detailed job info
scontrol show job <JOBID>

# Cancel all your jobs
scancel -u $USER

# Cancel all pending jobs only
scancel -u $USER --state=PENDING

# View historical job data
sacct -u $USER --starttime=2024-01-01 --format=JobID,JobName,Elapsed,MaxRSS,State,ExitCode

# Check partition availability
sinfo -p gpu --format="%n %G %C %m %T"

# Test job script without submitting
sbatch --test-only job.sh

# View queue with estimated start times
squeue -u $USER --start
```
