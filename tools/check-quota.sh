#!/usr/bin/env bash
# check-quota.sh — Check disk quota on AIRE (home and scratch)
set -euo pipefail

echo "=== Disk Quota Check ==="
echo ""

# Check if we are on AIRE
ON_AIRE=false
if hostname 2>/dev/null | grep -qi 'aire\|leeds' 2>/dev/null; then
    ON_AIRE=true
fi

if [ "$ON_AIRE" = true ]; then
    echo "--- Home Directory ---"
    quota -s 2>/dev/null || echo "  quota command not available"
    echo ""
    echo "Usage:"
    du -sh "$HOME" 2>/dev/null || echo "  Could not determine home usage"
    echo ""

    echo "--- Scratch (/nobackup) ---"
    if command -v lfs &>/dev/null; then
        lfs quota -u "$USER" /nobackup 2>/dev/null || echo "  lfs quota not available"
    else
        echo "  lfs command not available"
    fi
    echo ""
    SCRATCH_DIR="/nobackup/$USER"
    if [ -d "$SCRATCH_DIR" ]; then
        echo "Usage:"
        du -sh "$SCRATCH_DIR" 2>/dev/null || echo "  Could not determine scratch usage"
    else
        echo "  Scratch directory $SCRATCH_DIR does not exist"
    fi
else
    echo "Not running on AIRE."
    echo ""
    echo "To check quota, SSH into AIRE and run:"
    echo "  quota -s              # Home directory quota"
    echo "  lfs quota -u \$USER /nobackup  # Scratch quota"
    echo "  du -sh ~              # Home usage"
    echo "  du -sh /nobackup/\$USER  # Scratch usage"
fi
