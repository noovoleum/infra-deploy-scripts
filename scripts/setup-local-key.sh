#!/bin/bash
# Setup script to configure local decryption key for developers
# This creates a local key.env file (not committed to repo)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find the parent repo root by locating a real .git directory (not a submodule .git file)
REPO_ROOT=""
DIR="$SCRIPT_DIR"
while [ "$DIR" != "/" ]; do
    if [ -d "$DIR/.git" ]; then
        REPO_ROOT="$DIR"
        break
    fi
    DIR="$(cd "$DIR/.." && pwd)"
done

if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
KEY_FILE="$REPO_ROOT/key.env"

echo "Setting up local decryption key for .env files"
echo ""

# Check if key file already exists
if [ -f "$KEY_FILE" ]; then
    read -p "A local key file already exists. Overwrite? (y/N) " overwrite
    if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Get the key
if [ -z "$1" ]; then
    echo "Enter your decryption key (it will be stored locally in key.env):"
    read -s KEY
    echo ""
else
    KEY="$1"
    echo "Using provided key..."
fi

if [ -z "$KEY" ]; then
    echo "Error: Key cannot be empty" >&2
    exit 1
fi

# Save the key to local file in standard env format
echo "ENV_DECRYPTION_KEY=$KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"
echo ""
echo "✓ Key saved to $KEY_FILE (this file is not committed to the repository)"
echo ""
echo "The key will be used automatically by Git hooks to decrypt .env files."
echo "You can also set the ENV_DECRYPTION_KEY environment variable instead."
echo ""

# Check if OpenSSL is available before testing
if ! command -v openssl >/dev/null 2>&1; then
    echo ""
    echo "⚠ OpenSSL is not installed or not in PATH"
    echo "  Skipping decryption test."
    echo "  Install OpenSSL: sudo apt-get install openssl (or brew install openssl on Mac)"
    echo ""
    echo "✓ Key setup complete! Install OpenSSL to enable encryption/decryption."
    exit 0
fi

# Test decryption with the key
echo "Testing decryption..."
TEST_FILE=$(find "$REPO_ROOT/stacks" -name ".env.encrypted" -type f 2>/dev/null | head -n 1)

if [ -n "$TEST_FILE" ]; then
    STACK_NAME=$(basename "$(dirname "$TEST_FILE")")
    if "$SCRIPT_DIR/encryption/decrypt-env.sh" "$STACK_NAME" "$KEY" >/dev/null 2>&1; then
        echo "✓ Decryption test successful!"
    else
        echo "⚠ Decryption test failed. Please verify your key is correct." >&2
    fi
else
    echo "No .env.encrypted files found to test with."
fi
