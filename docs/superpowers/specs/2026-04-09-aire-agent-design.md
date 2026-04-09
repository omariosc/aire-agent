# aire-agent Design Spec

## Overview

**aire-agent** is a shell-first toolkit that makes any AI coding agent (Claude Code, Codex, Gemini CLI) an expert AIRE HPC assistant at the University of Leeds. Primary audience is the AIMS (AI in Medicine and Surgery) group, with broad utility for all AIRE users.

- **Repo**: `omariosc/aire-agent`
- **License**: MIT
- **Install**: `curl -fsSL https://raw.githubusercontent.com/omariosc/aire-agent/main/install.sh | bash`

### Design Principles

- Shell scripts for all tools (deterministic, fast, cheap on tokens)
- Python only for setup TUI (runs once)
- Agent reads knowledge files, not source code
- Works both locally (via SSH) and directly on AIRE (recommended)
- Tiered agent knowledge: critical rules always in context, deep lookups via MCP tools

---

## Architecture

```
aire-agent/
├── install.sh                  # curl entry point
├── bin/
│   ├── aire-setup              # One-time TUI wizard (Python/Rich)
│   └── aire-agent              # CLI dispatcher (shell)
├── tools/                      # MCP tools (shell scripts)
│   ├── submit-job.sh
│   ├── check-queue.sh
│   ├── cancel-job.sh
│   ├── job-status.sh
│   ├── job-efficiency.sh
│   ├── generate-script.sh
│   ├── validate-script.sh
│   ├── search-docs.sh
│   ├── list-modules.sh
│   ├── system-info.sh
│   ├── check-quota.sh
│   ├── node-availability.sh
│   ├── log-experiment.sh
│   ├── query-experiments.sh
│   ├── setup-wandb.sh
│   ├── sync-docs.sh
│   ├── update.sh
│   └── doctor.sh
├── mcp/
│   └── server.sh               # Thin stdio MCP wrapper dispatching to tools/
├── agent/
│   ├── CLAUDE.md               # Tiered AIRE knowledge
│   ├── AGENTS.md               # Multi-agent support (Codex, Gemini)
│   └── hooks/
│       └── session-start.sh    # Staleness check, sync if >24h
├── docs/                       # arcdocs/aire mirror (auto-synced)
├── knowledge/
│   ├── aire-system.md          # Hardware specs, node types, network
│   ├── slurm-guide.md          # Scheduler, partitions, job types, submission options
│   ├── storage.md              # Quotas, paths, env vars, best practices
│   ├── ml-on-aire.md           # PyTorch/TF on L40S, conda, CUDA, distributed training
│   ├── experiment-tracking.md  # Built-in logger, W&B, offline sync
│   ├── modules.md              # Full module list (auto-updated by sync)
│   └── troubleshooting.md      # Common errors, fixes, performance tips
├── templates/
│   ├── jobs/                   # SBATCH templates (cpu, gpu, multi-gpu, array, himem)
│   └── environments/           # Conda env yamls (pytorch, tf, medical-imaging)
├── scripts/
│   └── sync.sh                 # Daily arcdocs/aire sync
├── tests/
│   ├── unit/                   # Tool logic, script generation, validation
│   ├── integration/            # MCP server, install script, TUI headless
│   └── e2e/                    # SSH-based AIRE tests
├── .github/workflows/
│   ├── ci.yml                  # lint + unit + integration on push
│   ├── sync.yml                # daily arcdocs/aire sync
│   └── e2e.yml                 # SSH-based E2E on release
├── .last_sync                  # Timestamp of last docs sync
├── LICENSE                     # MIT
└── README.md
```

---

## MCP Server & Tools

The MCP server is a thin stdio wrapper that maps tool calls to shell scripts in `tools/`. Each tool is also accessible as a CLI subcommand via `aire-agent <subcommand>`.

### Tool Inventory

#### Job Management
| Tool | CLI | Description |
|------|-----|-------------|
| `submit-job` | `aire-agent submit job.sh` | Validate and submit SBATCH script, return job ID |
| `check-queue` | `aire-agent queue` | Show user's jobs (wraps `squeue --me`), structured output |
| `cancel-job` | `aire-agent cancel 12345` | Cancel job by ID |
| `job-status` | `aire-agent status 12345` | Detailed job info (wraps `scontrol show job`) |
| `job-efficiency` | `aire-agent efficiency 12345` | Resource usage after completion (wraps `seff`) |

#### Script Generation
| Tool | CLI | Description |
|------|-----|-------------|
| `generate-script` | `aire-agent generate --gpu 2 --time 4h --framework pytorch` | Generate validated SBATCH script from parameters |
| `validate-script` | `aire-agent validate job.sh` | Check script against AIRE constraints |

Validation rules:
- Max 3 GPUs per node
- `--partition=gpu` required with `--gres=gpu:N`
- `--time` must be specified
- Memory requests within node limits (768GB standard, 2.3TB himem, 256GB gpu)
- Multi-node required for >3 GPUs

#### Knowledge
| Tool | CLI | Description |
|------|-----|-------------|
| `search-docs` | `aire-agent search "cuda module"` | Grep-based search across docs/ and knowledge/ |
| `list-modules` | `aire-agent modules` | Available modules (cached, refreshed on sync) |
| `system-info` | `aire-agent info` | Hardware specs, partitions, storage quotas |

#### Experiment Logging
| Tool | CLI | Description |
|------|-----|-------------|
| `log-experiment` | `aire-agent log --job 12345 --metrics '{"loss": 0.5}'` | Append structured JSON to run log |
| `query-experiments` | `aire-agent experiments` | Search past runs by filters |
| `setup-wandb` | `aire-agent setup-wandb` | Guided W&B configuration |

#### Utility
| Tool | CLI | Description |
|------|-----|-------------|
| `check-quota` | `aire-agent quota` | Storage usage across HOME, SCRATCH, FLASH |
| `sync-docs` | `aire-agent sync` | Trigger manual arcdocs/aire sync |
| `node-availability` | `aire-agent nodes` | Free resources by partition |
| `update` | `aire-agent update` | Update aire-agent itself |
| `doctor` | `aire-agent doctor` | Diagnose common issues |

All tools output structured text by default, JSON with `--json` flag.

---

## Setup TUI & Installation

### Install Script

```bash
curl -fsSL https://raw.githubusercontent.com/omariosc/aire-agent/main/install.sh | bash
```

The install script:
1. Checks for Python 3.8+ and installs `rich`/`textual` via pip
2. Clones repo to `~/.aire-agent/`
3. Adds `~/.aire-agent/bin/` to PATH
4. Runs the setup TUI

### TUI Screens (Rich/Textual)

1. **Welcome** — What aire-agent is, what it will configure
2. **University credentials** — Username (e.g. `sc20abc`), email
3. **SSH setup** — Generates ed25519 key if needed, configures `~/.ssh/config` with ProxyJump through `rash.leeds.ac.uk`, creates `aire` shell alias
4. **AI agent selection** — Install Claude Code (recommended), Codex CLI, or Gemini CLI. Shows `--dangerously-skip-permissions` flag with honest risk/reward assessment
5. **MCP server registration** — Adds aire-agent MCP server to selected agent's config
6. **Experiment tracking** — Optional W&B / MLflow setup, or skip for built-in logger
7. **Initial sync** — Pulls latest arcdocs/aire docs
8. **Test connection** — SSH into AIRE to verify
9. **Done** — Summary + quick-start commands

### CLI Aliases After Setup

```bash
aire                    # SSH into AIRE
aire-agent <command>    # All subcommands listed above
```

---

## Agent Configuration

### CLAUDE.md — Tiered Knowledge

**Tier 1 (always loaded, ~200 lines):**
- AIRE hard constraints (max 3 GPUs/node, partitions, defaults)
- Common pitfalls and how to avoid them
- Storage paths and quotas ($HOME 65GB, $SCRATCH 1TB, $TMP_SHARED 1TB/job)
- Module loading patterns (cuda/12.6.2, miniforge/24.7.1, pytorch/2.5.1)
- AIMS-specific patterns (medical imaging, PyTorch best practices on L40S)
- Instruction: "Use aire-agent tools for detailed lookups, don't guess"

**Key rules:**
- Never request >3 GPUs on a single node
- Always specify `--time`, `--mem`, and `--partition` explicitly
- Always add `seff $SLURM_JOB_ID` at end of job scripts
- Use `--partition=gpu` with `--gres=gpu:N`, never one without the other
- Default allocation is 1 CPU, 1GB — always request more for real work
- Prefer $SCRATCH for data, $TMP_SHARED for I/O intensive, $HOME for scripts only
- Run `module load cuda/12.6.2` before any GPU work
- For >3 GPUs, use multi-node with torchrun/srun
- Check quota before large data operations
- Use email notifications on all jobs

**Tier 2 (accessed via MCP tools):**
- Full module list
- Application-specific guides
- Detailed job examples
- Storage deep-dive
- Troubleshooting database

### AGENTS.md

Same core rules formatted for Codex/Gemini CLI conventions.

### Hooks

- `on_session_start` — Check `.last_sync` age, run sync if >24h stale
- `on_job_submit` — Validate script against constraints before submitting

---

## Knowledge Base & Documentation

### Consolidation Plan

| Source | Action |
|--------|--------|
| `AIRE/AIRE.md` (958-line guide) | Consolidate into `knowledge/` files |
| `AIRE/aire-main/` (arcdocs repo) | Move to `docs/` as auto-synced mirror |
| `AIRE/*.pdf` | Delete — all info captured in knowledge files |
| `AIRE/*.html` | Delete — slide decks, info already extracted |
| `SWD6/*.ipynb` | Delete — generic training course, not AIRE-specific |
| `docs/Commands.md` | Delete — folded into knowledge + README |
| `README.md` | Rewrite completely |

### Knowledge Files

Each file is written for agent consumption — concise, structured, searchable:

- **aire-system.md** — Hardware specs (52 CPU nodes/168 cores each, 28 GPU nodes/3xL40S each, 2 himem nodes/2.3TB each), network (100Gb/s OmniPath), retirement date (31/07/2029)
- **slurm-guide.md** — Scheduler, partitions (default, gpu, himem), job types (batch, array, interactive), all submission options, fair-share policy
- **storage.md** — All storage types, paths, env vars, quotas, cleanup rules, what happens at 90%/100% capacity
- **ml-on-aire.md** — PyTorch/TF setup, conda env creation, CUDA versions, distributed training (torchrun, DDP), L40S-specific optimisations, medical imaging workflow patterns
- **experiment-tracking.md** — Built-in JSON logger usage, W&B setup (online/offline), MLflow, reproducibility practices
- **modules.md** — Full module list (auto-updated by sync from AIRE)
- **troubleshooting.md** — Common errors and fixes, performance tips, debugging checklist

---

## Auto-Sync Mechanism

**Primary: Script-based daily sync (`scripts/sync.sh`)**
1. Reads `.last_sync` timestamp
2. If >24h stale, pulls latest from `arcdocs/aire` into `docs/`
3. Diffs against previous version, logs changes
4. Updates `knowledge/modules.md` if module list changed
5. Writes new timestamp to `.last_sync`

**Fallback: Agent-driven staleness check**
- Claude Code hook on session start checks `.last_sync`
- If stale, runs sync automatically
- CLAUDE.md instructs agent to check periodically during long sessions

**CI-based sync:**
- GitHub Actions daily cron job pulls arcdocs/aire
- Commits changes if any, keeps repo up to date

---

## Testing Strategy

### Unit Tests (CI — every push)
- Script generation produces valid SBATCH syntax
- Validation catches constraint violations (>3 GPUs/node, missing partition)
- Docs search returns correct results
- Experiment logger writes valid JSON
- Sync script handles edge cases (no network, corrupted docs)
- CLI dispatcher routes all subcommands
- MCP server responds to all tool calls with correct schema

### Integration Tests (CI — every push)
- MCP server starts, accepts tool calls, returns structured output
- Install script works on clean environments (Ubuntu, macOS)
- Setup TUI runs headlessly with test inputs
- Agent config files are valid (CLAUDE.md parses, hooks execute)
- Templates produce runnable scripts

### E2E Tests (manual + CI with SSH secret)
- SSH into AIRE, submit a test job, check queue, cancel it
- Verify all modules in modules.md exist on AIRE
- Submit a real GPU job, confirm nvidia-smi output
- Run `aire-agent doctor` and verify all checks pass
- Test quota checking returns real values
- Sync pulls latest arcdocs/aire successfully

### CI/CD Pipeline
```
on push:    lint -> unit tests -> integration tests
on daily:   sync arcdocs/aire -> update modules.md -> commit if changed
on release: full E2E suite via SSH -> tag release
```

---

## README Structure

1. **Hero** — "AI-powered assistant for the University of Leeds AIRE HPC cluster"
2. **Quick install** — The curl command
3. **What it does** — Feature list with examples
4. **Setup guide** — TUI walkthrough
5. **CLI reference** — All `aire-agent` subcommands
6. **Using with AI agents** — Claude Code (recommended), Codex, Gemini CLI. `--dangerously-skip-permissions` explanation
7. **Running on AIRE** — Install and use directly on the cluster (recommended)
8. **For ML/DL researchers** — PyTorch/TF quick-start on L40S, AIMS workflows
9. **Experiment tracking** — Built-in logger + W&B/MLflow
10. **How it stays updated** — Auto-sync explained
11. **Contributing**
12. **License** — MIT

---

## User Journey

```
Install (curl) -> TUI setup -> aire alias works ->
pick your AI agent -> agent has full AIRE knowledge ->
generate scripts -> submit jobs -> track experiments ->
agent checks for doc updates daily
```
