# aire-agent

[![CI](https://github.com/omariosc/aire-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/omariosc/aire-agent/actions/workflows/ci.yml)
[![Sync](https://github.com/omariosc/aire-agent/actions/workflows/sync.yml/badge.svg)](https://github.com/omariosc/aire-agent/actions/workflows/sync.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)

AI-powered assistant for the University of Leeds AIRE HPC cluster.

https://github.com/user-attachments/assets/a26519b5-10f4-4bb8-bca4-f1c2a2745ba8

> Automated SSH login with Duo push + Claude Code as an AIRE expert — submit jobs, generate scripts, search docs, all conversationally.

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

<details>
<summary><strong>See what the installer looks like</strong></summary>

```
[sc20osc@login4[aire] ~]$ curl -fsSL https://raw.githubusercontent.com/omariosc/aire-agent/main/install.sh | bash

   ___  ______  ____       ___   ____  ____  _  __ ______
  / _ |/  _/ _ \/ __/ ___  / _ | / ___// __/ / |/ //_  __/
 / __ |_/ // , _/ _/  /___// __ |/ (_ // _/  /    /  / /
/_/ |_/___/_/|_/___/      /_/ |_|\___//___/ /_/|_/  /_/

          aire-agent installer

[info]  Checking for Python 3.8+ ...
[ ok ]  Python 3.9 detected.
[info]  Checking for git ...
[ ok ]  git 2.43.5 detected.
[info]  Cloning aire-agent to /users/sc20osc/.aire-agent ...
[ ok ]  Cloned successfully.
[info]  Installing Python dependencies ...
[ ok ]  Python dependencies installed.
[info]  Setting executable permissions ...
[ ok ]  Permissions set.

[ ok ]  aire-agent installed successfully at /users/sc20osc/.aire-agent
[info]  Run 'aire-agent' or add /users/sc20osc/.aire-agent/bin to your PATH.

[info]  Launching setup wizard ...

╭────────────────────────── aire-agent Setup Wizard ───────────────────────────╮
│                                                                              │
│  This wizard will configure:                                                 │
│                                                                              │
│    1. Environment detection (AIRE or local machine)                          │
│    2. SSH access to AIRE (local installs only)                               │
│    3. AI coding agent (Claude Code, Codex, Gemini)                           │
│    4. Experiment tracking (built-in or W&B)                                  │
│    5. Documentation sync                                                     │
│                                                                              │
│  Tip: The highlighted option is the default — just press Enter to accept     │
│  it.                                                                         │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯

--- Environment ---

  Detected hostname: login4.aire (looks like AIRE)

Where are you installing?
  aire   — Directly on the AIRE cluster
  local  — Your machine (macOS / Linux / WSL2) [aire/local] (aire): aire

--- Credentials ---

University username (sc20osc): sc20osc
Email address (sc20osc@leeds.ac.uk):

  Username: sc20osc
  Email:    sc20osc@leeds.ac.uk

--- Shell Configuration ---

  Added to ~/.bashrc:
    export PATH="$HOME/.aire-agent/bin:$PATH"

  Run source ~/.bashrc to activate in this session.

--- AI Agent ---

                     Available Agents
┏━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┓
┃ Choice ┃ Agent       ┃ Status        ┃ Notes           ┃
┡━━━━━━━━╇━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━┩
│ claude │ Claude Code │ installed     │ (recommended)   │
├────────┼─────────────┼───────────────┼─────────────────┤
│ codex  │ Codex CLI   │ not installed │                 │
├────────┼─────────────┼───────────────┼─────────────────┤
│ gemini │ Gemini CLI  │ not installed │                 │
├────────┼─────────────┼───────────────┼─────────────────┤
│  skip  │ Skip        │               │ Configure later │
└────────┴─────────────┴───────────────┴─────────────────┘

Which agent? [claude/codex/gemini/skip] (claude): claude
  Claude Code is already installed.

--- Claude MCP Configuration ---

  MCP server registered in ~/.claude/settings.json

╭──────────────────────────────── Permissions ─────────────────────────────────╮
│ About --dangerously-skip-permissions                                         │
│                                                                              │
│ AI agents can be run with a flag that skips permission prompts,              │
│ allowing them to execute commands without confirmation.                      │
│                                                                              │
│ Risk:  The agent can run arbitrary commands on AIRE                          │
│         (file deletions, job submissions, etc.) without asking.              │
│                                                                              │
│ Reward: Fully autonomous workflows — the agent handles                       │
│          the entire submit-monitor-analyse loop unattended.                  │
│                                                                              │
│ Use this flag only when you understand what the agent will do.               │
╰──────────────────────────────────────────────────────────────────────────────╯

--- Experiment Tracking ---

Tracking backend
  builtin — Local JSONL logger (no setup needed)
  wandb   — Weights & Biases (requires API key)
  skip    — Configure later [builtin/wandb/skip] (builtin):
  Created experiment directory: /users/sc20osc/.aire-agent/experiments

╭────────────────────────────────── All Done ──────────────────────────────────╮
│                                                                              │
│  Setup complete!                                                             │
│                                                                              │
│  Quick-start commands:                                                       │
│                                                                              │
│    aire-agent submit job.sh   Submit a Slurm job                             │
│    aire-agent queue            Check your job queue                          │
│    aire-agent generate         Generate an SBATCH script                     │
│    aire-agent doctor           Run health checks                             │
│                                                                              │
│  Start Claude Code:                                                          │
│                                                                              │
│    cd ~/.aire-agent && claude                                                │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
[sc20osc@login4[aire] ~]$
```

</details>

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

Claude Code reads `CLAUDE.md` for AIRE-specific context (hard constraints, storage rules, module patterns) and registers the MCP server automatically.

### Example Prompts

Try these to see what the agent can do:

**Quick test job:**
> Run a test job on a single GPU with recommended settings. Write a Python script that calculates the 100th prime number and logs how long it took. Email me when it's done and tell me the result.

**Train a model from scratch:**
> I have a ResNet-50 training script at `train.py` that uses PyTorch DDP. I want to run it on 3 GPUs for 24 hours with 32GB memory per GPU. Set up the conda environment, generate the job script, validate it, and submit. Use mixed precision and checkpoint every 5 epochs to scratch.

**Debug a failing job:**
> My job 847291 failed after 2 hours. Check what went wrong — look at the logs in `logs/`, check if it ran out of memory or hit the time limit, and suggest how to fix it.

**Multi-node distributed training:**
> I need to train a large 3D medical image segmentation model using MONAI on 6 GPUs across 2 nodes. Set up torchrun with DDP, use $TMP_SHARED for the dataset during training, and make sure results are copied back to $SCRATCH before the job ends.

**Batch processing with array jobs:**
> I have 200 MRI scans in `$SCRATCH/data/scans/` that each need preprocessing with a Python script `preprocess.py`. Set up an array job that processes them in parallel, 20 at a time, with 16 CPUs and 64GB memory per task.

**Optimise a slow job:**
> My training job 851003 just finished. Check its efficiency — I think I'm requesting too many resources. Show me what I actually used vs what I requested and suggest better settings for next time.

**Environment setup:**
> I'm starting a new project using nnU-Net for cardiac segmentation. Set up a conda environment with nnU-Net, MONAI, and PyTorch on CUDA 12.6. Configure nnU-Net paths on $SCRATCH and create a template training script for a single GPU.

**Compare experiments:**
> Show me my last 10 experiment runs. Which one had the best validation dice score? What hyperparameters did that run use compared to the others?

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

## Connecting to AIRE

The setup wizard configures SSH and creates an `aire` alias with automatic password entry and Duo push selection. All you need to do is approve the Duo notification on your phone — everything else is handled automatically:

```
sc20osc@UOL ~ % aire
spawn ssh aire
(sc20osc@rash.leeds.ac.uk) Password:
(sc20osc@rash.leeds.ac.uk) Duo two-factor login for sc20osc@leeds.ac.uk

Enter a passcode or select one of the following options:

 1. Duo Push to +XX XXXX XX8006
 2. Duo Push to iOS

Passcode or option (1-3): 1        ← auto-selected
Success. Logging you in...
(sc20osc@login4.aire.leeds.ac.uk) Password:
(sc20osc@login4.aire.leeds.ac.uk) Duo two-factor login for sc20osc@leeds.ac.uk

Passcode or option (1-3): 1        ← auto-selected
Success. Logging you in...

###############################################################################
                               Welcome to Aire
###############################################################################

[sc20osc@login4[aire] ~]$
```

The password is entered automatically for both hops (rash gateway → AIRE login node), and Duo push (option 1) is selected automatically for both 2FA prompts. You just approve twice on your phone.

## Running on AIRE (Recommended)

The best way to use aire-agent is directly on the AIRE login node, where it has native access to Slurm, modules, and the file system.

```bash
# SSH to AIRE
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

aire-agent doesn't replace your AI agent — it makes it an AIRE expert. The agent still uses Slurm commands directly (`sbatch`, `squeue`, `scancel`, `seff`). aire-agent adds:

- **AIRE knowledge** -- the agent reads a curated knowledge base covering hardware specs, constraints, partitions, storage policies, modules, and troubleshooting so it never guesses wrong.
- **Script generation** -- produce validated SBATCH scripts with correct resource requests, module loads, and framework boilerplate. Enforces AIRE constraints (3 GPU max, partition rules, memory bounds).
- **Script validation** -- catch mistakes before submitting. Checks against AIRE-specific rules that Slurm alone won't flag.
- **Experiment tracking** -- log runs with metrics, hyperparameters, and git commits to a local JSONL tracker; optionally sync to Weights & Biases.
- **Auto-updating docs** -- the knowledge base syncs from upstream AIRE docs daily, on session start, or on demand.

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

The `aire-agent` command provides helpers that add value beyond raw Slurm. For basic job management, use Slurm directly — the AI agent knows how.

### Script Generation & Validation

```bash
# Generate a single-GPU PyTorch job script (4 hours)
aire-agent generate --gpu 1 --time 4h --framework pytorch

# Generate a 6-GPU multi-node job
aire-agent generate --gpu 6 --time 24h --framework pytorch

# Validate a script against AIRE constraints before submitting
aire-agent validate my_job.sh
```

### Knowledge & Documentation

```bash
# Search AIRE documentation
aire-agent search "GPU memory limits"

# List available software modules
aire-agent modules

# Show AIRE system information
aire-agent info

# Sync knowledge base from upstream
aire-agent sync
```

### Experiment Tracking

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
# Update the toolkit
aire-agent update

# Run health checks
aire-agent doctor
```

### Slurm (use directly)

The AI agent runs these commands directly — no wrapper needed:

```bash
sbatch script.sh          # Submit a job
squeue --me               # Check your queue
scancel 123456            # Cancel a job
seff 123456               # Efficiency report
sinfo -p gpu              # Node availability
quota -s                  # Disk quota
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
