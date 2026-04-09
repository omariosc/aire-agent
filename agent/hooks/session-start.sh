#!/usr/bin/env bash
# session-start.sh — Check if knowledge base is stale and prompt sync.
# Called at the start of each agent session. Graceful: never errors out.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SYNC_STAMP="$REPO_DIR/.last_sync"
SYNC_SCRIPT="$REPO_DIR/scripts/sync.sh"
STALE_SECONDS=86400  # 24 hours

# If no timestamp file exists, warn but don't block
if [[ ! -f "$SYNC_STAMP" ]]; then
    echo "[session-start] No .last_sync file found. Knowledge base may be out of date."
    if [[ -x "$SYNC_SCRIPT" ]]; then
        echo "[session-start] Running sync..."
        "$SYNC_SCRIPT" || echo "[session-start] Sync script returned non-zero, continuing anyway."
    else
        echo "[session-start] To sync manually, run: bash scripts/sync.sh"
    fi
    exit 0
fi

# Read last sync timestamp
last_sync=$(cat "$SYNC_STAMP" 2>/dev/null || echo "0")
now=$(date +%s)

# Calculate age
age=$(( now - last_sync ))

if (( age > STALE_SECONDS )); then
    hours=$(( age / 3600 ))
    echo "[session-start] Knowledge base is ${hours}h old (last synced: $(date -r "$last_sync" '+%Y-%m-%d %H:%M' 2>/dev/null || echo 'unknown'))."
    if [[ -x "$SYNC_SCRIPT" ]]; then
        echo "[session-start] Running sync..."
        "$SYNC_SCRIPT" || echo "[session-start] Sync script returned non-zero, continuing anyway."
    else
        echo "[session-start] Sync script not found. To sync manually, run: bash scripts/sync.sh"
    fi
else
    echo "[session-start] Knowledge base is up to date (${age}s old)."
fi

exit 0
