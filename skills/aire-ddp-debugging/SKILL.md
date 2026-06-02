---
name: aire-ddp-debugging
description: >-
  Diagnoses PyTorch DDP and NCCL failures on AIRE L40S GPU jobs. Use when
  distributed training hangs, NCCL errors or timeouts occur, only one GPU is
  active, Slurm resources do not match torchrun, or seff shows wasted GPUs on
  AIRE.
---

# AIRE DDP Debugging

## When to use

- Hang at `init_process_group` or first step
- `NCCL error`, watchdog, connection refused
- One GPU busy, others idle
- Job “slow” but not failing (I/O or rank-0 logging)

Read: `$AIRE/knowledge/troubleshooting.md`, `$AIRE/knowledge/ml-on-aire.md`, job `logs/*.out`.

## Triage order

### 1. Slurm

| Symptom | Action |
|---------|--------|
| Pending | `squeue -u $USER -o "%i %T %r"` |
| Immediate exit | `sacct -j JOBID` ExitCode |
| Wrong GPU count | `scontrol show job JOBID` vs `torchrun` |

### 2. Init hang

- `MASTER_ADDR` = first host in `SLURM_JOB_NODELIST` (multi-node)
- `MASTER_PORT` consistent and free
- **Mismatch:** `--gres=gpu:3` but `--nproc_per_node=1`
- `export NCCL_SOCKET_IFNAME=eth0` (confirm with `ip route` on node)
- Debug run:

```bash
export NCCL_DEBUG=INFO
export TORCH_DISTRIBUTED_DEBUG=DETAIL
export TORCH_NCCL_ASYNC_ERROR_HANDLING=1
export NCCL_TIMEOUT=1800
```

- Isolate: `torchrun --standalone --nproc_per_node=2 train.py --max-steps 5`

### 3. Mid-training hang

- Rank 0 checkpoint/log without `barrier`
- Rank 0 writing to slow `$HOME` while others wait
- Missing `DistributedSampler` or `drop_last=True`
- `find_unused_parameters=True` with dead subgraphs

### 4. PCIe / NCCL (no NVLink)

- Try `NCCL_P2P_LEVEL=SYS` or `NCCL_P2P_DISABLE=1` if P2P broken
- Multi-node: watch NCCL timeout on large buckets

### 5. Software

| Error | Fix |
|-------|-----|
| `No kernel image` | PyTorch ≥2.1, `pytorch-cuda=12.4` |
| CUDA OOM | bf16, grad accum, checkpointing |
| `No module named X` | SBATCH conda block (`aire-conda-environments`) |

## Rank-0 logging

```python
def is_main():
    import os
    return int(os.environ.get("RANK", "0")) == 0

if is_main():
    import logging
    logging.basicConfig(level=logging.INFO)
```

## Diagnostic commands

```bash
nvidia-smi -l 5
scontrol show job $SLURM_JOB_ID
seff $SLURM_JOB_ID
sacct -j $JOBID --format=JobID,State,ExitCode,MaxRSS,Elapsed
du -sh "$TMP_SHARED" "$SCRATCH"
```

## AIRE-specific catalog

1. `gres>3` → job never schedules  
2. CRLF in `*.sh` → `bad interpreter`  
3. Data on `$HOME` → looks like hang  
4. Checkpoints only on `$TMP_SHARED` → “lost” after job  
5. Multi-node: ranks see different `$TMPDIR` paths  
6. Plain `python` instead of `torchrun` → 1 GPU used  
7. Low GPU util in `seff` → dataloader/I/O, not NCCL  

## Minimal repro

1 node, 2 GPU, synthetic data, 10 steps; log `RANK`, `LOCAL_RANK`, `WORLD_SIZE`, hostname per rank.

## seff tuning loop

1. Short representative job → 2. `seff JOBID` → 3. Adjust mem, cpus, batch, workers → 4. Resubmit

## Integration

- Setup: `aire-l40s-distributed-training`  
- Workflow: `aire-agent-workflow`
