---
name: aire-research-software-engineering
description: >-
  Scaffolds and maintains modular, reproducible ML research repositories for
  the AIRE HPC cluster. Use for project layout (src/, configs/, scripts/,
  tests/), Hydra or YAML configuration, git hygiene, SCRATCH-aware paths,
  and integrating runs with aire-agent log_experiment. Complements domain
  skills such as medical-cv-research-engineer.
---

# AIRE Research Software Engineering

## Operating mode

Optimize for **small modules**, **config-driven runs**, and **storage-aware paths**.

Execution note: `scaffold`, `refactor`, `migrate`, `audit`, `integrate-logging`; config system (Hydra / YAML / none).

Domain evaluation (splits, clinical metrics): use **`medical-cv-research-engineer`**, not this skill.

## Storage contract

| Purpose | Location |
|---------|----------|
| Source, configs, env YAML | `$HOME/.../project` (git) |
| Datasets, checkpoints, runs | `$SCRATCH/projects/<name>/` |
| Fast epoch I/O | `$TMP_SHARED` (copy out before job end) |
| Experiment index | `~/.aire-agent/experiments/` via `aire-agent log` |

## Standard layout

```
my-project/
├── README.md
├── pyproject.toml
├── environment.yaml
├── .gitignore
├── configs/
│   ├── config.yaml
│   └── paths/aire.yaml
├── src/my_project/
│   ├── data/
│   ├── models/
│   ├── training/
│   └── eval/
├── scripts/slurm/
│   └── train.sh
├── tests/
└── experiments/          # frozen configs for paper runs

$SCRATCH/projects/my-project/
├── data/
├── checkpoints/
└── runs/
```

## Example paths config (Hydra)

```yaml
# configs/paths/aire.yaml
scratch: ${oc.env:SCRATCH}/projects/my-project
data_root: ${paths.scratch}/data
checkpoint_dir: ${paths.scratch}/checkpoints
run_dir: ${paths.scratch}/runs/${now:%Y-%m-%d_%H%M%S}_job${oc.env:SLURM_JOB_ID,local}
```

## Scaffold checklist

1. `mkdir -p $SCRATCH/projects/<name>/{data,checkpoints,runs,cache}`
2. Init git; `.gitignore` checkpoints, `wandb/`, `runs/`, `*.pt`
3. Add `pyproject.toml`, `environment.yaml`, `configs/paths/aire.yaml`
4. SLURM wrapper from `$AIRE/templates/jobs/gpu-single.sh`
5. Epilog: `rsync` artifacts from `$TMP_SHARED` → `$SCRATCH`
6. `aire-agent validate` then `sbatch`

## Experiment logging

```bash
aire-agent log \
  --name "${RUN_NAME}" \
  --metrics '{"val_loss": 0.24}' \
  --params "$(cat run_dir/resolved_config.json)" \
  --status completed
```

Captures Slurm job ID, node, GPU count, git commit when available.

## Git / quality

- Track code + configs; never large checkpoints
- Pre-commit: ruff, mypy (optional), trailing whitespace
- `pip install -e .` from repo root — avoid `sys.path` hacks

## Anti-patterns

| Pattern | Fix |
|---------|-----|
| Monolithic 500+ line `train.py` | Split `data/`, `models/`, `training/` |
| Hardcoded `/users/...` | `configs/paths/aire.yaml` |
| Checkpoints in `$HOME` | `$SCRATCH` |
| Results only on `$TMP_SHARED` | Epilog copy to `$SCRATCH` |
| Config constants in Python | YAML + CLI overrides |

## Skill routing

| Need | Skill |
|------|-------|
| Slurm / submit | `aire-agent-workflow` |
| Conda env | `aire-conda-environments` |
| Multi-GPU | `aire-l40s-distributed-training` |
| Clinical metrics / leakage | `medical-cv-research-engineer` |
