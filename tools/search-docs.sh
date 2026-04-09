#!/usr/bin/env bash
# search-docs.sh — Search knowledge/ and docs/ for a query string
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

if [ $# -lt 1 ] || [ -z "$1" ]; then
    echo "Usage: search-docs.sh <query> [--json]"
    exit 1
fi

QUERY="$1"
JSON_MODE=false

for arg in "$@"; do
    if [ "$arg" = "--json" ]; then
        JSON_MODE=true
    fi
done

# Collect search results from knowledge/ and docs/
# Exclude plans/, tests/, and binary files
RESULTS=""
for dir in "$REPO_DIR/knowledge" "$REPO_DIR/docs"; do
    if [ -d "$dir" ]; then
        RESULTS+="$(grep -rni --exclude-dir=plans --exclude-dir=tests --include='*.md' --include='*.txt' --include='*.yml' --include='*.yaml' "$QUERY" "$dir" 2>/dev/null || true)"
        RESULTS+=$'\n'
    fi
done

# Remove empty lines
RESULTS="$(echo "$RESULTS" | sed '/^$/d')"

if [ -z "$RESULTS" ]; then
    exit 0
fi

if [ "$JSON_MODE" = true ]; then
    echo "["
    FIRST=true
    echo "$RESULTS" | head -50 | while IFS= read -r line; do
        FILE="$(echo "$line" | cut -d: -f1)"
        LINE_NUM="$(echo "$line" | cut -d: -f2)"
        CONTENT="$(echo "$line" | cut -d: -f3-)"
        # Strip REPO_DIR prefix
        FILE="${FILE#$REPO_DIR/}"
        # Escape quotes in content for JSON
        CONTENT="$(echo "$CONTENT" | sed 's/\\/\\\\/g; s/"/\\"/g')"
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo ","
        fi
        printf '  {"file": "%s", "line": %s, "content": "%s"}' "$FILE" "$LINE_NUM" "$CONTENT"
    done
    echo ""
    echo "]"
else
    # Strip REPO_DIR prefix from paths and limit to 50 lines
    echo "$RESULTS" | sed "s|$REPO_DIR/||g" | head -50
fi
