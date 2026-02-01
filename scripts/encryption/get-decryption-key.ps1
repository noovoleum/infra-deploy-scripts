# Helper script to get the decryption key from various sources
# Priority: Environment variable > Local key.env file

param(
    [string]$KeyFile = "key.env"
)

# First, try environment variable
$key = $env:ENV_DECRYPTION_KEY

if ($key) {
    return $key
}

# Second, try local key.env file (standard env file format, not committed to repo)
if (Test-Path $KeyFile) {
    # Parse ENV_DECRYPTION_KEY from key.env file (handles KEY=value format)
    $content = Get-Content $KeyFile -ErrorAction SilentlyContinue
    foreach ($line in $content) {
        if ($line -match '^ENV_DECRYPTION_KEY=(.*)$') {
            $key = $matches[1].Trim()
            # Remove surrounding quotes if present
            $key = $key -replace '^["'']|["'']$', ''
    if ($key) {
        return $key
            }
        }
    }
}

# If no key found, return empty (caller should handle this)
return $null

