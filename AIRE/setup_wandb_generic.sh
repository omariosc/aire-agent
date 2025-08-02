#!/bin/bash
#SBATCH --job-name=setup_wandb
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --time=00:10:00
#SBATCH --output=setup_wandb_%j.out
#SBATCH --error=setup_wandb_%j.err

# Generic W&B setup script for AIRE HPC
# This script can be reused across different projects

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
    login omarchoudhry
    password 311478d567920c661390f90001c75439a91e266c
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
            print('\\nWARNING: W&B credentials not configured!')
            print('Please edit ~/.netrc with your actual credentials')
            sys.exit(1)
        else:
            print('\\nW&B credentials appear to be configured')
except Exception as e:
    print(f'\\nError checking credentials: {e}')
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