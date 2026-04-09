# AIRE HPC System Reference

## Overview

| Field | Value |
|---|---|
| Cluster | AIRE (Advanced Infrastructure for Research and Enterprise) |
| Location | University of Leeds |
| Replaces | ARC3, ARC4 (decommissioned late 2024) |
| Managed by | Research Computing Team |
| Retirement date | 31/07/2029 |

## Node Types

### Standard Compute Nodes

| Field | Value |
|---|---|
| Count | 52 |
| Chassis | Dell R6625 |
| CPU | 2x AMD EPYC 9634 Genoa-X, 84 cores each, 2.2 GHz |
| Cores per node | 168 |
| Total CPU cores | 9,072 |
| Memory | 768 GB DDR5-4800 (~4.6 GB/core) |
| Partition | `default` |

### GPU Nodes

| Field | Value |
|---|---|
| Count | 28 |
| Chassis | Dell R7615 |
| GPU | 3x NVIDIA L40S, 48 GB GDDR6 each, PCIe |
| **CRITICAL** | **Maximum 3 GPUs per node. No NVLink.** |
| CPU | 1x AMD EPYC 9254 Genoa-X, 24 cores, 2.9 GHz |
| Memory | 256 GB DDR5-4800 |
| Partition | `gpu` |

### High-Memory Nodes

| Field | Value |
|---|---|
| Count | 2 |
| Chassis | Dell R6625 |
| CPU | 2x AMD EPYC 9634 Genoa-X, 84 cores each, 2.2 GHz |
| Cores per node | 168 |
| Memory | 2.3 TB DDR5-4800 (~13.8 GB/core) |
| Partition | `himem` |

### Login Nodes

| Field | Value |
|---|---|
| Count | 4 |
| GPU | Entry-level NVIDIA A2 (for configuration/testing only) |
| **IMPORTANT** | **NO jobs on login nodes. Login nodes are for file management, compilation, and job submission only.** |

## GPU Details (NVIDIA L40S)

| Field | Value |
|---|---|
| Architecture | Ada Lovelace |
| VRAM | 48 GB GDDR6 |
| Compute Capability | 8.9 |
| Interface | PCIe (NOT NVLink) |
| GPUs per node | 3 (max) |
| Total GPUs in cluster | 84 |

## Network

| Network | Speed | Purpose |
|---|---|---|
| OmniPath | 100 Gb/s | Compute fabric (MPI, inter-node) |
| Ethernet | 25 GbE | Management, storage |

## Partitions

| Partition | Node type | Nodes | Cores/node | Memory/node | GPUs/node |
|---|---|---|---|---|---|
| `default` | Standard compute | 52 | 168 | 768 GB | 0 |
| `gpu` | GPU | 28 | 24 | 256 GB | 3x L40S |
| `himem` | High-memory | 2 | 168 | 2.3 TB | 0 |

## Access

### SSH Connection

```bash
# Two-hop SSH via jump host (password authentication only, no keys)
ssh USERNAME@login1.aire.leeds.ac.uk -J USERNAME@rash.leeds.ac.uk
```

**IMPORTANT:** Password-only authentication. SSH keys are not supported.

### Login nodes

- `login1.aire.leeds.ac.uk`
- `login2.aire.leeds.ac.uk`
- `login3.aire.leeds.ac.uk`
- `login4.aire.leeds.ac.uk`

### Jump host

- `rash.leeds.ac.uk`

## Purchasing Nodes

Departments/groups can purchase priority (not exclusive) access to nodes.

| Node Type | Cost (ex. VAT) |
|---|---|
| Standard Compute (CPU) | ~£12,315 |
| High-Memory | ~£19,580 |
| GPU | ~£14,600 |

**Note:** Purchase grants priority scheduling, not exclusive access. Other users can still use idle purchased nodes.

## Support

| Channel | Contact |
|---|---|
| IT Service Desk | itservicedesk@leeds.ac.uk |
| Research Computing Team | rcteam@leeds.ac.uk |
| Documentation | https://arc.leeds.ac.uk |
