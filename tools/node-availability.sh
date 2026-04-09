#!/usr/bin/env bash
# node-availability.sh — Show AIRE node availability via sinfo/squeue
set -euo pipefail

echo "=== Node Availability ==="
echo ""

if ! command -v sinfo &>/dev/null; then
    echo "Not running on AIRE (sinfo not available)."
    echo ""
    echo "To check node availability, SSH into AIRE and run:"
    echo "  sinfo -N -l           # Detailed node list"
    echo "  sinfo -s              # Partition summary"
    echo "  squeue -p gpu         # GPU partition queue"
    exit 0
fi

echo "--- Partition Summary ---"
sinfo -s 2>/dev/null || echo "  Could not query sinfo"
echo ""

echo "--- Node List ---"
sinfo -N -l 2>/dev/null || echo "  Could not query node list"
echo ""

echo "--- GPU Queue ---"
squeue -p gpu 2>/dev/null || echo "  Could not query GPU queue"
