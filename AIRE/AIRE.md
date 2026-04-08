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
- `seff <JOBID>` - Show job efficiency and resource usage (after completion)

## Additional Documentation

For information not covered in this guide, refer to the comprehensive AIRE documentation at:
```
/Users/scsoc/Library/CloudStorage/OneDrive-UniversityofLeeds/University/PhD/Documents/HPC/hpc/AIRE/aire-main/
```

This includes:
- Full module listings (`modules.txt`)
- Application-specific guides (MATLAB, COMSOL, etc.)
- Container usage documentation
- Storage and filesystem quotas
- Data lifecycle management

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
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

module load miniforge
conda activate your_env

python your_script.py

# Show job efficiency
seff $SLURM_JOB_ID
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
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

module load miniforge
conda activate your_env

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OMP_PLACES=cores
export OMP_PROC_BIND=close

python your_multithread_script.py

seff $SLURM_JOB_ID
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
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

module load openmpi
module load miniforge
conda activate your_env

mpirun python your_mpi_script.py

seff $SLURM_JOB_ID
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

seff $SLURM_JOB_ID
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

seff $SLURM_JOB_ID
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
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

module load cuda/12.6.2
module load openmpi/5.0.6/gcc-13.2.0_cuda-12.6.2
module load miniforge
conda activate your_ml_env

# For PyTorch distributed training
export MASTER_ADDR=$(scontrol show hostname $SLURM_NODELIST | head -n1)
export MASTER_PORT=29500
export WORLD_SIZE=$((SLURM_NNODES * SLURM_NTASKS_PER_NODE))

srun python your_distributed_script.py

seff $SLURM_JOB_ID
```

**6 GPU Job Example (Requires 2 Nodes)**
```bash
#!/bin/bash
#SBATCH --job-name=6gpu_training
#SBATCH --time=08:00:00
#SBATCH --partition=gpu
#SBATCH --nodes=2             # Need 2 nodes for 6 GPUs
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:3          # 3 GPUs per node (max per node)
#SBATCH --cpus-per-task=24    # 8 CPUs per GPU
#SBATCH --mem-per-cpu=8G
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

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
    --nproc_per_node=3 \
    --rdzv_id=$SLURM_JOB_ID \
    --rdzv_backend=c10d \
    --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
    your_training_script.py

seff $SLURM_JOB_ID
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
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

module load miniforge
conda activate your_env

python your_memory_intensive_script.py

seff $SLURM_JOB_ID
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
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

# Create logs directory
mkdir -p logs

# Load modules
module load cuda/12.6.2
module load miniforge/24.7.1

# Initialize conda
source $(conda info --base)/etc/profile.d/conda.sh

# Activate environment
conda activate your_ml_env

# PyTorch GPU settings
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_LAUNCH_BLOCKING=0
export CUDNN_BENCHMARK=1

# Check GPU availability
nvidia-smi
python -c "import torch; print(f'GPUs available: {torch.cuda.device_count()}')"

# Run training
python train.py

seff $SLURM_JOB_ID
```

### Creating ML/AI Conda Environment

```bash
# Request interactive session
srun --partition=gpu --gres=gpu:1 --time=01:00:00 --pty /bin/bash

# Load modules
module load cuda/12.6.2
module load miniforge/24.7.1

# Create environment
conda create -n ml_env python=3.11 -y
conda activate ml_env

# Install PyTorch with CUDA support
conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia -y

# Install common ML packages
pip install transformers datasets accelerate wandb albumentations scikit-learn tensorboard
```

## Weights & Biases (W&B) Setup for Experiment Tracking

W&B is essential for tracking ML experiments. Here's comprehensive setup for AIRE:

### Initial W&B Setup Script

Save this as `setup_wandb.sh` and run with `sbatch setup_wandb.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=setup_wandb
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --time=00:10:00
#SBATCH --output=setup_wandb_%j.out
#SBATCH --error=setup_wandb_%j.err
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

echo "Setting up Weights & Biases (W&B) for experiment tracking..."
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Time: $(date)"

# Load required modules
module load miniforge

# Check if conda environment name was provided as argument
ENV_NAME=${1:-ml_env}
echo "Using conda environment: $ENV_NAME"

# Activate conda environment
source $(conda info --base)/etc/profile.d/conda.sh
conda activate $ENV_NAME

# Install W&B and common ML tracking tools
echo "Installing W&B and related packages..."
pip install --upgrade wandb tensorboard mlflow

# Install additional useful packages for ML experiments
pip install --upgrade \
    scikit-learn \
    albumentations \
    seaborn \
    matplotlib \
    pandas \
    tqdm \
    pyyaml

# Create .netrc file for W&B authentication if it doesn't exist
if [ ! -f ~/.netrc ]; then
    echo "Creating .netrc file for W&B authentication..."
    echo "================================================================"
    echo "IMPORTANT: Edit ~/.netrc and add your W&B credentials:"
    echo ""
    echo "machine api.wandb.ai"
    echo "  login YOUR_WANDB_USERNAME"
    echo "  password YOUR_WANDB_API_KEY"
    echo ""
    echo "Get your API key from: https://wandb.ai/settings"
    echo "================================================================"
    
    # Create template .netrc file
    cat > ~/.netrc << EOF
machine api.wandb.ai
  login YOUR_WANDB_USERNAME
  password YOUR_WANDB_API_KEY
EOF
    
    # Set correct permissions
    chmod 600 ~/.netrc
else
    echo ".netrc file already exists. Checking permissions..."
    chmod 600 ~/.netrc
fi

# Test W&B installation
echo ""
echo "Testing W&B installation..."
python -c "
import wandb
import sys

print(f'W&B version: {wandb.__version__}')

# Check if credentials are set
try:
    import os
    netrc_path = os.path.expanduser('~/.netrc')
    with open(netrc_path, 'r') as f:
        content = f.read()
        if 'YOUR_WANDB_USERNAME' in content:
            print('\nWARNING: W&B credentials not configured!')
            print('Please edit ~/.netrc with your actual credentials')
            sys.exit(1)
        else:
            print('\nW&B credentials appear to be configured')
except Exception as e:
    print(f'\nError checking credentials: {e}')
"

# Create directories for W&B
echo ""
echo "Creating W&B directories..."
mkdir -p ~/wandb
mkdir -p $SLURM_SUBMIT_DIR/wandb

# Test other installed packages
echo ""
echo "Testing other ML packages..."
python -c "
try:
    import sklearn
    print(f'scikit-learn version: {sklearn.__version__}')
except ImportError:
    print('scikit-learn not installed')

try:
    import albumentations
    print(f'albumentations version: {albumentations.__version__}')
except ImportError:
    print('albumentations not installed')

try:
    import tensorboard
    print(f'TensorBoard available')
except ImportError:
    print('TensorBoard not installed')
"

echo ""
echo "================================================================"
echo "W&B setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit ~/.netrc with your W&B credentials (if not already done)"
echo "2. In your job scripts, add:"
echo "   export WANDB_DIR=\$SLURM_SUBMIT_DIR/wandb"
echo "3. For offline mode (no internet), add:"
echo "   export WANDB_MODE=offline"
echo "4. After offline runs, sync with:"
echo "   wandb sync wandb/offline-run-*"
echo "================================================================"

# Save environment info
echo ""
echo "Saving environment information..."
conda env export > wandb_env_${SLURM_JOB_ID}.yml
pip freeze > wandb_requirements_${SLURM_JOB_ID}.txt

echo "Environment saved to:"
echo "  - wandb_env_${SLURM_JOB_ID}.yml"
echo "  - wandb_requirements_${SLURM_JOB_ID}.txt"
```

### Job Script with W&B Integration

Generic ML training template with W&B:

```bash
#!/bin/bash
#SBATCH --job-name=ml_training
#SBATCH --time=04:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
#SBATCH --output=logs/train_%j.out
#SBATCH --error=logs/train_%j.err
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

# Generic ML training job template with W&B integration
# Customize this template for your specific needs

# Create logs directory
mkdir -p logs

echo "Starting ML training job"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "GPUs: $CUDA_VISIBLE_DEVICES"
echo "Time: $(date)"

# Load required modules
module load cuda/12.6.2
module load miniforge

# Initialize conda
source $(conda info --base)/etc/profile.d/conda.sh

# Activate your environment (change this to your env name)
ENV_NAME=${ENV_NAME:-ml_env}
conda activate $ENV_NAME

# Set up environment variables
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# Enable CUDA optimizations
export TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6"
export CUDA_LAUNCH_BLOCKING=0
export CUDNN_BENCHMARK=1

# W&B configuration
export WANDB_DIR=$SLURM_SUBMIT_DIR/wandb
mkdir -p $WANDB_DIR

# Optional: Use offline mode if no internet
# export WANDB_MODE=offline

# Optional: Set W&B project name
export WANDB_PROJECT=${WANDB_PROJECT:-my-ml-project}

# Check GPU availability
echo ""
echo "Checking GPU availability..."
nvidia-smi
echo ""
python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'GPU count: {torch.cuda.device_count()}')
if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        print(f'GPU {i}: {torch.cuda.get_device_name(i)}')
        print(f'  Memory: {torch.cuda.get_device_properties(i).total_memory / 1e9:.2f} GB')
"

# Optional: Copy data to fast storage for better I/O
if [ -n "$USE_TMP_STORAGE" ]; then
    echo "Copying data to fast storage..."
    cp -r $DATA_DIR $TMP_SHARED/
    export DATA_DIR=$TMP_SHARED/$(basename $DATA_DIR)
fi

# Run your training script
echo ""
echo "Starting training..."
python train.py \
    --data-dir ${DATA_DIR:-./data} \
    --output-dir ${OUTPUT_DIR:-./outputs} \
    --epochs ${EPOCHS:-100} \
    --batch-size ${BATCH_SIZE:-32} \
    --learning-rate ${LR:-0.001} \
    --device cuda \
    ${EXTRA_ARGS}

# Save job exit status
EXIT_STATUS=$?

# Optional: Copy results back from fast storage
if [ -n "$USE_TMP_STORAGE" ]; then
    echo "Copying results back..."
    cp -r $TMP_SHARED/outputs/* $OUTPUT_DIR/
fi

# Sync W&B offline runs if in offline mode
if [ "$WANDB_MODE" = "offline" ]; then
    echo "W&B was in offline mode. To sync runs later, use:"
    echo "wandb sync $WANDB_DIR/offline-run-*"
fi

echo ""
echo "Job completed at $(date)"
echo "Exit status: $EXIT_STATUS"

# Print resource usage
echo ""
echo "Resource usage for job $SLURM_JOB_ID:"
seff $SLURM_JOB_ID || echo "seff not available yet"

exit $EXIT_STATUS
```

### W&B Best Practices on AIRE

1. **Always set WANDB_DIR** to avoid cluttering home directory
2. **Use offline mode** when internet is unreliable:
   ```bash
   export WANDB_MODE=offline
   ```
3. **Sync offline runs** after job completion:
   ```bash
   wandb sync wandb/offline-run-*
   ```
4. **Log system metrics**:
   ```python
   wandb.init(
       project="my-project",
       config=config,
       settings=wandb.Settings(
           _stats_sample_rate_seconds=0.1,
           _stats_samples_to_average=5
       )
   )
   ```

## Git LFS (Large File Storage) Setup

Git LFS is essential for ML projects with large model files, datasets, and checkpoints. Here's comprehensive setup for AIRE:

### Initial Git LFS Setup
```bash
# Install Git LFS (if not already available)
module load git-lfs
git lfs install

# Track common ML file types
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

# Track compressed archives
git lfs track "*.zip"
git lfs track "*.tar"
git lfs track "*.tar.gz"
git lfs track "*.tgz"
git lfs track "*.gz"
git lfs track "*.7z"
git lfs track "*.rar"

# Track large images
git lfs track "*.tif"
git lfs track "*.tiff"
git lfs track "*.png"
git lfs track "*.jpg"
git lfs track "*.jpeg"
git lfs track "*.bmp"
git lfs track "*.gif"
git lfs track "*.svg"
git lfs track "*.webp"

# Track media files
git lfs track "*.mp4"
git lfs track "*.avi"
git lfs track "*.mov"
git lfs track "*.mkv"
git lfs track "*.mp3"
git lfs track "*.wav"
git lfs track "*.flac"

# Track documents
git lfs track "*.pdf"
git lfs track "*.doc"
git lfs track "*.docx"

# Track large logs/results
git lfs track "*.log"  # Only if logs are large
git lfs track "results/*.csv"  # Large result CSVs

# Commit .gitattributes
git add .gitattributes
git commit -m "Configure Git LFS tracking"
```

### Always Ignore Python Cache Files
Add to `.gitignore`:
```
# Python
__pycache__/
*.py[cod]
*$py.class
*.pyc
*.pyo
*.pyd
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Jupyter
.ipynb_checkpoints/
*.ipynb_checkpoints

# Virtual environments
venv/
ENV/
env/
.venv/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs (unless tracked by LFS)
*.log
logs/

# Temporary
tmp/
temp/
.tmp/

# Model outputs (track with LFS if needed)
wandb/
runs/
outputs/
checkpoints/
```

### Git LFS on AIRE Best Practices

1. **Clone with LFS files**:
   ```bash
   git clone <repo>
   cd <repo>
   git lfs pull
   ```

2. **Clone without LFS files** (faster initial clone):
   ```bash
   GIT_LFS_SKIP_SMUDGE=1 git clone <repo>
   # Later, pull only needed files:
   git lfs pull --include="*.pth" --exclude="datasets/*"
   ```

3. **Check LFS status**:
   ```bash
   git lfs ls-files --size
   ```

## Storage and Data Transfer

### Storage Quotas
- Home directory: 5TB quota (check with `quota -s`)
- Project storage: Request via IT
- Fast scratch: `/tmp` (node-local, cleared after job)
- Shared fast storage: `$TMP_SHARED` (shared across nodes in job)

### Data Transfer Methods

1. **Small files (<100GB)**: Use `rsync`
   ```bash
   # To AIRE
   rsync -avP local/path/ aire:~/remote/path/
   
   # From AIRE
   rsync -avP aire:~/remote/path/ local/path/
   ```

2. **Large files (>100GB)**: Use Globus
   - Web interface: https://app.globus.org
   - AIRE endpoint: "University of Leeds - AIRE"

3. **Within jobs**: Copy to fast storage
   ```bash
   # In job script
   cp -r ~/data $TMP_SHARED/
   # Use $TMP_SHARED/data for training
   # Copy results back before job ends
   ```

### Best Practices for Results

**Always use timestamped directories**:
```python
import os
from datetime import datetime

# Create timestamped output directory
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
output_dir = f"results/experiment_{timestamp}"
os.makedirs(output_dir, exist_ok=True)

# Save all configuration
import json
with open(f"{output_dir}/config.json", "w") as f:
    json.dump(config, f, indent=2)

# Save code snapshot
os.system(f"cp -r src {output_dir}/")
os.system(f"git log -1 > {output_dir}/git_commit.txt")
```

## Email Notifications

AIRE supports email notifications for job status updates. Add these directives to your job scripts:

```bash
#SBATCH --mail-user=your.email@leeds.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL
```

Options for `--mail-type`:
- `BEGIN` - Email when job starts
- `END` - Email when job ends
- `FAIL` - Email if job fails
- `REQUEUE` - Email if job is requeued
- `ALL` - All of the above

For multiple recipients:
```bash
#SBATCH --mail-user=user1@leeds.ac.uk,user2@leeds.ac.uk
```

## Quick Reference Commands

### Job Management
```bash
sbatch script.sh          # Submit job
squeue -u $USER          # Check your jobs
scancel <JOBID>          # Cancel job
scontrol show job <JOBID> # Detailed job info
seff <JOBID>             # Job efficiency (after completion)
sacct -j <JOBID> --format=JobID,JobName,Partition,Account,AllocCPUS,State,ExitCode
```

### Module Commands
```bash
module avail             # List available modules
module list              # List loaded modules
module load cuda/12.6.2  # Load specific module
module unload cuda       # Unload module
module purge             # Unload all modules
```

### Interactive Sessions
```bash
# Quick test session (1 GPU, 1 hour)
srun --partition=gpu --gres=gpu:1 --time=01:00:00 --pty /bin/bash

# Longer development session
srun --partition=gpu --gres=gpu:1 --cpus-per-task=8 --mem=32G --time=04:00:00 --pty /bin/bash
```

## Troubleshooting

### Common Issues

1. **"Requested node configuration is not available"**
   - Trying to request >3 GPUs on single node
   - Solution: Use multi-node allocation

2. **"Out of memory" errors**
   - Default memory allocation too small
   - Solution: Request more with `--mem-per-cpu` or `--mem`

3. **Module not found**
   - Module not loaded or wrong version
   - Solution: Check `module avail` and load correct version

4. **Slow I/O performance**
   - Using home directory for large datasets
   - Solution: Copy to `$TMP_SHARED` in job script

5. **Git LFS bandwidth exceeded**
   - Too many large files being pulled
   - Solution: Use selective pull or increase quota

### Performance Tips

1. **Use local scratch for I/O intensive tasks** - Copy data to `$TMP_SHARED`
2. **Request appropriate resources** - Don't over-request, blocks others
3. **Use array jobs for parameter sweeps** - More efficient than separate jobs
4. **Enable GPU optimizations** - Set CUDNN_BENCHMARK=1
5. **Profile your code** - Use `nsys` or PyTorch profiler
6. **Enable email notifications** - Stay informed about job status
7. **Check job efficiency** - Use `seff` to optimize resource requests
8. **Use conda environments** - Better than system Python
9. **Save configurations** - Always save exact settings for reproducibility
10. **Use version control** - Track code changes with git
11. **Use Git LFS for large files** - Keep repos manageable
12. **Implement checkpointing** - Save progress for long jobs

## Support

- IT Service Desk: itservicedesk@leeds.ac.uk
- Research Computing Team: conda-research-computing@leeds.ac.uk
- Documentation: https://docs.hpc.leeds.ac.uk
- AIRE-specific docs: `/Users/scsoc/Library/CloudStorage/OneDrive-UniversityofLeeds/University/PhD/Documents/HPC/hpc/AIRE/aire-main/`