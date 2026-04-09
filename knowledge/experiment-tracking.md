# Experiment Tracking on AIRE

Methods and tools for tracking ML experiments, metrics, and ensuring reproducibility.

## Built-in Logger (aire-agent)

The `aire-agent` CLI provides a lightweight experiment logger that writes structured JSON logs.

### CLI Usage

```bash
# Log a completed experiment
aire-agent log \
  --name "resnet50-baseline" \
  --metrics '{"val_acc": 0.923, "val_loss": 0.241, "train_loss": 0.118}' \
  --params '{"lr": 0.001, "batch_size": 64, "epochs": 100, "optimizer": "adamw"}' \
  --status completed

# Log with explicit job ID
aire-agent log --job-id $SLURM_JOB_ID --name "experiment-v2" --status completed

# List recent experiments
aire-agent log --list

# Show details for a specific run
aire-agent log --show <run-id>
```

### JSON Log Format

Each experiment is stored as a JSON record with the following fields:

```json
{
  "timestamp": "2026-04-09T14:32:01Z",
  "job_id": "1234567",
  "name": "resnet50-baseline",
  "metrics": {
    "val_acc": 0.923,
    "val_loss": 0.241,
    "train_loss": 0.118
  },
  "params": {
    "lr": 0.001,
    "batch_size": 64,
    "epochs": 100,
    "optimizer": "adamw",
    "model": "resnet50"
  },
  "git_commit": "a1b2c3d",
  "node": "gpu-node-07",
  "gpus": 3,
  "runtime": "4h 23m 15s",
  "status": "completed"
}
```

**Fields:**
| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 time when logged |
| `job_id` | SLURM job ID (auto-detected from `$SLURM_JOB_ID`) |
| `name` | User-defined experiment name |
| `metrics` | Dict of metric name/value pairs |
| `params` | Dict of hyperparameters and config |
| `git_commit` | Short SHA of current git HEAD (auto-detected) |
| `node` | Compute node hostname (auto-detected from `$SLURMD_NODENAME`) |
| `gpus` | Number of GPUs allocated (auto-detected from `$SLURM_GPUS_ON_NODE`) |
| `runtime` | Wall time of the job |
| `status` | One of: `completed`, `failed`, `timeout`, `running` |

## Weights & Biases (W&B) on AIRE

### Setup

```bash
conda activate myenv
pip install wandb
wandb login  # paste API key from wandb.ai/authorize
```

### Configure for AIRE

```bash
# Set W&B cache/data directory to avoid filling home quota
export WANDB_DIR=$TMP_SHARED/wandb

# Offline mode (recommended) -- avoids needing internet from compute nodes
export WANDB_MODE=offline
```

### Sync Offline Runs

After job completes, sync from a login node (which has internet):
```bash
wandb sync $TMP_SHARED/wandb/offline-run-*
```

Or in a post-job script:
```bash
# Add to end of SLURM script or use --epilog
wandb sync --sync-all $WANDB_DIR
```

### Python Integration Example

```python
import wandb
import os

# Initialize run
wandb.init(
    project="my-aire-project",
    name=f"run-{os.environ.get('SLURM_JOB_ID', 'local')}",
    config={
        "learning_rate": 1e-3,
        "batch_size": 64,
        "epochs": 100,
        "architecture": "resnet50",
        "dataset": "imagenet-subset",
    }
)

# Log metrics each epoch
for epoch in range(num_epochs):
    train_loss, val_loss, val_acc = run_training_and_validation(model, dataloader)

    wandb.log({
        "epoch": epoch,
        "train_loss": train_loss,
        "val_loss": val_loss,
        "val_acc": val_acc,
        "learning_rate": optimizer.param_groups[0]["lr"],
    })

# Log final model artifact
wandb.save("best_model.pt")
wandb.finish()
```

### W&B in SLURM Script

```bash
#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --time=12:00:00

module load cuda/12.6.2
module load miniforge/24.7.1
conda activate myenv

export WANDB_DIR=$TMP_SHARED/wandb
export WANDB_MODE=offline
mkdir -p $WANDB_DIR

python train.py

# Sync runs after training (optional, may need internet)
# wandb sync --sync-all $WANDB_DIR
```

## MLflow on AIRE

### Setup

```bash
conda activate myenv
pip install mlflow
```

### File-Based Tracking URI

Use a local directory for the tracking store (no server needed):

```bash
export MLFLOW_TRACKING_URI=file:///users/$USER/mlflow-runs
```

Or in a shared project directory:
```bash
export MLFLOW_TRACKING_URI=file:///users/$USER/projects/myproject/mlruns
```

### Python Example

```python
import mlflow
import os

# Set tracking URI
mlflow.set_tracking_uri(f"file:///users/{os.environ['USER']}/mlflow-runs")
mlflow.set_experiment("my-experiment")

with mlflow.start_run(run_name=f"job-{os.environ.get('SLURM_JOB_ID', 'local')}"):
    # Log parameters
    mlflow.log_params({
        "learning_rate": 1e-3,
        "batch_size": 64,
        "epochs": 100,
        "model": "resnet50",
    })

    for epoch in range(num_epochs):
        train_loss, val_loss, val_acc = run_training_and_validation(model, dataloader)

        # Log metrics
        mlflow.log_metrics({
            "train_loss": train_loss,
            "val_loss": val_loss,
            "val_acc": val_acc,
        }, step=epoch)

    # Log model artifact
    mlflow.log_artifact("best_model.pt")
    mlflow.log_artifact("environment.yaml")
```

### View Results

```bash
# Launch MLflow UI on login node (port forward to local machine)
mlflow ui --backend-store-uri file:///users/$USER/mlflow-runs --port 5000

# From local machine:
ssh -L 5000:localhost:5000 username@aire.leeds.ac.uk
# Then open http://localhost:5000
```

## Reproducibility Practices

| Practice | How |
|----------|-----|
| **Log git commit hash** | `git rev-parse --short HEAD` -- include in every run log |
| **Pin all dependency versions** | `conda env export --no-builds > environment.yaml` |
| **Set random seeds** | `torch.manual_seed(42)`, `np.random.seed(42)`, `random.seed(42)` |
| **Use timestamped output dirs** | `output/2026-04-09_143201_job1234567/` |
| **Save a code snapshot** | `git archive HEAD -o code_snapshot.tar.gz` or log git SHA |
| **Log SLURM job info** | Capture `$SLURM_JOB_ID`, node name, GPU count |
| **Save full config** | Dump all hyperparameters + env info to JSON at run start |

### Reproducibility Setup Snippet

```python
import torch
import numpy as np
import random
import os
import json
import subprocess
from datetime import datetime

def setup_reproducibility(seed=42):
    """Set all random seeds for reproducibility."""
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    np.random.seed(seed)
    random.seed(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False

def get_run_metadata():
    """Capture environment metadata for logging."""
    git_hash = subprocess.check_output(
        ["git", "rev-parse", "--short", "HEAD"],
        text=True
    ).strip()

    return {
        "timestamp": datetime.now().isoformat(),
        "git_commit": git_hash,
        "slurm_job_id": os.environ.get("SLURM_JOB_ID", "none"),
        "node": os.environ.get("SLURMD_NODENAME", "local"),
        "gpus": os.environ.get("SLURM_GPUS_ON_NODE", "0"),
        "cuda_version": torch.version.cuda,
        "pytorch_version": torch.__version__,
    }

def create_output_dir(base="output"):
    """Create timestamped output directory."""
    job_id = os.environ.get("SLURM_JOB_ID", "local")
    timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    dirname = f"{timestamp}_job{job_id}"
    path = os.path.join(base, dirname)
    os.makedirs(path, exist_ok=True)
    return path

# Usage
setup_reproducibility(seed=42)
metadata = get_run_metadata()
output_dir = create_output_dir()
with open(os.path.join(output_dir, "run_metadata.json"), "w") as f:
    json.dump(metadata, f, indent=2)
```
