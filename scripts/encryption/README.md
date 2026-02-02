# Encryption/Decryption Scripts

This directory contains scripts for encrypting and decrypting environment files using OpenSSL AES-256-CBC.

**📚 For complete documentation, see the main [README.md](../../README.md)**

## Quick Reference

### Scripts

- `encrypt-env.sh` - Encrypt a single `.env` file
- `decrypt-env.sh` - Decrypt a single `.env.encrypted` file
- `encrypt-all-env.sh` - Encrypt all `.env` files in `stacks/`
- `decrypt-all-env.sh` - Decrypt all `.env.encrypted` files in `stacks/`
- `get-decryption-key.sh` - Helper to retrieve decryption key

### Usage

```bash
# Encrypt single stack
./encrypt-env.sh <stack-name>

# Decrypt single stack
./decrypt-env.sh <stack-name>

# Encrypt all stacks
./encrypt-all-env.sh

# Decrypt all stacks
./decrypt-all-env.sh

# With debug output
./decrypt-all-env.sh --debug
```

### Encrypted File Format

The scripts encrypt **values** while keeping **keys** visible:

**Before (`.env`):**
```env
DATABASE_URL=postgresql://user:pass@host:5432/db
```

**After (`.env.encrypted`):**
```env
DATABASE_URL=ENCRYPTED:U2FsdGVkX1...
```

---

For detailed documentation on:
- Installation and setup
- Platform-specific guides (Linux, macOS, Windows)
- Key management options
- PowerShell integration
- Troubleshooting

**See the main [README.md](../../README.md)**
