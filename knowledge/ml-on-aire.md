# ML/DL on AIRE

Reference for running machine learning and deep learning workloads on the AIRE HPC cluster.

## GPU Hardware

| Spec | Value |
|------|-------|
| GPU Model | NVIDIA L40S |
| VRAM | 48 GB GDDR6 |
| Architecture | Ada Lovelace |
| Compute Capability | 8.9 |
| Interconnect | PCIe Gen4 x16 |
| GPUs per node | 3 |
| Total nodes | 28 |
| Total GPUs | 84 |

**Key implication:** Maximum 3 GPUs per single-node job. For >3 GPUs, use multi-node DDP.

## Setting Up a Conda Environment

1. Get an interactive GPU session:
```bash
srun --partition=gpu --gres=gpu:1 --time=01:00:00 --mem=16G --pty bash
```

2. Load required modules:
```bash
module load cuda/12.6.2
module load miniforge/24.7.1
```

3. Create and activate environment:
```bash
conda create -n myenv python=3.11 -y
conda activate myenv
```

4. Install PyTorch with CUDA support:
```bash
conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia
```

## Available ML Modules

| Module | Version | Load Command |
|--------|---------|-------------|
| CUDA | 12.4.1 | `module load cuda/12.4.1` |
| CUDA | 12.6.2 | `module load cuda/12.6.2` |
| PyTorch | 2.5.1 | `module load pytorch/2.5.1` |
| Miniforge | 24.7.1 | `module load miniforge/24.7.1` |
| Python | 3.13.0 | `module load python/3.13.0` |
| OpenMPI+CUDA | various | `module load openmpi` (after cuda) |
| Intel DNNL | latest | `module load intel-dnnl` |
| Intel MKL | latest | `module load intel-mkl` |

## CUDA Build Note

The CUDA module does **NOT** set `CPATH`. When compiling CUDA extensions or custom kernels, explicitly pass the include path:

```bash
nvcc -I$CUDA_HOME/include ...
# or for pip/setup.py builds:
CPATH=$CUDA_HOME/include pip install ...
```

## PyTorch GPU Configuration

Set these environment variables in your job script for optimal GPU utilization:

```bash
# Memory allocator — use expandable segments to reduce fragmentation
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Enable cuDNN autotuner — finds fastest conv algorithms (set to 1 or use Python)
export CUDNN_BENCHMARK=1

# Limit number of CPU threads to avoid oversubscription
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK

# NCCL settings for multi-GPU
export NCCL_DEBUG=INFO
export NCCL_SOCKET_IFNAME=eth0
```

In Python:
```python
torch.backends.cudnn.benchmark = True
torch.backends.cudnn.deterministic = False  # True for reproducibility, slower
```

## GPU Verification

```python
import torch

print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")
print(f"cuDNN version: {torch.backends.cudnn.version()}")
print(f"GPU count: {torch.cuda.device_count()}")
for i in range(torch.cuda.device_count()):
    props = torch.cuda.get_device_properties(i)
    print(f"  GPU {i}: {props.name}, {props.total_mem / 1e9:.1f} GB, CC {props.major}.{props.minor}")
```

## Single GPU Training Template (Mixed Precision)

```python
import torch
import torch.nn as nn
from torch.amp import autocast, GradScaler

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = MyModel().to(device)
optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3)
scaler = GradScaler("cuda")

for epoch in range(num_epochs):
    model.train()
    for batch in dataloader:
        inputs, targets = batch[0].to(device), batch[1].to(device)
        optimizer.zero_grad()

        with autocast("cuda"):
            outputs = model(inputs)
            loss = criterion(outputs, targets)

        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()
```

## Multi-GPU: Distributed Data Parallel (DDP)

### Single Node (up to 3 GPUs)

SLURM script:
```bash
#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --gres=gpu:3
#SBATCH --ntasks-per-node=3
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=12:00:00

module load cuda/12.6.2
module load miniforge/24.7.1
conda activate myenv

torchrun \
    --standalone \
    --nproc_per_node=3 \
    train.py --batch_size 64
```

### Multi-Node (>3 GPUs)

SLURM script for 2 nodes / 6 GPUs:
```bash
#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --nodes=2
#SBATCH --gres=gpu:3
#SBATCH --ntasks-per-node=3
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=24:00:00

module load cuda/12.6.2
module load miniforge/24.7.1
conda activate myenv

export MASTER_ADDR=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n1)
export MASTER_PORT=29500

srun torchrun \
    --nnodes=$SLURM_NNODES \
    --nproc_per_node=3 \
    --rdzv_id=$SLURM_JOB_ID \
    --rdzv_backend=c10d \
    --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
    train.py --batch_size 64
```

DDP setup in Python:
```python
import os
import torch
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP

def setup_ddp():
    dist.init_process_group(backend="nccl")
    local_rank = int(os.environ["LOCAL_RANK"])
    torch.cuda.set_device(local_rank)
    return local_rank

def cleanup_ddp():
    dist.destroy_process_group()

local_rank = setup_ddp()
model = MyModel().to(local_rank)
model = DDP(model, device_ids=[local_rank])
# Use DistributedSampler for the dataloader
```

## L40S Optimization Tips

| Tip | Rationale |
|-----|-----------|
| **Always use mixed precision** (fp16/bf16) | L40S has strong FP16 tensor cores; 2x throughput vs FP32 |
| **Set `CUDNN_BENCHMARK=1`** | Auto-tunes conv algorithms for consistent input sizes |
| **Use gradient accumulation** | Simulate larger batch sizes without exceeding 48 GB VRAM |
| **Be aware of PCIe bandwidth bottleneck** | L40S uses PCIe, not NVLink; multi-GPU comms are slower than A100/H100 |
| **Set `pin_memory=True`** in DataLoader | Speeds up CPU-to-GPU transfers over PCIe |
| **Set `num_workers=4`** (or cpus_per_task) | Overlap data loading with GPU compute |
| **Use `$TMP_SHARED`** for data staging | Avoid slow network I/O during training |
| **Prefer bf16 over fp16** | bf16 has wider dynamic range, less likely to overflow |
| **Profile with `torch.profiler`** | Identify actual bottlenecks before optimizing |

## Checkpointing (Save and Resume)

```python
import os
import torch

def save_checkpoint(model, optimizer, epoch, loss, path):
    """Save training checkpoint."""
    torch.save({
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'loss': loss,
    }, path)
    print(f"Checkpoint saved: {path}")

def load_checkpoint(model, optimizer, path, device):
    """Resume from checkpoint."""
    if os.path.exists(path):
        checkpoint = torch.load(path, map_location=device, weights_only=True)
        model.load_state_dict(checkpoint['model_state_dict'])
        optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
        start_epoch = checkpoint['epoch'] + 1
        loss = checkpoint['loss']
        print(f"Resumed from epoch {checkpoint['epoch']}, loss={loss:.4f}")
        return start_epoch, loss
    return 0, float('inf')

# Usage in training loop
start_epoch, best_loss = load_checkpoint(model, optimizer, "checkpoint.pt", device)
for epoch in range(start_epoch, num_epochs):
    train_loss = train_one_epoch(model, dataloader, optimizer, device)
    if train_loss < best_loss:
        best_loss = train_loss
        save_checkpoint(model, optimizer, epoch, train_loss, "checkpoint.pt")
```

## TensorFlow Setup

TensorFlow on AIRE is installed via pip (not a system module):

```bash
module load cuda/12.6.2
module load miniforge/24.7.1
conda activate myenv

pip install tensorflow[and-cuda]
```

Verify:
```python
import tensorflow as tf
print(tf.config.list_physical_devices('GPU'))
```

## Dependency Management

| Practice | Details |
|----------|---------|
| **Use Miniforge, not Anaconda** | Anaconda has commercial licensing restrictions; Miniforge is fully open |
| **Pin all versions** | `pytorch=2.5.1`, `python=3.11`, `pytorch-cuda=12.4` etc. |
| **Export environment.yaml** | `conda env export --no-builds > environment.yaml` |
| **Rebuild from yaml** | `conda env create -f environment.yaml` |
| **Keep env file in version control** | Ensures reproducibility across runs and collaborators |

Recommended workflow:
```bash
# Create environment
conda create -n project_env python=3.11 -y
conda activate project_env
conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia
pip install wandb matplotlib scikit-learn

# Export for reproducibility
conda env export --no-builds > environment.yaml

# Recreate on another node/session
conda env create -f environment.yaml
```
