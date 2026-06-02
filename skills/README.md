# AIRE Agent Skills

Portable workflow skills for **any** coding agent that supports the open [Agent Skills](https://agentskills.io) format (`SKILL.md` with YAML frontmatter).

Compatible harnesses include **Claude Code**, **OpenAI Codex CLI**, **Gemini CLI**, **Cursor**, **OpenCode**, and others that load skills from standard directories.

## Skills in this directory

| Skill | Use when |
|-------|----------|
| `aire-agent-workflow` | Starting on AIRE; generate → validate → submit jobs; MCP vs Slurm |
| `aire-conda-environments` | Creating/updating conda envs, SBATCH activation, HOME quota |
| `aire-github-installs` | `pip install -e`, git+https, CUDA extensions, private repos |
| `aire-l40s-distributed-training` | Multi-GPU PyTorch DDP/FSDP on L40S, torchrun, I/O |
| `aire-ddp-debugging` | NCCL hangs, torchrun/Slurm mismatches, `seff` tuning |
| `aire-research-software-engineering` | Modular ML repo layout, Hydra configs, experiment logging |

Pair with domain skills (e.g. `medical-cv-research-engineer`) and the `.aire-agent` knowledge base (`knowledge/`, `CLAUDE.md`, `AGENTS.md`).

## Install (all agents)

From the aire-agent repo:

```bash
bash ~/.aire-agent/skills/install-skills.sh
```

This symlinks each skill into common harness paths:

| Harness | User skills directory |
|---------|------------------------|
| Cross-platform | `~/.agents/skills/` |
| Codex CLI | `~/.codex/skills/` |
| Claude Code | `~/.claude/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| Cursor | `~/.cursor/skills/` |

Re-run after `git pull` to refresh symlinks.

### Project-local install

Symlink or copy into your research repo:

```bash
mkdir -p .agents/skills
for s in ~/.aire-agent/skills/aire-*/; do
  ln -sfn "$s" ".agents/skills/$(basename "$s")"
done
```

Many agents also discover `.agents/skills/` at the project root.

### Manual / explicit invocation

- **Codex CLI:** `$skill-name` or `/skills`
- **Claude Code:** mention the skill or use skill discovery
- **Gemini CLI:** skills under `~/.gemini/skills/`
- **Cursor:** skills under `~/.cursor/skills/` (same `SKILL.md` format)

## Environment variable

Set once in `~/.bashrc` (optional):

```bash
export AIRE_AGENT="${AIRE_AGENT:-$HOME/.aire-agent}"
```

Skills reference `$AIRE_AGENT` for knowledge paths and tools.

## Authoring

Each skill is a directory with `SKILL.md`:

```yaml
---
name: skill-name
description: Third-person summary and trigger phrases for discovery.
---
```

Keep the main file under ~200 lines; put long tables in `references/` if needed.
