# justfile for infra-deploy-scripts
# Run commands with: just <command>
# See all commands: just --list
#
# Debug mode: Add --debug or -d flag to any command to see detailed output
# Example: just decrypt-all --debug

# Set the default recipe
default:
    @just --list

# Encryption/Decryption commands
encrypt-all:
    @echo "Encrypting all .env files in stacks..."
    @sh ./lib/infra-deploy-scripts/scripts/encryption/encrypt-all-env.sh {{debug}}

decrypt-all:
    @echo "Decrypting all .env.encrypted files in stacks/..."
    @sh ./lib/infra-deploy-scripts/scripts/encryption/decrypt-all-env.sh {{debug}}

encrypt stack:
    @echo "Encrypting {{stack}}/.env..."
    @sh ./lib/infra-deploy-scripts/scripts/encryption/encrypt-env.sh {{stack}} {{debug}}

decrypt stack:
    @echo "Decrypting {{stack}}/.env.encrypted..."
    @sh ./lib/infra-deploy-scripts/scripts/encryption/decrypt-env.sh {{stack}} {{debug}}

# Key management
setup-key:
    @echo "Setting up local encryption key..."
    @if [ ! -f key.env ]; then \
        echo "Please enter your encryption key:"; \
        read -s key; \
        echo "ENV_DECRYPTION_KEY='$${key}'" > key.env; \
        chmod 600 key.env; \
        echo "Key saved to key.env"; \
    else \
        echo "key.env already exists. Skipping."; \
    fi

# List all stacks
list-stacks:
    @echo "Available stacks:"
    @if [ -d "stacks" ]; then \
        ls -1 stacks/ 2>/dev/null | grep -v "^$" || echo "No stacks found."; \
    else \
        echo "stacks/ directory not found."; \
    fi

# Git submodule management
submodule-init:
    @echo "Initializing git submodules..."
    @git submodule update --init --recursive

submodule-update:
    @echo "Updating git submodules..."
    @git submodule update --remote --merge

submodule-status:
    @echo "Git submodule status:"
    @git submodule status

# Setup and installation
setup:
    @echo "Setting up infra-deploy-scripts..."
    @./scripts/setup.sh

install-just:
    @echo "Installing 'just' command runner..."
    @if command -v apt >/dev/null 2>&1; then \
        echo "Detected Debian/Ubuntu. Installing via cargo..."; \
        if ! command -v cargo >/dev/null 2>&1; then \
            echo "Installing rust/cargo first..."; \
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
            source $$HOME/.cargo/env; \
        fi; \
        cargo install just; \
    elif command -v brew >/dev/null 2>&1; then \
        echo "Detected macOS. Installing via brew..."; \
        brew install just; \
    elif command -v pacman >/dev/null 2>&1; then \
        echo "Detected Arch Linux. Installing via pacman..."; \
        sudo pacman -S just; \
    else \
        echo "Could not detect package manager."; \
        echo "Please install 'just' manually:"; \
        echo "  cargo install just"; \
        echo "Or visit: https://github.com/casey/just#installation"; \
    fi

# Utility commands
clean:
    @echo "Removing decrypted .env files..."
    @find stacks/ -name ".env" -type f -delete 2>/dev/null || echo "No .env files to remove."
    @echo "Cleaned decrypted files."

status:
    @echo "=== Repository Status ==="
    @echo ""
    @echo "Git status:"
    @git status --short
    @echo ""
    @echo "=== Submodule Status ==="
    @just submodule-status
    @echo ""
    @echo "=== Available Stacks ==="
    @just list-stacks

help:
    @echo "infra-deploy-scripts - Just Command Runner"
    @echo ""
    @echo "Common commands:"
    @echo "  just encrypt-all       Encrypt all .env files"
    @echo "  just decrypt-all       Decrypt all .env.encrypted files"
    @echo "  just encrypt <stack>   Encrypt specific stack"
    @echo "  just decrypt <stack>   Decrypt specific stack"
    @echo ""
    @echo "Key management:"
    @echo "  just setup-key         Set up local encryption key"
    @echo ""
    @echo "Git submodules:"
    @echo "  just submodule-init    Initialize git submodules"
    @echo "  just submodule-update  Update git submodules"
    @echo "  just submodule-status  Show submodule status"
    @echo ""
    @echo "Setup:"
    @echo "  just install-just      Install 'just' command runner"
    @echo "  just setup             Run full setup"
    @echo ""
    @echo "Utilities:"
    @echo "  just list-stacks       List all available stacks"
    @echo "  just clean             Remove decrypted .env files"
    @echo "  just status            Show repository status"
    @echo ""
    @echo "See all commands: just --list"
