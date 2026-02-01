# Automatically encrypt all .env files in the repository
# This script finds all .env files and encrypts them to .env.encrypted

param(
    [string]$SecretKey
)

$ErrorActionPreference = "Stop"

# Get encryption key if not provided
if (-not $SecretKey) {
    $SecretKey = & "$PSScriptRoot\get-decryption-key.ps1"
}

if (-not $SecretKey) {
    Write-Error "No encryption key found."
    Write-Host ""
    Write-Host "Run '.\scripts\setup-local-key.ps1' to configure your local key, or set ENV_DECRYPTION_KEY environment variable." -ForegroundColor Yellow
    exit 1
}

# Change to repo root directory
$repoRoot = Join-Path $PSScriptRoot ".."
Push-Location $repoRoot

try {
    # Find all .env files (but not .env.encrypted or .env.example)
    $envFiles = Get-ChildItem -Path "stacks" -Filter ".env" -Recurse -File |
        Where-Object {
            $_.Name -eq ".env" -and
            $_.FullName -notlike "*.encrypted" -and
            $_.FullName -notlike "*.example"
        }

    if ($envFiles.Count -eq 0) {
        Write-Host "No .env files found to encrypt."
        exit 0
    }

    Write-Host "Encrypting $($envFiles.Count) .env file(s)..."

    $successCount = 0
    $failCount = 0

    foreach ($envFile in $envFiles) {
        $stackDir = $envFile.DirectoryName
        $stackName = Split-Path -Leaf $stackDir
        $encryptedFile = Join-Path $stackDir ".env.encrypted"

        # Skip if .env.encrypted already exists and is newer
        if ((Test-Path $encryptedFile) -and ((Get-Item $encryptedFile).LastWriteTime -gt $envFile.LastWriteTime)) {
            Write-Host "  Skipping $stackName - .env.encrypted is up to date"
            continue
        }

        # Encrypt the file
        try {
            & "$PSScriptRoot\encrypt-env.ps1" -StackName $stackName -SecretKey $SecretKey | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Encrypted $stackName" -ForegroundColor Green
                $successCount++
            } else {
                Write-Warning "  Failed to encrypt $stackName"
                $failCount++
            }
        } catch {
            Write-Warning "  Failed to encrypt $stackName"
            Write-Warning "    Error: $_"
            $failCount++
        }
    }

    Write-Host ""
    Write-Host "Done! Encrypted: $successCount, Failed: $failCount"
}
finally {
    Pop-Location
}
