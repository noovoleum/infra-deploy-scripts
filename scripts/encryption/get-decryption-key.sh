#!/bin/sh
# Helper script to get the decryption key from various sources
# Priority: Environment variable > Local key.env file

KEY_FILE="${1:-key.env}"

# First, try environment variable
if [ -n "$ENV_DECRYPTION_KEY" ]; then
    echo "$ENV_DECRYPTION_KEY"
    exit 0
fi

# Second, try local key.env file (standard env file format, not committed to repo)
if [ -f "$KEY_FILE" ]; then
    # Parse ENV_DECRYPTION_KEY from key.env file (handles KEY=value format)
    KEY=$(grep -E '^ENV_DECRYPTION_KEY=' "$KEY_FILE" 2>/dev/null | sed 's/^ENV_DECRYPTION_KEY=//' | tr -d '\n\r' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')
    if [ -n "$KEY" ]; then
        echo "$KEY"
        exit 0
    fi
fi

# If no key found, return empty (caller should handle this)
exit 1

