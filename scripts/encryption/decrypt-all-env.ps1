# Automatically decrypt all .env.encrypted files in the repository
# This script is called by Git hooks after checkout/merge

param(
    [string]$SecretKey
)

$ErrorActionPreference = "SilentlyContinue"

# Get decryption key
if (-not $SecretKey) {
    $SecretKey = & "$PSScriptRoot\get-decryption-key.ps1"
}

if (-not $SecretKey) {
    Write-Warning "No decryption key found. Skipping automatic decryption."
    Write-Warning "Run '.\scripts\setup-local-key.ps1' to configure your local key, or set ENV_DECRYPTION_KEY environment variable."
    exit 0
}

# Change to repo root directory
$repoRoot = Join-Path $PSScriptRoot ".."
Push-Location $repoRoot

try {
    # Find all .env.encrypted files
    $encryptedFiles = Get-ChildItem -Path "stacks" -Filter ".env.encrypted" -Recurse -File

    if ($encryptedFiles.Count -eq 0) {
        Write-Host "No .env.encrypted files found to decrypt."
        exit 0
    }

    Write-Host "Decrypting $($encryptedFiles.Count) .env file(s)..."

    $successCount = 0
    $failCount = 0

    foreach ($encryptedFile in $encryptedFiles) {
        $stackDir = $encryptedFile.DirectoryName
        $stackName = Split-Path -Leaf $stackDir
        $envFile = Join-Path $stackDir ".env"

        # Skip if .env already exists and is newer
        if ((Test-Path $envFile) -and ((Get-Item $envFile).LastWriteTime -gt $encryptedFile.LastWriteTime)) {
            Write-Host "  Skipping $stackName - .env is up to date"
            continue
        }

        # Decrypt the file
        & "$PSScriptRoot\decrypt-env.ps1" -StackName $stackName -SecretKey $SecretKey | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Decrypted $stackName" -ForegroundColor Green
            $successCount++
        } else {
            Write-Warning "  Failed to decrypt $stackName"
            $failCount++
        }
    }

    Write-Host ""
    Write-Host "Done! Decrypted: $successCount, Failed: $failCount"
}
finally {
    Pop-Location
}
