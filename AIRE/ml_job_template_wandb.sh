#!/bin/bash
#SBATCH --job-name=ml_training
#SBATCH --time=04:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
#SBATCH --output=logs/train_%j.out
#SBATCH --error=logs/train_%j.err

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