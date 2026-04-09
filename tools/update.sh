#!/usr/bin/env bash
# update.sh — Update the AIRE HPC toolkit from git
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cd "$REPO_DIR"

if [ ! -d ".git" ]; then
    echo "Error: Not a git repository ($REPO_DIR)" >&2
    exit 1
fi

echo "=== Updating AIRE Toolkit ==="
echo ""

# Fetch latest changes
echo "Fetching from origin..."
git fetch origin 2>&1

# Get current commit before pulling
BEFORE="$(git rev-parse HEAD)"

# Pull latest
echo "Pulling origin main..."
git pull origin main 2>&1 || {
    echo ""
    echo "Pull failed. You may have local changes. Try:"
    echo "  git stash && git pull origin main && git stash pop"
    exit 1
}

AFTER="$(git rev-parse HEAD)"

echo ""
if [ "$BEFORE" = "$AFTER" ]; then
    echo "Already up to date."
else
    echo "Updated! Changes:"
    git log --oneline "$BEFORE..$AFTER"
fi
