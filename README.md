# aire-agent

AI-powered assistant for the University of Leeds AIRE HPC cluster.

## Quick Install

**macOS / Linux / WSL2:**

```bash
curl -fsSL https://raw.githubusercontent.com/omariosc/aire-agent/main/install.sh | bash
```

**On AIRE directly** (where `raw.githubusercontent.com` is blocked):

```bash
git clone https://github.com/omariosc/aire-agent.git ~/.aire-agent
chmod +x ~/.aire-agent/bin/* ~/.aire-agent/tools/*.sh
export PATH="$HOME/.aire-agent/bin:$PATH"
```

The curl installer clones the repository to `~/.aire-agent`, installs dependencies (Python 3.8+ and `rich`), sets executable permissions on all tools, and launches the setup wizard. The manual git clone method skips the wizard — run `aire-setup` afterwards to configure SSH and agent settings.

## Platform Requirements

**macOS and Linux** — works out of the box. No extra setup needed.

**Windows — requires WSL2.** The tools are shell scripts and will not run in Command Prompt or PowerShell. WSL2 gives you a full Linux environment on Windows and is the recommended way to use aire-agent (and Claude Code) on Windows.

### Setting Up WSL2 on Windows

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

This installs WSL2 with Ubuntu. Restart your machine when prompted, then open the **Ubuntu** app from the Start menu to complete the Ubuntu setup (create a username and password).

If you already have WSL installed but need to upgrade to WSL2:

```powershell
wsl --set-default-version 2
```

Once inside the Ubuntu terminal, install aire-agent with the curl command above. Everything — including Claude Code and SSH to AIRE — runs inside WSL2 from that point on.

> **Tip:** Windows Terminal (available from the Microsoft Store) gives you a much better WSL2 experience than the default Ubuntu app.

## Using with Claude Code

**Claude Code is the recommended way to use aire-agent.** It reads the AIRE knowledge base automatically and connects to the MCP server, giving you a conversational assistant that can submit jobs, generate scripts, search documentation, and debug issues — all without memorising commands.

### Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

Requires Node.js 18+. On macOS use `brew install node`; on Ubuntu/WSL2 use:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Start the Agent

```bash
cd ~/.aire-agent
claude
```

Claude Code reads `CLAUDE.md` for AIRE-specific context (hard constraints, storage rules, module patterns) and registers the MCP server automatically. You can ask it things like:

- *"Submit this training script with 2 GPUs for 8 hours"*
- *"Why is my job pending? Check the queue."*
- *"Generate a multi-node PyTorch job for 6 GPUs"*
- *"What's my scratch quota?"*
- *"Help me debug this CUDA out-of-memory error"*

### Autonomous Mode

To let the agent run tools without confirmation prompts:

```bash
claude --dangerously-skip-permissions
```

This lets the agent submit jobs, check queues, and run scripts autonomously. It is useful for long workflows where manual approval of each step is tedious, but it does mean the agent can execute commands on AIRE without asking first. Use it when you trust the task and want uninterrupted operation; skip it when you want to review each action.

### Setting Up the MCP Server

The setup wizard (`aire-setup`) registers the MCP server for you. To register it manually in an existing Claude Code installation:

```bash
claude mcp add aire ~/.aire-agent/mcp/server.py
```

## Running on AIRE (Recommended)

The best way to use aire-agent is directly on the AIRE login node, where it has native access to Slurm, modules, and the file system.

```bash
# SSH to AIRE (two-hop via rash)
ssh username@rash.leeds.ac.uk
ssh username@aire.leeds.ac.uk

# Install aire-agent
git clone https://github.com/omariosc/aire-agent.git ~/.aire-agent
chmod +x ~/.aire-agent/bin/* ~/.aire-agent/tools/*.sh
export PATH="$HOME/.aire-agent/bin:$PATH"

# Start Claude Code on AIRE
cd ~/.aire-agent
claude
```

Running on AIRE is better than running locally because the agent has direct access to Slurm commands (`sbatch`, `squeue`, `scancel`, `seff`), the module system, and your scratch/home directories. No SSH proxying or remote execution is needed.

## What It Does

- **Submit and manage Slurm jobs** -- submit scripts, check queue status, cancel jobs, and review efficiency reports without memorising Slurm flags.
- **Expert AIRE knowledge** -- search a curated knowledge base covering hardware specs, partitions, storage policies, modules, and troubleshooting.
- **Generate job scripts** -- produce validated SBATCH scripts with correct resource requests, module loads, and framework boilerplate for PyTorch, TensorFlow, or plain CPU jobs.
- **Track experiments** -- log runs with metrics, hyperparameters, and git commits to a local JSONL tracker; optionally sync to Weights & Biases.
- **Auto-updating documentation** -- the knowledge base syncs from upstream AIRE docs daily, on session start, or on demand.

## For ML/DL Researchers

### PyTorch Quick-Start

Generate job scripts for common GPU configurations:

```bash
# Single GPU (1x L40S, 48 GB VRAM)
aire-agent generate --gpu 1 --time 8h --framework pytorch

# 3 GPUs (full node, 3x L40S)
aire-agent generate --gpu 3 --time 24h --framework pytorch

# 6 GPUs (multi-node, 2 nodes x 3 GPUs)
aire-agent generate --gpu 6 --time 24h --framework pytorch
```

Generated scripts include module loads, PyTorch environment variables, DDP/torchrun setup for multi-GPU, and an `seff` call at the end for resource reporting.

### AIRE GPU Specs

AIRE has **84 NVIDIA L40S GPUs** (48 GB VRAM each) across 28 nodes, 3 GPUs per node. The L40S uses the Ada Lovelace architecture (compute capability 8.9) and supports bf16/fp16 tensor cores for approximately 2x throughput with mixed precision.

### Conda Environment Templates

Pre-built environment files are in `templates/environments/`:

```bash
# PyTorch environment
conda env create -f templates/environments/pytorch.yml

# TensorFlow environment
conda env create -f templates/environments/tensorflow.yml

# Medical imaging (MONAI, nnU-Net)
conda env create -f templates/environments/medical-imaging.yml
```

## Experiment Tracking

### Built-In Logger

Log experiments directly from your job script:

```bash
aire-agent log \
    --name "experiment_name" \
    --metrics '{"loss": 0.42, "dice": 0.87}' \
    --params '{"lr": 0.0003, "epochs": 100}' \
    --notes "Baseline with augmentation"
```

Experiments are stored as JSONL in `~/.aire-agent/experiments/experiments.jsonl`. The logger automatically captures the Slurm job ID, node name, GPU count, and git commit hash.

Query logged experiments:

```bash
aire-agent experiments
aire-agent experiments --last 5
```

### Weights & Biases

Run `aire-agent setup-wandb` to check your W&B installation and get HPC-specific configuration guidance. On compute nodes (no internet), use `WANDB_MODE=offline` and sync runs from the login node after completion.

## How It Stays Updated

The AIRE knowledge base syncs from upstream documentation in three ways:

1. **Daily** -- the sync script skips if the last sync was less than 24 hours ago.
2. **Session hook** -- each time an agent session starts, `agent/hooks/session-start.sh` checks the sync timestamp and pulls updates if stale.
3. **Manual** -- run `aire-agent sync` (or `aire-agent sync --force`) at any time.

## AIRE Quick Reference

| Resource       | Detail                                                     |
|----------------|------------------------------------------------------------|
| CPU nodes      | 52 nodes, 168 cores/node (2x AMD EPYC 9634), 768 GB RAM   |
| GPU nodes      | 28 nodes, 24 cores/node, 256 GB RAM, 3x L40S 48 GB each   |
| High-memory    | 2 nodes, 168 cores/node, 2.3 TB RAM                        |
| Partitions     | `default` (CPU), `gpu`, `himem`                            |
| Max GPUs/node  | 3 (NVIDIA L40S, Ada Lovelace, PCIe)                        |
| Total GPUs     | 84                                                         |
| `$HOME`        | 65 GB, backed up                                           |
| `$SCRATCH`     | 1 TB, not backed up                                        |
| `$TMP_SHARED`  | 1 TB/job, NVMe flash, auto-deleted when job ends           |
| Network        | OmniPath 100 Gb/s (compute), 25 GbE (management)          |
| Login          | `ssh user@rash.leeds.ac.uk` then `ssh user@aire.leeds.ac.uk` |
| Auth           | Password only (no SSH keys)                                |

## CLI Reference

The `aire-agent` command exposes all tools as subcommands. These are used internally by Claude Code via the MCP server, but you can also run them directly.

### Job Management

```bash
# Submit a job script
aire-agent submit my_job.sh

# Check your job queue
aire-agent queue

# Cancel a running job
aire-agent cancel 123456

# Get detailed status for a job
aire-agent status 123456

# Show efficiency report for a completed job
aire-agent efficiency 123456
```

### Script Generation

```bash
# Generate a single-GPU PyTorch job script (4 hours)
aire-agent generate --gpu 1 --time 4h --framework pytorch

# Generate a 6-GPU multi-node job
aire-agent generate --gpu 6 --time 24h --framework pytorch

# Validate a script before submitting
aire-agent validate my_job.sh
```

### Knowledge

```bash
# Search AIRE documentation
aire-agent search "GPU memory limits"

# List available software modules
aire-agent modules

# Show AIRE system information
aire-agent info
```

### Experiments

```bash
# Log an experiment with metrics and hyperparameters
aire-agent log --name "resnet50_v2" --metrics '{"val_loss": 0.32, "acc": 0.94}' --params '{"lr": 0.001, "batch": 64}'

# Query experiment history
aire-agent experiments

# Configure Weights & Biases for HPC
aire-agent setup-wandb
```

### Utility

```bash
# Check disk quota (home and scratch)
aire-agent quota

# Show node availability
aire-agent nodes

# Sync knowledge base from upstream
aire-agent sync

# Update the toolkit
aire-agent update

# Run health checks
aire-agent doctor
```

## Other AI Agents

aire-agent also works with other AI coding tools.

**Codex CLI** — Point it at the repo and reference `AGENTS.md` for context.

**Gemini CLI** — The `AGENTS.md` file provides the system prompt with AIRE-specific rules and tool descriptions.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/omariosc/aire-agent).

### Adding a New Tool

1. **Write a shell script** in `tools/` (e.g., `tools/my-tool.sh`). Follow the existing pattern: `set -euo pipefail`, argument parsing, `--help` flag, stdout output.
2. **Add a CLI route** in `bin/aire-agent` -- add a `case` entry that dispatches to your script.
3. **Register with the MCP server** in `mcp/server.py` -- add a tool definition to the `TOOLS` list and a dispatch entry in `TOOL_DISPATCH`.
4. **Add tests** in `tests/` -- write a `.bats` file for CLI tests and/or add MCP server test cases to `test_mcp_server.py`.

## License

MIT. See [LICENSE](LICENSE).
