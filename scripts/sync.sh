#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_DIR="$REPO_DIR/docs"
SYNC_FILE="$REPO_DIR/.last_sync"
UPSTREAM_REPO="https://github.com/arcdocs/aire.git"
SYNC_INTERVAL=86400  # 24 hours in seconds

# --- Usage ---------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Sync upstream ARC documentation into this repository.

Options:
    --force    Force sync even if recently synced
    --help     Show this help message

Without --force, skips sync if last sync was less than 24 hours ago.
EOF
}

# --- Parse arguments -----------------------------------------------------
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --help)  usage; exit 0 ;;
        *)       echo "Unknown option: $arg"; usage; exit 1 ;;
    esac
done

# --- Check if recently synced --------------------------------------------
if [ "$FORCE" = false ] && [ -f "$SYNC_FILE" ]; then
    last_sync=$(cat "$SYNC_FILE")
    now=$(date +%s)
    elapsed=$(( now - last_sync ))
    if [ "$elapsed" -lt "$SYNC_INTERVAL" ]; then
        hours=$(( elapsed / 3600 ))
        echo "Docs synced ${hours}h ago. Use --force to sync anyway."
        exit 0
    fi
fi

# --- Sync upstream docs --------------------------------------------------
TMPDIR_SYNC=$(mktemp -d)
trap 'rm -rf "$TMPDIR_SYNC"' EXIT

echo "Cloning upstream docs from $UPSTREAM_REPO ..."
git clone --depth 1 "$UPSTREAM_REPO" "$TMPDIR_SYNC/aire"

# Ensure docs directory exists
mkdir -p "$DOCS_DIR"

# Remove old arcdocs content but preserve superpowers/ and hidden files
find "$DOCS_DIR" -mindepth 1 \
    -not -name 'superpowers' \
    -not -path '*/superpowers/*' \
    -not -name '.*' \
    -exec rm -rf {} + 2>/dev/null || true

# Copy book/* into docs/
if [ -d "$TMPDIR_SYNC/aire/book" ]; then
    cp -R "$TMPDIR_SYNC/aire/book/"* "$DOCS_DIR/"
    echo "Copied book/ contents to docs/"
fi

# Copy modules.txt if it exists
if [ -f "$TMPDIR_SYNC/aire/modules.txt" ]; then
    cp "$TMPDIR_SYNC/aire/modules.txt" "$DOCS_DIR/modules.txt"
    echo "Copied modules.txt to docs/"
fi

# Update last sync timestamp
date +%s > "$SYNC_FILE"
echo "Sync complete."
