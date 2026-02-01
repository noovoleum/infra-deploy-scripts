#!/bin/sh
# Automatically decrypt all .env.encrypted files in the repository
# This script is called by Git hooks after checkout/merge

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

# Get decryption key if not provided
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
    echo "Warning: No decryption key found. Skipping automatic decryption."
    echo "Run './scripts/setup-local-key.sh' to configure your local key, or set ENV_DECRYPTION_KEY environment variable."
    exit 0
fi

# Find all .env.encrypted files
ENCRYPTED_FILES=$(find stacks -name ".env.encrypted" -type f 2>/dev/null || true)

if [ -z "$ENCRYPTED_FILES" ]; then
    echo "No .env.encrypted files found to decrypt."
    exit 0
fi

COUNT=$(echo "$ENCRYPTED_FILES" | wc -l | tr -d ' ')
echo "Decrypting $COUNT .env file(s)..."

echo "$ENCRYPTED_FILES" | while IFS= read -r encrypted_file; do
    stack_dir=$(dirname "$encrypted_file")
    stack_name=$(basename "$stack_dir")
    env_file="$stack_dir/.env"
    
    # Skip if .env already exists and is newer
    if [ -f "$env_file" ] && [ "$env_file" -nt "$encrypted_file" ]; then
        echo "  Skipping $stack_name - .env is up to date"
        continue
    fi
    
    # Decrypt the file
    # Use sh to execute and capture output for debugging
    OUTPUT=$(sh "$SCRIPT_DIR/decrypt-env.sh" "$stack_name" "$SECRET_KEY" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        echo "  ✓ Decrypted $stack_name"
    else
        echo "  ✗ Failed to decrypt $stack_name" >&2
        echo "    Error: $OUTPUT" >&2
    fi
done

echo "Done!"

