#!/bin/sh
# Automatically decrypt all .env.encrypted files in the repository
# This script is called by Git hooks after checkout/merge
# Usage: ./decrypt-all-env.sh [--debug|-d]

set -e

# Check for debug flag
DEBUG=0
for arg in "$@"; do
    case "$arg" in
        --debug|-d) DEBUG=1; shift ;;
    *) ;;
    esac
done

debug() {
    if [ "$DEBUG" = "1" ]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Get script directory (handle Windows backslashes from PowerShell)
SCRIPT_PATH="$0"
debug "Original script path: $SCRIPT_PATH"
# Convert backslashes to forward slashes
SCRIPT_PATH=$(echo "$SCRIPT_PATH" | tr '\\' '/')
debug "Normalized script path: $SCRIPT_PATH"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
debug "Script directory: $SCRIPT_DIR"
debug "Current directory: $(pwd)"

# Find the actual git repository root by traversing up from script location
# This works even when script is in a submodule and called via 'sh' from any directory
# We skip submodule .git files (which contain "gitdir:" text) to find the real repo
DIR="$SCRIPT_DIR"
while [ "$DIR" != "/" ]; do
    debug "Checking for git in: $DIR"
    # Check for .git directory (real repo) or file with content (submodule)
    if [ -d "$DIR/.git" ]; then
        REPO_ROOT="$DIR"
        debug "Found .git directory at: $DIR"
        break
    elif [ -f "$DIR/.git" ]; then
        # Check if it's a submodule .git file (contains "gitdir:")
        if grep -q "gitdir:" "$DIR/.git" 2>/dev/null; then
            # This is a submodule, continue up to find the real repo
            debug "Found submodule .git file at: $DIR, skipping"
        else
            # This is a regular file with .git name, use it
            REPO_ROOT="$DIR"
            debug "Found .git file at: $DIR"
            break
        fi
    fi
    DIR=$(dirname "$DIR")
done

# Fallback to script's parent directories if .git not found
if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$SCRIPT_DIR"
    debug "No .git found, using script directory as repo root"
fi

debug "Determined repo root: $REPO_ROOT"

# Change to repo root for operations
cd "$REPO_ROOT" || exit 1
debug "Changed to repo root, current dir: $(pwd)"
debug "Looking for .env.encrypted files in: $(pwd)/stacks"

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
# Use /usr/bin/find explicitly to avoid Windows find.exe which searches for text
FIND_CMD="find"
if [ -x "/usr/bin/find" ]; then
    FIND_CMD="/usr/bin/find"
fi

debug "Running: $FIND_CMD stacks -name '.env.encrypted' -type f"
debug "Current directory contents:"
debug "$(ls -la | head -10)"
ENCRYPTED_FILES=$($FIND_CMD stacks -name ".env.encrypted" -type f 2>/dev/null || true)

debug "find command exit code: $?"
debug "ENCRYPTED_FILES result: '$ENCRYPTED_FILES'"

if [ -z "$ENCRYPTED_FILES" ]; then
    debug "No .env.encrypted files found!"
    debug "Checking if stacks directory exists:"
    debug "$(ls -la stacks/ 2>&1 | head -10 || echo 'stacks directory not found')"
    echo "No .env.encrypted files found to decrypt."
    exit 0
fi

COUNT=$(echo "$ENCRYPTED_FILES" | wc -l | tr -d ' ')
echo "Decrypting $COUNT .env file(s)..."

FAILED=0
while IFS= read -r encrypted_file; do
    stack_dir=$(dirname "$encrypted_file")
    stack_name=$(basename "$stack_dir")
    env_file="$stack_dir/.env"
    
    # Skip if .env already exists and is newer
    if [ -f "$env_file" ] && [ "$env_file" -nt "$encrypted_file" ]; then
        echo "  Skipping $stack_name - .env is up to date"
        continue
    fi
    
    # Decrypt the file
    # Use bash to execute and capture output for debugging
    set +e
    OUTPUT=$(bash "$SCRIPT_DIR/decrypt-env.sh" "$stack_name" "$SECRET_KEY" 2>&1)
    EXIT_CODE=$?
    set -e
    if [ $EXIT_CODE -eq 0 ]; then
        echo "  ✓ Decrypted $stack_name"
    else
        echo "  ✗ Failed to decrypt $stack_name" >&2
        echo "$OUTPUT" | sed 's/^/    /' >&2
        FAILED=1
    fi
done <<EOF
$ENCRYPTED_FILES
EOF

if [ $FAILED -ne 0 ]; then
    echo "One or more stacks failed to decrypt." >&2
    exit 1
fi

echo "Done!"

