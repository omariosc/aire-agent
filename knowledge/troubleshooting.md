# AIRE Troubleshooting

Common errors, fixes, and diagnostic commands for the AIRE HPC cluster.

## Job Submission Errors

### "Requested node configuration is not available"

**Cause:** Requesting more than 3 GPUs on a single node.
**Fix:** AIRE has 3 GPUs per node. For >3 GPUs, use multi-node:
```bash
# Wrong: 4 GPUs on 1 node (impossible)
#SBATCH --gres=gpu:4

# Right: 4 GPUs across 2 nodes
#SBATCH --nodes=2
#SBATCH --gres=gpu:2
#SBATCH --ntasks-per-node=2
```

### "Invalid partition"

**Cause:** Partition name is misspelled or does not exist.
**Fix:** Check available partitions:
```bash
sinfo -s
# Common partitions: cpu, gpu, short, long
```

### "bash^M: bad interpreter"

**Cause:** Script has Windows line endings (CRLF instead of LF).
**Fix:**
```bash
dos2unix my_script.sh
# or
sed -i 's/\r$//' my_script.sh
```
**Prevention:** Configure your editor to use Unix line endings, or add a `.gitattributes` file:
```
*.sh text eol=lf
```

### "Invalid account"

**Cause:** Your SLURM account string is wrong or you are not a member of the specified account.
**Fix:**
```bash
# Check your available accounts
sacctmgr show associations user=$USER format=Account
# Use the correct one
#SBATCH --account=your-account
```

### Job Stuck Pending (Long Wait)

**Cause:** Cluster is busy, or resource request is too large/specific.
**Fix:**
```bash
# Check why it's pending
squeue -u $USER -o "%i %T %r"
# Common reasons:
#   Priority       -> wait or reduce walltime
#   Resources      -> reduce node/GPU/memory request
#   QOSMaxJobsPerUserLimit -> wait for another job to finish

# Check cluster load
sinfo -p gpu -N -o "%N %G %C %m %T"
```

## Runtime Errors

### OOM Killer (Out of CPU Memory)

**Symptom:** Job killed with "Exceeded job memory limit" or signal 9 (SIGKILL).
**Fix:** Increase `--mem`:
```bash
#SBATCH --mem=64G   # was 32G
```
Check actual usage of past jobs:
```bash
seff <job_id>
# Look at "Memory Utilized" vs "Memory Efficiency"
```

### CUDA Out of Memory

**Symptom:** `RuntimeError: CUDA out of memory. Tried to allocate X MiB`

**Fixes (in order of preference):**
1. **Reduce batch size**
2. **Enable mixed precision** (halves memory for activations):
   ```python
   with torch.amp.autocast("cuda"):
       output = model(input)
   ```
3. **Gradient accumulation** (simulate larger batch without more memory):
   ```python
   accumulation_steps = 4
   for i, batch in enumerate(dataloader):
       loss = model(batch) / accumulation_steps
       loss.backward()
       if (i + 1) % accumulation_steps == 0:
           optimizer.step()
           optimizer.zero_grad()
   ```
4. **Activation checkpointing** (trade compute for memory):
   ```python
   from torch.utils.checkpoint import checkpoint
   # In model forward():
   output = checkpoint(self.expensive_layer, input, use_reentrant=False)
   ```
5. **Clear cache between phases:**
   ```python
   torch.cuda.empty_cache()
   ```

### "No module named X"

**Cause:** Conda environment not activated in the SLURM script.
**Fix:** Add activation to your job script:
```bash
module load miniforge/24.7.1
source activate myenv
# or
conda activate myenv
```

**Note:** `conda activate` requires `conda init` to have been run. If it fails, use `source activate myenv` instead.

### "No kernel image is available for execution on the device"

**Cause:** PyTorch/CUDA was compiled for a different GPU compute capability.
**Fix:** AIRE L40S GPUs are compute capability 8.9 (Ada Lovelace). Ensure:
- PyTorch is built with CUDA support for CC 8.9
- Use `pytorch-cuda=12.4` from the official PyTorch conda channel
- Do not use old PyTorch versions (<2.1) that lack Ada Lovelace support

Check your PyTorch CUDA arch list:
```python
import torch
print(torch.cuda.get_arch_list())
# Should include 'sm_89' or 'sm_90'
```

## SSH / Connection Issues

### "Connection refused"

**Cause:** Not connected to the University VPN, or SSH service is down.
**Fix:**
1. Connect to the University of Leeds VPN first
2. Then SSH: `ssh username@aire.leeds.ac.uk`
3. If still failing, check if AIRE is in maintenance: https://it.leeds.ac.uk/service-status

### "Host key verification failed"

**Cause:** AIRE's host key changed (e.g., after maintenance), but your local machine has the old key cached.
**Fix:**
```bash
# Remove the old entry
ssh-keygen -R aire.leeds.ac.uk

# Then reconnect (accept the new key)
ssh username@aire.leeds.ac.uk
```

## Performance Issues

### Slow I/O (Data Loading Bottleneck)

**Symptom:** GPU utilization is low, `nvidia-smi` shows GPU mostly idle.
**Fix:** Stage data to local/fast storage:
```bash
# Copy dataset to fast shared temp at start of job
cp -r /users/$USER/data/dataset $TMP_SHARED/dataset
# Point training at fast copy
python train.py --data_dir $TMP_SHARED/dataset
```

### Low GPU Utilization

**Symptom:** `nvidia-smi` shows <50% GPU utilization during training.

| Cause | Fix |
|-------|-----|
| Data loading bottleneck | Increase `num_workers` in DataLoader (set to number of CPUs) |
| Batch size too small | Increase batch size to fill GPU memory (check with `nvidia-smi`) |
| CPU-bound preprocessing | Move transforms to GPU or use DALI |
| Frequent CPU-GPU sync | Avoid `.item()`, `.cpu()`, `print(tensor)` in training loop |

```python
dataloader = DataLoader(
    dataset,
    batch_size=64,
    num_workers=4,       # match --cpus-per-task
    pin_memory=True,     # faster CPU->GPU transfer
    prefetch_factor=2,   # pre-load batches
    persistent_workers=True,
)
```

### Job Using Less Than Requested Resources

**Symptom:** Allocated 3 GPUs but only 1 is active, or allocated 64G RAM but only using 8G.
**Fix:** Check actual usage:
```bash
# After job completes
seff <job_id>
```

For GPUs, ensure code is using all allocated devices (see DDP section in ml-on-aire.md).

## Diagnostic Commands

| Command | Purpose |
|---------|---------|
| `quota` | Check home directory disk usage and limits |
| `sinfo -p gpu` | Show GPU partition node status (idle/alloc/down) |
| `sinfo -N -l` | Show all nodes with detailed state |
| `sacct -j <jobid> --format=JobID,State,ExitCode,MaxRSS,Elapsed` | Job history and resource usage |
| `seff <jobid>` | Efficiency report (CPU, memory, GPU utilization) |
| `nvidia-smi` | GPU status (utilization, memory, temperature) |
| `nvidia-smi -l 5` | Auto-refresh GPU status every 5 seconds |
| `module list` | Show currently loaded modules |
| `du -sh ~/` | Check home directory size |
| `du -sh $TMP_SHARED/` | Check temp shared storage usage |
| `squeue -u $USER` | Show your queued/running jobs |
| `scancel <jobid>` | Cancel a job |
| `scontrol show job <jobid>` | Full job details |

### Quick Health Check

```bash
# Am I on a compute node with a GPU?
nvidia-smi

# What modules do I have loaded?
module list

# How much disk space am I using?
quota
du -sh ~/

# What jobs do I have running?
squeue -u $USER

# How did my last job do?
sacct -u $USER --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS -n | tail -5
```
