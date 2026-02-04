#!/bin/sh
# Script to encrypt .env file values using OpenSSL
# Usage: ./encrypt-env.sh <stack-name> [secret-key]
# If secret-key is not provided, it will be retrieved from key.env file or ENV_DECRYPTION_KEY environment variable
# The secret key should be shared only between you and Komodo
# This script encrypts ONLY the values, keeping keys visible in the format: KEY=ENCRYPTED:base64_value

set -e

# Get script directory (handle Windows backslashes from PowerShell)
SCRIPT_PATH="$0"
# Convert backslashes to forward slashes
SCRIPT_PATH=$(echo "$SCRIPT_PATH" | tr '\\' '/')
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Find the actual git repository root by traversing up from script location
# This works even when script is in a submodule and called via 'sh' from any directory
# We skip submodule .git files (which contain "gitdir:" text) to find the real repo
DIR="$SCRIPT_DIR"
while [ "$DIR" != "/" ]; do
    # Check for .git directory (real repo) or file with content (submodule)
    if [ -d "$DIR/.git" ]; then
        REPO_ROOT="$DIR"
        break
    elif [ -f "$DIR/.git" ]; then
        # Check if it's a submodule .git file (contains "gitdir:")
        if grep -q "gitdir:" "$DIR/.git" 2>/dev/null; then
            # This is a submodule, continue up to find the real repo
            :
        else
            # This is a regular file with .git name, use it
            REPO_ROOT="$DIR"
            break
        fi
    fi
    DIR=$(dirname "$DIR")
done

# Fallback to script's parent directories if .git not found
if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$SCRIPT_DIR"
fi

# Change to repo root for operations
cd "$REPO_ROOT" || exit 1

STACK_NAME=$1
SECRET_KEY="$2"
FORCE_ENCRYPT=""

# Handle flags
if [ "$STACK_NAME" = "--force" ]; then
    FORCE_ENCRYPT="--force"
    STACK_NAME="$2"
    SECRET_KEY="$3"
fi

if [ -z "$STACK_NAME" ]; then
    echo "Usage: $0 [--force] <stack-name> [secret-key]"
    echo "Example: $0 example-stack"
    echo "         $0 --force example-stack"
    echo "         $0 example-stack my-secret-key-123"
    exit 1
fi

# Get decryption key if not provided
if [ -z "$SECRET_KEY" ]; then
    SECRET_KEY=$("$SCRIPT_DIR/get-decryption-key.sh" 2>/dev/null || echo "")
fi

if [ -z "$SECRET_KEY" ]; then
    echo "Error: No secret key provided and no key found in key.env file or ENV_DECRYPTION_KEY environment variable" >&2
    echo ""
    echo "Either:" >&2
    echo "  1. Provide the key: $0 $STACK_NAME <key>" >&2
    echo "  2. Set up local key: ./scripts/setup-local-key.sh" >&2
    echo "  3. Set environment variable: export ENV_DECRYPTION_KEY='<key>'" >&2
    exit 1
fi

STACK_DIR="stacks/$STACK_NAME"
ENV_FILE="$STACK_DIR/.env"
ENCRYPTED_FILE="$STACK_DIR/.env.encrypted"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found"
    exit 1
fi

# Skip encryption if .env is older than .env.encrypted and hasn't changed
if [ -f "$ENCRYPTED_FILE" ] && [ -z "$FORCE_ENCRYPT" ]; then
    if [ "$ENV_FILE" -ot "$ENCRYPTED_FILE" ]; then
        echo "✓ Skipping: $ENV_FILE unchanged (older than $ENCRYPTED_FILE)"
        echo "  Use 'just encrypt --force $STACK_NAME' to force re-encryption"
        exit 0
    fi
fi

# Check if OpenSSL is available
# Try multiple methods to find openssl (compatible with sh)
OPENSSL_CMD=""
if command -v openssl >/dev/null 2>&1; then
    OPENSSL_CMD="openssl"
elif [ -x "/usr/bin/openssl" ]; then
    OPENSSL_CMD="/usr/bin/openssl"
elif [ -x "/usr/local/bin/openssl" ]; then
    OPENSSL_CMD="/usr/local/bin/openssl"
elif [ -x "/bin/openssl" ]; then
    OPENSSL_CMD="/bin/openssl"
fi

if [ -z "$OPENSSL_CMD" ]; then
    echo "Error: OpenSSL is not installed or not in PATH" >&2
    echo "Tried: openssl, /usr/bin/openssl, /usr/local/bin/openssl, /bin/openssl" >&2
    exit 1
fi

# Function to encrypt a value
encrypt_value() {
    local value="$1"

    # If value is already encrypted (starts with ENCRYPTED:), skip re-encryption
    case "$value" in
        ENCRYPTED:*)
            echo "$value"
            return
            ;;
    esac

    # Encrypt the value using OpenSSL
    # Use -base64 to get base64 output
    # Use -nopad to avoid padding issues
    local encrypted=$("$OPENSSL_CMD" enc -aes-256-cbc -salt -pbkdf2 -base64 -pass pass:"$SECRET_KEY" 2>/dev/null <<EOF
$value
EOF
)

    if [ $? -ne 0 ]; then
        echo "Error: Failed to encrypt value" >&2
        return 1
    fi

    # Remove newlines from base64 output to ensure single-line format
    encrypted=$(echo "$encrypted" | tr -d '\n')

    # Output the encrypted value with prefix
    echo "ENCRYPTED:$encrypted"
}

# Read .env file line by line and encrypt values
LINE_NUM=0
while IFS= read -r line || [ -n "$line" ]; do
    LINE_NUM=$((LINE_NUM + 1))

    # Skip empty lines
    case "$line" in
        ''|' '*|'	'*)
            echo "$line"
            continue
            ;;
    esac

    # Skip comment lines (lines starting with #)
    case "$line" in
        \#*)
            echo "$line"
            continue
            ;;
    esac

    # Check if line contains = sign
    case "$line" in
        *=*)
            # Split on first = sign to get key and value
            key="${line%%=*}"
            value="${line#*=}"

            # Encrypt the value
            encrypted_value=$(encrypt_value "$value")

            if [ $? -eq 0 ]; then
                echo "${key}=${encrypted_value}"
            else
                echo "Error: Failed to encrypt line $LINE_NUM: $line" >&2
                exit 1
            fi
            ;;
        *)
            # Line doesn't have = sign, keep as is
            echo "$line"
            ;;
    esac
done < "$ENV_FILE" > "$ENCRYPTED_FILE"

echo "Encrypted values in $ENV_FILE to $ENCRYPTED_FILE"
echo "Keys are visible, values are encrypted with ENCRYPTED: prefix"
echo "You can now safely commit $ENCRYPTED_FILE to the repository"
