#!/bin/sh
# Script to decrypt .env files using OpenSSL
# This version decrypts only the values while keeping keys visible
# Format in encrypted file: KEY=ENCRYPTED:base64_encrypted_value
# Usage: ./decrypt-env.sh <stack-name> [secret-key]
# If secret-key is not provided, it will be retrieved from key.env file or ENV_DECRYPTION_KEY environment variable

set -e

# Get script directory (compatible with sh)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

STACK_NAME=$1
SECRET_KEY="$2"

if [ -z "$STACK_NAME" ]; then
    echo "Usage: $0 <stack-name> [secret-key]"
    echo "Example: $0 example-stack"
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
ENCRYPTED_FILE="$STACK_DIR/.env.encrypted"
ENV_FILE="$STACK_DIR/.env"

if [ ! -f "$ENCRYPTED_FILE" ]; then
    echo "Error: $ENCRYPTED_FILE not found"
    exit 1
fi

# Check if OpenSSL is available
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

# Function to decrypt a base64-encoded value
decrypt_value() {
    encrypted_b64="$1"

    # Handle empty encrypted values
    if [ -z "$encrypted_b64" ]; then
        return 1
    fi

    # Remove any whitespace, newlines, or carriage returns from base64 string
    # This handles both single-line and multi-line base64 formats
    encrypted_b64=$(echo "$encrypted_b64" | tr -d '[:space:]\r\n')

    # Handle empty value after cleaning
    if [ -z "$encrypted_b64" ]; then
        return 1
    fi

    # Validate SECRET_KEY is not empty
    if [ -z "$SECRET_KEY" ]; then
        echo "Error: SECRET_KEY is empty or not set" >&2
        return 1
    fi

    # Decode base64 to binary, then decrypt with OpenSSL
    # Use base64 -d for decoding (most systems) or base64 -D (older macOS)
    if echo "$encrypted_b64" | base64 -d >/dev/null 2>&1; then
        echo "$encrypted_b64" | base64 -d | "$OPENSSL_CMD" enc -aes-256-cbc -d -pbkdf2 -pass pass:"$SECRET_KEY" 2>/dev/null
    elif echo "$encrypted_b64" | base64 -D >/dev/null 2>&1; then
        echo "$encrypted_b64" | base64 -D | "$OPENSSL_CMD" enc -aes-256-cbc -d -pbkdf2 -pass pass:"$SECRET_KEY" 2>/dev/null
    else
        return 1
    fi
}

# Process the encrypted file line by line
# Create temporary file for output
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Read the encrypted file and process each line
# Strip carriage returns (\r) that may be present from Windows line endings
while IFS= read -r line || [ -n "$line" ]; do
    # Remove carriage return characters from Windows line endings
    line=$(echo "$line" | tr -d '\r')
    # Skip empty lines and comments
    if [ -z "$line" ] || echo "$line" | grep -q '^[[:space:]]*#'; then
        echo "$line" >> "$TEMP_FILE"
        continue
    fi

    # Split on first '=' to get key and encrypted value
    key="${line%%=*}"
    value="${line#*=}"

    # Check if the value starts with "ENCRYPTED:"
    if echo "$value" | grep -q "^ENCRYPTED:"; then
        # Extract the base64 encrypted value (remove "ENCRYPTED:" prefix)
        encrypted_b64="${value#ENCRYPTED:}"

        # Handle empty encrypted values (KEY=ENCRYPTED: with nothing after)
        if [ -z "$encrypted_b64" ]; then
            echo "Warning: Empty encrypted value for key: $key, writing empty value" >&2
            echo "$key=" >> "$TEMP_FILE"
            continue
        fi

        # Decrypt the value
        decrypted_value=$(decrypt_value "$encrypted_b64" 2>/dev/null)

        if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
            echo "$key=$decrypted_value" >> "$TEMP_FILE"
        elif [ -z "$decrypted_value" ]; then
            # Decryption succeeded but returned empty value
            echo "Warning: Decrypted empty value for key: $key, writing empty value" >&2
            echo "$key=" >> "$TEMP_FILE"
        else
            echo "Error: Failed to decrypt value for key: $key" >&2
            echo "This could be due to:" >&2
            echo "  - Incorrect decryption key" >&2
            echo "  - Corrupted encrypted data" >&2
            echo "  - Empty encrypted value" >&2
            rm -f "$TEMP_FILE"
            exit 1
        fi
    else
        # Not an encrypted value, keep as-is (for backward compatibility)
        echo "$line" >> "$TEMP_FILE"
    fi
done < "$ENCRYPTED_FILE"

# Move temporary file to the target .env file
mv "$TEMP_FILE" "$ENV_FILE"

echo "Decrypted $ENCRYPTED_FILE to $ENV_FILE"
