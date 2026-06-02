---
name: aire-conda-environments
description: >-
  Manages Miniforge/conda environments on the University of Leeds AIRE HPC
  cluster. Use when creating, updating, exporting, or debugging Python/R conda
  envs on AIRE; wiring activation into SBATCH or srun; fixing HOME quota;
  or choosing Miniforge, conda-pack, Apptainer, or Pixi for ML stacks.
---

# AIRE Conda Environments

## Operating mode

Optimize for **AIRE policy**, **reproducibility**, and **HOME quota safety**.

Execution note: task type (`create`, `update`, `export`, `sbatch-wire`, `quota`), framework, GPU need, target (login / `srun` / batch).

Read when needed: `$AIRE/knowledge/ml-on-aire.md`, `$AIRE/docs/usage/dependency_management.md`, `$AIRE/knowledge/storage.md`, `$AIRE/templates/environments/*.yml`.

## Core rules

1. **Miniforge only** — `module load miniforge/24.7.1`; channel **conda-forge**.
2. **Envs in `$HOME`** — never relocate `envs/` or `.conda` to `$SCRATCH` as a quota workaround.
3. **Data and outputs on `$SCRATCH`** — datasets, checkpoints, `env-record.yaml` snapshots at scale.
4. **YAML-first** — edit `environment.yaml`, then `conda env update -f environment.yaml --prune`.
5. **Re-load modules + activate in every job** — login setup does not propagate to compute nodes.
6. **Heavy solves on compute** — use `srun` (GPU node for CUDA stacks), not login nodes.

## Create or update

```bash
srun --partition=gpu --gres=gpu:1 --cpus-per-task=8 --mem=32G --time=2:00:00 --pty bash
module load cuda/12.6.2
module load miniforge/24.7.1
conda env create -f environment.yaml   # or: conda env update -f environment.yaml --prune
conda activate <name>
python -c "import torch; print(torch.cuda.is_available())"
```

Templates: `$AIRE/templates/environments/pytorch.yml`, `tensorflow.yml`, `medical-imaging.yml`.

CUDA alignment: `cuda/12.6.2` module + `pytorch-cuda=12.4` in YAML (see `ml-on-aire.md`).

## SBATCH activation block

```bash
module load cuda/12.6.2          # if GPU
module load miniforge/24.7.1
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate <env_name>
```

If `conda activate` fails in batch: `source activate <env_name>` (`$AIRE/knowledge/troubleshooting.md`).

Prefer `$AIRE/tools/generate-script.sh` → validate → `sbatch`.

## Reproducibility exports

| Artifact | Command | Use |
|----------|---------|-----|
| Recipe | `environment.yaml` in git | Rebuild |
| Snapshot | `conda env export > $SCRATCH/.../env-record-${SLURM_JOB_ID}.yaml` | Tie to results |
| History | `conda env export --from-history` | Recover drifted envs |

## HOME quota triage

1. `conda env update -f environment.yaml --prune` on active envs  
2. `conda clean --all`  
3. `conda remove -n <unused> --all`  
4. `$AIRE/tools/check-quota.sh` or `aire-agent` quota helpers  
5. Request increase only after cleanup  

## Alternatives

| Tool | When |
|------|------|
| conda-pack | Ship env to another machine |
| Apptainer | Frozen portable stack (`module load apptainer/1.3.6`) |
| Pixi | Non-conda workflow (`module load pixi/0.41.4`) |
| `pytorch/2.5.1` module | Quick baseline without custom pip |

## Anti-patterns

- Ad-hoc `conda install` without YAML updates  
- GPU env builds on login nodes  
- Full `conda env export` as the only rebuild file  
- Omitting `source .../conda.sh` in SBATCH  

## Integration

- Next: `aire-github-installs` for pip/git deps inside the env  
- Jobs: `aire-agent-workflow`, `aire-l40s-distributed-training`
