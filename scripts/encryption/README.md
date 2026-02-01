# Encryption/Decryption Scripts

This module provides standardized scripts for encrypting and decrypting environment files in GitOps deployment repositories.

## Overview

These scripts are designed to work with Komodo GitOps deployments, allowing you to securely store encrypted environment variables in your repository while keeping the keys visible.

## Scripts

### Shell Scripts (Linux/macOS)

- `encrypt-env.sh` - Encrypt a single `.env` file
- `decrypt-env.sh` - Decrypt a single `.env.encrypted` file (with robust error handling)
- `encrypt-all-env.sh` - Encrypt all `.env` files in stacks directory
- `decrypt-all-env.sh` - Decrypt all `.env.encrypted` files in stacks directory
- `get-decryption-key.sh` - Helper script to retrieve decryption key from various sources

### PowerShell Scripts (Windows)

- `encrypt-env.ps1` - Encrypt a single `.env` file
- `decrypt-env.ps1` - Decrypt a single `.env.encrypted` file
- `encrypt-all-env.ps1` - Encrypt all `.env` files in stacks directory
- `decrypt-all-env.ps1` - Decrypt all `.env.encrypted` files in stacks directory
- `get-decryption-key.ps1` - Helper script to retrieve decryption key

## Usage

### Prerequisites

- OpenSSL must be installed on your system
- A decryption key must be provided via:
  - Command line argument
  - `key.env` file in the project root
  - `ENV_DECRYPTION_KEY` environment variable

### Encrypting Environment Files

```bash
# Encrypt a single stack
./scripts/encryption/encrypt-env.sh my-stack

# Encrypt with explicit key
./scripts/encryption/encrypt-env.sh my-stack "my-secret-key"

# Encrypt all stacks
./scripts/encryption/encrypt-all-env.sh
```

### Decrypting Environment Files

```bash
# Decrypt a single stack
./scripts/encryption/decrypt-env.sh my-stack

# Decrypt with explicit key
./scripts/encryption/decrypt-env.sh my-stack "my-secret-key"

# Decrypt all stacks
./scripts/encryption/decrypt-all-env.sh
```

### Setting Up Local Key

Create a `key.env` file in your project root (this file should be in `.gitignore`):

```bash
echo "ENV_DECRYPTION_KEY='your-secret-key-here'" > key.env
chmod 600 key.env
```

Or set as environment variable:

```bash
export ENV_DECRYPTION_KEY='your-secret-key-here'
```

## Encrypted File Format

The scripts use a hybrid encryption approach:
- Environment variable **keys** remain visible
- Environment variable **values** are encrypted

Example `.env.encrypted` file:

```env
DATABASE_URL=ENCRYPTED:U2FsdGVkX1...
API_KEY=ENCRYPTED:U2FsdGVkX1...
DEBUG=false
```

After decryption:

```env
DATABASE_URL=postgresql://user:pass@host:5432/db
API_KEY=sk_live_1234567890abcdef
DEBUG=false
```

## Robustness Features

The `decrypt-env.sh` script includes enhanced error handling for:

1. **Empty values** - Gracefully handles empty encrypted values (`KEY=ENCRYPTED:`)
2. **Invalid keys** - Provides clear error messages for incorrect decryption keys
3. **Missing OpenSSL** - Detects and reports if OpenSSL is not installed
4. **Corrupted data** - Handles cases where encrypted data is malformed
5. **Secret key validation** - Validates that the secret key is not empty before decryption

## Error Handling

The decryption script will:
- Continue with a warning for empty encrypted values (writes `KEY=` to output)
- Exit with error for corrupted encrypted data
- Exit with error for incorrect decryption key
- Provide detailed error messages to help diagnose issues

## Integration with GitOps

These scripts are designed to work with GitOps workflows:

1. Encrypt your environment files before committing
2. Commit `.env.encrypted` files to the repository
3. Deploy using Komodo with decryption happening at deploy time
4. Never commit `.env` files with plain text secrets

## Git Module Setup

This directory is intended to be used as a git submodule in `infra-deploy-*` repositories.

See the main repository documentation for setup instructions.
