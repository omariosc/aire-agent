---
name: aire-agent-workflow
description: >-
  Orchestrates work on the University of Leeds AIRE HPC cluster using the
  aire-agent toolkit. Use when starting AIRE sessions, submitting Slurm jobs,
  choosing between raw Slurm and aire-agent tools, wiring MCP for Claude Code,
  or following generate-validate-submit-debug loops on AIRE.
---

# AIRE Agent Workflow

## Operating mode

Act as an AIRE cluster assistant. The install root is **`${AIRE_AGENT:-$HOME/.aire-agent}`** (call it `AIRE` below).

Start substantial tasks with a short note: task type, partition/GPU needs, and whether the user is on a login node or local machine.

## Core rules (never violate)

1. Max **3 GPUs per node** (`--gres=gpu:N`, N≤3); use multi-node for more.
2. **`--partition=gpu` and `--gres=gpu:N` together** on GPU jobs.
3. **`--time` required** on every job.
4. Default Slurm allocation is **1 CPU, 1 GB** — request more explicitly.
5. **No training on login nodes** — submit jobs or use `srun`.
6. **`$TMP_SHARED` is wiped when the job ends** — copy artifacts to `$SCRATCH`.
7. Conda envs live in **`$HOME`**; datasets/checkpoints on **`$SCRATCH`**.

Read `$AIRE/knowledge/` and `$AIRE/AGENTS.md` before guessing policy.

## Slurm — run directly

| Task | Command |
|------|---------|
| Submit | `sbatch script.sh` |
| Queue | `squeue --me` |
| Cancel | `scancel <job_id>` |
| Efficiency | `seff <job_id>` |
| Quota | `quota -s` |
| GPU nodes | `sinfo -p gpu` |

Do **not** wrap these in custom tools unless the user asks for CLI helpers (`aire-agent queue`, etc.).

## aire-agent CLI — value-add only

```bash
export PATH="$AIRE/bin:$PATH"
aire-agent generate --gpu 1 --time 4h --framework pytorch
aire-agent validate my_job.sh
aire-agent search "GPU memory"
aire-agent log --name run1 --metrics '{"loss":0.3}' --params '{"lr":0.001}'
aire-agent doctor
```

## MCP server (Claude Code and compatible clients)

Register once:

```bash
claude mcp add aire "$AIRE/mcp/server.py"
```

**Registered MCP tools** (see `$AIRE/mcp/server.py`):

| Tool | Purpose |
|------|---------|
| `generate_script` | SBATCH with AIRE constraints |
| `validate_script` | Pre-submit checks |
| `search_docs` | Knowledge base search |
| `list_modules` | Module list |
| `system_info` | Hardware summary |
| `log_experiment` | JSONL experiment log |
| `query_experiments` | Query past runs |
| `sync_docs` | Refresh upstream docs |

Job queue/submit tools are **intentionally not** in MCP — use Slurm directly.

## Standard workflow

1. **Environment** — skill `aire-conda-environments`; optional `aire-github-installs`.
2. **Generate** — `aire-agent generate` or MCP `generate_script`.
3. **Validate** — `aire-agent validate` or MCP `validate_script`.
4. **Submit** — `sbatch script.sh`.
5. **Monitor** — `squeue --me`; tail `logs/`.
6. **After completion** — `seff <job_id>`; skill `aire-ddp-debugging` if distributed.
7. **Log run** — `aire-agent log` or MCP `log_experiment`.

## Skill routing

| User need | Load skill |
|-----------|------------|
| Conda / env YAML | `aire-conda-environments` |
| GitHub pip / editable install | `aire-github-installs` |
| Multi-GPU training | `aire-l40s-distributed-training` |
| DDP hang / NCCL | `aire-ddp-debugging` |
| Repo layout / Hydra | `aire-research-software-engineering` |
| Medical CV science | `medical-cv-research-engineer` (domain, not AIRE ops) |

## References

- `$AIRE/CLAUDE.md` — Claude Code session behavior
- `$AIRE/AGENTS.md` — generic agent rules
- `$AIRE/README.md` — install and examples
