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
pip install transformers datasets accelerate wandb
```

### 3. Code Optimization
- Use mixed precision training: `torch.cuda.amp`
- Enable CUDA optimizations: `torch.backends.cudnn.benchmark = True`
- Profile GPU usage: `nvidia-smi dmon`
- Monitor memory: `torch.cuda.memory_summary()`

### 4. Data Management
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

This guide should serve as a comprehensive reference for both manual use and AI agent automation of AIRE HPC jobs.
