# PowerShell Profile Setup for Shell Script Support
# This script configures PowerShell to run .sh scripts directly
# Run: .\setup-powershell.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== PowerShell Shell Script Integration Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if Git Bash is installed
$bashPath = "C:\Program Files\Git\bin\bash.exe"
if (-not (Test-Path $bashPath)) {
    Write-Host "❌ Git Bash not found at $bashPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Git for Windows:" -ForegroundColor Yellow
    Write-Host "  https://git-scm.com/download/win" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "✓ Git Bash found" -ForegroundColor Green
Write-Host ""

# PowerShell profile content
$profileContent = @'

# ============================================
# Shell Script Support via Git Bash
# ============================================

function sh {
    <#
    .SYNOPSIS
    Run a shell script using Git Bash

    .EXAMPLE
    sh ./scripts/encrypt-env.sh outline
    sh "just encrypt-all"
    #>
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $bashPath = "C:\Program Files\Git\bin\bash.exe"

    if (Test-Path $bashPath) {
        # Join arguments and pass to bash
        $cmd = $Arguments -join ' '
        & $bashPath -c $cmd
    } else {
        Write-Error "Git Bash not found at $bashPath. Please install Git for Windows."
    }
}

# Just command runner
function just {
    <#
    .SYNOPSIS
    Run just commands

    .EXAMPLE
    just encrypt-all
    just decrypt outline
    #>
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    sh "just $Arguments"
}

# Encryption shortcuts
function Encrypt-Stack {
    <#
    .SYNOPSIS
    Encrypt a single stack

    .EXAMPLE
    Encrypt-Stack outline
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Stack
    )

    sh "./scripts/encrypt-env.sh $Stack"
}

function Decrypt-Stack {
    <#
    .SYNOPSIS
    Decrypt a single stack

    .EXAMPLE
    Decrypt-Stack outline
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Stack
    )

    sh "./scripts/decrypt-env.sh $Stack"
}

function Encrypt-AllStacks {
    <#
    .SYNOPSIS
    Encrypt all stacks

    .EXAMPLE
    Encrypt-AllStacks
    #>
    sh "just encrypt-all"
}

function Decrypt-AllStacks {
    <#
    .SYNOPSIS
    Decrypt all stacks

    .EXAMPLE
    Decrypt-AllStacks
    #>
    sh "just decrypt-all"
}

function Show-Stacks {
    <#
    .SYNOPSIS
    List all available stacks

    .EXAMPLE
    Show-Stacks
    #>
    sh "just list-stacks"
}

function Show-DeploymentStatus {
    <#
    .SYNOPSIS
    Show deployment status

    .EXAMPLE
    Show-DeploymentStatus
    #>
    sh "just status"
}

Write-Host "✓ Shell script integration loaded" -ForegroundColor Green
Write-Host "  Try: sh ./script.sh or just encrypt-all" -ForegroundColor Cyan
'@

# Create profile directory if it doesn't exist
$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) {
    Write-Host "Creating profile directory: $profileDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Check if profile exists
if (Test-Path $PROFILE) {
    Write-Host "Found existing PowerShell profile:" -ForegroundColor Yellow
    Write-Host "  $PROFILE" -ForegroundColor Cyan
    Write-Host ""

    # Check if our functions are already there
    $profileContent = Get-Content $PROFILE -Raw
    if ($profileContent -match "function sh") {
        Write-Host "⚠ Shell script integration already installed" -ForegroundColor Yellow
        Write-Host ""
        $update = Read-Host "Update anyway? (y/N)"

        if ($update -ne 'y' -and $update -ne 'Y') {
            Write-Host "Setup cancelled" -ForegroundColor Red
            exit 0
        }
    }

    # Backup existing profile
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$PROFILE.backup_$timestamp"
    Copy-Item $PROFILE $backupPath -Force
    Write-Host "✓ Existing profile backed up to:" -ForegroundColor Green
    Write-Host "  $backupPath" -ForegroundColor Cyan
    Write-Host ""
}

# Append to profile
Add-Content -Path $PROFILE -Value $profileContent

Write-Host "✓ PowerShell profile updated!" -ForegroundColor Green
Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart PowerShell" -ForegroundColor Cyan
Write-Host "  2. Try these commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "     # Check requirements" -ForegroundColor White
Write-Host "     PS> sh ./lib/infra-deploy-scripts/scripts/check-requirements.sh" -ForegroundColor Green
Write-Host ""
Write-Host "     # Encrypt all stacks" -ForegroundColor White
Write-Host "     PS> just encrypt-all" -ForegroundColor Green
Write-Host "     PS> Encrypt-AllStacks" -ForegroundColor Green
Write-Host ""
Write-Host "     # Encrypt specific stack" -ForegroundColor White
Write-Host "     PS> sh ./scripts/encrypt-env.sh outline" -ForegroundColor Green
Write-Host "     PS> Encrypt-Stack outline" -ForegroundColor Green
Write-Host ""
Write-Host "     # Decrypt all stacks" -ForegroundColor White
Write-Host "     PS> just decrypt-all" -ForegroundColor Green
Write-Host "     PS> Decrypt-AllStacks" -ForegroundColor Green
Write-Host ""
Write-Host "     # Show status" -ForegroundColor White
Write-Host "     PS> just status" -ForegroundColor Green
Write-Host "     PS> Show-DeploymentStatus" -ForegroundColor Green
Write-Host ""
Write-Host "For more information, see:" -ForegroundColor Yellow
Write-Host "  lib/infra-deploy-scripts/POWERSHELL_INTEGRATION.md" -ForegroundColor Cyan
Write-Host ""
