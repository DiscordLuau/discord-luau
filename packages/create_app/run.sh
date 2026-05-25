#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# discord-luau create_app bootstrap
# Usage: bash run.sh [options] [output-dir]
#   e.g. bash run.sh --ide=vscode ~/Projects/MyBot
# If no output directory is given, ~/Documents is used.
# ---------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { printf "${GREEN}[discord-luau]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[discord-luau]${NC} %s\n" "$*"; }
error() { printf "${RED}[discord-luau] error:${NC} %s\n" "$*" >&2; }

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------

missing=()

if ! command -v git &>/dev/null; then
    missing+=("git   - https://git-scm.com/downloads")
fi

if ! command -v zune &>/dev/null; then
    missing+=("zune  - https://zune.sh/")
fi

if ! command -v pesde &>/dev/null; then
    missing+=("pesde - https://pesde.dev")
fi

if [ ${#missing[@]} -gt 0 ]; then
    error "The following required tools were not found in PATH:"
    for tool in "${missing[@]}"; do
        printf "  • %s\n" "$tool" >&2
    done
    exit 1
fi

info "Found zune $(zune --version 2>/dev/null || echo '(version unknown)')"
info "Found pesde $(pesde --version 2>/dev/null || echo '(version unknown)')"

# ---------------------------------------------------------------------------
# Resolve the temp directory for cloning
# ---------------------------------------------------------------------------

TMP_BASE="${TMPDIR:-${TEMP:-/tmp}}"
CLONE_DIR="${TMP_BASE}/discord-luau"

if [ -d "$CLONE_DIR" ]; then
    warn "Removing existing clone at $CLONE_DIR"
    rm -rf "$CLONE_DIR"
fi

# ---------------------------------------------------------------------------
# Clone repository
# ---------------------------------------------------------------------------

info "Cloning discord-luau into $CLONE_DIR ..."
git clone --depth=1 https://github.com/DiscordLuau/discord-luau.git "$CLONE_DIR"

# ---------------------------------------------------------------------------
# Install dependencies
# ---------------------------------------------------------------------------

info "Installing dependencies ..."
(cd "$CLONE_DIR" && pesde install)

# ---------------------------------------------------------------------------
# Build argument list for create_app
# If the caller passed no positional path argument, inject ~/Documents as the
# default so the scaffold has somewhere sensible to land.
# ---------------------------------------------------------------------------

ARGS=("$@")

# Detect whether any argument looks like an output path (not a flag).
# We check the last argument: if it starts with '-' or is empty, append the
# default.  create_app treats the final positional as the target directory.
DEFAULT_DIR="${HOME}/Documents"

has_path_arg=false
for arg in "${ARGS[@]+"${ARGS[@]}"}"; do
    if [[ "$arg" != -* ]]; then
        has_path_arg=true
        break
    fi
done

if [ "$has_path_arg" = false ]; then
    warn "No output directory specified - defaulting to $DEFAULT_DIR"
    ARGS+=("$DEFAULT_DIR")
fi

# ---------------------------------------------------------------------------
# Run create_app
# ---------------------------------------------------------------------------

info "Running create_app ..."
(cd "$CLONE_DIR" && zune run packages/create_app/src create "${ARGS[@]+"${ARGS[@]}"}")
