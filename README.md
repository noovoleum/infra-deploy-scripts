# infra-deploy-scripts

Standardized scripts and tooling for GitOps deployment across `infra-deploy-*` repositories using Komodo.

## Overview

This repository provides shared scripts, just commands, and documentation for managing encrypted environment variables in GitOps deployments. It's designed to be used as a git submodule in `infra-deploy-*` repositories.

**Features:**
- 🔐 **Encryption/Decryption** - OpenSSL-based encryption for environment variables
- ⚡ **Just Command Runner** - Simple, discoverable commands for common operations
- 🔧 **Requirements Checker** - Automatic verification of required tools
- 🪟 **Cross-Platform** - Full support for Linux, macOS, and Windows (via Git Bash)
- 📦 **Git Submodule** - Easy integration and updates across all repos

---

## Quick Start

### 1. Add as Submodule (Recommended)

```bash
cd your-infra-deploy-repo
git submodule add https://github.com/noovoleum/infra-deploy-scripts.git lib/infra-deploy-scripts
git commit -m "Add infra-deploy-scripts submodule"
```

### 2. Run Setup

```bash
./lib/infra-deploy-scripts/scripts/check-requirements.sh  # Verify requirements
./lib/infra-deploy-scripts/scripts/setup.sh               # Install just, create symlinks
```

### 3. Start Using

```bash
just decrypt-all           # Decrypt all .env.encrypted files
just encrypt-all           # Encrypt all .env files
just decrypt <stack>       # Decrypt specific stack
just encrypt <stack>       # Encrypt specific stack
just status                # Show repository status
```

---

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Encryption Details](#encryption-details)
- [Platform Guides](#platform-guides)
- [PowerShell Integration](#powershell-integration)
- [Git Submodule Usage](#git-submodule-usage)
- [Troubleshooting](#troubleshooting)

---

## Installation

### Requirements

**Required Tools:**
- **Git** - Version control
- **OpenSSL** - Encryption/decryption
- **Basic Unix tools** - `base64`, `tr`, `grep` (usually pre-installed)

**Optional Tools:**
- **just** - Command runner (highly recommended)
- **cargo** - Rust package manager (for installing `just`)

### Check Requirements

```bash
./lib/infra-deploy-scripts/scripts/check-requirements.sh
```

This will verify all required tools are installed and show installation instructions for any missing tools.

### Install Just Command Runner

The setup script can install `just` automatically:

```bash
./lib/infra-deploy-scripts/scripts/setup.sh
```

Or install manually:

**Via cargo (recommended):**
```bash
cargo install just
```

**Via Homebrew (macOS):**
```bash
brew install just
```

**Via Pacman (Arch Linux):**
```bash
sudo pacman -S just
```

---

## Usage

### Just Commands

The easiest way to use the scripts is via `just` commands:

#### Encryption/Decryption

```bash
just encrypt-all            # Encrypt all .env files in stacks/
just decrypt-all            # Decrypt all .env.encrypted files in stacks/
just encrypt <stack>        # Encrypt specific stack
just decrypt <stack>        # Decrypt specific stack
```

#### Debug Mode

Add `--debug` flag to any command for detailed output:

```bash
just decrypt-all --debug
just encrypt outline --debug
```

#### Key Management

```bash
just setup-key              # Interactive key setup (creates key.env)
```

#### Repository Management

```bash
just list-stacks            # List all available stacks
just status                 # Show git and submodule status
just clean                  # Remove decrypted .env files
```

#### Git Submodules

```bash
just submodule-init         # Initialize git submodules
just submodule-update       # Update git submodules to latest
just submodule-status       # Show submodule status
```

#### Setup Commands

```bash
just install-just           # Install just command runner
just setup                  # Run full setup
just help                   # Show help message
```

### Direct Script Usage

You can also run scripts directly without `just`:

```bash
# From project root (when used as submodule)
./lib/infra-deploy-scripts/scripts/encryption/decrypt-all-env.sh
./lib/infra-deploy-scripts/scripts/encryption/encrypt-env.sh <stack>
./lib/infra-deploy-scripts/scripts/encryption/decrypt-env.sh <stack>
```

---

## Encryption Details

### How It Works

The scripts use OpenSSL AES-256-CBC to encrypt environment variable **values** while keeping the **keys** visible:

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
- ✅ Commit `.env.encrypted` files to Git
- ✅ Keep variable keys visible for documentation
- ✅ Securely store sensitive values
- ✅ Decrypt at deploy time with Komodo

### Key Management

The decryption key can be provided via:

1. **`key.env` file** (local, not committed to Git)
2. **`ENV_DECRYPTION_KEY` environment variable**
3. **Command line argument** (not recommended, appears in shell history)

#### Setting Up a Local Key

**Option 1: Create key.env file**
```bash
echo "ENV_DECRYPTION_KEY='your-secret-key-here'" > key.env
chmod 600 key.env
# Add key.env to .gitignore!
```

**Option 2: Environment variable**
```bash
export ENV_DECRYPTION_KEY='your-secret-key-here'
# Add to ~/.bashrc or ~/.zshrc for persistence
```

**Option 3: Use just setup-key**
```bash
just setup-key  # Interactive prompt
```

### Encryption Script Features

The decryption scripts include robust error handling for:
- ✅ **Empty values** - Gracefully handles `KEY=ENCRYPTED:` (no value after prefix)
- ✅ **Invalid keys** - Clear error messages for incorrect decryption keys
- ✅ **Missing OpenSSL** - Detects and reports if OpenSSL is not installed
- ✅ **Corrupted data** - Handles cases where encrypted data is malformed
- ✅ **Key validation** - Validates that the secret key is not empty

---

## Platform Guides

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

We recommend using **Git Bash** for full shell script compatibility without needing separate PowerShell scripts.

#### Why Git Bash?

- ✅ **Single script set** - No need to maintain both `.sh` and `.ps1` files
- ✅ **Full compatibility** - Complete Unix-like environment on Windows
- ✅ **Same commands** - Use the exact same commands as Linux/macOS users
- ✅ **Better tools** - Access to Unix tools like `grep`, `sed`, `awk`, etc.
- ✅ **Consistent experience** - Same workflows across all platforms

#### Windows Quick Start

1. **Install Git for Windows**
   - Download from: https://git-scm.com/download/win
   - Keep default settings
   - Ensure "Git Bash Here" is enabled

2. **Install OpenSSL** (if not included with Git Bash)
   - Download from: https://slproweb.com/products/Win32OpenSSL.html
   - Install "Win64 OpenSSL v3.x.x (Full)"
   - Add to PATH: `C:\Program Files\OpenSSL-Win64\bin`

3. **Open Git Bash** and run:
   ```bash
   ./lib/infra-deploy-scripts/scripts/check-requirements.sh
   ./lib/infra-deploy-scripts/scripts/setup.sh
   ```

4. **Start using:**
   ```bash
   just decrypt-all
   just encrypt-all
   ```

#### Windows-Specific Notes

**File Paths:**
Git Bash uses Unix-style paths:
- Windows `C:\Users\Name` → Git Bash `/c/Users/Name`
- Your project is likely at `/c/Users/YourName/Projects/infra-deploy-xxx`

**Line Endings:**
```bash
# Configure git to handle line endings
git config --global core.autocrlf true
```

**Permissions:**
Git Bash on Windows doesn't enforce Unix permissions, but you can still use:
```bash
chmod +x script.sh  # Won't actually change permissions
./script.sh         # Git Bash will still run it
```

#### Alternative: WSL

If you prefer a more native Linux experience, you can use WSL:

```powershell
# In PowerShell (as Administrator)
wsl --install
```

**Benefits:** Native Linux environment, better performance, apt package manager
**Trade-offs:** Larger installation, more complex file system integration

For most users, Git Bash is sufficient and simpler.

---

## PowerShell Integration

If you prefer PowerShell, you can run shell scripts directly without opening Git Bash.

### Option 1: PowerShell Profile Functions (Recommended)

Add these functions to your PowerShell profile (`$PROFILE`):

```powershell
# Function to run shell scripts via Git Bash
function sh {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $bashPath = "C:\Program Files\Git\bin\bash.exe"

    if (Test-Path $bashPath) {
        & $bashPath -c @Arguments
    } else {
        Write-Error "Git Bash not found at $bashPath. Please install Git for Windows."
    }
}

# Just command runner
function just {
    sh "just $args"
}

# Encryption shortcuts
function Encrypt-Stack {
    param([string]$Stack)
    sh "./lib/infra-deploy-scripts/scripts/encryption/encrypt-env.sh $Stack"
}

function Decrypt-Stack {
    param([string]$Stack)
    sh "./lib/infra-deploy-scripts/scripts/encryption/decrypt-env.sh $Stack"
}

function Encrypt-AllStacks {
    sh "just encrypt-all"
}

function Decrypt-AllStacks {
    sh "just decrypt-all"
}
```

**Then you can run:**
```powershell
PS> just decrypt-all
PS> just encrypt outline
PS> Encrypt-Stack outline
PS> Decrypt-Stack boxui-sim
```

**Edit your PowerShell profile:**
```powershell
notepad $PROFILE
# Add the functions above, save, and restart PowerShell
```

### Option 2: Direct Bash Invocation

No setup required - just call bash directly:

```powershell
PS> bash ./lib/infra-deploy-scripts/scripts/encryption/decrypt-all-env.sh
PS> bash ./lib/infra-deploy-scripts/scripts/encryption/encrypt-env.sh outline
```

---

## Git Submodule Usage

### Adding to a Repository

```bash
cd infra-deploy-xxx
git submodule add https://github.com/noovoleum/infra-deploy-scripts.git lib/infra-deploy-scripts
git commit -m "Add infra-deploy-scripts submodule"
```

### Initial Clone with Submodules

```bash
# Clone repository and initialize submodules
git clone --recurse-submodules https://github.com/noovoleum/infra-deploy-xxx.git

# Or if you already cloned:
git submodule update --init --recursive
```

### Updating Submodules

When `infra-deploy-scripts` is updated:

```bash
# Update to latest version
git submodule update --remote lib/infra-deploy-scripts

# Commit the update
git add lib/infra-deploy-scripts
git commit -m "chore: update infra-deploy-scripts to latest"
```

Or use the just command:
```bash
just submodule-update
```

### Removing and Reinitializing

If you have submodule issues:

```bash
git submodule deinit -f lib/infra-deploy-scripts
rm -rf .git/modules/lib/infra-deploy-scripts
git rm -f lib/infra-deploy-scripts
git submodule add https://github.com/noovoleum/infra-deploy-scripts.git lib/infra-deploy-scripts
```

---

## Troubleshooting

### Requirements Check Fails

```bash
./lib/infra-deploy-scripts/scripts/check-requirements.sh
```
This will show you which tools are missing and how to install them.

### "openssl: command not found"

**Linux:** `sudo apt install openssl` (or equivalent for your distro)
**macOS:** `brew install openssl`
**Windows:** Included with Git Bash or install from [slproweb.com](https://slproweb.com/products/Win32OpenSSL.html)

### "just: command not found"

The scripts work without `just`, but it's recommended:

```bash
cargo install just
# or
brew install just  # macOS
```

### "No .env.encrypted files found"

Make sure you're in the correct directory (repository root) and that the `stacks/` directory contains `.env.encrypted` files.

```bash
# Verify files exist
ls -la stacks/*/.env.encrypted

# Check current directory
pwd
```

### Decryption Fails with "Incorrect key"

- Verify your `ENV_DECRYPTION_KEY` environment variable is set correctly
- Check that `key.env` file exists and contains the correct key
- Ensure you're using the same key that was used for encryption

### Submodule Not Initialized

```bash
just submodule-init
# or
git submodule update --init --recursive
```

### Line Ending Issues (Windows)

```bash
# Configure git to handle line endings
git config --global core.autocrlf input

# Or convert files
dos2unix script.sh
```

### Find Command Not Working (Windows)

If you're running scripts from PowerShell and `find` doesn't work, the scripts automatically detect and use `/usr/bin/find` to avoid conflicts with Windows' `find.exe` command.

### Script Permissions Denied

**Linux/macOS:**
```bash
chmod +x ./lib/infra-deploy-scripts/scripts/**/*.sh
```

**Windows (Git Bash):**
Just use `sh script.sh` instead of `./script.sh`:
```bash
sh ./lib/infra-deploy-scripts/scripts/decrypt-all-env.sh
```

---

## Repository Structure

```
infra-deploy-scripts/
├── justfile                          # Just command definitions
├── README.md                         # This file
├── scripts/
│   ├── setup.sh                      # Main setup script
│   ├── check-requirements.sh         # Requirements checker
│   └── encryption/                   # Encryption/decryption scripts
│       ├── README.md                 # Encryption documentation (this file)
│       ├── encrypt-env.sh            # Encrypt single .env
│       ├── decrypt-env.sh            # Decrypt single .env (with robust error handling)
│       ├── encrypt-all-env.sh        # Encrypt all stacks
│       ├── decrypt-all-env.sh        # Decrypt all stacks
│       └── get-decryption-key.sh     # Key retrieval helper
└── encryption/                       # (Legacy alias for scripts/encryption)
```

---

## Workflow Examples

### Initial Setup

```bash
# 1. Clone your repo with submodules
git clone --recurse-submodules https://github.com/noovoleum/infra-deploy-xxx.git
cd infra-deploy-xxx

# 2. Run setup
./lib/infra-deploy-scripts/scripts/setup.sh

# 3. Set up your encryption key
just setup-key
```

### Daily Workflow

```bash
# 1. Pull latest changes
git pull

# 2. Update submodules
just submodule-update

# 3. Decrypt all stacks to work on them
just decrypt-all

# 4. Make changes to .env files...

# 5. Encrypt all stacks before committing
just encrypt-all

# 6. Clean up decrypted files
just clean

# 7. Commit and push
git add .
git commit -m "Update environment configuration"
git push
```

### Single Stack Workflow

```bash
# Decrypt just one stack
just decrypt outline

# Make changes...

# Encrypt it back
just encrypt outline
```

---

## Contributing

When contributing changes:

1. Test on multiple platforms (Linux, macOS, Windows with Git Bash)
2. Update relevant documentation
3. Test the requirements checker
4. Ensure just commands work correctly
5. Update this README if adding new features

---

## License

This repository is part of the Noovoleum infrastructure deployment tooling.

---

## Related Repositories

- **Parent repositories:** `infra-deploy-*` repositories
- **Komodo:** [Komodo Deployment Platform](https://github.com/ISO-KOMODO/komodo)

---

## Support

For issues or questions:

1. Check the documentation in this repository
2. Run `./lib/infra-deploy-scripts/scripts/check-requirements.sh` to verify your setup
3. See platform-specific guides (Linux, macOS, Windows)
4. Check the troubleshooting section above

---

## Changelog

### v1.1.0 (Current)
- Added `*FLAGS` parameter support for intuitive debug flag usage
- Fixed Windows `find.exe` command conflict
- Enhanced error handling for empty encrypted values
- Added backslash to forward slash path conversion for PowerShell
- Improved submodule .git file detection

### v1.0.0
- Initial release
- Encryption/decryption scripts with robust error handling
- Just command runner integration
- Requirements checker
- Windows Git Bash support
- Comprehensive documentation
