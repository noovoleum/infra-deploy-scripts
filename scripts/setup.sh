#!/bin/bash
# Setup script for infra-deploy-scripts
# One-time developer workflow setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Find the parent repository root by going up until we find a .git directory (not a file)
# This handles submodules at various depths (e.g., lib/infra-deploy-scripts, infra-deploy-scripts)
PARENT_DIR="$REPO_ROOT"
while [ "$PARENT_DIR" != "/" ]; do
    if [ -d "$PARENT_DIR/.git" ]; then
        break
    fi
    PARENT_DIR="$(cd "$PARENT_DIR/.." && pwd)"
done

if [ "$PARENT_DIR" = "/" ]; then
    echo -e "${RED}Error: Could not find parent repository root${NC}"
    exit 1
fi

FORCE=false
while [ $# -gt 0 ]; do
    case "$1" in
        --force|-f)
            FORCE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--force]"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--force]"
            exit 1
            ;;
    esac
    shift
done

SETUP_MARKER="${HOME:-$REPO_ROOT}/.infra-deploy-scripts-setup"
if [ -f "$SETUP_MARKER" ]; then
    SETUP_DATE=$(cat "$SETUP_MARKER" 2>/dev/null || echo "unknown")
    echo "Previous setup detected on $SETUP_DATE. Continuing with idempotent setup..."
    echo ""
fi

echo "=== infra-deploy-scripts Setup ==="
echo ""

# Detect environment
OS_UNAME="$(uname -s 2>/dev/null || echo unknown)"
OS_LABEL="$OS_UNAME"
IS_WSL=false
case "$OS_UNAME" in
    Linux)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            OS_LABEL="Linux (WSL)"
            IS_WSL=true
        else
            OS_LABEL="Linux"
        fi
        ;;
    Darwin)
        OS_LABEL="macOS"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        OS_LABEL="Windows (unsupported)"
        ;;
esac

echo "Detected environment: $OS_LABEL"

if [ "$OS_LABEL" = "Windows (unsupported)" ]; then
    echo -e "${RED}Windows detected. WSL is required for infra-deploy-scripts.${NC}"
    echo "Install WSL (PowerShell as Administrator):"
    echo "  wsl --install"
    echo "Docs: https://learn.microsoft.com/windows/wsl/install"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}Git not found in PATH. Please install git and try again.${NC}"
    exit 1
fi

echo ""

# Check requirements
echo "Checking requirements..."
if [ -f "$SCRIPT_DIR/check-requirements.sh" ]; then
    if ! sh "$SCRIPT_DIR/check-requirements.sh"; then
        echo ""
        echo -e "${RED}Requirements check failed. Install missing requirements and run setup again.${NC}"
        exit 1
    fi
    echo ""
else
    echo -e "${YELLOW}Warning: check-requirements.sh not found, skipping requirements check${NC}"
    echo ""
fi

# Check if just is installed
if ! command -v just >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: 'just' command runner is not installed${NC}"
    echo ""
    echo "Installing 'just'..."

    if command -v apt >/dev/null 2>&1; then
        echo -e "${GREEN}Detected Debian/Ubuntu${NC}"
        if command -v cargo >/dev/null 2>&1; then
            echo "Installing just via cargo..."
            cargo install just
        else
            echo "Rust/cargo not found. Installing via apt..."
            echo -e "${YELLOW}Note: just is not in default apt repos${NC}"
            echo "Please install cargo first:"
            echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
            echo "Then run: cargo install just"
            echo ""
            echo "Or visit: https://github.com/casey/just#installation"
            exit 1
        fi
    elif command -v brew >/dev/null 2>&1; then
        echo -e "${GREEN}Detected macOS${NC}"
        echo "Installing just via brew..."
        brew install just
    elif command -v pacman >/dev/null 2>&1; then
        echo -e "${GREEN}Detected Arch Linux${NC}"
        echo "Installing just via pacman..."
        sudo pacman -S just
    else
        echo -e "${RED}Could not detect package manager${NC}"
        echo "Please install 'just' manually:"
        echo "  cargo install just"
        echo "Or visit: https://github.com/casey/just#installation"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}OK: just installed successfully${NC}"
else
    echo -e "${GREEN}OK: 'just' is already installed${NC}"
    JUST_VERSION=$(just --version 2>/dev/null || echo "unknown")
    echo "  Version: $JUST_VERSION"
fi

echo ""

# Check if we're in a submodule
if [ -f "$REPO_ROOT/.git" ]; then
    GIT_FILE_CONTENT="$(cat "$REPO_ROOT/.git")"
    if echo "$GIT_FILE_CONTENT" | grep -q "gitdir: .*modules/.*infra-deploy-scripts"; then
        echo -e "${GREEN}OK: Detected running as git submodule${NC}"
        IS_SUBMODULE=true
    else
        echo -e "${YELLOW}Note: .git file exists but doesn't match expected submodule pattern${NC}"
        echo "  Content: $GIT_FILE_CONTENT"
        IS_SUBMODULE=false
    fi
else
    echo -e "${YELLOW}Note: Not running as a git submodule${NC}"
    IS_SUBMODULE=false
fi

echo ""

# Create copy of justfile in parent directory (not symlink for Windows compatibility)
if [ "$IS_SUBMODULE" = true ]; then
    if [ ! -f "$PARENT_DIR/justfile" ]; then
        echo "Copying justfile to parent directory..."
        cp "$REPO_ROOT/justfile" "$PARENT_DIR/justfile"
        echo -e "${GREEN}OK: Created justfile in: $PARENT_DIR/justfile${NC}"
    else
        echo -e "${GREEN}OK: justfile already exists in parent directory${NC}"
    fi

    echo ""
    echo "=== Setup Complete ==="
    echo ""
    echo "You can now run commands from the parent directory:"
    echo "  cd $PARENT_DIR"
    echo "  just --list"
    echo "  just setup-key"
    echo ""
    echo "Common commands:"
    echo "  just encrypt-all"
    echo "  just decrypt-all"
    echo "  just encrypt <stack>"
    echo "  just decrypt <stack>"
    echo "  just list-stacks"
    echo "  just status"
    echo "  just update-justfile"
    echo ""
else
    echo ""
    echo "=== Setup Complete ==="
    echo ""
    echo "Run commands from this directory:"
    echo "  cd $REPO_ROOT"
    echo "  just --list"
    echo "  just setup-key"
    echo ""
fi

SETUP_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)
echo "$SETUP_DATE" > "$SETUP_MARKER"

echo -e "${GREEN}Happy deploying!${NC}"
