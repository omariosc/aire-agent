#!/usr/bin/env bash
set -euo pipefail

# ── Colour definitions ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

# ── Helper functions ────────────────────────────────────────────────
info()  { printf "${BLUE}[info]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[ ok ]${NC}  %s\n" "$*"; }
warn()  { printf "${YELLOW}[warn]${NC}  %s\n" "$*"; }
err()   { printf "${RED}[err ]${NC}  %s\n" "$*" >&2; }

# ── Configuration ───────────────────────────────────────────────────
REPO_URL="https://github.com/omariosc/aire-agent.git"
INSTALL_DIR="$HOME/.aire-agent"

# ── Banner ──────────────────────────────────────────────────────────
printf "${BLUE}"
cat << 'BANNER'

   ___  ______  ____       ___   ____  ____  _  __ ______
  / _ |/  _/ _ \/ __/ ___  / _ | / ___// __/ / |/ //_  __/
 / __ |_/ // , _/ _/  /___// __ |/ (_ // _/  /    /  / /
/_/ |_/___/_/|_/___/      /_/ |_|\___//___/ /_/|_/  /_/

          aire-agent installer

BANNER
printf "${NC}"

# ── Check Python 3.8+ ──────────────────────────────────────────────
info "Checking for Python 3.8+ ..."
if ! command -v python3 &>/dev/null; then
    err "python3 not found. Please install Python 3.8 or later."
    exit 1
fi

PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)

if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 8 ]; }; then
    err "Python $PY_VERSION found, but 3.8+ is required."
    exit 1
fi
ok "Python $PY_VERSION detected."

# ── Check git ───────────────────────────────────────────────────────
info "Checking for git ..."
if ! command -v git &>/dev/null; then
    err "git not found. Please install git first."
    exit 1
fi
ok "git $(git --version | awk '{print $3}') detected."

# ── Clone or update repo ───────────────────────────────────────────
if [ -d "$INSTALL_DIR" ]; then
    info "Existing installation found at $INSTALL_DIR — updating ..."
    cd "$INSTALL_DIR"
    git pull --ff-only || { warn "git pull failed; continuing with current version."; }
    ok "Updated to latest version."
else
    info "Cloning aire-agent to $INSTALL_DIR ..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    ok "Cloned successfully."
    cd "$INSTALL_DIR"
fi

# ── Install Python dependencies ─────────────────────────────────────
info "Installing Python dependencies ..."
python3 -m pip install --quiet --user rich
ok "Python dependencies installed."

# ── Set executable permissions ──────────────────────────────────────
info "Setting executable permissions ..."

chmod +x bin/aire-agent   2>/dev/null || true
chmod +x bin/aire-setup   2>/dev/null || true

for f in tools/*.sh; do
    [ -f "$f" ] && chmod +x "$f"
done

for f in scripts/*.sh; do
    [ -f "$f" ] && chmod +x "$f"
done

for f in agent/hooks/*.sh; do
    [ -f "$f" ] && chmod +x "$f"
done

chmod +x mcp/server.py    2>/dev/null || true

ok "Permissions set."

# ── Done ────────────────────────────────────────────────────────────
printf "\n"
ok "aire-agent installed successfully at ${INSTALL_DIR}"
info "Run 'aire-agent' or add ${INSTALL_DIR}/bin to your PATH."
printf "\n"

# ── Launch setup TUI ────────────────────────────────────────────────
info "Launching setup wizard ..."
python3 bin/aire-setup
