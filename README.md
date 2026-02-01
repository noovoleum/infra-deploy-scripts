# infra-deploy-scripts

Standardized scripts and tooling for GitOps deployment across `infra-deploy-*` repositories using Komodo.

## Overview

This repository provides shared scripts, just commands, and documentation for managing encrypted environment variables in GitOps deployments. It's designed to be used as a git submodule in `infra-deploy-*` repositories.

## Features

- 🔐 **Encryption/Decryption Scripts** - OpenSSL-based encryption for environment variables
- ⚡ **Just Command Runner** - Simple, discoverable commands for common operations
- 🔧 **Requirements Checker** - Automatic verification of required tools
- 🪟 **Windows Support** - Full Windows compatibility via Git Bash
- 📦 **Git Submodule** - Easy integration and updates across all repos

## Quick Start

### 1. Clone or Add as Submodule

**As a submodule (recommended):**
```bash
cd your-infra-deploy-repo
git submodule add https://github.com/noovoleum/infra-deploy-scripts.git lib/infra-deploy-scripts
```

**Or clone standalone:**
```bash
git clone https://github.com/noovoleum/infra-deploy-scripts.git
cd infra-deploy-scripts
```

### 2. Check Requirements

```bash
./scripts/check-requirements.sh
```

This will verify that you have the required tools installed (Git, OpenSSL, etc.).

### 3. Run Setup

```bash
./scripts/setup.sh
```

This will:
- Verify all requirements are met
- Install `just` command runner (optional but recommended)
- Create symlink to justfile in parent directory (if used as submodule)

### 4. Start Using Commands

```bash
just encrypt-all        # Encrypt all .env files
just decrypt-all        # Decrypt all .env.encrypted files
just encrypt <stack>    # Encrypt specific stack
just decrypt <stack>    # Decrypt specific stack
just list-stacks        # List all available stacks
just status             # Show repository status
```

## Documentation

### Core Documentation

- **[Encryption Scripts README](scripts/encryption/README.md)** - Encryption/decryption usage
- **[Just Commands Guide](JUST.md)** - Just command runner documentation
- **[Windows Setup Guide](WINDOWS_SETUP.md)** - Windows Git Bash setup instructions

### For Parent Repositories

When using this as a submodule, you'll also have access to:

- **Requirements Checker** - `./lib/infra-deploy-scripts/scripts/check-requirements.sh`
- **Setup Script** - `./lib/infra-deploy-scripts/scripts/setup.sh`

## Requirements

### Required Tools

- **Git** - Version control
- **OpenSSL** - Encryption/decryption
- **Basic Unix tools** - `base64`, `tr`, `grep` (usually pre-installed)

### Optional Tools

- **just** - Command runner (highly recommended for better UX)
- **cargo** - Rust package manager (for installing `just`)

See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) for Windows-specific installation instructions.

## Repository Structure

```
infra-deploy-scripts/
├── justfile                    # Just command definitions
├── README.md                   # This file
├── JUST.md                     # Just documentation
├── WINDOWS_SETUP.md            # Windows setup guide
├── scripts/
│   ├── setup.sh                # Main setup script
│   ├── check-requirements.sh   # Requirements checker
│   └── encryption/             # Encryption/decryption scripts
│       ├── README.md           # Encryption documentation
│       ├── encrypt-env.sh      # Encrypt single .env
│       ├── decrypt-env.sh      # Decrypt single .env
│       ├── encrypt-all-env.sh  # Encrypt all stacks
│       ├── decrypt-all-env.sh  # Decrypt all stacks
│       └── get-decryption-key.sh # Key retrieval helper
└── encryption/                 # (Legacy alias for scripts/encryption)
```

## Encryption/Decryption Overview

### How It Works

The encryption scripts use OpenSSL AES-256-CBC to encrypt environment variable values while keeping the keys visible:

**Before (`.env`):**
```env
DATABASE_URL=postgresql://user:pass@host:5432/db
API_KEY=sk_live_1234567890abcdef
```

**After (`.env.encrypted`):**
```env
DATABASE_URL=ENCRYPTED:U2FsdGVkX1...
API_KEY=ENCRYPTED:U2FsdGVkX1...
```

This allows you to:
- Commit `.env.encrypted` files to Git
- Keep variable keys visible for documentation
- Securely store sensitive values

### Key Management

The decryption key can be provided via:

1. **Command line argument** (not recommended for security)
2. **`key.env` file** (local, not committed)
3. **`ENV_DECRYPTION_KEY` environment variable**

Example `key.env`:
```bash
ENV_DECRYPTION_KEY='your-secret-key-here'
```

## Just Commands

The `justfile` provides convenient commands for common operations:

### Encryption/Decryption

```bash
just encrypt-all        # Encrypt all stacks
just decrypt-all        # Decrypt all stacks
just encrypt <stack>    # Encrypt specific stack
just decrypt <stack>    # Decrypt specific stack
```

### Key Management

```bash
just setup-key          # Interactive key setup
```

### Repository Management

```bash
just list-stacks        # List all stacks
just status             # Show repository status
just clean              # Remove .env files
```

### Git Submodules

```bash
just submodule-init     # Initialize submodules
just submodule-update   # Update submodules
just submodule-status   # Show submodule status
```

### Setup

```bash
just install-just       # Install just command runner
just setup              # Run full setup
just help               # Show help
```

See [JUST.md](JUST.md) for complete documentation.

## Windows Support

This repository fully supports Windows via **Git Bash**, which provides a Unix-compatible shell environment.

### Why Git Bash?

- **Single script set** - No need for separate PowerShell scripts
- **Full compatibility** - Same commands as Linux/macOS
- **Better tools** - Access to Unix utilities
- **Consistent workflow** - Same experience across platforms

### Setup on Windows

1. Install [Git for Windows](https://git-scm.com/download/win)
2. Install [OpenSSL for Windows](https://slproweb.com/products/Win32OpenSSL.html) (if not included)
3. Open Git Bash and run:
   ```bash
   ./scripts/check-requirements.sh
   ./scripts/setup.sh
   ```

See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) for detailed Windows setup instructions.

## Platform-Specific Notes

### Linux

Most tools are pre-installed or available via package managers:

```bash
# Ubuntu/Debian
sudo apt install openssl

# Arch Linux
sudo pacman -S openssl

# Install just (optional)
cargo install just
```

### macOS

Install tools via Homebrew:

```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install openssl just
```

### Windows

See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) for detailed instructions.

## Integration with Parent Repositories

This repository is designed to be used as a git submodule in `infra-deploy-*` repositories.

### Adding to a Repository

```bash
cd infra-deploy-xxx
git submodule add https://github.com/noovoleum/infra-deploy-scripts.git lib/infra-deploy-scripts
git commit -m "Add infra-deploy-scripts submodule"
```

### Wrapper Scripts

The parent repository should include wrapper scripts that delegate to the submodule:

```bash
#!/bin/sh
# scripts/encrypt-env.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENCRYPTION_DIR="$SCRIPT_DIR/../lib/infra-deploy-scripts/scripts/encryption"

exec sh "$ENCRYPTION_DIR/encrypt-env.sh" "$@"
```

Or use symlinks for simplicity:

```bash
cd scripts/
ln -sf ../lib/infra-deploy-scripts/scripts/encryption/encrypt-env.sh encrypt-env.sh
ln -sf ../lib/infra-deploy-scripts/scripts/encryption/decrypt-env.sh decrypt-env.sh
# etc.
```

## Updating

When this repository is updated, update the submodule in your repositories:

```bash
# In each infra-deploy-* repository
git submodule update --remote lib/infra-deploy-scripts
git add lib/infra-deploy-scripts
git commit -m "chore: update infra-deploy-scripts to latest"
```

## Troubleshooting

### Requirements Check Fails

Run the requirements checker:
```bash
./scripts/check-requirements.sh
```

This will show you which tools are missing and how to install them.

### "openssl: command not found"

**Linux:** `sudo apt install openssl` (or equivalent for your distro)
**macOS:** `brew install openssl`
**Windows:** Included with Git Bash or install from [slproweb.com](https://slproweb.com/products/Win32OpenSSL.html)

### "just: command not found"

The scripts work without `just`, but it's recommended for better UX:

```bash
cargo install just
# or
brew install just  # macOS
```

### Submodule Issues

```bash
# Remove and reinitialize
git submodule deinit -f lib/infra-deploy-scripts
rm -rf .git/modules/lib/infra-deploy-scripts
git rm -f lib/infra-deploy-scripts
git submodule add https://github.com/noovoleum/infra-deploy-scripts.git lib/infra-deploy-scripts
```

### Windows Line Ending Issues

```bash
# Configure git to handle line endings
git config --global core.autocrlf input

# Convert files if needed
dos2unix script.sh
```

## Contributing

When contributing changes:

1. Test on multiple platforms (Linux, macOS, Windows with Git Bash)
2. Update relevant documentation
3. Test the requirements checker
4. Ensure just commands work correctly
5. Update this README if adding new features

## License

This repository is part of the Noovoleum infrastructure deployment tooling.

## Related Repositories

- **Parent repositories:** `infra-deploy-*` repositories
- **Komodo:** [Komodo Deployment Platform](https://github.com/ISO-KOMODO/komodo)

## Support

For issues or questions:

1. Check the documentation in this repository
2. Run `./scripts/check-requirements.sh` to verify your setup
3. See platform-specific guides (Linux, macOS, Windows)
4. Check the troubleshooting section above

## Changelog

### v1.0.0 (Current)
- Initial release
- Encryption/decryption scripts with robust error handling
- Just command runner integration
- Requirements checker
- Windows Git Bash support
- Comprehensive documentation
