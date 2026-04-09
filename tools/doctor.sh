#!/usr/bin/env bash
# doctor.sh — Health check for the AIRE HPC toolkit
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0
WARN=0
FAIL=0

check_pass() {
    echo "[PASS] $1"
    PASS=$((PASS + 1))
}

check_warn() {
    echo "[WARN] $1"
    WARN=$((WARN + 1))
}

check_fail() {
    echo "[FAIL] $1"
    FAIL=$((FAIL + 1))
}

echo "=== AIRE Toolkit Doctor ==="
echo ""

# Check knowledge/ exists
if [ -d "$REPO_DIR/knowledge" ]; then
    check_pass "knowledge/ directory exists"
else
    check_fail "knowledge/ directory missing"
fi

# Check docs/ exists
if [ -d "$REPO_DIR/docs" ]; then
    check_pass "docs/ directory exists"
else
    check_fail "docs/ directory missing"
fi

# Check tools/ exists
if [ -d "$REPO_DIR/tools" ]; then
    check_pass "tools/ directory exists"
else
    check_fail "tools/ directory missing"
fi

# Check templates/ exists
if [ -d "$REPO_DIR/templates" ]; then
    check_pass "templates/ directory exists"
else
    check_fail "templates/ directory missing"
fi

# Check .last_sync freshness (if it exists)
LAST_SYNC="$REPO_DIR/.last_sync"
if [ -f "$LAST_SYNC" ]; then
    SYNC_TIME="$(cat "$LAST_SYNC")"
    NOW="$(date +%s)"
    # Try to parse the sync time
    if [ -n "$SYNC_TIME" ] && [ "$SYNC_TIME" -eq "$SYNC_TIME" ] 2>/dev/null; then
        AGE=$(( NOW - SYNC_TIME ))
        if [ "$AGE" -gt 604800 ]; then
            check_warn ".last_sync is older than 7 days ($(( AGE / 86400 )) days old)"
        else
            check_pass ".last_sync is recent ($(( AGE / 86400 )) days old)"
        fi
    else
        check_warn ".last_sync exists but has unexpected format"
    fi
else
    check_warn ".last_sync file not found (sync may not have been run)"
fi

# Check Slurm availability
if command -v sinfo &>/dev/null; then
    check_pass "Slurm (sinfo) is available"
else
    check_warn "Slurm (sinfo) not available (not on AIRE)"
fi

# Check nvidia-smi availability
if command -v nvidia-smi &>/dev/null; then
    check_pass "nvidia-smi is available"
else
    check_warn "nvidia-smi not available (no GPU or not on AIRE)"
fi

# Check SSH config for AIRE
SSH_CONFIG="$HOME/.ssh/config"
if [ -f "$SSH_CONFIG" ] && grep -qi 'aire' "$SSH_CONFIG" 2>/dev/null; then
    check_pass "SSH config contains AIRE entry"
else
    check_warn "No AIRE entry in SSH config ($SSH_CONFIG)"
fi

echo ""
echo "--- Summary ---"
echo "Pass: $PASS  Warn: $WARN  Fail: $FAIL"

if [ "$FAIL" -gt 0 ]; then
    exit 1
else
    exit 0
fi
