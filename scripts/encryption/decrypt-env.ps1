# PowerShell script to decrypt .env files using OpenSSL
# Only values are encrypted; keys remain visible
# Usage: .\decrypt-env.ps1 -StackName <stack-name> [-SecretKey <secret-key>]
# If SecretKey is not provided, it will be retrieved from key.env file or ENV_DECRYPTION_KEY environment variable
# This is used by Komodo during deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$StackName,

    [Parameter(Mandatory=$false)]
    [string]$SecretKey
)

# Get decryption key if not provided
if (-not $SecretKey) {
    $SecretKey = & "$PSScriptRoot\get-decryption-key.ps1"
}

if (-not $SecretKey) {
    Write-Error "Error: No secret key provided and no key found in key.env file or ENV_DECRYPTION_KEY environment variable"
    Write-Host ""
    Write-Host "Either:" -ForegroundColor Yellow
    Write-Host "  1. Provide the key: .\decrypt-env.ps1 -StackName $StackName -SecretKey <key>" -ForegroundColor White
    Write-Host "  2. Set up local key: .\scripts\setup-local-key.ps1" -ForegroundColor White
    Write-Host "  3. Set environment variable: `$env:ENV_DECRYPTION_KEY = '<key>'" -ForegroundColor White
    exit 1
}

$StackDir = "stacks\$StackName"
$EncryptedFile = "$StackDir\.env.encrypted"
$EnvFile = "$StackDir\.env"

if (-not (Test-Path $EncryptedFile)) {
    Write-Error "Error: $EncryptedFile not found"
    exit 1
}

# Check if OpenSSL is available
$opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
if (-not $opensslPath) {
    Write-Error "Error: OpenSSL is not installed or not in PATH"
    exit 1
}

# Read the encrypted .env file line by line
$lines = Get-Content $EncryptedFile
$decryptedLines = @()

foreach ($line in $lines) {
    # Skip empty lines and comments
    if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith('#')) {
        $decryptedLines += $line
        continue
    }

    # Split line by first '=' to get key and encrypted value
    $firstEqualIndex = $line.IndexOf('=')
    if ($firstEqualIndex -eq -1) {
        # No equals sign, keep line as-is
        $decryptedLines += $line
        continue
    }

    $key = $line.Substring(0, $firstEqualIndex)
    $value = $line.Substring($firstEqualIndex + 1)

    # Check if value is encrypted (starts with ENCRYPTED:)
    if ($value.StartsWith('ENCRYPTED:')) {
        # Extract the base64-encoded encrypted value
        $encryptedBase64 = $value.Substring(10) # Remove 'ENCRYPTED:' prefix

        try {
            # Decode base64 to bytes
            $encryptedBytes = [Convert]::FromBase64String($encryptedBase64)

            # Create a temporary file for OpenSSL to decrypt
            $tempInput = [System.IO.Path]::GetTempFileName()
            $tempOutput = [System.IO.Path]::GetTempFileName()

            # Write encrypted bytes to temp file
            [System.IO.File]::WriteAllBytes($tempInput, $encryptedBytes)

            # Decrypt using OpenSSL
            & openssl enc -aes-256-cbc -d -pbkdf2 -in $tempInput -out $tempOutput -pass pass:$SecretKey 2>$null

            if ($LASTEXITCODE -eq 0) {
                # Read decrypted value and remove any trailing newlines
                $decryptedValue = Get-Content $tempOutput -Raw
                $decryptedValue = $decryptedValue.Trim()
                $decryptedLines += "$key=$decryptedValue"
            } else {
                Write-Warning "Warning: Failed to decrypt value for key '$key'. Keeping encrypted value."
                $decryptedLines += $line
            }

            # Clean up temp files
            Remove-Item $tempInput -Force -ErrorAction SilentlyContinue
            Remove-Item $tempOutput -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "Warning: Error decrypting value for key '$key': $($_.Exception.Message). Keeping encrypted value."
            $decryptedLines += $line
        }
    } else {
        # Value is not encrypted, keep as-is
        $decryptedLines += $line
    }
}

# Write decrypted content to .env file
$decryptedLines | Out-File -FilePath $EnvFile -Encoding UTF8

Write-Host "Decrypted $EncryptedFile to $EnvFile"
