#!/usr/bin/env bash
# list-modules.sh — List available AIRE modules from knowledge/modules.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
MODULES_FILE="$REPO_DIR/knowledge/modules.md"

if [ ! -f "$MODULES_FILE" ]; then
    echo "Error: modules.md not found at $MODULES_FILE" >&2
    exit 1
fi

FILTER="${1:-}"

# Extract module entries from markdown tables (lines with |, filtering out headers and separators)
ENTRIES="$(grep '|' "$MODULES_FILE" | grep -v '^\s*|---' | grep -v '^\s*| Field' | grep -v '^\s*| Command' | grep -v '^\s*| Module' | grep -v '^\s*| Network' | grep -v '^\s*| Partition' | grep -v '^\s*|---|' || true)"

if [ -n "$FILTER" ]; then
    ENTRIES="$(echo "$ENTRIES" | grep -i "$FILTER" || true)"
fi

if [ -n "$ENTRIES" ]; then
    echo "$ENTRIES"
fi
