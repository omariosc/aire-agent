# AIRE HPC System Guide

This comprehensive guide covers everything you need to know about running jobs on the AIRE HPC cluster at University of Leeds, with specific focus on AI/ML workloads using CUDA, PyTorch, and Python.

## System Overview

### Hardware Resources

**Standard Compute Nodes (52 nodes)**
- Dell R6625 servers
- AMD Dual 84-core 2.2GHz (9634 Genoa-X)
- 768GB DDR5-4800 Memory per node
- Total: 9,072 CPU cores
- ~4.6GB memory per core

**GPU Nodes (28 nodes)**
- Dell R7615 servers
- **3x NVIDIA L40S 48GB GPUs per node (maximum 3 GPUs per node)**
- AMD 24-core 2.9GHz CPU per node
- 256GB DDR5-4800 Memory per node
- Total: 84 GPU cards
- ~8 CPU cores and 85GB memory per GPU

**High-Memory Nodes (2 nodes)**
- AMD Dual 84-core 2.2GHz
- 2.3TB DDR5-4800 Memory per node
- ~13.8GB memory per core

## Job Scheduler (Slurm)

AIRE uses Slurm for job scheduling. Key commands:
- `sbatch script.sh` - Submit batch job
- `squeue --user=$USER` - Check your job status
- `scancel <JOBID>` - Cancel job
- `srun` - Interactive jobs (can also run `session` as alias command for interactive shell)

## Resource Types & Job Scripts

### 1. CPU-Only Jobs

**Serial Job (1 CPU)**
```bash
#!/bin/bash
#SBATCH --job-name=cpu_serial
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

module load miniforge
conda activate your_env

python your_script.py
```

**Multi-CPU Threaded Job (OpenMP)**
```bash
#!/bin/bash
#SBATCH --job-name=cpu_threaded
#SBATCH --time=02:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16

module load miniforge
conda activate your_env

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OMP_PLACES=cores
export OMP_PROC_BIND=close

python your_multithread_script.py
```

**Multi-Node MPI Job**
```bash
#!/bin/bash
#SBATCH --job-name=cpu_mpi
#SBATCH --time=04:00:00
#SBATCH --mem=256G
#SBATCH --ntasks=256
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128

module load openmpi
module load miniforge
conda activate your_env

mpirun python your_mpi_script.py
```

### 2. GPU Jobs

**Important GPU Constraints:**
- **Maximum 3 GPUs per node** (hardware limitation)
- For >3 GPUs, use multi-node allocation
- Default resources: 1 CPU core, 1GB memory (must request more)
- Common error "Requested node configuration is not available" means:
  - Requesting >3 GPUs on single node
  - Insufficient resources available
  - All GPU nodes occupied

**Single GPU Job**
```bash
#!/bin/bash
#SBATCH --job-name=gpu_single
#SBATCH --time=01:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

module load cuda/12.6.2
module load miniforge
conda activate your_ml_env

# Verify GPU availability
nvidia-smi

python your_gpu_script.py
```

**Multi-GPU Job (Single Node - Max 3 GPUs)**
```bash
#!/bin/bash
#SBATCH --job-name=gpu_multi
#SBATCH --time=02:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:3          # Maximum 3 GPUs per node!
#SBATCH --cpus-per-task=24    # 8 CPUs per GPU
#SBATCH --mem-per-cpu=8G
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

module load cuda/12.6.2
module load miniforge
conda activate your_ml_env

# Set GPU visibility
export CUDA_VISIBLE_DEVICES=0,1,2

# For PyTorch multi-GPU
python -m torch.distributed.launch --nproc_per_node=3 your_script.py
```

**Multi-GPU Multi-Node Job (For >3 GPUs)**
```bash
#!/bin/bash
#SBATCH --job-name=gpu_distributed
#SBATCH --time=04:00:00
#SBATCH --partition=gpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=2
#SBATCH --gres=gpu:2          # 2 GPUs per node = 4 total
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G

module load cuda/12.6.2
module load openmpi/5.0.6/gcc-13.2.0_cuda-12.6.2
module load miniforge
conda activate your_ml_env

# For PyTorch distributed training
export MASTER_ADDR=$(scontrol show hostname $SLURM_NODELIST | head -n1)
export MASTER_PORT=29500
export WORLD_SIZE=$((SLURM_NNODES * SLURM_NTASKS_PER_NODE))

srun python your_distributed_script.py
```

**4 GPU Job Example (Requires 2 Nodes)**
```bash
#!/bin/bash
#SBATCH --job-name=4gpu_training
#SBATCH --time=08:00:00
#SBATCH --partition=gpu
#SBATCH --nodes=2             # Need 2 nodes for 4 GPUs
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:2          # 2 GPUs per node
#SBATCH --cpus-per-task=16    # 8 CPUs per GPU
#SBATCH --mem-per-cpu=8G

module load cuda/12.6.2
module load miniforge
conda activate your_ml_env

# For torchrun distributed training
head_node=$(scontrol show hostname $SLURM_NODELIST | head -n1)
export MASTER_ADDR=$head_node
export MASTER_PORT=29500

# Use srun to launch torchrun on each node
srun torchrun \
    --nnodes=$SLURM_NNODES \
    --nproc_per_node=2 \
    --rdzv_id=$SLURM_JOB_ID \
    --rdzv_backend=c10d \
    --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
    your_training_script.py
```

### 3. High-Memory Jobs

```bash
#!/bin/bash
#SBATCH --job-name=himem_job
#SBATCH --time=01:00:00
#SBATCH --partition=himem
#SBATCH --mem=500G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32

module load miniforge
conda activate your_env

python your_memory_intensive_script.py
```

## AI/ML Specific Configuration

### Available Modules
```bash
# CUDA versions
module load cuda/12.4.1
module load cuda/12.6.2

# PyTorch
module load pytorch/2.5.1

# Python environments
module load miniforge/24.7.1
module load python/3.13.0

# Compilers
module load gcc/14.2.0
module load intel/oneapi/compiler/2025.0.4
```

### PyTorch GPU Setup Template
```bash
#!/bin/bash
#SBATCH --job-name=pytorch_gpu_job
#SBATCH --time=02:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
#SBATCH --output=output_%j.out
#SBATCH --error=error_%j.err

# Load modules
module load cuda/12.6.2
module load miniforge
conda activate pytorch_env

# Verify setup
echo "CUDA Version:"
nvcc --version
echo "GPU Status:"
nvidia-smi
echo "PyTorch CUDA availability:"
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}, Device count: {torch.cuda.device_count()}')"

# Run training
python train_model.py \
    --batch-size 32 \
    --epochs 10 \
    --lr 0.001 \
    --device cuda
```

## Fast Storage for I/O Intensive Jobs

Use `$TMP_SHARED` for temporary high-performance storage:

```bash
#!/bin/bash
#SBATCH --job-name=io_intensive
#SBATCH --time=02:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G

module load cuda/12.6.2
module load miniforge
conda activate your_env

# Copy data to fast storage
echo "Copying data to fast storage: $TMP_SHARED"
cp -r $HOME/datasets/large_dataset $TMP_SHARED/

# Run job using fast storage
python train_model.py \
    --data-path $TMP_SHARED/large_dataset \
    --output-path $TMP_SHARED/results

# Copy results back
mkdir -p $HOME/results/job_$SLURM_JOB_ID
cp -r $TMP_SHARED/results/* $HOME/results/job_$SLURM_JOB_ID/

echo "Results saved to: $HOME/results/job_$SLURM_JOB_ID"
```

## Task Arrays for Parameter Sweeps

```bash
#!/bin/bash
#SBATCH --job-name=param_sweep
#SBATCH --time=01:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8G
#SBATCH --array=1-10
#SBATCH --output=sweep_%A_%a.out
#SBATCH --error=sweep_%A_%a.err
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

module load cuda/12.6.2
module load miniforge
conda activate your_env

# Define parameter arrays
learning_rates=(0.001 0.003 0.01 0.03 0.1 0.3 1.0 3.0 10.0 30.0)
batch_sizes=(16 32 64 128 256 512 1024 2048 4096 8192)

# Get parameters for this task
lr=${learning_rates[$((SLURM_ARRAY_TASK_ID-1))]}
bs=${batch_sizes[$((SLURM_ARRAY_TASK_ID-1))]}

echo "Running task $SLURM_ARRAY_TASK_ID with lr=$lr, batch_size=$bs"

python train_model.py \
    --learning-rate $lr \
    --batch-size $bs \
    --output-dir results/task_$SLURM_ARRAY_TASK_ID
```

## Testing & Development Workflow

### Quick Test Job Template
```bash
#!/bin/bash
#SBATCH --job-name=quick_test
#SBATCH --time=00:10:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=FAIL

module load cuda/12.6.2
module load miniforge
conda activate your_env

# Run quick test with minimal data
python test_model.py \
    --test-mode \
    --max-samples 100 \
    --epochs 1
```

### Interactive Development Session
```bash
# Request interactive GPU session
srun -t 01:00:00 -p gpu --gres=gpu:1 --cpus-per-task=4 --mem=16G --pty /bin/bash

# Once on compute node, load environment
module load cuda/12.6.2
module load miniforge
conda activate your_env

# Test your code interactively
python -c "import torch; print(torch.cuda.is_available())"
```

## Best Practices

### 1. Resource Estimation
- **CPU**: 1 core for serial, 8-16 for GPU jobs, up to 168 for parallel
- **Memory**: 
  - CPU jobs: 4-8GB per core
  - GPU jobs: 8-16GB per GPU (max ~85GB per GPU available)
  - ML training: Often memory-bound, monitor usage
- **Time**: Add 20% buffer to estimates
- **GPU Limits**:
  - Single node: 1-3 GPUs max
  - Multi-node: 2+ nodes for >3 GPUs
  - Each GPU node: 24 CPUs, 256GB RAM total

### 2. Environment Setup
```bash
# Create ML environment
module load miniforge
conda create -n ml_env python=3.11
conda activate ml_env
conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia
pip install transformers datasets accelerate wandb albumentations
```

### 3. Weights & Biases (W&B) Setup for Experiment Tracking

W&B is essential for tracking ML experiments. Here's how to set it up on AIRE:

#### Initial Setup (One-time)
```bash
# 1. Get your API key from https://wandb.ai/settings
# 2. Create .netrc file for authentication
cat > ~/.netrc << EOF
machine api.wandb.ai
    login omarchoudhry
    password 311478d567920c661390f90001c75439a91e266c
EOF

# 3. Set correct permissions
chmod 600 ~/.netrc

# 4. Test W&B
python -c "import wandb; print(f'W&B version: {wandb.__version__}')"
```

#### Job Script with W&B
```bash
#!/bin/bash
#SBATCH --job-name=ml_wandb
#SBATCH --time=04:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G

module load cuda/12.6.2 miniforge
conda activate ml_env

# W&B configuration
export WANDB_DIR=$SLURM_SUBMIT_DIR/wandb
# Use offline mode if no internet
# export WANDB_MODE=offline

python train_with_wandb.py
```

#### Offline Mode for AIRE
If AIRE has no internet access, use offline mode:
```bash
# In your job script
export WANDB_MODE=offline
export WANDB_DIR=$SLURM_SUBMIT_DIR/wandb

# After job completion, sync offline runs
wandb sync wandb/offline-run-*
```

### 4. Code Optimization
- Use mixed precision training: `torch.cuda.amp`
- Enable CUDA optimizations: `torch.backends.cudnn.benchmark = True`
- Profile GPU usage: `nvidia-smi dmon`
- Monitor memory: `torch.cuda.memory_summary()`
- Enable TF32 for A100/L40S: `torch.backends.cuda.matmul.allow_tf32 = True`
- Gradient accumulation for larger effective batch sizes
- Use DistributedDataParallel (DDP) for multi-GPU

### 5. Data Management
- Use `$TMP_SHARED` for large datasets during jobs
- Pre-process data to reduce I/O
- Use DataLoader with multiple workers
- Consider data compression

## Common Commands for AI Agents

### Submit and Monitor
```bash
# Submit job
sbatch your_script.sh

# Check job status
squeue --user=$USER

# Check detailed job info
scontrol show job <JOBID>

# Cancel job
scancel <JOBID>

# Check GPU usage on running job
ssh <nodename>
nvidia-smi
```

### Resource Usage Monitoring
```bash
# Check job efficiency after completion
seff <JOBID>

# Check accounting info
sacct -j <JOBID> --format=JobID,JobName,Partition,State,Time,Start,End,NodeList,AllocCPUS,ReqMem,MaxRSS,MaxVMSize
```

### GPU Availability Checking
```bash
# Check GPU partition status
sinfo -p gpu

# Check GPU partition with node details
sinfo -p gpu -o "%N %G %C %m %e %t"

# Check current GPU usage
squeue -p gpu

# Check specific GPU node availability
scontrol show node <nodename>

# Quick GPU availability summary
sinfo -p gpu --Format=nodes,nodelist,gres,cpus,memory,statelong
```

### Module Management
```bash
# List available modules
module avail

# Load modules
module load cuda/12.6.2 miniforge

# List loaded modules
module list

# Unload modules
module purge
```

## Troubleshooting

### Common Issues
1. **Job pending**: Check `squeue` reason field
2. **Out of memory**: Reduce batch size or request more memory
3. **CUDA errors**: Verify GPU allocation and CUDA module loading
4. **Slow I/O**: Use `$TMP_SHARED` for large datasets
5. **"Requested node configuration is not available"**:
   - Requesting >3 GPUs on single node (use multi-node)
   - Requesting too many CPUs/memory per GPU
   - Check available resources: `sinfo -p gpu`
6. **Module not found errors (sklearn, albumentations, etc.)**:
   - Install in conda environment: `pip install scikit-learn albumentations`
   - Submit installation job if on compute node
7. **CUDA device ordinal errors**:
   - Check CUDA_VISIBLE_DEVICES matches actual GPUs
   - For multi-node: ensure proper rank/world_size setup
8. **Distributed training failures**:
   - Use srun to launch torchrun on each node
   - Set MASTER_ADDR and MASTER_PORT correctly
   - Check network connectivity between nodes

### Debugging Scripts
```bash
# Add to job script for debugging
set -e  # Exit on error
set -x  # Print commands

# Check environment
echo "Node: $(hostname)"
echo "CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
echo "Loaded modules:"
module list

# Test GPU
nvidia-smi
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"
```

## Python Package Management on AIRE

### Installing Packages on Compute Nodes
Since compute nodes may not have internet access, create installation scripts:

```bash
#!/bin/bash
#SBATCH --job-name=install_packages
#SBATCH --time=00:15:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --output=install_%j.out
#SBATCH --error=install_%j.err

module load miniforge
conda activate your_env

# Install packages
pip install scikit-learn albumentations wandb tensorboard

# Verify installations
python -c "import sklearn, albumentations, wandb; print('All packages installed successfully')"
```

### Essential ML Packages
```bash
# Core ML/DL
pip install torch torchvision torchaudio  # Use conda for CUDA support
pip install tensorflow tensorboard

# Data processing
pip install numpy pandas scikit-learn
pip install opencv-python albumentations
pip install h5py zarr

# Experiment tracking
pip install wandb mlflow tensorboard

# Distributed training
pip install accelerate deepspeed

# NLP
pip install transformers datasets tokenizers

# Computer Vision
pip install timm segmentation-models-pytorch
```

### Managing Dependencies
Create a requirements file for reproducibility:
```bash
# Generate requirements
pip freeze > requirements.txt

# Install from requirements in job
pip install -r requirements.txt
```

## Git LFS (Large File Storage) Setup

Git LFS is essential for ML projects with large model files, datasets, and checkpoints. Here's comprehensive setup for AIRE:

### Initial Git LFS Setup
```bash
# Install Git LFS (if not already available)
module load git/2.41.0  # Or latest version
git lfs install

# Initialize LFS in your repository
cd your_project
git lfs track "*.pkl"    # Model files
git lfs track "*.pth"    # PyTorch models
git lfs track "*.pt"     # PyTorch tensors
git lfs track "*.ckpt"   # Checkpoints
git lfs track "*.h5"     # HDF5 files
git lfs track "*.hdf5"   # HDF5 files
git lfs track "*.safetensors"  # Safetensors format
git lfs track "*.onnx"   # ONNX models
git lfs track "*.pb"     # TensorFlow models
git lfs track "*.tflite" # TensorFlow Lite
git lfs track "*.caffemodel"  # Caffe models
git lfs track "*.npy"    # NumPy arrays
git lfs track "*.npz"    # Compressed NumPy
git lfs track "*.zarr"   # Zarr arrays
git lfs track "*.parquet"  # Parquet files
git lfs track "*.arrow"  # Arrow files
git lfs track "*.feather"  # Feather files
git lfs track "*.bin"    # Binary files
git lfs track "*.model"  # Generic model files
git lfs track "*.weights"  # Model weights

# Dataset files
git lfs track "*.zip"
git lfs track "*.tar"
git lfs track "*.tar.gz"
git lfs track "*.tgz"
git lfs track "*.gz"
git lfs track "*.7z"
git lfs track "*.rar"

# Image datasets
git lfs track "*.tif"
git lfs track "*.tiff"
git lfs track "*.png"
git lfs track "*.jpg"
git lfs track "*.jpeg"
git lfs track "*.bmp"
git lfs track "*.gif"
git lfs track "*.svg"
git lfs track "*.webp"

# Video/Audio for multimodal models
git lfs track "*.mp4"
git lfs track "*.avi"
git lfs track "*.mov"
git lfs track "*.mkv"
git lfs track "*.mp3"
git lfs track "*.wav"
git lfs track "*.flac"

# Document datasets
git lfs track "*.pdf"
git lfs track "*.doc"
git lfs track "*.docx"

# Logs and results (be selective)
git lfs track "*.log"  # Only if logs are large
git lfs track "results/*.csv"  # Large result CSVs

# Add the .gitattributes file
git add .gitattributes
git commit -m "Configure Git LFS tracking"
```

### Essential .gitignore for ML Projects
Create a comprehensive .gitignore:
```bash
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
ENV/
.venv
pip-log.txt
pip-delete-this-directory.txt
.pytest_cache/
*.egg-info/
.eggs/
*.egg

# Jupyter Notebooks
.ipynb_checkpoints
*/.ipynb_checkpoints/*
*.ipynb_checkpoints

# ML/DL frameworks
.pytorch_models/
.tensorflow/
.keras/

# Logs (unless using LFS for large logs)
logs/
*.log
!important.log  # Exception for critical logs

# Temporary files
*.tmp
*.temp
*.swp
*.swo
*~
.DS_Store

# IDE
.vscode/
.idea/
*.sublime-project
*.sublime-workspace

# Data (if not using LFS)
data/raw/
data/processed/
datasets/

# Model outputs (selective)
outputs/
checkpoints/
models/temp/
*.ckpt.tmp

# Wandb
wandb/
offline-run-*

# Slurm
slurm-*.out
core.*

# Environment
.env
.envrc

# OS
Thumbs.db
.directory

# Build artifacts
build/
dist/
*.so
*.dylib
*.dll
EOF

git add .gitignore
git commit -m "Add comprehensive .gitignore for ML projects"
```

### Git LFS on AIRE Best Practices

#### 1. Clone with LFS
```bash
# Clone with all LFS files
git clone https://github.com/username/repo.git
cd repo
git lfs pull

# Clone without LFS files (faster initial clone)
GIT_LFS_SKIP_SMUDGE=1 git clone https://github.com/username/repo.git
cd repo
# Selectively pull LFS files
git lfs pull --include="*.pth" --exclude="datasets/*"
```

#### 2. Storage Management
```bash
# Check LFS storage usage
git lfs ls-files --size

# Prune old LFS files
git lfs prune

# Fetch only recent LFS files
git lfs fetch --recent

# Track storage in job scripts
echo "LFS storage before job:"
du -sh .git/lfs
```

#### 3. Job Script with Git Integration
```bash
#!/bin/bash
#SBATCH --job-name=ml_git_job
#SBATCH --time=04:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1

# Load git module
module load git/2.41.0

# Auto-commit results after training
cd $SLURM_SUBMIT_DIR

# Pull latest changes
git pull
git lfs pull

# Run training
python train.py

# Commit results (excluding temp files)
git add results/*.json results/*.png
git add -u  # Update tracked files
git commit -m "Results from job $SLURM_JOB_ID"

# Optional: Push if you have SSH keys set up
# git push
```

#### 4. LFS for Checkpointing
```python
# In your training script
import os
import subprocess

def save_checkpoint_with_git(model, optimizer, epoch, path):
    """Save checkpoint and track with Git LFS."""
    # Save checkpoint
    torch.save({
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
    }, path)
    
    # Track with Git LFS if not already tracked
    if not os.path.exists('.gitattributes'):
        subprocess.run(['git', 'lfs', 'track', '*.pth'])
    
    # Add to git
    subprocess.run(['git', 'add', path])
    subprocess.run(['git', 'commit', '-m', f'Checkpoint epoch {epoch}'])
```

#### 5. Handling Large Datasets
```bash
# Option 1: Keep datasets outside git
echo "datasets/" >> .gitignore

# Option 2: Use Git LFS with pointer files
git lfs track "datasets/**"

# Option 3: Use DVC (Data Version Control) instead
pip install dvc
dvc init
dvc add datasets/
git add datasets.dvc .gitignore
git commit -m "Track datasets with DVC"
```

### Troubleshooting Git LFS on AIRE

1. **LFS bandwidth exceeded**:
   ```bash
   # Use SSH instead of HTTPS
   git remote set-url origin git@github.com:username/repo.git
   ```

2. **Slow LFS downloads**:
   ```bash
   # Increase concurrent transfers
   git config lfs.concurrenttransfers 8
   ```

3. **Storage quota issues**:
   ```bash
   # Clean up old LFS objects
   git lfs prune --verify-remote
   ```

4. **Missing LFS files**:
   ```bash
   # Re-fetch missing files
   git lfs fetch --all
   git lfs checkout
   ```

## Experiment Organization Best Practices

### Never Overwrite Results - Use Timestamped Directories

**Critical**: Always create timestamped directories for each run to prevent data loss:

```python
# In your training script
from datetime import datetime
from pathlib import Path

# Create unique run directory
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
run_name = f"run_{timestamp}"
output_dir = Path("results") / run_name

# Create subdirectories
(output_dir / "checkpoints").mkdir(parents=True, exist_ok=True)
(output_dir / "logs").mkdir(parents=True, exist_ok=True)
(output_dir / "config").mkdir(parents=True, exist_ok=True)
(output_dir / "plots").mkdir(parents=True, exist_ok=True)

# Save all configuration
config_info = {
    'timestamp': timestamp,
    'slurm_job_id': os.environ.get('SLURM_JOB_ID', 'local'),
    'training_config': {...},
    'model_config': {...},
    'system_info': {...}
}

# Save config for reproducibility
with open(output_dir / "config/full_config.yaml", 'w') as f:
    yaml.dump(config_info, f)

# Create symlink to latest run
latest_link = Path("results/latest")
if latest_link.exists():
    latest_link.unlink()
latest_link.symlink_to(output_dir.absolute())
```

### What to Save in Each Run

1. **Configuration** (`config/`):
   - Full training configuration
   - Model architecture details
   - Dataset information
   - Environment (pip freeze, conda export)
   - System information
   - SLURM job details

2. **Checkpoints** (`checkpoints/`):
   - Best model weights
   - Latest model weights
   - Optimizer state for resuming

3. **Logs** (`logs/`):
   - Training logs
   - Validation metrics
   - Error logs
   - W&B offline runs

4. **Results** (`results/`):
   - Final predictions
   - Confusion matrices
   - Performance metrics
   - Summary statistics

5. **Visualizations** (`plots/`):
   - Training curves
   - Sample predictions
   - Feature visualizations
   - Metric plots

### Job Script Example with Proper Organization

```bash
#!/bin/bash
#SBATCH --job-name=ml_organized
#SBATCH --output=logs/%j_%x.out
#SBATCH --error=logs/%j_%x.err

# Create base logs directory
mkdir -p logs

# Generate timestamp for this run
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RUN_NAME="run_${TIMESTAMP}_job${SLURM_JOB_ID}"

# Export for Python script to use
export RUN_NAME=$RUN_NAME
export OUTPUT_DIR="results/$RUN_NAME"

# Log run information
echo "Starting run: $RUN_NAME"
echo "Output directory: $OUTPUT_DIR"
echo "Timestamp: $TIMESTAMP"
echo "SLURM Job ID: $SLURM_JOB_ID"

# Run training
python train.py --output-dir $OUTPUT_DIR

# After training, create summary
echo "Run completed. Results in: $OUTPUT_DIR"
ls -la $OUTPUT_DIR/
```

### Post-Run Analysis

Create a summary script to quickly review runs:

```bash
#!/bin/bash
# List all runs with key metrics
for run in results/run_*/; do
    if [ -f "$run/training_summary.json" ]; then
        echo "=== $run ==="
        jq '.final_metrics.best_pore_iou' "$run/training_summary.json"
        echo ""
    fi
done
```

## Email Notifications for Job Status

AIRE supports email notifications for job status updates. Add these directives to your job scripts:

```bash
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL
```

### Email Notification Options
- `BEGIN` - Email when job starts
- `END` - Email when job completes
- `FAIL` - Email if job fails
- `ALL` - Email for all events
- `REQUEUE` - Email if job is requeued
- `TIME_LIMIT_90` - Email when 90% of time limit reached
- `TIME_LIMIT` - Email when time limit reached

### Example with Notifications
```bash
#!/bin/bash
#SBATCH --job-name=ml_training
#SBATCH --time=04:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL,TIME_LIMIT_90

# Your job commands here
```

### Multiple Recipients
For multiple recipients, use comma-separated emails:
```bash
#SBATCH --mail-user=user1@leeds.ac.uk,user2@leeds.ac.uk
```

### Email Content
Emails typically include:
- Job ID and name
- Start/end time
- Exit status
- Resources used
- Node allocation

## Best Practices Summary

1. **Always test with small jobs first** - 10-minute test runs save hours
2. **Use timestamped directories** - Never lose results by overwriting
3. **Save complete configuration** - Ensure full reproducibility
4. **Enable email notifications** - Stay informed about job status
4. **Monitor resource usage** - Use `seff` after jobs complete
5. **Use array jobs for hyperparameter searches** - More efficient than sequential
6. **Enable W&B for experiment tracking** - Essential for comparing runs
7. **Save checkpoints frequently** - Jobs can be preempted
8. **Use mixed precision (fp16/bf16)** - 2x speedup with minimal accuracy loss
9. **Profile before optimizing** - Know where the bottlenecks are
10. **Document module combinations** - Some versions conflict
11. **Use Git LFS for large files** - Keep repos manageable
12. **Always exclude .pyc files** - They're environment-specific
13. **Create symlinks to latest runs** - Easy access to most recent results
14. **Generate summaries** - Quick overview without opening multiple files

This guide should serve as a comprehensive reference for both manual use and AI agent automation of AIRE HPC jobs.
