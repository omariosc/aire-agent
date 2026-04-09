#!/usr/bin/env bash
# system-info.sh — Display AIRE HPC system specifications (hardcoded)
set -euo pipefail

JSON_MODE=false
for arg in "$@"; do
    if [ "$arg" = "--json" ]; then
        JSON_MODE=true
    fi
done

if [ "$JSON_MODE" = true ]; then
    cat <<'ENDJSON'
{
  "system": "AIRE (Advanced Infrastructure for Research and Enterprise)",
  "location": "University of Leeds",
  "retirement_date": "2029-07-31",
  "nodes": {
    "standard_compute": {
      "count": 52,
      "cpu": "2x AMD EPYC 9634 Genoa-X (84 cores each)",
      "cores_per_node": 168,
      "total_cores": 9072,
      "memory": "768 GB DDR5-4800",
      "partition": "default"
    },
    "gpu": {
      "count": 28,
      "cpu": "1x AMD EPYC 9254 Genoa-X (24 cores)",
      "cores_per_node": 24,
      "gpu_model": "NVIDIA L40S",
      "gpus_per_node": 3,
      "gpu_vram": "48 GB GDDR6",
      "total_gpus": 84,
      "memory": "256 GB DDR5-4800",
      "partition": "gpu"
    },
    "himem": {
      "count": 2,
      "cpu": "2x AMD EPYC 9634 Genoa-X (84 cores each)",
      "cores_per_node": 168,
      "memory": "2.3 TB DDR5-4800",
      "partition": "himem"
    }
  },
  "network": {
    "compute_fabric": "OmniPath 100 Gb/s",
    "management": "Ethernet 25 GbE"
  },
  "storage": {
    "home": "10 GB quota",
    "scratch": "/nobackup — large, no backup, purged periodically"
  }
}
ENDJSON
else
    cat <<'EOF'
=== AIRE HPC System ===

Cluster:  AIRE (Advanced Infrastructure for Research and Enterprise)
Location: University of Leeds
Retires:  31/07/2029

--- Standard Compute Nodes ---
  Count:      52
  CPU:        2x AMD EPYC 9634 Genoa-X (84 cores each, 2.2 GHz)
  Cores/node: 168 (total: 9,072)
  Memory:     768 GB DDR5-4800
  Partition:  default

--- GPU Nodes ---
  Count:      28
  CPU:        1x AMD EPYC 9254 Genoa-X (24 cores, 2.9 GHz)
  GPU:        3x NVIDIA L40S (48 GB GDDR6 each, PCIe)
  Total GPUs: 84
  Memory:     256 GB DDR5-4800
  Partition:  gpu
  NOTE:       Max 3 GPUs per node. No NVLink.

--- High-Memory Nodes ---
  Count:      2
  CPU:        2x AMD EPYC 9634 Genoa-X (84 cores each, 2.2 GHz)
  Cores/node: 168
  Memory:     2.3 TB DDR5-4800
  Partition:  himem

--- Network ---
  Compute:    OmniPath 100 Gb/s
  Management: Ethernet 25 GbE

--- Storage ---
  Home:    10 GB quota
  Scratch: /nobackup (large, no backup, purged periodically)
EOF
fi
