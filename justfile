# justfile for infra-deploy-scripts
# Run commands with: just <command>
# See all commands: just --list
#
# Debug mode: Add --debug flag to any command to see detailed output
# Example: just decrypt-all --debug

# Set the default recipe
default:
    @just --list

# Encryption/Decryption commands
encrypt-all *FLAGS:
    @echo "Encrypting all .env files in stacks..."
    @sh ./lib/infra-deploy-scripts/scripts/encryption/encrypt-all-env.sh {{FLAGS}}

decrypt-all *FLAGS:
    @echo "Decrypting all .env.encrypted files in stacks/..."
    @sh ./lib/infra-deploy-scripts/scripts/encryption/decrypt-all-env.sh {{FLAGS}}

encrypt stack *FLAGS:
    @echo "Encrypting {{stack}}/.env..."
    @sh ./lib/infra-deploy-scripts/scripts/encryption/encrypt-env.sh {{stack}} {{FLAGS}}

decrypt stack *FLAGS:
    @echo "Decrypting {{stack}}/.env.encrypted..."
    @sh ./lib/infra-deploy-scripts/scripts/encryption/decrypt-env.sh {{stack}} {{FLAGS}}

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

update-justfile:
    @echo "Updating justfile from template..."
    @if [ -f "lib/infra-deploy-scripts/justfile" ]; then \
        cp lib/infra-deploy-scripts/justfile justfile; \
        echo "✓ justfile updated from lib/infra-deploy-scripts/justfile"; \
    else \
        echo "✗ Error: lib/infra-deploy-scripts/justfile not found"; \
        echo "  Make sure the submodule is initialized:"; \
        echo "  just submodule-init"; \
        exit 1; \
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
    @echo "Debug mode (add --debug to any command):"
    @echo "  just decrypt-all --debug"
    @echo "  just encrypt outline --debug"
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
    @echo "  just setup             Run full setup"
    @echo ""
    @echo "Utilities:"
    @echo "  just list-stacks       List all available stacks"
    @echo "  just clean             Remove decrypted .env files"
    @echo "  just status            Show repository status"
    @echo ""
    @echo "See all commands: just --list"
