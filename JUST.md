# Just Command Runner

This repository includes a [`justfile`](../justfile) with convenient commands for managing encryption/decryption and repository operations.

## What is Just?

[Just](https://github.com/casey/just) is a command runner like `make`, but simpler. It allows you to define and run commands with a clean, easy-to-read syntax.

## Installation

### Quick Install (via the setup script)

The easiest way to get started is to run the setup script:

```bash
./lib/infra-deploy-scripts/scripts/setup.sh
```

This will:
- Check if `just` is installed
- Install `just` if needed (via cargo, brew, or pacman)
- Create a symlink to the justfile in your project root

### Manual Installation

If you prefer to install `just` manually:

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

See the [just documentation](https://github.com/casey/just#installation) for more installation options.

## Usage

Once `just` is installed and the setup script has been run, you can use commands from your project root:

```bash
# See all available commands
just --list

# Encrypt all stacks
just encrypt-all

# Decrypt all stacks
just decrypt-all

# Encrypt a specific stack
just encrypt outline

# Decrypt a specific stack
just decrypt outline

# List all available stacks
just list-stacks

# Set up your encryption key
just setup-key

# Check repository status
just status

# Remove decrypted .env files
just clean

# Update git submodules
just submodule-update

# Show help
just help
```

## Available Commands

### Encryption/Decryption
- `just encrypt-all` - Encrypt all `.env` files in `stacks/`
- `just decrypt-all` - Decrypt all `.env.encrypted` files in `stacks/`
- `just encrypt <stack>` - Encrypt a specific stack
- `just decrypt <stack>` - Decrypt a specific stack

### Key Management
- `just setup-key` - Set up local encryption key in `key.env`

### Repository Management
- `just list-stacks` - List all available stacks
- `just status` - Show repository and submodule status
- `just clean` - Remove decrypted `.env` files

### Git Submodules
- `just submodule-init` - Initialize git submodules
- `just submodule-update` - Update git submodules to latest
- `just submodule-status` - Show submodule status

### Setup
- `just install-just` - Install `just` command runner
- `just setup` - Run full setup
- `just help` - Show help message

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
# Decrypt all stacks to work on them
just decrypt-all

# Make changes to .env files...

# Encrypt all stacks before committing
just encrypt-all

# Clean up decrypted files
just clean

# Commit and push
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

## Updating Just Commands

The justfile is maintained in the `noovoleum/infra-deploy-scripts` repository. To get the latest commands:

```bash
# Update the submodule
just submodule-update

# Or manually:
git submodule update --remote lib/infra-deploy-scripts
```

## Integration with Existing Scripts

The justfile works alongside the existing shell scripts:

| Just Command | Equivalent Shell Command |
|-------------|------------------------|
| `just encrypt-all` | `./scripts/encrypt-all-env.sh` |
| `just decrypt-all` | `./scripts/decrypt-all-env.sh` |
| `just encrypt <stack>` | `./scripts/encrypt-env.sh <stack>` |
| `just decrypt <stack>` | `./scripts/decrypt-env.sh <stack>` |

The justfile provides a simpler, more discoverable interface, but the underlying scripts remain directly executable if needed.

## Troubleshooting

### Command not found: just

Run the setup script or install manually:
```bash
./lib/infra-deploy-scripts/scripts/setup.sh
# or
cargo install just
```

### Justfile not found

Make sure you've run the setup script:
```bash
./lib/infra-deploy-scripts/scripts/setup.sh
```

Or manually create the symlink:
```bash
ln -s lib/infra-deploy-scripts/justfile justfile
```

### Submodule not initialized

```bash
just submodule-init
# or
git submodule update --init --recursive
```

## Why Just?

Compared to alternatives like `make`:

- **Simpler syntax** - No need for tabs or complex Makefile syntax
- **Better error messages** - Clear, helpful output
- **Command listing** - Built-in `just --list` to see all commands
- **Shell integration** - Works with your existing shell scripts
- **No dependencies** - Just a single binary, no Makefile complexities

## More Information

- [Just Documentation](https://github.com/casey/just)
- [Just Command Examples](https://just.systems/manual/en/)
