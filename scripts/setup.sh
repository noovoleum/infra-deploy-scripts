#!/bin/sh
# Setup script for infra-deploy-scripts
# This script configures the justfile for the parent repository

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
        # Found the parent repository
        break
    fi
    PARENT_DIR="$(cd "$PARENT_DIR/.." && pwd)"
done

if [ "$PARENT_DIR" = "/" ]; then
    echo -e "${RED}Error: Could not find parent repository root${NC}"
    exit 1
fi

echo "=== infra-deploy-scripts Setup ==="
echo ""

# First, check requirements
echo "Checking requirements..."
if [ -f "$SCRIPT_DIR/check-requirements.sh" ]; then
    if ! sh "$SCRIPT_DIR/check-requirements.sh"; then
        echo ""
        echo -e "${RED}Requirements check failed. Please install missing requirements and run setup again.${NC}"
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
    
    # Try to detect package manager and install
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
    echo -e "${GREEN}✓ just installed successfully${NC}"
else
    echo -e "${GREEN}✓ 'just' is already installed${NC}"
    JUST_VERSION=$(just --version 2>/dev/null || echo "unknown")
    echo "  Version: $JUST_VERSION"
fi

echo ""

# Check if we're in a submodule
if [ -f "$REPO_ROOT/.git" ]; then
    GIT_FILE_CONTENT="$(cat "$REPO_ROOT/.git")"
    # Check various possible submodule path patterns
    if echo "$GIT_FILE_CONTENT" | grep -q "gitdir: .*modules/.*infra-deploy-scripts"; then
        echo -e "${GREEN}✓ Detected: Running as git submodule${NC}"
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

# Create symlink/copy of justfile in parent directory
if [ "$IS_SUBMODULE" = true ]; then
    if [ ! -f "$PARENT_DIR/justfile" ]; then
        echo "Creating justfile symlink in parent directory..."
        ln -sf "$REPO_ROOT/justfile" "$PARENT_DIR/justfile"
        echo -e "${GREEN}✓ Created symlink: $PARENT_DIR/justfile -> $REPO_ROOT/justfile${NC}"
    else
        if [ -L "$PARENT_DIR/justfile" ]; then
            echo -e "${GREEN}✓ justfile symlink already exists${NC}"
        else
            echo -e "${YELLOW}Warning: justfile already exists in parent directory (not a symlink)${NC}"
            echo "  Please remove it manually if you want to use the infra-deploy-scripts justfile:"
            echo "  rm $PARENT_DIR/justfile"
            echo "  ln -s $REPO_ROOT/justfile $PARENT_DIR/justfile"
        fi
    fi
    
    echo ""
    echo "=== Setup Complete! ==="
    echo ""
    echo "You can now run commands from the parent directory:"
    echo ""
    cd "$PARENT_DIR"
    echo "  Available commands:"
    echo "    just encrypt-all        Encrypt all .env files"
    echo "    just decrypt-all        Decrypt all .env.encrypted files"
    echo "    just encrypt <stack>    Encrypt specific stack"
    echo "    just decrypt <stack>    Decrypt specific stack"
    echo "    just list-stacks        List all available stacks"
    echo "    just setup-key          Set up local encryption key"
    echo "    just status             Show repository status"
    echo ""
    echo "  See all commands:"
    echo "    just --list"
    echo "    just help"
    echo ""
else
    echo ""
    echo "=== Setup Complete! ==="
    echo ""
    echo "The justfile is available in: $REPO_ROOT/justfile"
    echo ""
    echo "Run commands from this directory:"
    echo "  cd $REPO_ROOT"
    echo "  just --list"
    echo ""
fi

echo -e "${GREEN}Happy deploying!${NC}"
