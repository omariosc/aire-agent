---
name: aire-github-installs
description: >-
  Installs Python packages and research code from GitHub on AIRE HPC. Use for
  pip install git+https, editable installs (-e), git submodules, private
  repositories, CUDA/C++ extension builds, or import failures between login
  and compute nodes on AIRE.
---

# AIRE GitHub Installs

## Operating mode

Optimize for **correct node type**, **pinned commits**, and **CUDA build hygiene**.

Execution note: task type (`install`, `editable`, `submodule`, `private`, `cuda-build`, `debug`), public vs private repo, compile required?, code location (`$HOME` vs `$SCRATCH`).

Read: `$AIRE/knowledge/ml-on-aire.md`, `$AIRE/docs/software/compilers/cuda.md`, `$AIRE/knowledge/troubleshooting.md`, `$AIRE/AGENTS.md`.

## Core rules

1. **Compile GPU extensions on compute nodes** — `srun` with GPU if CUDA needed.
2. **Load cuda before nvcc builds** — `module load cuda/12.6.2`; set `CPATH=$CUDA_HOME/include`.
3. **Same conda env as SBATCH** — activate before `pip install`.
4. **Pin commits in `environment.yaml`** under `pip:` or `requirements-git.txt`.
5. **No personal SSH keys on AIRE** — use HTTPS+token, rsync from laptop, or CI artifacts.
6. **Batch jobs must re-load modules and activate env** — login installs are not enough alone.

## Clone

```bash
cd "${SCRATCH:-/mnt/scratch/$USER}/src"
git clone --recursive https://github.com/org/repo.git
cd repo && git submodule update --init --recursive
```

## Editable install (development)

```bash
srun --partition=gpu --gres=gpu:1 --cpus-per-task=8 --mem=32G --time=2:00:00 --pty bash
module load cuda/12.6.2
module load miniforge/24.7.1
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate <env>
export CPATH="${CUDA_HOME}/include${CPATH:+:${CPATH}}"
export MAX_JOBS="${SLURM_CPUS_PER_TASK:-4}"
pip install -e ".[dev]"
python -c "import mypackage; print(mypackage.__file__)"
```

## Pin in environment.yaml

```yaml
  - pip:
      - monai @ git+https://github.com/Project-MONAI/MONAI.git@v1.3.0
```

## Private repositories

| Approach | AIRE fit |
|----------|----------|
| HTTPS + `GITHUB_TOKEN` env (not in git) | Best on-cluster |
| Clone locally → `rsync` to `$SCRATCH` | No token on cluster |
| `git@github.com:...` with user SSH key | **Not supported** |

## SBATCH pattern

Install once during setup; in jobs only activate:

```bash
module load cuda/12.6.2
module load miniforge/24.7.1
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate <env>
python train.py
```

Do **not** `pip install` in every array task unless unavoidable.

## Common failures

| Symptom | Fix |
|---------|-----|
| `No module named X` in job | Add conda block; validate script |
| CUDA headers missing | `export CPATH=$CUDA_HOME/include` |
| `No kernel image available` | PyTorch ≥2.1, `pytorch-cuda=12.4`, sm_89 |
| Build OK on login, fail in job | Repeat module load + activate in SBATCH |
| Empty submodule dir | `git submodule update --init --recursive` |

## Anti-patterns

- `pip install git+...` on login for GPU extensions  
- Editable install from `$TMP_SHARED`  
- Tokens in YAML or SBATCH  
- Assuming `~/.bashrc` conda init suffices in batch  

## Integration

- Prerequisite: `aire-conda-environments`  
- Training: `aire-l40s-distributed-training`  
- Workflow: `aire-agent-workflow`
