#!/bin/sh
# Automatically encrypt all .env files in the repository
# This script finds all .env files and encrypts them to .env.encrypted

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Find the actual git repository root (works even when script is in a submodule)
# Try to find .git directory by going up until we find it
DIR="$(pwd)"
while [ "$DIR" != "/" ]; do
    if [ -d "$DIR/.git" ] || [ -f "$DIR/.git" ]; then
        REPO_ROOT="$DIR"
        break
    fi
    DIR=$(dirname "$DIR")
done

# Fallback to current directory if .git not found
if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$(pwd)"
fi

# Change to repo root for operations
cd "$REPO_ROOT" || exit 1

SECRET_KEY="${1:-}"

# Get encryption key if not provided
if [ -z "$SECRET_KEY" ]; then
    # First try environment variable directly
    if [ -n "$ENV_DECRYPTION_KEY" ]; then
        SECRET_KEY="$ENV_DECRYPTION_KEY"
    else
        # Try get-decryption-key.sh script (checks env var and key.env file)
        SECRET_KEY=$("$SCRIPT_DIR/get-decryption-key.sh" 2>/dev/null || echo "")
    fi
fi

if [ -z "$SECRET_KEY" ]; then
    echo "Error: No encryption key found." >&2
    echo "Run './scripts/setup-local-key.sh' to configure your local key, or set ENV_DECRYPTION_KEY environment variable." >&2
    exit 1
fi

# Find all .env files (but not .env.encrypted or .env.example)
# We look for files named exactly ".env" in stack directories
ENV_FILES=$(find stacks -type f -name ".env" 2>/dev/null | while read -r file; do
    # Skip if it's .env.encrypted or .env.example
    case "$file" in
        *.encrypted|*.example) ;;
        *) echo "$file" ;;
    esac
done || true)

if [ -z "$ENV_FILES" ]; then
    echo "No .env files found to encrypt."
    exit 0
fi

COUNT=$(echo "$ENV_FILES" | wc -l | tr -d ' ')
echo "Encrypting $COUNT .env file(s)..."

echo "$ENV_FILES" | while IFS= read -r env_file; do
    stack_dir=$(dirname "$env_file")
    stack_name=$(basename "$stack_dir")
    encrypted_file="$stack_dir/.env.encrypted"
    
    # Skip if .env.encrypted already exists and is newer than .env
    if [ -f "$encrypted_file" ] && [ "$encrypted_file" -nt "$env_file" ]; then
        echo "  Skipping $stack_name - .env.encrypted is up to date"
        continue
    fi
    
    # Encrypt the file (change to repo root first)
    cd "$REPO_ROOT" || exit 1
    # Use sh to execute and capture output for debugging
    OUTPUT=$(sh "$SCRIPT_DIR/encrypt-env.sh" "$stack_name" "$SECRET_KEY" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        echo "  ✓ Encrypted $stack_name"
    else
        echo "  ✗ Failed to encrypt $stack_name" >&2
        echo "    Error: $OUTPUT" >&2
    fi
done

echo "Done!"

