# Windows Setup Guide

This guide explains how to set up the infra-deploy-scripts on Windows using Git Bash, which provides full shell script compatibility without needing separate PowerShell scripts.

## Why Git Bash on Windows?

**Benefits:**
- **Single script set** - No need to maintain both `.sh` and `.ps1` files
- **Full compatibility** - Git Bash provides a complete Unix-like environment on Windows
- **Same commands** - Use the exact same commands as Linux/macOS users
- **Better tools** - Access to Unix tools like `grep`, `sed`, `awk`, etc.
- **Consistent experience** - Same workflows across all platforms

## Quick Start (Recommended)

### 1. Install Git for Windows

Download and install Git for Windows from: https://git-scm.com/download/win

During installation:
- ✅ Keep default settings
- ✅ Ensure "Git Bash Here" is enabled (adds context menu option)
- ✅ Choose "Use Git from the Windows Command Prompt" if you want git in CMD too

### 2. Install Required Tools

**Open Git Bash** (search for "Git Bash" in Start menu) and run:

```bash
# Check requirements
./lib/infra-deploy-scripts/scripts/check-requirements.sh
```

This will show you what's installed and what's missing.

#### OpenSSL (Required)

Git for Windows includes OpenSSL, but if it's not found:

1. Download OpenSSL for Windows: https://slproweb.com/products/Win32OpenSSL.html
2. Install the "Win64 OpenSSL v3.x.x" (Full) version
3. Add to PATH: `C:\Program Files\OpenSSL-Win64\bin`
4. Restart Git Bash and verify: `openssl version`

#### Just - Command Runner (Optional but Recommended)

```bash
# Install Rust/Cargo first (if not installed)
# Download from: https://rustup.rs/

# Then install just
cargo install just
```

Alternatively, you can use the chocolatey package manager:
```powershell
# In PowerShell (as Administrator)
choco install just
```

### 3. Run Setup

```bash
./lib/infra-deploy-scripts/scripts/setup.sh
```

### 4. Verify Installation

```bash
# Check that commands work
just --list
./scripts/decrypt-env.sh
```

## Using Git Bash

### Starting Git Bash

You have several options:

1. **From Start Menu** - Search "Git Bash" and open it
2. **From Context Menu** - Right-click in any folder → "Git Bash Here"
3. **From VS Code** - Use integrated terminal with Git Bash profile

### Setting VS Code to Use Git Bash

1. Open VS Code Settings (Ctrl+,)
2. Search for "terminal integrated default profile windows"
3. Set to "Git Bash"

```json
{
  "terminal.integrated.defaultProfile.windows": "Git Bash"
}
```

### Setting Windows Terminal to Use Git Bash

1. Open Windows Terminal
2. Open Settings (Ctrl+,)
3. Add a new profile:

```json
{
    "guid": "{<generate-new-guid>}",
    "name": "Git Bash",
    "commandline": "C:\\Program Files\\Git\\bin\\bash.exe",
    "icon": "C:\\Program Files\\Git\\mingw64\\share\\git\\git-for-windows.ico"
}
```

4. Set as default profile if desired

## Common Git Bash Commands

### File Operations

```bash
# List files
ls -la

# Change directory
cd /c/Users/YourName/Projects

# Current directory
pwd

# Create directory
mkdir dirname

# Remove file
rm filename

# Copy file
cp source dest

# Move/rename
mv oldname newname
```

### Git Operations

```bash
# Clone repository
git clone https://github.com/noovoleum/infra-deploy-xxx.git

# Initialize submodules
git submodule update --init --recursive

# Update submodules
git submodule update --remote
```

### Encryption/Decryption

```bash
# Encrypt all stacks
just encrypt-all

# Decrypt all stacks
just decrypt-all

# Encrypt specific stack
just encrypt outline

# Decrypt specific stack
just decrypt outline
```

## Windows-Specific Considerations

### File Paths

Git Bash uses Unix-style paths:

- Windows `C:\Users\Name` → Git Bash `/c/Users/Name`
- Your project is likely at `/c/Users/YourName/Projects/infra-deploy-xxx`

### Line Endings

Git for Windows handles line endings automatically. If you have issues:

```bash
# Configure git to handle line endings
git config --global core.autocrlf true
```

### Permissions

Git Bash on Windows doesn't use Unix permissions, but you can still use:

```bash
# Make script executable (won't actually change permissions on Windows)
chmod +x script.sh

# Git Bash will still run it
./script.sh
```

### Environment Variables

Set environment variables in Git Bash:

```bash
# Temporary (current session only)
export ENV_DECRYPTION_KEY='your-key'

# Permanent - add to ~/.bashrc
echo "export ENV_DECRYPTION_KEY='your-key'" >> ~/.bashrc
source ~/.bashrc
```

### Windows Environment Variables

To access Windows environment variables:

```bash
# Use this syntax
echo $WINDOWS_ENV_VAR

# Example
echo $USERPROFILE  # Windows user profile directory
```

## Troubleshooting

### "openssl: command not found"

**Solution 1:** Git Bash includes OpenSSL, try reopening Git Bash

**Solution 2:** Install OpenSSL for Windows
1. Download from: https://slproweb.com/products/Win32OpenSSL.html
2. Install "Win64 OpenSSL v3.x.x (Full)"
3. Add to PATH: `C:\Program Files\OpenSSL-Win64\bin`
4. Restart Git Bash

### "base64: command not found"

Git Bash should include this. If missing:
1. Reinstall Git for Windows
2. Ensure you're using Git Bash, not regular CMD

### Script permissions denied

Git Bash on Windows doesn't enforce permissions:
- Try running with `sh script.sh` instead of `./script.sh`
- Or use `bash script.sh`

### Line ending issues (CRLF vs LF)

```bash
# Configure git to auto-convert
git config --global core.autocrlf input

# Or convert files
dos2unix filename.sh
```

### Submodule issues

```bash
# Remove and reinitialize
git submodule deinit -f lib/infra-deploy-scripts
rm -rf .git/modules/lib/infra-deploy-scripts
git rm -f lib/infra-deploy-scripts
git submodule add https://github.com/noovoleum/infra-deploy-scripts.git lib/infra-deploy-scripts
```

## Alternative: WSL (Windows Subsystem for Linux)

If you prefer a more native Linux experience, you can use WSL:

### Install WSL

```powershell
# In PowerShell (as Administrator)
wsl --install
```

This will install Ubuntu on Windows. After restart, you'll have a full Linux terminal.

### Benefits of WSL

- Native Linux environment
- Better performance for some operations
- Access to Linux package manager (apt)
- Full compatibility with all shell scripts

### Trade-offs

- Larger installation
- Slightly more complex file system integration
- Some Windows tool integration issues

For most users, Git Bash is sufficient and simpler.

## Migration from PowerShell Scripts

If you have existing PowerShell scripts, here's how to migrate:

### Before (PowerShell)

```powershell
.\scripts\decrypt-env.ps1 -StackName outline
```

### After (Git Bash)

```bash
./scripts/decrypt-env.sh outline
# or
just decrypt outline
```

### Key Differences

| PowerShell | Git Bash |
|------------|----------|
| `.\script.ps1` | `./script.sh` |
| `-ParameterName value` | Positional: `script.sh value` |
| `$variable` | `$variable` (same) |
| `$env:VARIABLE` | `$VARIABLE` or `$ENV_VARIABLE` |
| `Write-Host` | `echo` |
| `Get-Location` | `pwd` |
| `Set-Location` | `cd` |

## Recommended Workflow

### Daily Usage

1. **Open Git Bash** in your project directory
2. **Pull latest changes**: `git pull`
3. **Update submodules**: `git submodule update --remote`
4. **Decrypt stacks**: `just decrypt-all`
5. **Make changes**
6. **Encrypt stacks**: `just encrypt-all`
7. **Clean up**: `just clean`
8. **Commit**: `git add . && git commit -m "message" && git push`

### First Time Setup

1. Install Git for Windows
2. Open Git Bash in project directory
3. Run requirements check: `./lib/infra-deploy-scripts/scripts/check-requirements.sh`
4. Install missing tools if needed
5. Run setup: `./lib/infra-deploy-scripts/scripts/setup.sh`
6. Set up encryption key: `just setup-key`

## Getting Help

If you encounter issues:

1. Check requirements: `./lib/infra-deploy-scripts/scripts/check-requirements.sh`
2. Run setup: `./lib/infra-deploy-scripts/scripts/setup.sh`
3. See troubleshooting section above
4. Check Git Bash documentation: https://gitforwindows.org/

## Additional Resources

- [Git for Windows](https://gitforwindows.org/)
- [Git Bash Reference](https://gist.github.com/senseij/4320190)
- [Windows Terminal](https://aka.ms/terminal)
- [Just Command Runner](https://github.com/casey/just)
