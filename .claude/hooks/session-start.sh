#!/usr/bin/env bash
# session-start.sh — Check if knowledge base is stale and sync if needed.
# Registered as a UserPromptSubmit hook in .claude/settings.json.
# Silent when up to date; only prints if a sync is triggered.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SYNC_STAMP="$REPO_DIR/.last_sync"
SYNC_SCRIPT="$REPO_DIR/scripts/sync.sh"
STALE_SECONDS=86400  # 24 hours

# No timestamp file — knowledge base has never been synced
if [[ ! -f "$SYNC_STAMP" ]]; then
    echo "[aire-agent] Knowledge base not yet synced. Running initial sync..."
    if [[ -x "$SYNC_SCRIPT" ]]; then
        "$SYNC_SCRIPT" || echo "[aire-agent] Sync returned non-zero, continuing anyway."
    else
        echo "[aire-agent] To sync manually: bash scripts/sync.sh"
    fi
    exit 0
fi

last_sync=$(cat "$SYNC_STAMP" 2>/dev/null || echo "0")
now=$(date +%s)
age=$(( now - last_sync ))

if (( age > STALE_SECONDS )); then
    hours=$(( age / 3600 ))
    echo "[aire-agent] Knowledge base is ${hours}h old — syncing..."
    if [[ -x "$SYNC_SCRIPT" ]]; then
        "$SYNC_SCRIPT" || echo "[aire-agent] Sync returned non-zero, continuing anyway."
    else
        echo "[aire-agent] To sync manually: bash scripts/sync.sh"
    fi
fi

# Silent exit when up to date
exit 0
