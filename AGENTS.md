# AIRE HPC Agent — Generic Agent Instructions

Instructions for AI coding agents (Codex, Gemini CLI, etc.) working with the AIRE HPC cluster at University of Leeds.

## Core Rules (NEVER violate)

1. **Max 3 GPUs per node.** GPU nodes have 3x NVIDIA L40S. Never request more than 3 in `--gres=gpu:N`.
2. **`--partition=gpu` and `--gres=gpu:N` must be used together.** Always pair them.
3. **`--time` is REQUIRED on all jobs.** Slurm rejects jobs without a wall-time limit.
4. **Default allocation is 1 CPU, 1 GB.** Always request more explicitly.
5. **Password-only SSH.** No SSH keys. Two-hop via `rash.leeds.ac.uk`.
6. **No jobs on login nodes.** Login nodes are for file management and job submission only.
7. **`$TMP_SHARED` is deleted when jobs end.** Copy results to `$SCRATCH` or `$HOME` before completion.

## Available Tools

The MCP server (`mcp/server.py`) exposes these tools via JSON-RPC over stdio:

| Tool                | Purpose                                        |
|---------------------|------------------------------------------------|
| `system_info`       | AIRE system specs                              |
| `search_docs`       | Search knowledge base                          |
| `list_modules`      | List software modules                          |
| `generate_script`   | Generate SBATCH job scripts                    |
| `validate_script`   | Validate job scripts for errors                |
| `submit_job`        | Submit a job to Slurm                          |
| `check_queue`       | View pending/running jobs                      |
| `job_efficiency`    | Efficiency report for completed jobs           |
| `log_experiment`    | Log experiment to local tracker                |
| `check_quota`       | Disk quota usage                               |
| `node_availability` | Current node/partition status                  |

**Always validate scripts before submitting. Always check efficiency after completion.**

## Key Facts

| Resource       | Value                                                      |
|----------------|------------------------------------------------------------|
| CPU nodes      | 52 nodes, 168 cores, 768 GB RAM each                      |
| GPU nodes      | 28 nodes, 3x L40S (48 GB), 24 cores, 256 GB RAM each     |
| High-memory    | 2 nodes, 168 cores, 2.3 TB RAM each                       |
| Total GPUs     | 84 NVIDIA L40S (Ada Lovelace, CC 8.9, PCIe)               |
| Partitions     | `default`, `gpu`, `himem`                                  |
| `$HOME`        | 65 GB, backed up                                           |
| `$SCRATCH`     | 1 TB, not backed up                                        |
| `$TMP_SHARED`  | 1 TB/job, NVMe flash, auto-deleted                         |
| Network        | OmniPath 100 Gb/s compute, 25 GbE management              |
| Retirement     | 2029-07-31                                                 |

## Key Modules

```
cuda/12.6.2    miniforge/24.7.1    openmpi    openmpi-cuda    pytorch/2.5.1
```

## Knowledge Base

Detailed documentation is in the `knowledge/` directory:

- `knowledge/aire-system.md` — Full hardware specs and access details
- `knowledge/storage.md` — Storage areas, quotas, data transfer
- `knowledge/slurm-guide.md` — Slurm commands, partitions, job arrays
- `knowledge/modules.md` — Complete module listing
- `knowledge/ml-on-aire.md` — ML/DL setup, DDP, mixed precision
- `knowledge/experiment-tracking.md` — Experiment logging
- `knowledge/troubleshooting.md` — Common errors and fixes

Read these files for detailed information before answering complex questions.
