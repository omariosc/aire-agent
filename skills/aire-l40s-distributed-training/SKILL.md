---
name: aire-l40s-distributed-training
description: >-
  Designs PyTorch distributed training on AIRE NVIDIA L40S GPUs (Ada, 48GB,
  PCIe, max 3 GPUs per node). Covers DDP vs FSDP, bf16, batch sizing, NCCL and
  torchrun with Slurm, TMP_SHARED staging, and SCRATCH checkpointing. Use for
  multi-GPU or multi-node training on AIRE gpu partition.
---

# AIRE L40S Distributed Training

## Hardware (state when relevant)

- **L40S:** CC 8.9, 48 GB GDDR6, Ada Tensor Cores — **bf16 default**
- **Max 3 GPUs/node**, PCIe only — **no NVLink**
- **>3 GPUs:** multi-node; `WORLD_SIZE = SLURM_NNODES × 3`
- **GPU partition:** 24 cores, 256 GB RAM per node

Canonical SLURM patterns: **`$AIRE/templates/jobs/gpu-*.sh`** (prefer over conflicting snippets in `ml-on-aire.md`).

## DDP vs FSDP

| Use DDP when | Use FSDP (+ activation checkpointing) when |
|--------------|---------------------------------------------|
| Model+optimizer fit in ~40 GB/GPU with bf16 | Does not fit in 48 GB even with bf16 |
| ResNet / ViT / UNet scale | Large transformers, big 3D volumes |

**PCIe:** favor larger per-GPU batch + gradient accumulation before adding GPUs; FSDP increases all-gather traffic — profile on L40S before wide multi-node FSDP.

## Precision

```python
with torch.amp.autocast("cuda", dtype=torch.bfloat16):
    ...
```

- **bf16** default (no GradScaler on Ada)
- fp16 only if required; use GradScaler
- Tensor Core friendly dims: multiples of 8

## Job script env vars

```bash
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export CUDNN_BENCHMARK=1
export OMP_NUM_THREADS=4          # tune: cpus_per_rank
export MKL_NUM_THREADS=4
# Multi-node only:
export NCCL_SOCKET_IFNAME=eth0    # verify: ip -o link on compute node
export TORCH_NCCL_ASYNC_ERROR_HANDLING=1
export NCCL_DEBUG=WARN
```

## SLURM + torchrun (canonical)

**1 GPU** — `$AIRE/templates/jobs/gpu-single.sh`: `python train.py`

**3 GPUs, 1 node** — `gpu-multi.sh`:

```bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --gres=gpu:3
torchrun --nproc_per_node=3 train.py
```

**6 GPUs, 2 nodes** — `gpu-multi-node.sh`:

```bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:3
export MASTER_ADDR=$(scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -n 1)
export MASTER_PORT=$(expr 10000 + ${SLURM_JOB_ID} % 20000)
srun torchrun \
  --nnodes=${SLURM_NNODES} \
  --nproc_per_node=3 \
  --rdzv_id=${SLURM_JOB_ID} \
  --rdzv_backend=c10d \
  --rdzv_endpoint=${MASTER_ADDR}:${MASTER_PORT} \
  train.py
```

**Global batch:** `per_gpu_batch × world_size × grad_accum_steps`

## Python DDP checklist

- `dist.init_process_group("nccl")`
- `local_rank = int(os.environ["LOCAL_RANK"])`
- `torch.cuda.set_device(local_rank)`
- `DistributedSampler` + `set_epoch(epoch)`
- `DDP(model, device_ids=[local_rank])`
- Checkpoint on **rank 0** + `dist.barrier()`

## I/O workflow

1. Dataset on `$SCRATCH`
2. `rsync` to `$TMP_SHARED` at job start (rank 0 or per-node)
3. Train from `$TMP_SHARED`
4. Checkpoints → `$SCRATCH/...` (write `.tmp` then `mv`)
5. Never leave sole copy on `$TMP_SHARED`

## Resource tuning

After job: `seff $SLURM_JOB_ID`. Low GPU util → I/O, `num_workers`, batch size; low memory efficiency → reduce `--mem`.

## Anti-patterns

- `--gres=gpu:4`, `DataParallel` for 3 GPUs, datasets on `$HOME`
- Old PyTorch without sm_89
- Mismatch: `--gres=gpu:3` but `torchrun --nproc_per_node=1`

## Integration

- Debug: `aire-ddp-debugging`
- Env: `aire-conda-environments`
- Workflow: `aire-agent-workflow`
