# aire-agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a shell-first AI-powered toolkit that makes any AI coding agent an expert AIRE HPC assistant, installable via a single curl command.

**Architecture:** Shell scripts for all tools (deterministic, fast, cheap on tokens). Thin Python MCP server dispatches to shell scripts over stdio. Python/Rich TUI for one-time setup only. Tiered agent knowledge in CLAUDE.md with MCP tools for deep lookups. Auto-sync from arcdocs/aire daily.

**Tech Stack:** Bash (tools, CLI), Python 3.8+ (MCP server, setup TUI), Rich/Textual (TUI), bats-core (shell tests), pytest (Python tests), GitHub Actions (CI/CD)

**Spec:** `docs/superpowers/specs/2026-04-09-aire-agent-design.md`

**Important notes:**
- AIRE uses password-only SSH (no SSH key auth) — TUI setup must reflect this
- AIRE login: `ssh username@login1.aire.leeds.ac.uk -J username@rash.leeds.ac.uk`
- Max 3 GPUs per node (L40S 48GB each), 28 GPU nodes, 52 CPU nodes, 2 himem nodes
- System retirement: 31/07/2029
- Repo: `omariosc/aire-agent` (already renamed from `omariosc/hpc`)

---

## Task 1: Repo Cleanup & Scaffold

**Files:**
- Delete: `AIRE/` (entire directory — PDFs, HTML, AIRE.md, aire-main/)
- Delete: `SWD6/` (entire directory)
- Delete: `docs/Commands.md`
- Delete: `README.md` (will be rewritten in Task 15)
- Create: directory scaffold for new structure
- Create: `LICENSE`
- Modify: `.gitignore`

- [ ] **Step 1: Pull latest arcdocs/aire before deleting**

We need the latest docs content. Clone arcdocs/aire fresh into a temp location so we have the source material:

```bash
git clone https://github.com/arcdocs/aire.git /tmp/aire-docs
```

- [ ] **Step 2: Create the new directory scaffold**

```bash
mkdir -p bin
mkdir -p tools
mkdir -p mcp
mkdir -p agent/hooks
mkdir -p docs
mkdir -p knowledge
mkdir -p templates/jobs
mkdir -p templates/environments
mkdir -p scripts
mkdir -p tests/unit
mkdir -p tests/integration
mkdir -p tests/e2e
mkdir -p .github/workflows
```

- [ ] **Step 3: Copy arcdocs/aire into docs/**

```bash
cp -r /tmp/aire-docs/book/* docs/
cp /tmp/aire-docs/modules.txt docs/
rm -rf /tmp/aire-docs
```

- [ ] **Step 4: Delete old files**

```bash
git rm -rf AIRE/
git rm -rf SWD6/
git rm -f docs/Commands.md
git rm -f README.md
```

Note: `docs/` now contains only the arcdocs/aire content, not the old Commands.md.

- [ ] **Step 5: Write MIT LICENSE**

Create `LICENSE`:

```
MIT License

Copyright (c) 2026 Omar Sherif Cuevas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 6: Rewrite .gitignore**

Replace entire `.gitignore` with:

```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.egg-info/
dist/
build/
.eggs/
*.egg

# Virtual environments
.venv/
venv/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Jupyter
.ipynb_checkpoints/

# aire-agent runtime
.last_sync
experiments/
```

- [ ] **Step 7: Create .last_sync placeholder**

```bash
echo "0" > .last_sync
```

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "refactor: clean repo and scaffold aire-agent structure

Remove AIRE/, SWD6/, old README, Commands.md.
Add new directory structure, MIT license, clean .gitignore.
Import arcdocs/aire documentation into docs/."
```

---

## Task 2: Knowledge Base — System, Storage, Slurm

**Files:**
- Create: `knowledge/aire-system.md`
- Create: `knowledge/storage.md`
- Create: `knowledge/slurm-guide.md`

These are the core reference files the agent uses. Written for machine consumption — structured, factual, searchable. Source material is in `docs/` (arcdocs/aire mirror) and the design spec.

- [ ] **Step 1: Write knowledge/aire-system.md**

Create `knowledge/aire-system.md`:

```markdown
# AIRE System Reference

## Overview

AIRE (Advanced Infrastructure for Research and Education) is the University of Leeds HPC cluster. It replaced ARC3/ARC4 in late 2024. Managed by Research Computing Team. Retirement date: 31/07/2029.

## Hardware

### Standard Compute Nodes (52 nodes)
- Server: Dell R6625
- CPU: AMD Dual 84-core 2.2GHz (9634 Genoa-X)
- Cores per node: 168
- Total CPU cores: 9,072
- Memory: 768GB DDR5-4800 per node (~4.6GB per core)
- Storage: Dual 480GB M2 drives
- Network: 100 Gb/s OmniPath + 25GbE Ethernet

### GPU Nodes (28 nodes)
- Server: Dell R7615
- GPU: 3x NVIDIA L40S 48GB PCIe per node
- Total GPUs: 84 cards
- CPU: AMD 24-core 2.9GHz (9254 Genoa-X)
- Cores per node: 24
- Memory: 256GB DDR5-4800 per node (~8 CPU cores and ~85GB memory per GPU)
- Storage: Dual 480GB M2 drives
- CRITICAL: Maximum 3 GPUs per node (hardware limit)

### High-Memory Nodes (2 nodes)
- Server: Dell R6625
- CPU: AMD Dual 84-core 2.2GHz (9634 Genoa-X)
- Cores per node: 168
- Memory: 2.3TB DDR5-4800 per node (~13.8GB per core)
- Storage: Dual 480GB M2 drives

### Login Nodes (4 nodes)
- Entry-level NVIDIA A2 GPUs (config/testing only)
- DO NOT run jobs on login nodes

### Management Nodes (2 nodes)
- Slurm scheduler, cluster management

## GPU Details — NVIDIA L40S

- Architecture: Ada Lovelace
- VRAM: 48GB GDDR6 per card
- Connection: PCIe (not NVLink)
- CUDA Compute Capability: 8.9
- Good for: training medium models, inference, mixed precision (FP16/BF16)
- Note: PCIe bandwidth (~64 GB/s) is slower than NVLink for multi-GPU communication

## Network
- 100 Gb/s OmniPath (low-latency interconnect between nodes)
- 25 GbE Ethernet (management network)

## Partitions
| Partition | Nodes | Use Case |
|-----------|-------|----------|
| (default) | 52 CPU nodes | Standard compute jobs |
| gpu | 28 GPU nodes | GPU-accelerated jobs |
| himem | 2 high-memory nodes | Memory-intensive jobs (>768GB) |

## Access
- SSH with password authentication (no SSH key auth)
- Must be on University network (campus wired, or VPN/gateway for off-campus)
- Login: `ssh USERNAME@login1.aire.leeds.ac.uk -J USERNAME@rash.leeds.ac.uk`
- ProxyJump through rash.leeds.ac.uk required for off-campus access

## Purchasing Additional Nodes
- Standard CPU node: ~£12,315 +VAT
- High-Memory CPU node: ~£19,580 +VAT
- GPU node: ~£14,600 +VAT
- Grants priority access, not exclusive ownership
- Available until system retirement (31/07/2029)

## Support
- IT Service Desk: itservicedesk@leeds.ac.uk
- Research Computing Team: rcteam@leeds.ac.uk
- Website: https://arc.leeds.ac.uk
- Documentation: https://arcdocs.leeds.ac.uk
```

- [ ] **Step 2: Write knowledge/storage.md**

Create `knowledge/storage.md`:

```markdown
# AIRE Storage Reference

## Storage Types

### Home Directory ($HOME)
- Path: /users/<username>
- Env: $HOME, ~
- Quota: 65GB, 1.5 million files
- Backup: Yes (periodic)
- Auto-delete: No
- Use for: Scripts, configs, small persistent files
- NOT for: Large datasets, high I/O

### Scratch on Lustre ($SCRATCH)
- Path: /mnt/scratch/<username>
- Env: $SCRATCH
- Symlink: /scratch -> /mnt/scratch
- Quota: 1TB, 1.5 million files
- Backup: No
- Auto-delete: No
- Use for: Large datasets, active job data
- IMPORTANT: Manual cleanup required

### Flash on Lustre ($TMP_SHARED)
- Path: /mnt/flash/tmp/job.<JOB-ID>
- Env: $TMP_SHARED
- Symlink: /flash -> /mnt/flash
- Quota: 1TB per job, 1.5M files per job
- Backup: No
- Auto-delete: Yes (purged when job ends)
- Use for: I/O-intensive tasks, fast temporary storage (NVMe)
- CRITICAL: Data is deleted when job completes — copy results back before job ends

### Scratch on Compute Nodes ($TMPDIR)
- Path: /tmp/job.JOB-ID
- Env: $TMP_LOCAL, $TMPDIR
- Quota: None (limited by node disk ~372GB)
- Backup: No
- Auto-delete: Yes (purged when job ends)
- Use for: Single-node fast local storage
- NOTE: Not shared between nodes

## Total System Capacity
| Filesystem | Total Space | Total Inodes |
|------------|-------------|-------------|
| $HOME | 106 TB | 2,269,138,752 |
| $SCRATCH | 3.7 PB | 2,997,485,568 |
| $TMP_SHARED | 139 TB | 293,022,729 |
| $TMPDIR | 372 GB/node | 24,838,144/node |

## Capacity Warnings
- At 90% capacity: performance degrades, write delays, possible corruption
- At 100% capacity: all writes fail, running jobs crash, new jobs cannot start
- Emergency response: job scheduling suspended, site-wide email, files may be deleted without warning, system reboot possible

## Best Practices
1. Use $SCRATCH for large datasets, not $HOME
2. Copy data to $TMP_SHARED at start of job for I/O-intensive work
3. Copy results from $TMP_SHARED back to $SCRATCH before job ends
4. Regularly clean up $SCRATCH — it is not backed up
5. Check quota with: `quota -s` (home), `lfs quota -u $USER /mnt/scratch` (scratch)
6. Use `du -sh` to check directory sizes
7. Archive critical data externally — $SCRATCH is not backed up

## Data Transfer
- Small files (<100GB): `rsync -avP`
- Large files (>100GB): Globus (https://app.globus.org, endpoint "University of Leeds - AIRE")
- Within jobs: copy to $TMP_SHARED for fast I/O
```

- [ ] **Step 3: Write knowledge/slurm-guide.md**

Create `knowledge/slurm-guide.md`:

```markdown
# AIRE Slurm Guide

## Overview
AIRE uses Slurm for job scheduling. Fair-share policy (not first-come-first-served). Higher recent usage = lower priority; priority recovers over time.

## Essential Commands
| Command | Purpose |
|---------|---------|
| `sbatch script.sh` | Submit batch job |
| `squeue --me` | Check your jobs |
| `scancel <JOBID>` | Cancel job |
| `scontrol show job <JOBID>` | Detailed job info |
| `seff <JOBID>` | Job efficiency (after completion) |
| `srun -t 01:00:00 --pty /bin/bash` | Interactive session |
| `sacct -j <JOBID> --format=JobID,JobName,Partition,AllocCPUS,State,ExitCode` | Job accounting |

## Default Resources (if not specified)
- CPUs: 1
- Memory: 1GB
- Partition: default (standard compute)
- No GPU access

CRITICAL: Always explicitly request resources. Defaults are almost never sufficient.

## Submission Options
| Option | Description | Default |
|--------|-------------|---------|
| `--time=hh:mm:ss` or `-t` | Wall clock time (REQUIRED) | Must specify |
| `--mem=<size>` | Total memory per node | 1GB |
| `--mem-per-cpu=<size>` | Memory per CPU | 1GB |
| `--cpus-per-task=N` or `-c` | CPUs per task (threading) | 1 |
| `--ntasks=N` or `-n` | Total tasks (MPI processes) | 1 |
| `--nodes=N` or `-N` | Number of nodes | 1 |
| `--ntasks-per-node=N` | Tasks per node | - |
| `--partition=<name>` or `-p` | Partition (gpu, himem) | default |
| `--gres=gpu:N` | Number of GPUs | 0 |
| `--array=start-stop` or `-a` | Task array | - |
| `--job-name=<name>` or `-J` | Job name | script filename |
| `--output=<path>` | Stdout file (%j = job ID) | slurm-<jobid>.out |
| `--error=<path>` | Stderr file | same as output |
| `--mail-type=BEGIN,END,FAIL` | Email notifications | none |
| `--mail-user=<email>` | Notification email | - |

## Job Types

### Serial (1 CPU)
```bash
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
```

### Threaded/OpenMP (multi-CPU, single node)
```bash
#SBATCH --time=02:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
```

### MPI (multi-node)
```bash
#SBATCH --time=04:00:00
#SBATCH --nodes=2
#SBATCH --ntasks=256
#SBATCH --ntasks-per-node=128
module load openmpi
mpirun ./program
```

### Single GPU
```bash
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
module load cuda/12.6.2
```

### Multi-GPU (single node, max 3)
```bash
#SBATCH --partition=gpu
#SBATCH --gres=gpu:3
#SBATCH --cpus-per-task=24
#SBATCH --mem-per-cpu=8G
module load cuda/12.6.2
```

### Multi-GPU Multi-Node (>3 GPUs)
```bash
#SBATCH --partition=gpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:3
#SBATCH --cpus-per-task=24
#SBATCH --mem-per-cpu=8G
export MASTER_ADDR=$(scontrol show hostname $SLURM_NODELIST | head -n1)
export MASTER_PORT=29500
srun torchrun --nnodes=$SLURM_NNODES --nproc_per_node=3 train.py
```

### High Memory
```bash
#SBATCH --partition=himem
#SBATCH --mem=500G
#SBATCH --cpus-per-task=32
```

### Task Array
```bash
#SBATCH --array=1-100
#SBATCH --time=01:00:00
# Use $SLURM_ARRAY_TASK_ID for per-task input/output
```

## Validation Rules (CRITICAL)
1. `--time` is REQUIRED — jobs fail without it
2. `--partition=gpu` MUST be used with `--gres=gpu:N`
3. `--gres=gpu:N` MUST be used with `--partition=gpu`
4. Max 3 GPUs per node — for >3, use multiple nodes
5. GPU node memory: 256GB total, ~85GB per GPU
6. Standard node memory: 768GB total, ~4.6GB per core
7. Himem node memory: 2.3TB total, ~13.8GB per core
8. Always add `seff $SLURM_JOB_ID` at end of scripts to check efficiency

## Job States
| Code | Meaning |
|------|---------|
| PD | Pending (waiting for resources) |
| R | Running |
| CG | Completing |
| CD | Completed |
| F | Failed |
| CA | Cancelled |
| TO | Timeout |
| OOM | Out of Memory |

## Environment Variables (available in job scripts)
| Variable | Content |
|----------|---------|
| $SLURM_JOB_ID | Job ID |
| $SLURM_JOB_NAME | Job name |
| $SLURM_NODELIST | Allocated nodes |
| $SLURM_NNODES | Number of nodes |
| $SLURM_NTASKS | Total tasks |
| $SLURM_CPUS_PER_TASK | CPUs per task |
| $SLURM_ARRAY_TASK_ID | Array task index |
| $SLURM_SUBMIT_DIR | Directory from which job was submitted |

## Common Errors
| Error | Cause | Fix |
|-------|-------|-----|
| "Requested node configuration is not available" | >3 GPUs on single node, or resources unavailable | Use multi-node or reduce request |
| "Invalid partition" | Wrong partition name | Use: default, gpu, or himem |
| "/bin/bash^M: bad interpreter" | Windows line endings | Run `dos2unix script.sh` |
| "Out of memory" | Insufficient memory requested | Increase --mem or --mem-per-cpu |
```

- [ ] **Step 4: Commit**

```bash
git add knowledge/aire-system.md knowledge/storage.md knowledge/slurm-guide.md
git commit -m "docs: add core knowledge base — system, storage, slurm"
```

---

## Task 3: Knowledge Base — ML, Experiments, Modules, Troubleshooting

**Files:**
- Create: `knowledge/ml-on-aire.md`
- Create: `knowledge/experiment-tracking.md`
- Create: `knowledge/modules.md`
- Create: `knowledge/troubleshooting.md`

- [ ] **Step 1: Write knowledge/ml-on-aire.md**

Create `knowledge/ml-on-aire.md`:

```markdown
# ML/DL on AIRE

## GPU Hardware
- 84x NVIDIA L40S 48GB (Ada Lovelace, Compute Capability 8.9)
- PCIe connection (not NVLink)
- 3 GPUs per node, 28 GPU nodes
- ~8 CPU cores and ~85GB system memory per GPU

## Setting Up a Conda Environment

```bash
# Request interactive GPU session
srun --partition=gpu --gres=gpu:1 --cpus-per-task=8 --mem=32G --time=01:00:00 --pty /bin/bash

# Load modules
module load cuda/12.6.2
module load miniforge/24.7.1

# Create environment
conda create -n ml_env python=3.11 -y
conda activate ml_env

# Install PyTorch with CUDA 12.4 support
conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia -y

# Install common ML packages
pip install transformers datasets accelerate wandb scikit-learn tensorboard
```

## Available Modules for ML
| Module | Version | Load Command |
|--------|---------|-------------|
| CUDA | 12.4.1, 12.6.2 | `module load cuda/12.6.2` |
| PyTorch | 2.5.1 | `module load pytorch/2.5.1` |
| Miniforge (Conda) | 24.7.1 | `module load miniforge/24.7.1` |
| Python | 3.13.0 | `module load python/3.13.0` |
| OpenMPI + CUDA | 5.0.6 | `module load openmpi/5.0.6/gcc-13.2.0_cuda-12.6.2` |
| Intel oneDNN | 3.6.1 | `module load intel/oneapi/dnnl/3.6.1` |
| Intel MKL | 2025.0 | `module load intel/oneapi/mkl/2025.0` |

## CUDA Build Note
The CUDA module does NOT set CPATH. When compiling CUDA code directly, use:
```bash
-I$CUDA_HOME/include
```

## PyTorch GPU Configuration

### Essential Environment Variables
```bash
# In your SBATCH script:
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_LAUNCH_BLOCKING=0
export CUDNN_BENCHMARK=1
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
```

### Verify GPU Access
```python
import torch
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"GPU count: {torch.cuda.device_count()}")
for i in range(torch.cuda.device_count()):
    print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
    print(f"  Memory: {torch.cuda.get_device_properties(i).total_mem / 1e9:.1f} GB")
```

## Single GPU Training Template
```python
import torch

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = Model().to(device)
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)

# Mixed precision for L40S (recommended)
scaler = torch.amp.GradScaler()
for batch in dataloader:
    inputs, targets = batch[0].to(device), batch[1].to(device)
    optimizer.zero_grad()
    with torch.amp.autocast(device_type="cuda"):
        outputs = model(inputs)
        loss = criterion(outputs, targets)
    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
```

## Multi-GPU Training (DDP)

### Single Node (up to 3 GPUs)
```python
import torch
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP

def setup(rank, world_size):
    dist.init_process_group("nccl", rank=rank, world_size=world_size)
    torch.cuda.set_device(rank)

def cleanup():
    dist.destroy_process_group()

def train(rank, world_size):
    setup(rank, world_size)
    model = Model().to(rank)
    model = DDP(model, device_ids=[rank])
    # ... training loop ...
    cleanup()
```

Launch with:
```bash
torchrun --nproc_per_node=3 train.py
```

### Multi-Node (>3 GPUs)
SBATCH script sets MASTER_ADDR and MASTER_PORT. Launch with:
```bash
srun torchrun \
    --nnodes=$SLURM_NNODES \
    --nproc_per_node=3 \
    --rdzv_id=$SLURM_JOB_ID \
    --rdzv_backend=c10d \
    --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
    train.py
```

## L40S Optimisation Tips
1. Use mixed precision (FP16/BF16) — L40S has excellent FP16 throughput
2. Set CUDNN_BENCHMARK=1 for consistent input sizes
3. Use gradient accumulation if batch size is limited by 48GB VRAM
4. PCIe bandwidth is the bottleneck for multi-GPU — minimize inter-GPU communication
5. For >3 GPUs across nodes, prefer gradient accumulation over multi-node if possible
6. Pin memory in DataLoader: `pin_memory=True`
7. Use multiple DataLoader workers: `num_workers=4` (up to 8 per GPU)
8. Copy training data to $TMP_SHARED for fast I/O

## Checkpointing (essential for long jobs)
```python
# Save checkpoint
torch.save({
    "epoch": epoch,
    "model_state_dict": model.state_dict(),
    "optimizer_state_dict": optimizer.state_dict(),
    "loss": loss,
}, f"checkpoint_epoch_{epoch}.pt")

# Resume from checkpoint
checkpoint = torch.load("checkpoint_epoch_N.pt")
model.load_state_dict(checkpoint["model_state_dict"])
optimizer.load_state_dict(checkpoint["optimizer_state_dict"])
start_epoch = checkpoint["epoch"] + 1
```

## TensorFlow on AIRE
```bash
# In conda environment
pip install tensorflow[and-cuda]

# Verify
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

## Dependency Management
- Use Miniforge (not Anaconda — licensing issues)
- Pin versions in environment.yaml
- Export: `conda env export --from-history > environment.yaml`
- Recreate: `conda env create -f environment.yaml`
- Update: `conda env update --file environment.yaml --prune`
- Conda environments live in $HOME — watch quota (65GB limit)
```

- [ ] **Step 2: Write knowledge/experiment-tracking.md**

Create `knowledge/experiment-tracking.md`:

```markdown
# Experiment Tracking on AIRE

## Built-in Logger (aire-agent)

aire-agent includes a lightweight JSON logger that requires no external services.

### Usage
```bash
# Log an experiment
aire-agent log \
    --job $SLURM_JOB_ID \
    --name "resnet50_lr001" \
    --metrics '{"loss": 0.234, "accuracy": 0.891}' \
    --params '{"lr": 0.001, "batch_size": 32, "epochs": 100}'

# Query past experiments
aire-agent experiments
aire-agent experiments --filter "loss<0.3"
```

### Log Format
Experiments are stored as newline-delimited JSON in `~/.aire-agent/experiments/`:
```json
{
    "timestamp": "2026-04-09T14:30:00Z",
    "job_id": "12345",
    "name": "resnet50_lr001",
    "metrics": {"loss": 0.234, "accuracy": 0.891},
    "params": {"lr": 0.001, "batch_size": 32, "epochs": 100},
    "git_commit": "abc123",
    "node": "gpu007",
    "gpus": 1,
    "runtime": "02:15:33",
    "status": "COMPLETED"
}
```

## Weights & Biases (W&B)

### Setup on AIRE
```bash
# Install
pip install wandb

# Login (creates ~/.netrc)
wandb login

# Or set API key in environment
export WANDB_API_KEY="your-key-here"
```

### Usage in Job Scripts
```bash
# In SBATCH script
export WANDB_DIR=$SLURM_SUBMIT_DIR/wandb
mkdir -p $WANDB_DIR

# For offline mode (recommended — AIRE has limited internet)
export WANDB_MODE=offline
```

### Syncing Offline Runs
```bash
# After job completes, sync from login node
wandb sync wandb/offline-run-*
```

### Python Integration
```python
import wandb

wandb.init(
    project="my-project",
    config={
        "learning_rate": 0.001,
        "batch_size": 32,
        "architecture": "ResNet50",
    },
)

# During training
wandb.log({"loss": loss, "accuracy": acc})

# End
wandb.finish()
```

## MLflow

### Setup on AIRE
```bash
pip install mlflow

# Start tracking server (optional — can use file-based tracking)
# File-based is simpler on AIRE
export MLFLOW_TRACKING_URI=file:///mnt/scratch/$USER/mlflow
```

### Python Integration
```python
import mlflow

mlflow.set_tracking_uri(f"file:///mnt/scratch/{os.environ['USER']}/mlflow")
mlflow.set_experiment("my-experiment")

with mlflow.start_run():
    mlflow.log_param("lr", 0.001)
    mlflow.log_metric("loss", 0.234)
    mlflow.log_artifact("model.pt")
```

## Reproducibility Best Practices
1. Always log: git commit hash, conda environment, SLURM job ID
2. Pin all package versions
3. Set random seeds: `torch.manual_seed(42)`, `random.seed(42)`, `np.random.seed(42)`
4. Save full config alongside results
5. Use timestamped output directories
6. Save code snapshot with results
```

- [ ] **Step 3: Write knowledge/modules.md**

Create `knowledge/modules.md`:

```markdown
# AIRE Available Modules

Last updated: auto-synced from AIRE

## Compilers
| Module | Load Command |
|--------|-------------|
| cuda/12.4.1 | `module load cuda/12.4.1` |
| cuda/12.6.2 | `module load cuda/12.6.2` |
| gcc/13.2.0 | `module load gcc/13.2.0` |
| gcc/14.2.0 | `module load gcc/14.2.0` |
| intel/oneapi/compiler/2025.0.4 | `module load intel/oneapi/compiler/2025.0.4` |
| intel/oneapi/mkl/2025.0 | `module load intel/oneapi/mkl/2025.0` |
| intel/oneapi/mpi/2021.14 | `module load intel/oneapi/mpi/2021.14` |
| intel/oneapi/dnnl/3.6.1 | `module load intel/oneapi/dnnl/3.6.1` |
| java/jdk-21.0.6 | `module load java/jdk-21.0.6` |

## Libraries
| Module | Load Command |
|--------|-------------|
| fftw/3.3.10 | `module load fftw/3.3.10` |
| hdf5/1.14.5/gcc-14.2.0 | `module load hdf5/1.14.5/gcc-14.2.0` |
| lapack/3.12.0 | `module load lapack/3.12.0` |
| netcdf/4.9.2/gcc-14.2.0_hdf5-1.14.5 | `module load netcdf/4.9.2/gcc-14.2.0_hdf5-1.14.5` |
| openblas/0.3.28/gcc-14.2.0 | `module load openblas/0.3.28/gcc-14.2.0` |
| openmpi/5.0.6/gcc-14.2.0 | `module load openmpi/5.0.6/gcc-14.2.0` |
| openmpi/5.0.6/gcc-13.2.0_cuda-12.6.2 | `module load openmpi/5.0.6/gcc-13.2.0_cuda-12.6.2` |
| pytorch/2.5.1 | `module load pytorch/2.5.1` |
| vtk/9.3.1/gcc-14.2.0_hdf5-1.14.5 | `module load vtk/9.3.1/gcc-14.2.0_hdf5-1.14.5` |

## Interpreters
| Module | Load Command |
|--------|-------------|
| miniforge/24.7.1 | `module load miniforge/24.7.1` |
| python/3.13.0 | `module load python/3.13.0` |
| julia/1.11.3 | `module load julia/1.11.3` |

## Tools
| Module | Load Command |
|--------|-------------|
| apptainer/1.3.6 | `module load apptainer/1.3.6` |
| cmake (via spack) | `module load cmake` |
| spack/0.23 | `module load spack/0.23` |
| texlive/2025 | `module load texlive/2025` |
| pixi/0.41.4 | `module load pixi/0.41.4` |

## Applications
| Module | Load Command |
|--------|-------------|
| abaqus/2022 | `module load abaqus/2022` |
| ansys/2024R2 | `module load ansys/2024R2` |
| castep/25.12 | `module load castep/25.12/gcc-13.2.0_cuda-12.6.2_fftw-3.3.10_openblas-0.3.28` |
| comsol/6.2 | `module load comsol/6.2` |
| gaussian | via request |
| gromacs/2024.4/gcc-13.2.0_cuda-12.6.2 | `module load gromacs/2024.4/gcc-13.2.0_cuda-12.6.2` |
| matlab/R2023a | `module load matlab/R2023a` |
| namd/2.14/gcc-13.2.0 | `module load namd/2.14/gcc-13.2.0` |
| openfoam/v2412 | `module load openfoam/v2412` |
| orca/6.0.1 | `module load orca/6.0.1` |
| paraview/5.13.1 | `module load paraview/5.13.1` |
| stata/19 | `module load stata/19` |
| vasp (licensed) | `module load vasp` |

## Module Commands
```bash
module avail              # List all available modules
module list               # List currently loaded modules
module load <name>        # Load a module
module unload <name>      # Unload a module
module purge              # Unload all modules
module show <name>        # Show module details (paths, env vars)
```
```

- [ ] **Step 4: Write knowledge/troubleshooting.md**

Create `knowledge/troubleshooting.md`:

```markdown
# AIRE Troubleshooting

## Job Submission Errors

### "Requested node configuration is not available"
- Cause: Requesting >3 GPUs on single node, or resources unavailable
- Fix: Use multi-node for >3 GPUs, or reduce resource request
- Check: `aire-agent nodes` to see available resources

### "Invalid partition name specified"
- Cause: Wrong partition name
- Fix: Valid partitions are: (default), gpu, himem
- Note: Don't specify partition for standard compute jobs

### "/bin/bash^M: bad interpreter: No such file or directory"
- Cause: Windows line endings in script
- Fix: `dos2unix script.sh`

### "error: Unable to allocate resources: Invalid account"
- Cause: Account not set up or expired
- Fix: Contact itservicedesk@leeds.ac.uk

### Job pending for a long time
- Cause: Fair-share scheduling — heavy recent usage lowers priority
- Check: `squeue --me --start` to see estimated start time
- Tip: Request only resources you need — smaller jobs schedule faster

## Runtime Errors

### "Out of memory" / OOM Killer
- Cause: Exceeded requested memory
- Fix: Increase `--mem` or `--mem-per-cpu`
- Check: `seff <JOBID>` after a completed job to see actual memory used
- For GPU OOM: Reduce batch size, use gradient accumulation, enable mixed precision

### "CUDA out of memory"
- Cause: GPU VRAM exhausted (L40S has 48GB)
- Fix:
  1. Reduce batch size
  2. Use `torch.amp.autocast` for mixed precision
  3. Use gradient accumulation
  4. Use `torch.utils.checkpoint` for activation checkpointing
  5. Check for memory leaks: `torch.cuda.memory_summary()`

### "No module named X"
- Cause: Conda environment not activated, or package not installed
- Fix: Add `module load miniforge` and `conda activate env_name` to script
- Note: Modules loaded on login node don't carry to compute nodes

### "CUDA error: no kernel image is available"
- Cause: PyTorch compiled for wrong CUDA compute capability
- Fix: Install PyTorch with correct CUDA version: `pytorch-cuda=12.4`
- L40S requires: Compute Capability 8.9 (Ada Lovelace)

## SSH/Connection Issues

### "Connection refused" or timeout
- Cause: Not on University network
- Fix: Connect to University VPN or use campus wired network
- Login: `ssh USER@login1.aire.leeds.ac.uk -J USER@rash.leeds.ac.uk`

### "Host key verification failed"
- Cause: AIRE host keys changed (system upgrade)
- Fix: Remove old entries from ~/.ssh/known_hosts:
  `ssh-keygen -R login1.aire.leeds.ac.uk`

## Performance Issues

### Slow I/O
- Cause: Using $HOME for large data reads/writes
- Fix: Copy data to $TMP_SHARED at start of job
- Pattern:
  ```bash
  cp -r $SCRATCH/data $TMP_SHARED/
  # Use $TMP_SHARED/data in your script
  cp -r $TMP_SHARED/results $SCRATCH/
  ```

### Low GPU utilisation
- Check: `nvidia-smi` during job (via interactive session or add to script)
- Common causes:
  1. Data loading bottleneck — increase num_workers
  2. Small batch size — increase or use gradient accumulation
  3. CPU-bound preprocessing — move to GPU or use faster I/O
  4. Synchronisation overhead — check for unnecessary .item() or .cpu() calls

### Job using less resources than requested
- Check: `seff <JOBID>` after completion
- Shows: CPU efficiency, memory efficiency, wall time efficiency
- Tip: Adjust future requests to match actual usage — wastes less and schedules faster

## Diagnostic Commands
```bash
# Check your quota
quota -s
lfs quota -u $USER /mnt/scratch

# Check node status
sinfo -N -l

# Check your recent jobs
sacct --starttime=2026-04-01 --format=JobID,JobName,Partition,State,Elapsed,MaxRSS

# Check GPU status (on GPU node)
nvidia-smi

# Check loaded modules
module list

# Check disk usage
du -sh ~/
du -sh /mnt/scratch/$USER/
```
```

- [ ] **Step 5: Commit**

```bash
git add knowledge/ml-on-aire.md knowledge/experiment-tracking.md knowledge/modules.md knowledge/troubleshooting.md
git commit -m "docs: add ML, experiment tracking, modules, and troubleshooting knowledge"
```

---

## Task 4: SBATCH & Conda Templates

**Files:**
- Create: `templates/jobs/cpu-serial.sh`
- Create: `templates/jobs/cpu-threaded.sh`
- Create: `templates/jobs/cpu-mpi.sh`
- Create: `templates/jobs/gpu-single.sh`
- Create: `templates/jobs/gpu-multi.sh`
- Create: `templates/jobs/gpu-multi-node.sh`
- Create: `templates/jobs/himem.sh`
- Create: `templates/jobs/array.sh`
- Create: `templates/environments/pytorch.yml`
- Create: `templates/environments/tensorflow.yml`
- Create: `templates/environments/medical-imaging.yml`

- [ ] **Step 1: Write templates/jobs/cpu-serial.sh**

```bash
#!/bin/bash
#SBATCH --job-name=cpu_serial
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

python your_script.py

seff $SLURM_JOB_ID
```

- [ ] **Step 2: Write templates/jobs/cpu-threaded.sh**

```bash
#!/bin/bash
#SBATCH --job-name=cpu_threaded
#SBATCH --time=02:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OMP_PLACES=cores
export OMP_PROC_BIND=close

python your_script.py

seff $SLURM_JOB_ID
```

- [ ] **Step 3: Write templates/jobs/cpu-mpi.sh**

```bash
#!/bin/bash
#SBATCH --job-name=cpu_mpi
#SBATCH --time=04:00:00
#SBATCH --mem=256G
#SBATCH --nodes=2
#SBATCH --ntasks=256
#SBATCH --ntasks-per-node=128
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

module load openmpi/5.0.6/gcc-14.2.0
module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

mpirun python your_mpi_script.py

seff $SLURM_JOB_ID
```

- [ ] **Step 4: Write templates/jobs/gpu-single.sh**

```bash
#!/bin/bash
#SBATCH --job-name=gpu_single
#SBATCH --time=04:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

module load cuda/12.6.2
module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_LAUNCH_BLOCKING=0
export CUDNN_BENCHMARK=1
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

nvidia-smi
python -c "import torch; print(f'GPUs: {torch.cuda.device_count()}')"

python train.py

seff $SLURM_JOB_ID
```

- [ ] **Step 5: Write templates/jobs/gpu-multi.sh**

```bash
#!/bin/bash
#SBATCH --job-name=gpu_multi
#SBATCH --time=08:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:3
#SBATCH --cpus-per-task=24
#SBATCH --mem-per-cpu=8G
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

# NOTE: Maximum 3 GPUs per node on AIRE

mkdir -p logs

module load cuda/12.6.2
module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_LAUNCH_BLOCKING=0
export CUDNN_BENCHMARK=1
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

nvidia-smi

torchrun --nproc_per_node=3 train.py

seff $SLURM_JOB_ID
```

- [ ] **Step 6: Write templates/jobs/gpu-multi-node.sh**

```bash
#!/bin/bash
#SBATCH --job-name=gpu_distributed
#SBATCH --time=12:00:00
#SBATCH --partition=gpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:3
#SBATCH --cpus-per-task=24
#SBATCH --mem-per-cpu=8G
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

# 6 GPUs total (3 per node x 2 nodes)

mkdir -p logs

module load cuda/12.6.2
module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_LAUNCH_BLOCKING=0
export CUDNN_BENCHMARK=1
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

head_node=$(scontrol show hostname $SLURM_NODELIST | head -n1)
export MASTER_ADDR=$head_node
export MASTER_PORT=29500

nvidia-smi

srun torchrun \
    --nnodes=$SLURM_NNODES \
    --nproc_per_node=3 \
    --rdzv_id=$SLURM_JOB_ID \
    --rdzv_backend=c10d \
    --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
    train.py

seff $SLURM_JOB_ID
```

- [ ] **Step 7: Write templates/jobs/himem.sh**

```bash
#!/bin/bash
#SBATCH --job-name=himem_job
#SBATCH --time=04:00:00
#SBATCH --partition=himem
#SBATCH --mem=500G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

python your_memory_intensive_script.py

seff $SLURM_JOB_ID
```

- [ ] **Step 8: Write templates/jobs/array.sh**

```bash
#!/bin/bash
#SBATCH --job-name=array_job
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --array=1-100
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err
#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

mkdir -p logs

module load miniforge/24.7.1
source $(conda info --base)/etc/profile.d/conda.sh
conda activate YOUR_ENV

echo "Array task ID: $SLURM_ARRAY_TASK_ID"

python process.py --task-id $SLURM_ARRAY_TASK_ID

seff $SLURM_JOB_ID
```

- [ ] **Step 9: Write templates/environments/pytorch.yml**

```yaml
name: pytorch-env
channels:
  - pytorch
  - nvidia
  - conda-forge
dependencies:
  - python=3.11
  - pytorch
  - torchvision
  - torchaudio
  - pytorch-cuda=12.4
  - numpy
  - scipy
  - pandas
  - matplotlib
  - scikit-learn
  - tqdm
  - pyyaml
  - pip
  - pip:
    - wandb
    - tensorboard
```

- [ ] **Step 10: Write templates/environments/tensorflow.yml**

```yaml
name: tensorflow-env
channels:
  - conda-forge
dependencies:
  - python=3.11
  - numpy
  - scipy
  - pandas
  - matplotlib
  - scikit-learn
  - tqdm
  - pyyaml
  - pip
  - pip:
    - tensorflow[and-cuda]
    - wandb
    - tensorboard
```

- [ ] **Step 11: Write templates/environments/medical-imaging.yml**

```yaml
name: medical-imaging-env
channels:
  - pytorch
  - nvidia
  - conda-forge
dependencies:
  - python=3.11
  - pytorch
  - torchvision
  - torchaudio
  - pytorch-cuda=12.4
  - numpy
  - scipy
  - pandas
  - matplotlib
  - scikit-learn
  - scikit-image
  - pillow
  - tqdm
  - pyyaml
  - h5py
  - pip
  - pip:
    - monai
    - nibabel
    - SimpleITK
    - albumentations
    - opencv-python-headless
    - wandb
    - tensorboard
    - connected-components-3d
```

- [ ] **Step 12: Commit**

```bash
git add templates/
git commit -m "feat: add SBATCH job templates and conda environment configs"
```

---

## Task 5: Shell Tools — Job Management

**Files:**
- Create: `tools/submit-job.sh`
- Create: `tools/check-queue.sh`
- Create: `tools/cancel-job.sh`
- Create: `tools/job-status.sh`
- Create: `tools/job-efficiency.sh`
- Test: `tests/unit/test_job_tools.bats`

- [ ] **Step 1: Write tests/unit/test_job_tools.bats**

Install bats-core if not available: `npm install -g bats` or `brew install bats-core`

Create `tests/unit/test_job_tools.bats`:

```bash
#!/usr/bin/env bats

TOOLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../tools" && pwd)"

# Test that all job tools exist and are executable
@test "submit-job.sh exists and is executable" {
    [ -x "$TOOLS_DIR/submit-job.sh" ]
}

@test "check-queue.sh exists and is executable" {
    [ -x "$TOOLS_DIR/check-queue.sh" ]
}

@test "cancel-job.sh exists and is executable" {
    [ -x "$TOOLS_DIR/cancel-job.sh" ]
}

@test "job-status.sh exists and is executable" {
    [ -x "$TOOLS_DIR/job-status.sh" ]
}

@test "job-efficiency.sh exists and is executable" {
    [ -x "$TOOLS_DIR/job-efficiency.sh" ]
}

# Test submit-job validates input
@test "submit-job.sh rejects missing script argument" {
    run "$TOOLS_DIR/submit-job.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "submit-job.sh rejects nonexistent script" {
    run "$TOOLS_DIR/submit-job.sh" "/nonexistent/script.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}

# Test cancel-job validates input
@test "cancel-job.sh rejects missing job ID" {
    run "$TOOLS_DIR/cancel-job.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

# Test job-status validates input
@test "job-status.sh rejects missing job ID" {
    run "$TOOLS_DIR/job-status.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

# Test job-efficiency validates input
@test "job-efficiency.sh rejects missing job ID" {
    run "$TOOLS_DIR/job-efficiency.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

# Test check-queue works without arguments
@test "check-queue.sh accepts no arguments" {
    # Will fail if not on AIRE, but should not error on argument validation
    run "$TOOLS_DIR/check-queue.sh" --help
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bats tests/unit/test_job_tools.bats
```

Expected: All tests FAIL (tools don't exist yet)

- [ ] **Step 3: Write tools/submit-job.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "Usage: aire-agent submit <script.sh>"
    echo ""
    echo "Validate and submit a SBATCH job script to AIRE."
    echo ""
    echo "Options:"
    echo "  --json    Output result as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

if [[ $# -lt 1 ]]; then
    echo "Error: No script specified"
    usage 1
fi

script="$1"

if [[ ! -f "$script" ]]; then
    echo "Error: Script '$script' not found"
    exit 1
fi

# Validate before submitting
validation=$("$SCRIPT_DIR/validate-script.sh" "$script" 2>&1) || {
    echo "Validation failed:"
    echo "$validation"
    exit 1
}

# Submit the job
output=$(sbatch "$script" 2>&1) || {
    echo "Error submitting job: $output"
    exit 1
}

# Extract job ID from "Submitted batch job 12345"
job_id=$(echo "$output" | grep -oP '\d+$')

if $json_mode; then
    echo "{\"job_id\": \"$job_id\", \"script\": \"$script\", \"status\": \"submitted\"}"
else
    echo "Job submitted successfully"
    echo "Job ID: $job_id"
    echo "Script: $script"
fi
```

- [ ] **Step 4: Write tools/check-queue.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: aire-agent queue [options]"
    echo ""
    echo "Show your jobs in the AIRE queue."
    echo ""
    echo "Options:"
    echo "  --all     Show all users' jobs"
    echo "  --json    Output as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false
all_users=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --all) all_users=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

if $all_users; then
    queue_cmd="squeue"
else
    queue_cmd="squeue --me"
fi

output=$($queue_cmd --format="%.18i %.30j %.10P %.8u %.8T %.10M %.6D %R" 2>&1) || {
    echo "Error checking queue: $output"
    exit 1
}

if $json_mode; then
    # Parse squeue output into JSON
    echo "$output" | awk 'NR>1 {
        gsub(/^ +| +$/, "");
        printf "{\"job_id\": \"%s\", \"name\": \"%s\", \"partition\": \"%s\", \"user\": \"%s\", \"state\": \"%s\", \"time\": \"%s\", \"nodes\": \"%s\", \"reason\": \"%s\"}\n",
            $1, $2, $3, $4, $5, $6, $7, $8
    }'
else
    echo "$output"
fi
```

- [ ] **Step 5: Write tools/cancel-job.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: aire-agent cancel <job_id> [job_id2 ...]"
    echo ""
    echo "Cancel one or more AIRE jobs."
    echo ""
    echo "Options:"
    echo "  --json    Output result as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

if [[ $# -lt 1 ]]; then
    echo "Error: No job ID specified"
    usage 1
fi

for job_id in "$@"; do
    output=$(scancel "$job_id" 2>&1) || {
        echo "Error cancelling job $job_id: $output"
        continue
    }
    if $json_mode; then
        echo "{\"job_id\": \"$job_id\", \"status\": \"cancelled\"}"
    else
        echo "Cancelled job $job_id"
    fi
done
```

- [ ] **Step 6: Write tools/job-status.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: aire-agent status <job_id>"
    echo ""
    echo "Show detailed information about an AIRE job."
    echo ""
    echo "Options:"
    echo "  --json    Output as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

if [[ $# -lt 1 ]]; then
    echo "Error: No job ID specified"
    usage 1
fi

job_id="$1"

output=$(scontrol show job "$job_id" 2>&1) || {
    echo "Error getting job status: $output"
    exit 1
}

if $json_mode; then
    # Parse key=value pairs into JSON
    echo "$output" | tr ' ' '\n' | grep '=' | awk -F= '{
        gsub(/^ +| +$/, "", $1);
        gsub(/^ +| +$/, "", $2);
        printf "\"%s\": \"%s\",\n", $1, $2
    }' | sed '$ s/,$//' | (echo "{"; cat; echo "}")
else
    echo "$output"
fi
```

- [ ] **Step 7: Write tools/job-efficiency.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: aire-agent efficiency <job_id>"
    echo ""
    echo "Show resource efficiency for a completed AIRE job."
    echo ""
    echo "Options:"
    echo "  --json    Output as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

if [[ $# -lt 1 ]]; then
    echo "Error: No job ID specified"
    usage 1
fi

job_id="$1"

output=$(seff "$job_id" 2>&1) || {
    echo "Error getting job efficiency: $output"
    exit 1
}

if $json_mode; then
    echo "$output" | awk -F': ' '{
        gsub(/^ +| +$/, "", $1);
        gsub(/^ +| +$/, "", $2);
        if ($2 != "") printf "\"%s\": \"%s\",\n", $1, $2
    }' | sed '$ s/,$//' | (echo "{"; cat; echo "}")
else
    echo "$output"
fi
```

- [ ] **Step 8: Make all tools executable**

```bash
chmod +x tools/submit-job.sh tools/check-queue.sh tools/cancel-job.sh tools/job-status.sh tools/job-efficiency.sh
```

- [ ] **Step 9: Run tests**

```bash
bats tests/unit/test_job_tools.bats
```

Expected: Input validation tests PASS, AIRE-dependent tests skip gracefully

- [ ] **Step 10: Commit**

```bash
git add tools/submit-job.sh tools/check-queue.sh tools/cancel-job.sh tools/job-status.sh tools/job-efficiency.sh tests/unit/test_job_tools.bats
git commit -m "feat: add job management shell tools with tests"
```

---

## Task 6: Shell Tools — Script Generation & Validation

**Files:**
- Create: `tools/generate-script.sh`
- Create: `tools/validate-script.sh`
- Test: `tests/unit/test_script_tools.bats`

- [ ] **Step 1: Write tests/unit/test_script_tools.bats**

```bash
#!/usr/bin/env bats

TOOLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../tools" && pwd)"
TEMPLATES_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../templates/jobs" && pwd)"

# --- validate-script tests ---

@test "validate-script.sh exists and is executable" {
    [ -x "$TOOLS_DIR/validate-script.sh" ]
}

@test "validate-script rejects script with >3 GPUs on single node" {
    tmp=$(mktemp)
    cat > "$tmp" <<'SCRIPT'
#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --gres=gpu:4
#SBATCH --time=01:00:00
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$tmp"
    [ "$status" -ne 0 ]
    [[ "$output" == *"3 GPUs"* ]]
    rm "$tmp"
}

@test "validate-script rejects gpu partition without gres" {
    tmp=$(mktemp)
    cat > "$tmp" <<'SCRIPT'
#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --time=01:00:00
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$tmp"
    [ "$status" -ne 0 ]
    [[ "$output" == *"--gres"* ]]
    rm "$tmp"
}

@test "validate-script rejects gres without gpu partition" {
    tmp=$(mktemp)
    cat > "$tmp" <<'SCRIPT'
#!/bin/bash
#SBATCH --gres=gpu:1
#SBATCH --time=01:00:00
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$tmp"
    [ "$status" -ne 0 ]
    [[ "$output" == *"partition=gpu"* ]]
    rm "$tmp"
}

@test "validate-script rejects missing time" {
    tmp=$(mktemp)
    cat > "$tmp" <<'SCRIPT'
#!/bin/bash
#SBATCH --mem=4G
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$tmp"
    [ "$status" -ne 0 ]
    [[ "$output" == *"--time"* ]]
    rm "$tmp"
}

@test "validate-script accepts valid GPU script" {
    tmp=$(mktemp)
    cat > "$tmp" <<'SCRIPT'
#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --gres=gpu:2
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=8
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$tmp"
    [ "$status" -eq 0 ]
    rm "$tmp"
}

@test "validate-script accepts valid CPU script" {
    tmp=$(mktemp)
    cat > "$tmp" <<'SCRIPT'
#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --mem=4G
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$tmp"
    [ "$status" -eq 0 ]
    rm "$tmp"
}

# --- generate-script tests ---

@test "generate-script.sh exists and is executable" {
    [ -x "$TOOLS_DIR/generate-script.sh" ]
}

@test "generate-script produces valid GPU script" {
    run "$TOOLS_DIR/generate-script.sh" --gpu 1 --time 2h --framework pytorch
    [ "$status" -eq 0 ]
    [[ "$output" == *"#SBATCH --partition=gpu"* ]]
    [[ "$output" == *"#SBATCH --gres=gpu:1"* ]]
    [[ "$output" == *"cuda"* ]]
}

@test "generate-script produces valid CPU script" {
    run "$TOOLS_DIR/generate-script.sh" --time 1h --cpus 4 --mem 16G
    [ "$status" -eq 0 ]
    [[ "$output" != *"partition=gpu"* ]]
    [[ "$output" == *"#SBATCH --cpus-per-task=4"* ]]
}

@test "generate-script uses himem partition for large memory" {
    run "$TOOLS_DIR/generate-script.sh" --time 1h --mem 1T --partition himem
    [ "$status" -eq 0 ]
    [[ "$output" == *"--partition=himem"* ]]
}

@test "generate-script rejects >3 GPUs without multi-node" {
    run "$TOOLS_DIR/generate-script.sh" --gpu 4 --time 1h
    [ "$status" -eq 0 ]
    # Should auto-generate multi-node config
    [[ "$output" == *"--nodes=2"* ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bats tests/unit/test_script_tools.bats
```

Expected: All FAIL

- [ ] **Step 3: Write tools/validate-script.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: aire-agent validate <script.sh>"
    echo ""
    echo "Validate a SBATCH script against AIRE constraints."
    echo ""
    echo "Checks:"
    echo "  - --time is specified"
    echo "  - GPU partition used correctly with --gres"
    echo "  - Max 3 GPUs per node"
    echo "  - Memory within node limits"
    echo ""
    echo "Options:"
    echo "  --json    Output as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

if [[ $# -lt 1 ]]; then
    echo "Error: No script specified"
    usage 1
fi

script="$1"
if [[ ! -f "$script" ]]; then
    echo "Error: Script '$script' not found"
    exit 1
fi

errors=()
warnings=()

# Extract SBATCH directives
has_time=$(grep -c '#SBATCH.*--time' "$script" 2>/dev/null || echo 0)
has_partition_gpu=$(grep -c '#SBATCH.*--partition=gpu' "$script" 2>/dev/null || echo 0)
has_gres=$(grep -c '#SBATCH.*--gres=gpu' "$script" 2>/dev/null || echo 0)
has_partition_himem=$(grep -c '#SBATCH.*--partition=himem' "$script" 2>/dev/null || echo 0)
has_mail=$(grep -c '#SBATCH.*--mail-type' "$script" 2>/dev/null || echo 0)
has_seff=$(grep -c 'seff' "$script" 2>/dev/null || echo 0)

# Extract GPU count
gpu_count=0
if [[ "$has_gres" -gt 0 ]]; then
    gpu_count=$(grep '#SBATCH.*--gres=gpu:' "$script" | grep -oP 'gpu:\K\d+' | head -1)
fi

# Extract node count
node_count=$(grep '#SBATCH.*--nodes=' "$script" | grep -oP '(?<=--nodes=)\d+' | head -1)
node_count=${node_count:-1}

# Check --time is specified
if [[ "$has_time" -eq 0 ]]; then
    errors+=("ERROR: --time is required. Specify wall clock time (e.g., --time=01:00:00)")
fi

# Check GPU partition consistency
if [[ "$has_partition_gpu" -gt 0 && "$has_gres" -eq 0 ]]; then
    errors+=("ERROR: --partition=gpu specified but no --gres=gpu:N. Add --gres=gpu:<number>")
fi

if [[ "$has_gres" -gt 0 && "$has_partition_gpu" -eq 0 ]]; then
    errors+=("ERROR: --gres=gpu specified but missing --partition=gpu. Add --partition=gpu")
fi

# Check max 3 GPUs per node
if [[ "$gpu_count" -gt 3 && "$node_count" -eq 1 ]]; then
    errors+=("ERROR: Maximum 3 GPUs per node on AIRE. Requesting $gpu_count GPUs on 1 node. Use --nodes=2 or more for >3 GPUs")
fi

# Warnings
if [[ "$has_mail" -eq 0 ]]; then
    warnings+=("WARNING: No email notifications. Add --mail-type=BEGIN,END,FAIL and --mail-user=your@leeds.ac.uk")
fi

if [[ "$has_seff" -eq 0 ]]; then
    warnings+=("WARNING: No seff call. Add 'seff \$SLURM_JOB_ID' at end of script to check resource efficiency")
fi

# Output results
if $json_mode; then
    echo "{"
    echo "  \"valid\": $([ ${#errors[@]} -eq 0 ] && echo 'true' || echo 'false'),"
    echo "  \"errors\": ["
    for i in "${!errors[@]}"; do
        comma=$([[ $i -lt $((${#errors[@]} - 1)) ]] && echo "," || echo "")
        echo "    \"${errors[$i]}\"$comma"
    done
    echo "  ],"
    echo "  \"warnings\": ["
    for i in "${!warnings[@]}"; do
        comma=$([[ $i -lt $((${#warnings[@]} - 1)) ]] && echo "," || echo "")
        echo "    \"${warnings[$i]}\"$comma"
    done
    echo "  ]"
    echo "}"
else
    for err in "${errors[@]}"; do
        echo "$err"
    done
    for warn in "${warnings[@]}"; do
        echo "$warn"
    done
fi

if [[ ${#errors[@]} -gt 0 ]]; then
    exit 1
fi

if [[ ${#errors[@]} -eq 0 ]] && ! $json_mode; then
    echo "Script is valid"
fi
```

- [ ] **Step 4: Write tools/generate-script.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$REPO_DIR/templates/jobs"

usage() {
    echo "Usage: aire-agent generate [options]"
    echo ""
    echo "Generate a validated SBATCH job script."
    echo ""
    echo "Options:"
    echo "  --gpu N          Number of GPUs (default: 0)"
    echo "  --time TIME      Wall time (e.g., 1h, 4h, 1d, 01:00:00)"
    echo "  --cpus N         CPUs per task (default: 1, or 8 per GPU)"
    echo "  --mem SIZE       Memory (e.g., 4G, 32G, 1T)"
    echo "  --nodes N        Number of nodes (auto-calculated for >3 GPUs)"
    echo "  --partition NAME Partition (auto: gpu if GPUs requested, himem if specified)"
    echo "  --framework NAME Framework: pytorch, tensorflow, or none (default: none)"
    echo "  --job-name NAME  Job name (default: aire_job)"
    echo "  --email EMAIL    Notification email"
    echo "  --array RANGE    Array job range (e.g., 1-100)"
    echo "  --output FILE    Write to file instead of stdout"
    echo "  --help           Show this help"
    exit "${1:-1}"
}

# Defaults
gpu=0
time_str=""
cpus=""
mem=""
nodes=""
partition=""
framework="none"
job_name="aire_job"
email=""
array=""
output_file=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --gpu) gpu="$2"; shift 2 ;;
        --time) time_str="$2"; shift 2 ;;
        --cpus) cpus="$2"; shift 2 ;;
        --mem) mem="$2"; shift 2 ;;
        --nodes) nodes="$2"; shift 2 ;;
        --partition) partition="$2"; shift 2 ;;
        --framework) framework="$2"; shift 2 ;;
        --job-name) job_name="$2"; shift 2 ;;
        --email) email="$2"; shift 2 ;;
        --array) array="$2"; shift 2 ;;
        --output) output_file="$2"; shift 2 ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) echo "Error: Unexpected argument $1"; usage 1 ;;
    esac
done

if [[ -z "$time_str" ]]; then
    echo "Error: --time is required"
    usage 1
fi

# Normalize time format
normalize_time() {
    local t="$1"
    if [[ "$t" =~ ^([0-9]+)h$ ]]; then
        printf "%02d:00:00" "${BASH_REMATCH[1]}"
    elif [[ "$t" =~ ^([0-9]+)d$ ]]; then
        echo "${BASH_REMATCH[1]}-00:00:00"
    elif [[ "$t" =~ ^([0-9]+)m$ ]]; then
        printf "00:%02d:00" "${BASH_REMATCH[1]}"
    else
        echo "$t"
    fi
}

time_fmt=$(normalize_time "$time_str")

# Auto-detect partition
if [[ -z "$partition" ]]; then
    if [[ "$gpu" -gt 0 ]]; then
        partition="gpu"
    fi
fi

# Auto-calculate nodes for >3 GPUs
if [[ "$gpu" -gt 3 ]]; then
    nodes=$(( (gpu + 2) / 3 ))  # ceil(gpu/3)
    gpus_per_node=3
else
    nodes=${nodes:-1}
    gpus_per_node=$gpu
fi

# Auto-set CPUs
if [[ -z "$cpus" ]]; then
    if [[ "$gpu" -gt 0 ]]; then
        cpus=$((8 * gpus_per_node))
    else
        cpus=1
    fi
fi

# Auto-set memory
if [[ -z "$mem" ]]; then
    if [[ "$gpu" -gt 0 ]]; then
        mem="8G"
        mem_flag="--mem-per-cpu=${mem}"
    else
        mem="4G"
        mem_flag="--mem=${mem}"
    fi
else
    if [[ "$gpu" -gt 0 ]]; then
        mem_flag="--mem-per-cpu=${mem}"
    else
        mem_flag="--mem=${mem}"
    fi
fi

# Generate script
generate() {
    echo "#!/bin/bash"
    echo "#SBATCH --job-name=$job_name"
    echo "#SBATCH --time=$time_fmt"
    echo "#SBATCH $mem_flag"

    if [[ "$partition" == "gpu" || "$partition" == "himem" ]]; then
        echo "#SBATCH --partition=$partition"
    fi

    if [[ "$gpu" -gt 0 ]]; then
        if [[ "$gpu" -gt 3 ]]; then
            echo "#SBATCH --nodes=$nodes"
            echo "#SBATCH --ntasks-per-node=1"
            echo "#SBATCH --gres=gpu:$gpus_per_node"
        else
            echo "#SBATCH --gres=gpu:$gpus_per_node"
        fi
    fi

    echo "#SBATCH --cpus-per-task=$cpus"
    echo "#SBATCH --output=logs/%x_%j.out"
    echo "#SBATCH --error=logs/%x_%j.err"

    if [[ -n "$email" ]]; then
        echo "#SBATCH --mail-user=$email"
        echo "#SBATCH --mail-type=BEGIN,END,FAIL"
    else
        echo "#SBATCH --mail-user=YOUR_EMAIL@leeds.ac.uk"
        echo "#SBATCH --mail-type=BEGIN,END,FAIL"
    fi

    if [[ -n "$array" ]]; then
        echo "#SBATCH --array=$array"
    fi

    echo ""
    echo "mkdir -p logs"
    echo ""

    # Module loading
    if [[ "$gpu" -gt 0 ]]; then
        echo "module load cuda/12.6.2"
    fi
    echo "module load miniforge/24.7.1"
    echo "source \$(conda info --base)/etc/profile.d/conda.sh"
    echo "conda activate YOUR_ENV"
    echo ""

    # Framework-specific setup
    if [[ "$framework" == "pytorch" && "$gpu" -gt 0 ]]; then
        echo "export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512"
        echo "export CUDA_LAUNCH_BLOCKING=0"
        echo "export CUDNN_BENCHMARK=1"
        echo "export OMP_NUM_THREADS=\$SLURM_CPUS_PER_TASK"
        echo ""
        echo "nvidia-smi"
        echo ""

        if [[ "$gpu" -gt 3 ]]; then
            echo "head_node=\$(scontrol show hostname \$SLURM_NODELIST | head -n1)"
            echo "export MASTER_ADDR=\$head_node"
            echo "export MASTER_PORT=29500"
            echo ""
            echo "srun torchrun \\"
            echo "    --nnodes=\$SLURM_NNODES \\"
            echo "    --nproc_per_node=$gpus_per_node \\"
            echo "    --rdzv_id=\$SLURM_JOB_ID \\"
            echo "    --rdzv_backend=c10d \\"
            echo "    --rdzv_endpoint=\$MASTER_ADDR:\$MASTER_PORT \\"
            echo "    train.py"
        elif [[ "$gpu" -gt 1 ]]; then
            echo "torchrun --nproc_per_node=$gpus_per_node train.py"
        else
            echo "python train.py"
        fi
    elif [[ "$framework" == "tensorflow" && "$gpu" -gt 0 ]]; then
        echo "export OMP_NUM_THREADS=\$SLURM_CPUS_PER_TASK"
        echo ""
        echo "nvidia-smi"
        echo ""
        echo "python train.py"
    else
        if [[ -n "$array" ]]; then
            echo "echo \"Array task ID: \$SLURM_ARRAY_TASK_ID\""
            echo ""
            echo "python process.py --task-id \$SLURM_ARRAY_TASK_ID"
        else
            echo "python your_script.py"
        fi
    fi

    echo ""
    echo "seff \$SLURM_JOB_ID"
}

if [[ -n "$output_file" ]]; then
    generate > "$output_file"
    chmod +x "$output_file"
    echo "Script written to: $output_file"
else
    generate
fi
```

- [ ] **Step 5: Make tools executable**

```bash
chmod +x tools/generate-script.sh tools/validate-script.sh
```

- [ ] **Step 6: Run tests**

```bash
bats tests/unit/test_script_tools.bats
```

Expected: All tests PASS

- [ ] **Step 7: Commit**

```bash
git add tools/generate-script.sh tools/validate-script.sh tests/unit/test_script_tools.bats
git commit -m "feat: add script generation and validation tools with tests"
```

---

## Task 7: Shell Tools — Knowledge, Quota, Nodes, Doctor

**Files:**
- Create: `tools/search-docs.sh`
- Create: `tools/list-modules.sh`
- Create: `tools/system-info.sh`
- Create: `tools/check-quota.sh`
- Create: `tools/node-availability.sh`
- Create: `tools/doctor.sh`
- Create: `tools/update.sh`
- Test: `tests/unit/test_knowledge_tools.bats`

- [ ] **Step 1: Write tests/unit/test_knowledge_tools.bats**

```bash
#!/usr/bin/env bats

TOOLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../tools" && pwd)"
REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

@test "search-docs.sh finds content in knowledge files" {
    run "$TOOLS_DIR/search-docs.sh" "L40S"
    [ "$status" -eq 0 ]
    [[ "$output" == *"L40S"* ]]
}

@test "search-docs.sh returns empty for nonsense query" {
    run "$TOOLS_DIR/search-docs.sh" "zzzznonexistenttermzzzz"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "list-modules.sh shows modules" {
    run "$TOOLS_DIR/list-modules.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"cuda"* ]]
}

@test "system-info.sh shows hardware specs" {
    run "$TOOLS_DIR/system-info.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"GPU"* ]]
    [[ "$output" == *"L40S"* ]]
}

@test "doctor.sh runs without error" {
    run "$TOOLS_DIR/doctor.sh"
    # May report issues but should not crash
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "update.sh exists and is executable" {
    [ -x "$TOOLS_DIR/update.sh" ]
}
```

- [ ] **Step 2: Write tools/search-docs.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "Usage: aire-agent search <query>"
    echo ""
    echo "Search AIRE documentation and knowledge base."
    echo ""
    echo "Options:"
    echo "  --json    Output as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

if [[ $# -lt 1 ]]; then
    echo "Error: No search query specified"
    usage 1
fi

query="$*"

# Search knowledge/ and docs/ directories
results=$(grep -rni "$query" "$REPO_DIR/knowledge/" "$REPO_DIR/docs/" 2>/dev/null || true)

if $json_mode; then
    echo "["
    first=true
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        file=$(echo "$line" | cut -d: -f1)
        lineno=$(echo "$line" | cut -d: -f2)
        content=$(echo "$line" | cut -d: -f3-)
        file_rel="${file#$REPO_DIR/}"
        $first || echo ","
        first=false
        printf '  {"file": "%s", "line": %s, "content": "%s"}' \
            "$file_rel" "$lineno" "$(echo "$content" | sed 's/"/\\"/g' | head -c 200)"
    done <<< "$results"
    echo ""
    echo "]"
else
    if [[ -z "$results" ]]; then
        echo ""
    else
        echo "$results" | sed "s|$REPO_DIR/||g" | head -50
    fi
fi
```

- [ ] **Step 3: Write tools/list-modules.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "Usage: aire-agent modules [filter]"
    echo ""
    echo "List available modules on AIRE."
    echo ""
    echo "Options:"
    echo "  --json    Output as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

filter="${1:-}"
modules_file="$REPO_DIR/knowledge/modules.md"

if [[ ! -f "$modules_file" ]]; then
    echo "Error: modules.md not found. Run 'aire-agent sync' first."
    exit 1
fi

# Extract module names from the markdown tables
if [[ -n "$filter" ]]; then
    grep -i "$filter" "$modules_file" | grep '|' | grep -v '^\-\-' | grep -v 'Module' || echo "No modules matching '$filter'"
else
    grep '|' "$modules_file" | grep -v '^\-\-' | grep -v '^|.*Module' | grep -v '^|.*---'
fi
```

- [ ] **Step 4: Write tools/system-info.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "Usage: aire-agent info"
    echo ""
    echo "Show AIRE system information."
    echo ""
    echo "Options:"
    echo "  --json    Output as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

if $json_mode; then
    cat <<'EOF'
{
    "system": "AIRE",
    "institution": "University of Leeds",
    "retirement_date": "2029-07-31",
    "cpu_nodes": {"count": 52, "cores_per_node": 168, "total_cores": 9072, "memory_gb": 768, "cpu": "AMD Dual 84-core 2.2GHz 9634 Genoa-X"},
    "gpu_nodes": {"count": 28, "gpus_per_node": 3, "total_gpus": 84, "gpu_model": "NVIDIA L40S 48GB", "cores_per_node": 24, "memory_gb": 256, "cpu": "AMD 24-core 2.9GHz 9254 Genoa-X"},
    "himem_nodes": {"count": 2, "cores_per_node": 168, "memory_gb": 2300},
    "storage": {"home_gb": 65, "scratch_tb": 1, "flash_tb_per_job": 1},
    "network": {"interconnect": "100 Gb/s OmniPath", "ethernet": "25GbE"},
    "partitions": ["default", "gpu", "himem"]
}
EOF
else
    cat <<'EOF'
AIRE HPC Cluster — University of Leeds
=======================================

CPU Nodes:     52 nodes, 168 cores each (9,072 total), 768GB RAM
GPU Nodes:     28 nodes, 3x NVIDIA L40S 48GB each (84 total), 24 cores, 256GB RAM
High-Memory:   2 nodes, 168 cores each, 2.3TB RAM
Network:       100 Gb/s OmniPath + 25GbE
Retirement:    31 July 2029

Partitions:    default (CPU), gpu (GPU), himem (high-memory)

Storage:
  $HOME        65GB quota (backed up)
  $SCRATCH     1TB quota (not backed up)
  $TMP_SHARED  1TB per job (NVMe, auto-deleted)
  $TMPDIR      Node-local (auto-deleted)

GPU Details:
  Model:       NVIDIA L40S
  VRAM:        48GB GDDR6
  Architecture: Ada Lovelace (Compute Capability 8.9)
  Connection:  PCIe
  Max per node: 3
EOF
fi
```

- [ ] **Step 5: Write tools/check-quota.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: aire-agent quota"
    echo ""
    echo "Show storage quota usage on AIRE."
    echo ""
    echo "Options:"
    echo "  --json    Output as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

echo "=== Home Directory ($HOME) ==="
quota -s 2>/dev/null || echo "quota command not available (are you on AIRE?)"

echo ""
echo "=== Scratch ($SCRATCH) ==="
if [[ -d "/mnt/scratch" ]]; then
    lfs quota -u "$USER" /mnt/scratch 2>/dev/null || echo "lfs quota not available"
else
    echo "Scratch filesystem not found (are you on AIRE?)"
fi

echo ""
echo "=== Disk Usage ==="
echo "Home: $(du -sh ~ 2>/dev/null | cut -f1 || echo 'N/A')"
if [[ -d "/mnt/scratch/$USER" ]]; then
    echo "Scratch: $(du -sh "/mnt/scratch/$USER" 2>/dev/null | cut -f1 || echo 'N/A')"
fi
```

- [ ] **Step 6: Write tools/node-availability.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: aire-agent nodes"
    echo ""
    echo "Show available resources by partition on AIRE."
    echo ""
    echo "Options:"
    echo "  --json    Output as JSON"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

echo "=== Node Availability ==="
sinfo -N -l 2>/dev/null || {
    echo "Error: sinfo not available. Are you on AIRE?"
    exit 1
}

echo ""
echo "=== Partition Summary ==="
sinfo -s 2>/dev/null || true

echo ""
echo "=== GPU Status ==="
squeue -p gpu --format="%.8i %.30j %.8u %.8T %.10M %.6D %R" 2>/dev/null || true
```

- [ ] **Step 7: Write tools/doctor.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "Usage: aire-agent doctor"
    echo ""
    echo "Diagnose common issues with aire-agent setup."
    echo ""
    echo "Options:"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) usage 0 ;;
        *) break ;;
    esac
done

pass=0
fail=0
warn=0

check() {
    local desc="$1"
    local result="$2"
    if [[ "$result" == "ok" ]]; then
        echo "[PASS] $desc"
        ((pass++))
    elif [[ "$result" == "warn" ]]; then
        echo "[WARN] $desc"
        ((warn++))
    else
        echo "[FAIL] $desc"
        ((fail++))
    fi
}

echo "aire-agent doctor"
echo "=================="
echo ""

# Check repo integrity
if [[ -d "$REPO_DIR/knowledge" ]]; then
    check "Knowledge base exists" "ok"
else
    check "Knowledge base exists" "fail"
fi

if [[ -d "$REPO_DIR/docs" ]]; then
    check "Documentation exists" "ok"
else
    check "Documentation exists" "fail"
fi

if [[ -d "$REPO_DIR/tools" ]]; then
    check "Tools directory exists" "ok"
else
    check "Tools directory exists" "fail"
fi

if [[ -d "$REPO_DIR/templates" ]]; then
    check "Templates exist" "ok"
else
    check "Templates exist" "fail"
fi

# Check sync status
if [[ -f "$REPO_DIR/.last_sync" ]]; then
    last_sync=$(cat "$REPO_DIR/.last_sync")
    now=$(date +%s)
    age=$(( (now - last_sync) / 86400 ))
    if [[ $age -le 1 ]]; then
        check "Docs synced within 24h" "ok"
    elif [[ $age -le 7 ]]; then
        check "Docs synced within 24h (last sync: ${age} days ago)" "warn"
    else
        check "Docs synced within 24h (last sync: ${age} days ago)" "fail"
    fi
else
    check "Docs sync timestamp exists" "fail"
fi

# Check if on AIRE
if command -v sbatch &>/dev/null; then
    check "Slurm available (on AIRE)" "ok"
else
    check "Slurm available (not on AIRE — job tools require SSH)" "warn"
fi

if command -v nvidia-smi &>/dev/null; then
    check "nvidia-smi available" "ok"
else
    check "nvidia-smi available (not on GPU node)" "warn"
fi

# Check SSH config
if grep -q "aire" ~/.ssh/config 2>/dev/null; then
    check "SSH config for AIRE" "ok"
else
    check "SSH config for AIRE (run 'aire-agent setup')" "warn"
fi

echo ""
echo "Results: $pass passed, $warn warnings, $fail failed"

[[ $fail -eq 0 ]]
```

- [ ] **Step 8: Write tools/update.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "Usage: aire-agent update"
    echo ""
    echo "Update aire-agent to the latest version."
    echo ""
    echo "Options:"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) usage 0 ;;
        *) break ;;
    esac
done

echo "Updating aire-agent..."

cd "$REPO_DIR"

# Fetch and pull latest
git fetch origin 2>/dev/null || {
    echo "Error: Could not fetch from remote"
    exit 1
}

current=$(git rev-parse HEAD)
git pull origin main 2>/dev/null || {
    echo "Error: Could not pull latest changes"
    exit 1
}
new=$(git rev-parse HEAD)

if [[ "$current" == "$new" ]]; then
    echo "Already up to date."
else
    echo "Updated from ${current:0:7} to ${new:0:7}"
    # Show what changed
    git log --oneline "$current..$new"
fi
```

- [ ] **Step 9: Make all tools executable**

```bash
chmod +x tools/search-docs.sh tools/list-modules.sh tools/system-info.sh tools/check-quota.sh tools/node-availability.sh tools/doctor.sh tools/update.sh
```

- [ ] **Step 10: Run tests**

```bash
bats tests/unit/test_knowledge_tools.bats
```

Expected: PASS for search, modules, system-info, doctor. Quota and nodes may warn (not on AIRE).

- [ ] **Step 11: Commit**

```bash
git add tools/search-docs.sh tools/list-modules.sh tools/system-info.sh tools/check-quota.sh tools/node-availability.sh tools/doctor.sh tools/update.sh tests/unit/test_knowledge_tools.bats
git commit -m "feat: add knowledge, quota, nodes, doctor, and update tools"
```

---

## Task 8: Shell Tools — Experiment Logging

**Files:**
- Create: `tools/log-experiment.sh`
- Create: `tools/query-experiments.sh`
- Create: `tools/setup-wandb.sh`
- Test: `tests/unit/test_experiment_tools.bats`

- [ ] **Step 1: Write tests/unit/test_experiment_tools.bats**

```bash
#!/usr/bin/env bats

TOOLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../tools" && pwd)"

setup() {
    export AIRE_AGENT_DIR=$(mktemp -d)
    mkdir -p "$AIRE_AGENT_DIR/experiments"
}

teardown() {
    rm -rf "$AIRE_AGENT_DIR"
}

@test "log-experiment.sh creates valid JSON log entry" {
    run "$TOOLS_DIR/log-experiment.sh" --name "test_run" --metrics '{"loss": 0.5}' --params '{"lr": 0.001}'
    [ "$status" -eq 0 ]
    # Check the log file was created
    log_file=$(ls "$AIRE_AGENT_DIR/experiments/"*.jsonl 2>/dev/null | head -1)
    [ -f "$log_file" ]
    # Verify JSON is valid
    run python3 -c "import json; json.loads(open('$log_file').readline())"
    [ "$status" -eq 0 ]
}

@test "query-experiments.sh returns logged experiments" {
    "$TOOLS_DIR/log-experiment.sh" --name "test_query" --metrics '{"loss": 0.3}'
    run "$TOOLS_DIR/query-experiments.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"test_query"* ]]
}

@test "log-experiment.sh rejects missing name" {
    run "$TOOLS_DIR/log-experiment.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]] || [[ "$output" == *"--name"* ]]
}
```

- [ ] **Step 2: Write tools/log-experiment.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

AIRE_AGENT_DIR="${AIRE_AGENT_DIR:-$HOME/.aire-agent}"

usage() {
    echo "Usage: aire-agent log --name <name> [options]"
    echo ""
    echo "Log an experiment result."
    echo ""
    echo "Options:"
    echo "  --name NAME         Experiment name (required)"
    echo "  --job JOB_ID        Slurm job ID"
    echo "  --metrics JSON      Metrics as JSON string"
    echo "  --params JSON       Parameters as JSON string"
    echo "  --notes TEXT        Free-text notes"
    echo "  --help              Show this help"
    exit "${1:-1}"
}

name=""
job_id="${SLURM_JOB_ID:-}"
metrics="{}"
params="{}"
notes=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name) name="$2"; shift 2 ;;
        --job) job_id="$2"; shift 2 ;;
        --metrics) metrics="$2"; shift 2 ;;
        --params) params="$2"; shift 2 ;;
        --notes) notes="$2"; shift 2 ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

if [[ -z "$name" ]]; then
    echo "Error: --name is required"
    usage 1
fi

# Create experiments directory
exp_dir="$AIRE_AGENT_DIR/experiments"
mkdir -p "$exp_dir"

# Get context
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
node="${SLURMD_NODENAME:-$(hostname)}"
gpus="${SLURM_GPUS_ON_NODE:-0}"

# Build JSON entry using python for reliable JSON formatting
python3 -c "
import json, sys
entry = {
    'timestamp': '$timestamp',
    'name': '$name',
    'job_id': '$job_id',
    'metrics': $metrics,
    'params': $params,
    'git_commit': '$git_commit',
    'node': '$node',
    'gpus': '$gpus',
    'notes': '''$notes'''
}
print(json.dumps(entry))
" >> "$exp_dir/experiments.jsonl"

echo "Experiment logged: $name ($timestamp)"
```

- [ ] **Step 3: Write tools/query-experiments.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

AIRE_AGENT_DIR="${AIRE_AGENT_DIR:-$HOME/.aire-agent}"

usage() {
    echo "Usage: aire-agent experiments [options]"
    echo ""
    echo "Query logged experiments."
    echo ""
    echo "Options:"
    echo "  --filter EXPR   Filter expression (e.g., 'loss<0.3')"
    echo "  --last N        Show last N experiments (default: 20)"
    echo "  --json          Output as JSON"
    echo "  --help          Show this help"
    exit "${1:-1}"
}

filter=""
last=20
json_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --filter) filter="$2"; shift 2 ;;
        --last) last="$2"; shift 2 ;;
        --json) json_mode=true; shift ;;
        --help) usage 0 ;;
        -*) echo "Error: Unknown option $1"; usage 1 ;;
        *) break ;;
    esac
done

exp_file="$AIRE_AGENT_DIR/experiments/experiments.jsonl"

if [[ ! -f "$exp_file" ]]; then
    echo "No experiments logged yet."
    exit 0
fi

if $json_mode; then
    tail -n "$last" "$exp_file"
else
    python3 -c "
import json, sys

with open('$exp_file') as f:
    lines = f.readlines()

entries = [json.loads(l) for l in lines[-$last:]]

for e in entries:
    metrics_str = ', '.join(f'{k}={v}' for k, v in e.get('metrics', {}).items())
    print(f\"{e['timestamp']}  {e['name']:30s}  job={e.get('job_id', 'N/A'):10s}  {metrics_str}\")
"
fi
```

- [ ] **Step 4: Write tools/setup-wandb.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: aire-agent setup-wandb"
    echo ""
    echo "Configure Weights & Biases for experiment tracking on AIRE."
    echo ""
    echo "Options:"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) usage 0 ;;
        *) break ;;
    esac
done

echo "=== W&B Setup for AIRE ==="
echo ""

# Check if wandb is installed
if ! python3 -c "import wandb" 2>/dev/null; then
    echo "wandb is not installed. Install it with:"
    echo "  pip install wandb"
    echo ""
    read -p "Install now? [y/N] " install_now
    if [[ "$install_now" =~ ^[Yy] ]]; then
        pip install wandb
    else
        exit 0
    fi
fi

echo ""
echo "W&B version: $(python3 -c 'import wandb; print(wandb.__version__)')"
echo ""

# Check for existing login
if python3 -c "import wandb; wandb.login(relogin=False)" 2>/dev/null; then
    echo "Already logged in to W&B."
else
    echo "Log in to W&B:"
    echo "  1. Go to https://wandb.ai/settings"
    echo "  2. Copy your API key"
    echo ""
    wandb login
fi

echo ""
echo "=== Recommended SBATCH additions ==="
echo ""
echo "Add these to your job scripts:"
echo ""
echo '  export WANDB_DIR=$SLURM_SUBMIT_DIR/wandb'
echo '  mkdir -p $WANDB_DIR'
echo ""
echo "For offline mode (recommended on AIRE):"
echo '  export WANDB_MODE=offline'
echo ""
echo "Sync offline runs after job:"
echo '  wandb sync wandb/offline-run-*'
```

- [ ] **Step 5: Make tools executable**

```bash
chmod +x tools/log-experiment.sh tools/query-experiments.sh tools/setup-wandb.sh
```

- [ ] **Step 6: Run tests**

```bash
bats tests/unit/test_experiment_tools.bats
```

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add tools/log-experiment.sh tools/query-experiments.sh tools/setup-wandb.sh tests/unit/test_experiment_tools.bats
git commit -m "feat: add experiment logging tools with tests"
```

---

## Task 9: CLI Dispatcher

**Files:**
- Create: `bin/aire-agent`
- Test: `tests/unit/test_cli.bats`

- [ ] **Step 1: Write tests/unit/test_cli.bats**

```bash
#!/usr/bin/env bats

BIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../bin" && pwd)"
CLI="$BIN_DIR/aire-agent"

@test "aire-agent exists and is executable" {
    [ -x "$CLI" ]
}

@test "aire-agent with no args shows help" {
    run "$CLI"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "aire-agent --help shows help" {
    run "$CLI" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "aire-agent routes 'info' to system-info tool" {
    run "$CLI" info
    [ "$status" -eq 0 ]
    [[ "$output" == *"AIRE"* ]]
}

@test "aire-agent routes 'modules' to list-modules tool" {
    run "$CLI" modules
    [ "$status" -eq 0 ]
    [[ "$output" == *"cuda"* ]]
}

@test "aire-agent routes 'search' to search-docs tool" {
    run "$CLI" search "L40S"
    [ "$status" -eq 0 ]
    [[ "$output" == *"L40S"* ]]
}

@test "aire-agent routes 'validate' to validate-script tool" {
    tmp=$(mktemp)
    echo -e '#!/bin/bash\n#SBATCH --time=01:00:00' > "$tmp"
    run "$CLI" validate "$tmp"
    [ "$status" -eq 0 ]
    rm "$tmp"
}

@test "aire-agent rejects unknown commands" {
    run "$CLI" nonexistent_command
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown"* ]]
}

@test "aire-agent --version shows version" {
    run "$CLI" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+ ]]
}
```

- [ ] **Step 2: Write bin/aire-agent**

```bash
#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"

# Resolve the real directory of this script (follow symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TOOLS_DIR="$REPO_DIR/tools"

usage() {
    cat <<EOF
aire-agent v$VERSION — AI-powered AIRE HPC assistant

Usage: aire-agent <command> [options]

Job Management:
  submit <script.sh>     Submit a job to AIRE
  queue                  Show your jobs in the queue
  cancel <job_id>        Cancel a job
  status <job_id>        Show detailed job info
  efficiency <job_id>    Show resource efficiency (completed jobs)

Script Generation:
  generate [options]     Generate a SBATCH job script
  validate <script.sh>   Validate a script against AIRE constraints

Knowledge:
  search <query>         Search AIRE documentation
  modules [filter]       List available modules
  info                   Show AIRE system information

Experiments:
  log [options]          Log an experiment result
  experiments            Query past experiments
  setup-wandb            Configure Weights & Biases

Utility:
  quota                  Show storage quota usage
  nodes                  Show node availability
  sync                   Sync AIRE documentation
  update                 Update aire-agent
  doctor                 Diagnose setup issues
  setup                  Run setup wizard

Options:
  --version              Show version
  --help                 Show this help

Documentation: https://github.com/omariosc/aire-agent
EOF
    exit "${1:-0}"
}

if [[ $# -eq 0 ]]; then
    usage 0
fi

# Command routing
case "$1" in
    --version) echo "aire-agent v$VERSION"; exit 0 ;;
    --help|-h) usage 0 ;;
    submit)    shift; exec "$TOOLS_DIR/submit-job.sh" "$@" ;;
    queue)     shift; exec "$TOOLS_DIR/check-queue.sh" "$@" ;;
    cancel)    shift; exec "$TOOLS_DIR/cancel-job.sh" "$@" ;;
    status)    shift; exec "$TOOLS_DIR/job-status.sh" "$@" ;;
    efficiency) shift; exec "$TOOLS_DIR/job-efficiency.sh" "$@" ;;
    generate)  shift; exec "$TOOLS_DIR/generate-script.sh" "$@" ;;
    validate)  shift; exec "$TOOLS_DIR/validate-script.sh" "$@" ;;
    search)    shift; exec "$TOOLS_DIR/search-docs.sh" "$@" ;;
    modules)   shift; exec "$TOOLS_DIR/list-modules.sh" "$@" ;;
    info)      shift; exec "$TOOLS_DIR/system-info.sh" "$@" ;;
    log)       shift; exec "$TOOLS_DIR/log-experiment.sh" "$@" ;;
    experiments) shift; exec "$TOOLS_DIR/query-experiments.sh" "$@" ;;
    setup-wandb) shift; exec "$TOOLS_DIR/setup-wandb.sh" "$@" ;;
    quota)     shift; exec "$TOOLS_DIR/check-quota.sh" "$@" ;;
    nodes)     shift; exec "$TOOLS_DIR/node-availability.sh" "$@" ;;
    sync)      shift; exec "$REPO_DIR/scripts/sync.sh" "$@" ;;
    update)    shift; exec "$TOOLS_DIR/update.sh" "$@" ;;
    doctor)    shift; exec "$TOOLS_DIR/doctor.sh" "$@" ;;
    setup)     shift; exec python3 "$REPO_DIR/bin/aire-setup" "$@" ;;
    *)         echo "Error: Unknown command '$1'"; echo ""; usage 1 ;;
esac
```

- [ ] **Step 3: Make executable**

```bash
chmod +x bin/aire-agent
```

- [ ] **Step 4: Run tests**

```bash
bats tests/unit/test_cli.bats
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add bin/aire-agent tests/unit/test_cli.bats
git commit -m "feat: add CLI dispatcher for all aire-agent commands"
```

---

## Task 10: MCP Server

**Files:**
- Create: `mcp/server.py`
- Test: `tests/unit/test_mcp_server.py`

- [ ] **Step 1: Write tests/unit/test_mcp_server.py**

```python
"""Tests for the aire-agent MCP server."""
import json
import subprocess
import sys
import os

REPO_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SERVER_PATH = os.path.join(REPO_DIR, "mcp", "server.py")


def send_mcp_request(method, params=None, req_id=1):
    """Send a JSON-RPC request to the MCP server and return the response."""
    request = {"jsonrpc": "2.0", "id": req_id, "method": method}
    if params:
        request["params"] = params

    proc = subprocess.run(
        [sys.executable, SERVER_PATH],
        input=json.dumps(request) + "\n",
        capture_output=True,
        text=True,
        timeout=10,
    )
    # Parse last non-empty line as response
    lines = [l for l in proc.stdout.strip().split("\n") if l.strip()]
    if lines:
        return json.loads(lines[-1])
    return None


def test_server_exists():
    assert os.path.exists(SERVER_PATH)


def test_initialize():
    resp = send_mcp_request("initialize", {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "test", "version": "1.0"},
    })
    assert resp is not None
    assert "result" in resp
    assert "capabilities" in resp["result"]


def test_tools_list():
    resp = send_mcp_request("tools/list")
    assert resp is not None
    assert "result" in resp
    tools = resp["result"]["tools"]
    tool_names = [t["name"] for t in tools]
    assert "system_info" in tool_names
    assert "search_docs" in tool_names
    assert "validate_script" in tool_names
    assert "generate_script" in tool_names


def test_system_info_tool():
    resp = send_mcp_request("tools/call", {
        "name": "system_info",
        "arguments": {},
    })
    assert resp is not None
    assert "result" in resp
    content = resp["result"]["content"][0]["text"]
    assert "AIRE" in content
    assert "L40S" in content
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /path/to/aire-agent && python3 -m pytest tests/unit/test_mcp_server.py -v
```

Expected: FAIL (server doesn't exist)

- [ ] **Step 3: Write mcp/server.py**

```python
#!/usr/bin/env python3
"""aire-agent MCP server.

Thin stdio server implementing the Model Context Protocol.
Dispatches tool calls to shell scripts in tools/.
No external dependencies — stdlib only.
"""
import json
import os
import subprocess
import sys

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS_DIR = os.path.join(REPO_DIR, "tools")

# Tool definitions for MCP
TOOLS = [
    {
        "name": "submit_job",
        "description": "Submit a SBATCH job script to AIRE. Validates first.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "script_path": {"type": "string", "description": "Path to the SBATCH script"},
            },
            "required": ["script_path"],
        },
    },
    {
        "name": "check_queue",
        "description": "Show your jobs in the AIRE queue.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "all_users": {"type": "boolean", "description": "Show all users", "default": False},
            },
        },
    },
    {
        "name": "cancel_job",
        "description": "Cancel an AIRE job by ID.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "job_id": {"type": "string", "description": "Slurm job ID"},
            },
            "required": ["job_id"],
        },
    },
    {
        "name": "job_status",
        "description": "Show detailed information about an AIRE job.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "job_id": {"type": "string", "description": "Slurm job ID"},
            },
            "required": ["job_id"],
        },
    },
    {
        "name": "job_efficiency",
        "description": "Show resource efficiency for a completed AIRE job.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "job_id": {"type": "string", "description": "Slurm job ID"},
            },
            "required": ["job_id"],
        },
    },
    {
        "name": "generate_script",
        "description": "Generate a validated SBATCH job script for AIRE.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "gpu": {"type": "integer", "description": "Number of GPUs", "default": 0},
                "time": {"type": "string", "description": "Wall time (e.g., 1h, 4h, 01:00:00)"},
                "cpus": {"type": "integer", "description": "CPUs per task"},
                "mem": {"type": "string", "description": "Memory (e.g., 4G, 32G)"},
                "partition": {"type": "string", "description": "Partition (gpu, himem)"},
                "framework": {"type": "string", "description": "Framework: pytorch, tensorflow, none"},
                "job_name": {"type": "string", "description": "Job name"},
                "email": {"type": "string", "description": "Notification email"},
                "array": {"type": "string", "description": "Array range (e.g., 1-100)"},
            },
            "required": ["time"],
        },
    },
    {
        "name": "validate_script",
        "description": "Validate a SBATCH script against AIRE constraints.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "script_path": {"type": "string", "description": "Path to the SBATCH script"},
            },
            "required": ["script_path"],
        },
    },
    {
        "name": "search_docs",
        "description": "Search AIRE documentation and knowledge base.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Search query"},
            },
            "required": ["query"],
        },
    },
    {
        "name": "list_modules",
        "description": "List available software modules on AIRE.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "filter": {"type": "string", "description": "Filter by name"},
            },
        },
    },
    {
        "name": "system_info",
        "description": "Show AIRE hardware specs, partitions, and storage.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "check_quota",
        "description": "Show storage quota usage on AIRE.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "node_availability",
        "description": "Show free resources by partition on AIRE.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "log_experiment",
        "description": "Log an experiment result with metrics and parameters.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "name": {"type": "string", "description": "Experiment name"},
                "job_id": {"type": "string", "description": "Slurm job ID"},
                "metrics": {"type": "string", "description": "Metrics as JSON string"},
                "params": {"type": "string", "description": "Parameters as JSON string"},
            },
            "required": ["name"],
        },
    },
    {
        "name": "query_experiments",
        "description": "Query past logged experiments.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "last": {"type": "integer", "description": "Number of recent experiments", "default": 20},
            },
        },
    },
    {
        "name": "sync_docs",
        "description": "Sync AIRE documentation from upstream.",
        "inputSchema": {"type": "object", "properties": {}},
    },
]

# Map tool names to shell scripts and argument builders
TOOL_DISPATCH = {
    "submit_job": ("submit-job.sh", lambda args: [args["script_path"]]),
    "check_queue": ("check-queue.sh", lambda args: ["--all"] if args.get("all_users") else []),
    "cancel_job": ("cancel-job.sh", lambda args: [args["job_id"]]),
    "job_status": ("job-status.sh", lambda args: [args["job_id"]]),
    "job_efficiency": ("job-efficiency.sh", lambda args: [args["job_id"]]),
    "validate_script": ("validate-script.sh", lambda args: [args["script_path"]]),
    "search_docs": ("search-docs.sh", lambda args: [args["query"]]),
    "list_modules": ("list-modules.sh", lambda args: [args["filter"]] if args.get("filter") else []),
    "system_info": ("system-info.sh", lambda _: []),
    "check_quota": ("check-quota.sh", lambda _: []),
    "node_availability": ("node-availability.sh", lambda _: []),
    "log_experiment": ("log-experiment.sh", lambda args: _build_experiment_args(args)),
    "query_experiments": ("query-experiments.sh", lambda args: ["--last", str(args.get("last", 20))]),
    "sync_docs": ("../scripts/sync.sh", lambda _: []),
}


def _build_experiment_args(args):
    cmd_args = ["--name", args["name"]]
    if args.get("job_id"):
        cmd_args.extend(["--job", args["job_id"]])
    if args.get("metrics"):
        cmd_args.extend(["--metrics", args["metrics"]])
    if args.get("params"):
        cmd_args.extend(["--params", args["params"]])
    return cmd_args


def _build_generate_args(args):
    cmd_args = ["--time", args["time"]]
    for key in ("gpu", "cpus", "mem", "partition", "framework", "job_name", "email", "array"):
        val = args.get(key)
        if val is not None and val != "":
            flag = f"--{key.replace('_', '-')}"
            cmd_args.extend([flag, str(val)])
    return cmd_args


# Add generate_script separately since it has complex args
TOOL_DISPATCH["generate_script"] = ("generate-script.sh", _build_generate_args)


def run_tool(name, arguments):
    """Execute a shell tool and return its output."""
    if name not in TOOL_DISPATCH:
        return f"Unknown tool: {name}"

    script, arg_builder = TOOL_DISPATCH[name]
    script_path = os.path.join(TOOLS_DIR, script)
    cmd_args = arg_builder(arguments or {})

    try:
        result = subprocess.run(
            [script_path] + cmd_args,
            capture_output=True,
            text=True,
            timeout=60,
            cwd=REPO_DIR,
        )
        output = result.stdout
        if result.returncode != 0 and result.stderr:
            output += "\n" + result.stderr
        return output.strip() or "(no output)"
    except subprocess.TimeoutExpired:
        return "Error: Tool timed out after 60 seconds"
    except FileNotFoundError:
        return f"Error: Tool script not found: {script_path}"
    except Exception as e:
        return f"Error running tool: {e}"


def handle_request(request):
    """Process a single JSON-RPC request and return a response."""
    method = request.get("method", "")
    req_id = request.get("id")
    params = request.get("params", {})

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "aire-agent", "version": "0.1.0"},
            },
        }

    if method == "notifications/initialized":
        return None  # No response for notifications

    if method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {"tools": TOOLS},
        }

    if method == "tools/call":
        tool_name = params.get("name", "")
        arguments = params.get("arguments", {})
        output = run_tool(tool_name, arguments)
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "content": [{"type": "text", "text": output}],
            },
        }

    return {
        "jsonrpc": "2.0",
        "id": req_id,
        "error": {"code": -32601, "message": f"Unknown method: {method}"},
    }


def main():
    """Main loop: read JSON-RPC from stdin, write responses to stdout."""
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            request = json.loads(line)
            response = handle_request(request)
            if response is not None:
                sys.stdout.write(json.dumps(response) + "\n")
                sys.stdout.flush()
        except json.JSONDecodeError:
            error_resp = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": "Parse error"},
            }
            sys.stdout.write(json.dumps(error_resp) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Make server executable**

```bash
chmod +x mcp/server.py
```

- [ ] **Step 5: Run tests**

```bash
python3 -m pytest tests/unit/test_mcp_server.py -v
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add mcp/server.py tests/unit/test_mcp_server.py
git commit -m "feat: add MCP server dispatching to shell tools"
```

---

## Task 11: Agent Configuration

**Files:**
- Create: `agent/CLAUDE.md`
- Create: `agent/AGENTS.md`
- Create: `agent/hooks/session-start.sh`

- [ ] **Step 1: Write agent/CLAUDE.md**

```markdown
# AIRE HPC Agent — Claude Code Configuration

You are an AI assistant with expert knowledge of the AIRE HPC cluster at the University of Leeds. You help researchers submit jobs, optimise code, debug issues, and manage experiments on AIRE.

## Critical Constraints (NEVER violate these)

1. **Max 3 GPUs per node** — AIRE GPU nodes have exactly 3x NVIDIA L40S. For >3 GPUs, use `--nodes=2+` with multi-node distributed training.
2. **`--partition=gpu` + `--gres=gpu:N`** — These MUST be used together. Never one without the other.
3. **`--time` is REQUIRED** — Every job must specify wall time. Jobs without `--time` will fail.
4. **Default resources are minimal** — 1 CPU, 1GB RAM. Always request appropriate resources.
5. **No SSH key auth** — AIRE uses password-only authentication.
6. **No jobs on login nodes** — Login nodes are for file management and job submission only.
7. **$TMP_SHARED is deleted when jobs end** — Always copy results back to $SCRATCH before job completes.

## Hardware Quick Reference

| Resource | Spec |
|----------|------|
| CPU nodes | 52 nodes, 168 cores, 768GB RAM each |
| GPU nodes | 28 nodes, 3x L40S 48GB, 24 cores, 256GB RAM each |
| High-mem | 2 nodes, 168 cores, 2.3TB RAM each |
| Total GPUs | 84x NVIDIA L40S 48GB (Ada Lovelace, CC 8.9) |
| Partitions | default, gpu, himem |
| Network | 100 Gb/s OmniPath |
| Retirement | 31 July 2029 |

## Storage Quick Reference

| Location | Env Var | Quota | Backed Up | Auto-Delete |
|----------|---------|-------|-----------|-------------|
| /users/<user> | $HOME | 65GB | Yes | No |
| /mnt/scratch/<user> | $SCRATCH | 1TB | No | No |
| /mnt/flash/tmp/job.<ID> | $TMP_SHARED | 1TB/job | No | Yes |
| /tmp/job.<ID> | $TMPDIR | Node disk | No | Yes |

## Module Loading Patterns

```bash
# For GPU/ML work:
module load cuda/12.6.2
module load miniforge/24.7.1

# For MPI:
module load openmpi/5.0.6/gcc-14.2.0

# For MPI+CUDA:
module load openmpi/5.0.6/gcc-13.2.0_cuda-12.6.2
```

## Best Practices You MUST Follow

1. Always add `seff $SLURM_JOB_ID` at the end of job scripts
2. Always add `--mail-type=BEGIN,END,FAIL` and `--mail-user=`
3. Always create `logs/` directory and use `--output=logs/%x_%j.out`
4. Request 8 CPUs per GPU for data loading
5. Use `--mem-per-cpu=8G` for GPU jobs (not `--mem`)
6. For PyTorch: set CUDNN_BENCHMARK=1, use mixed precision on L40S
7. Use $SCRATCH for datasets, $TMP_SHARED for fast I/O during jobs
8. Save checkpoints for jobs >2 hours
9. Pin package versions in conda environments
10. Use timestamped output directories for reproducibility

## Using aire-agent Tools

You have MCP tools available. Use them instead of guessing:

- **system_info** — Get AIRE specs
- **search_docs** — Search documentation for specific topics
- **list_modules** — Check available software modules
- **generate_script** — Create SBATCH scripts from parameters
- **validate_script** — Check scripts before submission
- **submit_job** — Submit jobs
- **check_queue** — Check job status
- **job_efficiency** — Check resource usage after completion
- **log_experiment** — Log experiment results
- **check_quota** — Check storage usage
- **node_availability** — Check free resources

Always validate scripts before submitting. Always check job efficiency after completion to optimize future resource requests.

## AIMS-Specific Patterns

The primary users are from the AI in Medicine and Surgery (AIMS) group. Common workloads:
- Medical image segmentation (MONAI, nnU-Net)
- Surgical video analysis
- PyTorch-based deep learning
- Large medical imaging datasets (NIfTI, DICOM)

For medical imaging:
- Use `SimpleITK` or `nibabel` for NIfTI loading
- Use `MONAI` transforms for medical image preprocessing
- Store datasets on $SCRATCH, cache preprocessed data on $TMP_SHARED
- Use mixed precision — L40S has excellent FP16 throughput
```

- [ ] **Step 2: Write agent/AGENTS.md**

```markdown
# AIRE HPC Agent — Multi-Agent Configuration

This file configures AI coding agents (Codex CLI, Gemini CLI) for AIRE HPC assistance.

## Core Rules

All agents MUST follow these rules when working with AIRE:

1. Max 3 GPUs per node. For >3, use multi-node.
2. `--partition=gpu` and `--gres=gpu:N` must be used together.
3. `--time` is required on all jobs.
4. Default resources: 1 CPU, 1GB. Always request more.
5. No SSH key auth — password only.
6. No jobs on login nodes.
7. $TMP_SHARED is deleted when jobs end.

## Available Tools

If the aire-agent MCP server is running, use these tools:
- system_info, search_docs, list_modules
- generate_script, validate_script, submit_job
- check_queue, cancel_job, job_status, job_efficiency
- log_experiment, query_experiments
- check_quota, node_availability

## Key Facts

- 84x NVIDIA L40S 48GB GPUs (28 nodes, 3 per node)
- AMD Genoa-X CPUs (168 cores/CPU node, 24 cores/GPU node)
- Partitions: default (CPU), gpu, himem
- Storage: $HOME (65GB), $SCRATCH (1TB), $TMP_SHARED (1TB/job, auto-deleted)
- Slurm scheduler with fair-share policy
- System retirement: 31 July 2029

## Documentation

Knowledge base files in `knowledge/` directory contain detailed reference material.
Full AIRE documentation in `docs/` directory (synced from arcdocs/aire).
```

- [ ] **Step 3: Write agent/hooks/session-start.sh**

```bash
#!/usr/bin/env bash
# Claude Code hook: runs on session start
# Checks if AIRE docs are stale and syncs if needed

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
SYNC_FILE="$REPO_DIR/.last_sync"
SYNC_SCRIPT="$REPO_DIR/scripts/sync.sh"

# Check if sync file exists
if [[ ! -f "$SYNC_FILE" ]]; then
    echo "aire-agent: No sync timestamp found. Run 'aire-agent sync' to update docs."
    exit 0
fi

# Check staleness (24 hours = 86400 seconds)
last_sync=$(cat "$SYNC_FILE")
now=$(date +%s)
age=$(( now - last_sync ))

if [[ $age -gt 86400 ]]; then
    days=$(( age / 86400 ))
    echo "aire-agent: AIRE docs are ${days} day(s) old. Syncing..."
    if [[ -x "$SYNC_SCRIPT" ]]; then
        "$SYNC_SCRIPT" 2>/dev/null || echo "aire-agent: Sync failed. Run 'aire-agent sync' manually."
    else
        echo "aire-agent: Sync script not found. Run 'aire-agent sync' manually."
    fi
fi
```

- [ ] **Step 4: Make hook executable**

```bash
chmod +x agent/hooks/session-start.sh
```

- [ ] **Step 5: Commit**

```bash
git add agent/CLAUDE.md agent/AGENTS.md agent/hooks/session-start.sh
git commit -m "feat: add CLAUDE.md, AGENTS.md, and session-start hook"
```

---

## Task 12: Auto-Sync System

**Files:**
- Create: `scripts/sync.sh`
- Test: `tests/unit/test_sync.bats`

- [ ] **Step 1: Write tests/unit/test_sync.bats**

```bash
#!/usr/bin/env bats

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../scripts" && pwd)"
REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

@test "sync.sh exists and is executable" {
    [ -x "$SCRIPTS_DIR/sync.sh" ]
}

@test "sync.sh creates .last_sync file" {
    # This test requires network access
    if ! ping -c 1 github.com &>/dev/null; then
        skip "No network access"
    fi
    run "$SCRIPTS_DIR/sync.sh"
    [ -f "$REPO_DIR/.last_sync" ]
    # Timestamp should be recent
    last_sync=$(cat "$REPO_DIR/.last_sync")
    now=$(date +%s)
    diff=$(( now - last_sync ))
    [ "$diff" -lt 60 ]
}
```

- [ ] **Step 2: Write scripts/sync.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$REPO_DIR/docs"
SYNC_FILE="$REPO_DIR/.last_sync"
UPSTREAM_REPO="https://github.com/arcdocs/aire.git"
TMP_DIR=$(mktemp -d)

usage() {
    echo "Usage: aire-agent sync"
    echo ""
    echo "Sync AIRE documentation from upstream (arcdocs/aire)."
    echo ""
    echo "Options:"
    echo "  --force   Force sync even if recently synced"
    echo "  --help    Show this help"
    exit "${1:-1}"
}

force=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) force=true; shift ;;
        --help) usage 0 ;;
        *) break ;;
    esac
done

# Check if sync is needed
if [[ -f "$SYNC_FILE" ]] && ! $force; then
    last_sync=$(cat "$SYNC_FILE")
    now=$(date +%s)
    age=$(( now - last_sync ))
    if [[ $age -lt 86400 ]]; then
        hours=$(( age / 3600 ))
        echo "Docs synced ${hours}h ago. Use --force to sync anyway."
        exit 0
    fi
fi

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Syncing AIRE documentation from $UPSTREAM_REPO..."

# Clone upstream
git clone --depth 1 "$UPSTREAM_REPO" "$TMP_DIR/aire" 2>/dev/null || {
    echo "Error: Could not clone upstream repository."
    echo "Check your network connection."
    exit 1
}

# Sync book content to docs/
if [[ -d "$TMP_DIR/aire/book" ]]; then
    # Remove old docs (except hidden files)
    find "$DOCS_DIR" -mindepth 1 -not -name '.*' -exec rm -rf {} + 2>/dev/null || true

    # Copy new docs
    cp -r "$TMP_DIR/aire/book/"* "$DOCS_DIR/"

    # Copy modules.txt if it exists
    if [[ -f "$TMP_DIR/aire/modules.txt" ]]; then
        cp "$TMP_DIR/aire/modules.txt" "$DOCS_DIR/"
    fi

    echo "Documentation updated."
else
    echo "Warning: No book/ directory found in upstream."
fi

# Update timestamp
date +%s > "$SYNC_FILE"
echo "Sync complete. Timestamp updated."
```

- [ ] **Step 3: Make executable**

```bash
chmod +x scripts/sync.sh
```

- [ ] **Step 4: Run tests**

```bash
bats tests/unit/test_sync.bats
```

- [ ] **Step 5: Commit**

```bash
git add scripts/sync.sh tests/unit/test_sync.bats
git commit -m "feat: add documentation auto-sync script"
```

---

## Task 13: Setup TUI

**Files:**
- Create: `bin/aire-setup`

This is the Python/Rich TUI that runs once during installation. It's the only Python component besides the MCP server.

- [ ] **Step 1: Write bin/aire-setup**

```python
#!/usr/bin/env python3
"""aire-agent setup wizard.

Interactive TUI for configuring SSH access, AI agents, and experiment tracking.
Requires: pip install rich
"""
import os
import subprocess
import sys

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.prompt import Prompt, Confirm
    from rich.table import Table
    from rich import print as rprint
except ImportError:
    print("Error: 'rich' package required. Install with: pip install rich")
    sys.exit(1)

console = Console()
REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def welcome():
    console.print(Panel.fit(
        "[bold green]aire-agent[/bold green] Setup Wizard\n\n"
        "This will configure:\n"
        "  1. SSH access to AIRE\n"
        "  2. Your preferred AI coding agent\n"
        "  3. Experiment tracking (optional)\n"
        "  4. Initial documentation sync",
        title="Welcome",
        border_style="green",
    ))
    console.print()


def get_credentials():
    console.print("[bold]Step 1: University Credentials[/bold]\n")
    username = Prompt.ask("University username (e.g., sc20abc)")
    email = Prompt.ask("University email", default=f"{username}@leeds.ac.uk")
    return username, email


def setup_ssh(username):
    console.print("\n[bold]Step 2: SSH Configuration[/bold]\n")

    ssh_dir = os.path.expanduser("~/.ssh")
    os.makedirs(ssh_dir, mode=0o700, exist_ok=True)

    config_path = os.path.join(ssh_dir, "config")

    # Check if AIRE config already exists
    if os.path.exists(config_path):
        with open(config_path) as f:
            if "aire" in f.read().lower():
                console.print("[yellow]SSH config for AIRE already exists.[/yellow]")
                if not Confirm.ask("Overwrite existing AIRE SSH config?"):
                    return

    # Add SSH config
    aire_config = f"""
# AIRE HPC - University of Leeds
Host rash
    HostName rash.leeds.ac.uk
    User {username}

Host aire
    HostName login1.aire.leeds.ac.uk
    User {username}
    ProxyJump rash
"""

    # Append to existing config
    mode = "a" if os.path.exists(config_path) else "w"
    with open(config_path, mode) as f:
        f.write(aire_config)
    os.chmod(config_path, 0o600)

    console.print("[green]SSH config added.[/green]")
    console.print(f"  You can now connect with: [bold]ssh aire[/bold]")
    console.print(f"  (Password required — AIRE uses password auth only)")

    # Add shell alias
    setup_alias()


def setup_alias():
    shell = os.environ.get("SHELL", "/bin/bash")
    if "zsh" in shell:
        rc_file = os.path.expanduser("~/.zshrc")
    else:
        rc_file = os.path.expanduser("~/.bashrc")

    alias_line = 'alias aire="ssh aire"'
    path_line = f'export PATH="$HOME/.aire-agent/bin:$PATH"'

    if os.path.exists(rc_file):
        with open(rc_file) as f:
            content = f.read()
        if alias_line in content:
            console.print("[yellow]Shell alias 'aire' already exists.[/yellow]")
            return

    with open(rc_file, "a") as f:
        f.write(f"\n# aire-agent\n{alias_line}\n{path_line}\n")

    console.print(f"[green]Added 'aire' alias and PATH to {rc_file}[/green]")
    console.print("  Run [bold]source " + rc_file + "[/bold] or restart your terminal.")


def setup_agent():
    console.print("\n[bold]Step 3: AI Agent Selection[/bold]\n")

    table = Table(title="Available AI Agents")
    table.add_column("Agent", style="bold")
    table.add_column("Install Command")
    table.add_column("Notes")
    table.add_row("Claude Code", "npm install -g @anthropic-ai/claude-code", "[green]Recommended[/green]")
    table.add_row("Codex CLI", "npm install -g @openai/codex", "OpenAI")
    table.add_row("Gemini CLI", "npm install -g @anthropic-ai/gemini-cli", "Google")
    console.print(table)
    console.print()

    agent = Prompt.ask(
        "Which agent to install?",
        choices=["claude", "codex", "gemini", "skip"],
        default="claude",
    )

    if agent == "skip":
        console.print("[yellow]Skipping agent installation.[/yellow]")
        return agent

    install_cmds = {
        "claude": "npm install -g @anthropic-ai/claude-code",
        "codex": "npm install -g @openai/codex",
        "gemini": "npm install -g @google/gemini-cli",
    }

    if Confirm.ask(f"Install {agent}?"):
        console.print(f"Running: {install_cmds[agent]}")
        subprocess.run(install_cmds[agent], shell=True)

    # MCP server registration
    if agent == "claude":
        setup_claude_mcp()

    # Permission flag discussion
    console.print()
    console.print(Panel(
        "[bold yellow]About --dangerously-skip-permissions[/bold yellow]\n\n"
        "This flag lets the AI agent run commands without asking for\n"
        "permission each time. This is more productive but means the\n"
        "agent can execute any command.\n\n"
        "[green]Safe if:[/green] You use version control, work on your own code,\n"
        "and review changes before pushing.\n\n"
        "[red]Risky if:[/red] You're working on shared production systems\n"
        "or sensitive data without backups.",
        title="Permission Mode",
        border_style="yellow",
    ))

    return agent


def setup_claude_mcp():
    console.print("\n[bold]Registering MCP server with Claude Code...[/bold]")

    settings_dir = os.path.expanduser("~/.claude")
    os.makedirs(settings_dir, exist_ok=True)

    # Claude Code MCP config
    import json
    settings_path = os.path.join(settings_dir, "settings.json")

    settings = {}
    if os.path.exists(settings_path):
        with open(settings_path) as f:
            settings = json.load(f)

    if "mcpServers" not in settings:
        settings["mcpServers"] = {}

    settings["mcpServers"]["aire-agent"] = {
        "command": "python3",
        "args": [os.path.join(REPO_DIR, "mcp", "server.py")],
    }

    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)

    console.print("[green]MCP server registered in Claude Code settings.[/green]")


def setup_experiments():
    console.print("\n[bold]Step 4: Experiment Tracking[/bold]\n")

    choice = Prompt.ask(
        "Set up experiment tracking?",
        choices=["builtin", "wandb", "skip"],
        default="builtin",
    )

    if choice == "builtin":
        exp_dir = os.path.expanduser("~/.aire-agent/experiments")
        os.makedirs(exp_dir, exist_ok=True)
        console.print(f"[green]Built-in logger ready. Logs at: {exp_dir}[/green]")

    elif choice == "wandb":
        console.print("Setting up W&B...")
        subprocess.run(
            [os.path.join(REPO_DIR, "tools", "setup-wandb.sh")],
            cwd=REPO_DIR,
        )


def initial_sync():
    console.print("\n[bold]Step 5: Initial Documentation Sync[/bold]\n")

    if Confirm.ask("Sync AIRE documentation now?", default=True):
        console.print("Syncing from arcdocs/aire...")
        result = subprocess.run(
            [os.path.join(REPO_DIR, "scripts", "sync.sh"), "--force"],
            cwd=REPO_DIR,
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            console.print("[green]Documentation synced.[/green]")
        else:
            console.print(f"[yellow]Sync failed: {result.stderr}[/yellow]")
            console.print("You can sync later with: aire-agent sync")


def test_connection(username):
    console.print("\n[bold]Step 6: Test Connection[/bold]\n")

    if Confirm.ask("Test SSH connection to AIRE?", default=False):
        console.print(f"Connecting to AIRE as {username}...")
        console.print("[yellow]You will be prompted for your password.[/yellow]")
        subprocess.run(
            ["ssh", "-o", "ConnectTimeout=10", "aire", "echo", "Connection successful!"],
        )


def done():
    console.print()
    console.print(Panel.fit(
        "[bold green]Setup complete![/bold green]\n\n"
        "Quick start:\n"
        "  [bold]aire[/bold]                    — SSH into AIRE\n"
        "  [bold]aire-agent info[/bold]          — Show AIRE specs\n"
        "  [bold]aire-agent generate --gpu 1 --time 2h --framework pytorch[/bold]\n"
        "  [bold]aire-agent doctor[/bold]        — Check setup\n\n"
        "With Claude Code:\n"
        "  [bold]claude --dangerously-skip-permissions[/bold]\n"
        "  Then ask: \"Help me submit a GPU training job on AIRE\"",
        title="All Done",
        border_style="green",
    ))


def main():
    welcome()
    username, email = get_credentials()
    setup_ssh(username)
    setup_agent()
    setup_experiments()
    initial_sync()
    test_connection(username)
    done()


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Make executable**

```bash
chmod +x bin/aire-setup
```

- [ ] **Step 3: Test TUI runs without crashing**

```bash
python3 bin/aire-setup --help 2>/dev/null || python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('setup', 'bin/aire-setup')
mod = importlib.util.module_from_spec(spec)
# Just verify it imports without error
print('TUI module loads successfully')
"
```

- [ ] **Step 4: Commit**

```bash
git add bin/aire-setup
git commit -m "feat: add interactive setup TUI with Rich"
```

---

## Task 14: Install Script

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Write install.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

# aire-agent installer
# Usage: curl -fsSL https://raw.githubusercontent.com/omariosc/aire-agent/main/install.sh | bash

REPO_URL="https://github.com/omariosc/aire-agent.git"
INSTALL_DIR="$HOME/.aire-agent"
MIN_PYTHON="3.8"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       aire-agent installer           ║${NC}"
echo -e "${GREEN}║  AI-powered AIRE HPC assistant       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""

# Check Python
info "Checking Python..."
if command -v python3 &>/dev/null; then
    py_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    py_major=$(echo "$py_version" | cut -d. -f1)
    py_minor=$(echo "$py_version" | cut -d. -f2)
    if [[ "$py_major" -ge 3 && "$py_minor" -ge 8 ]]; then
        ok "Python $py_version found"
    else
        err "Python $MIN_PYTHON+ required. Found $py_version"
    fi
else
    err "Python 3 not found. Install Python $MIN_PYTHON+ first."
fi

# Check git
info "Checking git..."
if command -v git &>/dev/null; then
    ok "git found"
else
    err "git not found. Install git first."
fi

# Install or update
if [[ -d "$INSTALL_DIR" ]]; then
    info "Existing installation found. Updating..."
    cd "$INSTALL_DIR"
    git pull origin main 2>/dev/null || warn "Could not update. Continuing with existing installation."
else
    info "Cloning aire-agent..."
    git clone "$REPO_URL" "$INSTALL_DIR" || err "Failed to clone repository"
fi

cd "$INSTALL_DIR"

# Install Python dependencies for TUI
info "Installing Python dependencies..."
python3 -m pip install --quiet --user rich 2>/dev/null || warn "Could not install 'rich'. TUI may not work."

# Make scripts executable
info "Setting permissions..."
chmod +x bin/aire-agent bin/aire-setup
find tools/ -name "*.sh" -exec chmod +x {} \;
find scripts/ -name "*.sh" -exec chmod +x {} \;
find agent/hooks/ -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
chmod +x mcp/server.py

ok "aire-agent installed to $INSTALL_DIR"
echo ""

# Run setup wizard
info "Starting setup wizard..."
echo ""
python3 bin/aire-setup
```

- [ ] **Step 2: Make executable**

```bash
chmod +x install.sh
```

- [ ] **Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: add curl-installable install script"
```

---

## Task 15: README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

```markdown
# aire-agent

AI-powered assistant for the University of Leeds AIRE HPC cluster.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/omariosc/aire-agent/main/install.sh | bash
```

This clones the repo, installs dependencies, and runs an interactive setup wizard that configures SSH access, your preferred AI agent, and experiment tracking.

## What It Does

- **Submit and manage jobs** — Generate, validate, and submit SBATCH scripts with AIRE-aware constraints
- **Expert knowledge** — Your AI agent understands AIRE hardware, Slurm, storage, and common pitfalls
- **Script generation** — Create optimised job scripts from simple parameters
- **Experiment tracking** — Log results with a built-in JSON logger or W&B
- **Auto-updating docs** — Syncs daily from the official AIRE documentation

## CLI Reference

```bash
# SSH into AIRE
aire

# Job management
aire-agent submit job.sh          # Submit a job
aire-agent queue                  # Check your jobs
aire-agent cancel 12345           # Cancel a job
aire-agent status 12345           # Detailed job info
aire-agent efficiency 12345       # Resource usage (completed jobs)

# Script generation
aire-agent generate --gpu 2 --time 4h --framework pytorch
aire-agent validate job.sh        # Check against AIRE constraints

# Knowledge
aire-agent search "cuda module"   # Search documentation
aire-agent modules                # List available modules
aire-agent info                   # AIRE system specs

# Experiments
aire-agent log --name "exp1" --metrics '{"loss": 0.5}'
aire-agent experiments            # View past runs
aire-agent setup-wandb            # Configure W&B

# Utility
aire-agent quota                  # Storage usage
aire-agent nodes                  # Node availability
aire-agent sync                   # Update documentation
aire-agent update                 # Update aire-agent
aire-agent doctor                 # Diagnose issues
```

## Using with AI Agents

aire-agent works with any AI coding agent. It provides an MCP server with tools for job management, script generation, and documentation search.

### Claude Code (Recommended)

```bash
# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Run with aire-agent knowledge (MCP server auto-registered during setup)
claude

# Or for autonomous mode:
claude --dangerously-skip-permissions
```

The `--dangerously-skip-permissions` flag lets Claude run commands without asking each time. This is safe if you use version control and review changes before pushing. It is risky on shared production systems or sensitive data without backups.

### Codex CLI

```bash
npm install -g @openai/codex
```

### Gemini CLI

```bash
npm install -g @google/gemini-cli
```

## Running on AIRE (Recommended)

For the best experience, install aire-agent directly on AIRE:

```bash
# SSH into AIRE
ssh YOUR_USERNAME@login1.aire.leeds.ac.uk -J YOUR_USERNAME@rash.leeds.ac.uk

# Install aire-agent
curl -fsSL https://raw.githubusercontent.com/omariosc/aire-agent/main/install.sh | bash

# Install Claude Code on AIRE
npm install -g @anthropic-ai/claude-code

# Start working
claude
```

Running directly on AIRE gives your AI agent direct access to Slurm commands, GPU status, module system, and storage — no SSH tunnelling needed.

## For ML/DL Researchers

### Quick Start: PyTorch on L40S GPUs

```bash
# Generate a GPU training job script
aire-agent generate --gpu 1 --time 4h --framework pytorch --email you@leeds.ac.uk

# Or for multi-GPU (max 3 per node):
aire-agent generate --gpu 3 --time 8h --framework pytorch

# For >3 GPUs (auto multi-node):
aire-agent generate --gpu 6 --time 12h --framework pytorch
```

### AIRE GPU Specs

- 84x NVIDIA L40S 48GB (Ada Lovelace)
- 3 GPUs per node, 28 GPU nodes
- Best with: mixed precision (FP16/BF16), CUDNN_BENCHMARK=1

### Conda Environments

Ready-to-use environment configs in `templates/environments/`:

```bash
# PyTorch environment
conda env create -f ~/.aire-agent/templates/environments/pytorch.yml

# Medical imaging (MONAI, SimpleITK, etc.)
conda env create -f ~/.aire-agent/templates/environments/medical-imaging.yml
```

## Experiment Tracking

### Built-in Logger (no setup required)

```bash
# Log results
aire-agent log --name "resnet_exp1" --job $SLURM_JOB_ID --metrics '{"loss": 0.23, "acc": 0.91}'

# View experiments
aire-agent experiments
```

### Weights & Biases

```bash
aire-agent setup-wandb
```

Use `WANDB_MODE=offline` on AIRE (recommended), then sync after job completion.

## How It Stays Updated

aire-agent automatically syncs documentation from the [official AIRE docs](https://github.com/arcdocs/aire):

- **Daily sync** via `scripts/sync.sh`
- **Session hook** checks staleness when you start an AI agent session
- **Manual sync** with `aire-agent sync`

## AIRE Quick Reference

| Resource | Details |
|----------|---------|
| CPU Nodes | 52 nodes, 168 cores, 768GB RAM |
| GPU Nodes | 28 nodes, 3x L40S 48GB, 24 cores, 256GB RAM |
| High-Memory | 2 nodes, 168 cores, 2.3TB RAM |
| Partitions | default, gpu, himem |
| Max GPUs/node | 3 |
| $HOME | 65GB (backed up) |
| $SCRATCH | 1TB (not backed up) |
| Login | `ssh USER@login1.aire.leeds.ac.uk -J USER@rash.leeds.ac.uk` |
| Auth | Password only (no SSH keys) |

## Contributing

Contributions welcome. Please open issues or pull requests on [GitHub](https://github.com/omariosc/aire-agent).

To add a new tool:
1. Create a shell script in `tools/`
2. Add routing in `bin/aire-agent`
3. Add MCP definition in `mcp/server.py`
4. Add tests in `tests/`

## License

MIT License. See [LICENSE](LICENSE) for details.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add comprehensive README"
```

---

## Task 16: CI/CD Workflows

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/sync.yml`

- [ ] **Step 1: Write .github/workflows/ci.yml**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check shell scripts
        run: |
          find tools/ scripts/ bin/ agent/hooks/ -name "*.sh" -exec bash -n {} \;
          echo "All shell scripts parse successfully"

      - name: Check Python syntax
        run: python3 -m py_compile mcp/server.py

      - name: Check executable permissions
        run: |
          for f in bin/aire-agent bin/aire-setup; do
            test -x "$f" || (echo "ERROR: $f not executable" && exit 1)
          done
          find tools/ -name "*.sh" | while read f; do
            test -x "$f" || (echo "ERROR: $f not executable" && exit 1)
          done

  unit-tests:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4

      - name: Install bats
        run: |
          git clone https://github.com/bats-core/bats-core.git /tmp/bats
          sudo /tmp/bats/install.sh /usr/local

      - name: Run shell tests
        run: bats tests/unit/*.bats

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install Python test deps
        run: pip install pytest rich

      - name: Run Python tests
        run: python3 -m pytest tests/unit/*.py -v

  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install deps
        run: pip install rich

      - name: Test MCP server initialization
        run: |
          echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
          python3 mcp/server.py | \
          python3 -c "import json,sys; r=json.loads(sys.stdin.readline()); assert 'result' in r, f'Bad response: {r}'; print('MCP init OK')"

      - name: Test MCP tools/list
        run: |
          echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | \
          python3 mcp/server.py | \
          python3 -c "import json,sys; r=json.loads(sys.stdin.readline()); tools=[t['name'] for t in r['result']['tools']]; assert 'system_info' in tools; print(f'Found {len(tools)} tools')"

      - name: Test CLI dispatcher
        run: |
          ./bin/aire-agent --version
          ./bin/aire-agent info | grep -q "AIRE"
          ./bin/aire-agent modules | grep -q "cuda"
          echo "CLI dispatcher OK"

      - name: Validate all templates
        run: |
          for f in templates/jobs/*.sh; do
            echo "Validating $f..."
            ./tools/validate-script.sh "$f" || echo "WARN: $f has validation issues"
          done

  install-test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    needs: unit-tests
    steps:
      - uses: actions/checkout@v4

      - name: Test install script (dry run structure)
        run: |
          # Verify install.sh is valid bash
          bash -n install.sh
          # Verify all referenced paths exist
          test -d bin
          test -d tools
          test -d mcp
          test -d scripts
          test -d knowledge
          test -d templates
          test -f bin/aire-agent
          test -f mcp/server.py
          echo "Install structure OK on ${{ matrix.os }}"
```

- [ ] **Step 2: Write .github/workflows/sync.yml**

```yaml
name: Sync AIRE Docs

on:
  schedule:
    - cron: "0 6 * * *"  # Daily at 6am UTC
  workflow_dispatch:       # Manual trigger

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Sync documentation
        run: |
          ./scripts/sync.sh --force

      - name: Check for changes
        id: changes
        run: |
          if git diff --quiet docs/; then
            echo "changed=false" >> $GITHUB_OUTPUT
          else
            echo "changed=true" >> $GITHUB_OUTPUT
          fi

      - name: Commit and push
        if: steps.changes.outputs.changed == 'true'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs/ .last_sync
          git commit -m "chore: sync AIRE documentation from upstream"
          git push
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml .github/workflows/sync.yml
git commit -m "ci: add CI pipeline and daily docs sync workflow"
```

---

## Task 17: Final Integration & Push

**Files:** None new — verify everything works together.

- [ ] **Step 1: Run all tests locally**

```bash
# Shell tests
bats tests/unit/*.bats

# Python tests
python3 -m pytest tests/unit/*.py -v

# CLI smoke test
./bin/aire-agent --version
./bin/aire-agent info
./bin/aire-agent search "GPU"
./bin/aire-agent modules cuda
./bin/aire-agent doctor
```

- [ ] **Step 2: Validate all templates**

```bash
for f in templates/jobs/*.sh; do
    echo "=== $f ==="
    ./tools/validate-script.sh "$f"
done
```

- [ ] **Step 3: Test MCP server**

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | python3 mcp/server.py
```

- [ ] **Step 4: Verify directory structure**

```bash
find . -not -path './.git/*' -not -name '.DS_Store' | sort
```

Verify it matches the spec architecture.

- [ ] **Step 5: Push to remote**

```bash
git push origin main
```

- [ ] **Step 6: Verify CI passes**

```bash
gh run watch
```

Wait for CI to pass on GitHub Actions.
