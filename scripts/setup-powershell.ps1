# PowerShell WSL Integration Setup
# This script configures PowerShell to run infra-deploy-scripts via WSL
# Run: .\setup-powershell.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== PowerShell WSL Integration Setup ===" -ForegroundColor Cyan
Write-Host ""

if ($env:OS -ne "Windows_NT") {
    Write-Host "This script is intended for Windows PowerShell." -ForegroundColor Yellow
    Write-Host "If you are on Linux/macOS, use the bash setup script instead." -ForegroundColor Yellow
    exit 1
}

$wslExe = Get-Command wsl.exe -ErrorAction SilentlyContinue
if (-not $wslExe) {
    Write-Host "WSL not found. WSL is required for infra-deploy-scripts." -ForegroundColor Red
    Write-Host "Install WSL (PowerShell as Administrator):" -ForegroundColor Yellow
    Write-Host "  wsl --install" -ForegroundColor Cyan
    Write-Host "Docs: https://learn.microsoft.com/windows/wsl/install" -ForegroundColor Cyan
    exit 1
}

$wslList = & $wslExe.Source -l -q 2>$null
if (-not $wslList) {
    Write-Host "WSL is installed but no distributions were found." -ForegroundColor Red
    Write-Host "Install a distro, then re-run this setup." -ForegroundColor Yellow
    exit 1
}

Write-Host "OK: WSL detected" -ForegroundColor Green
Write-Host "This setup will add PowerShell helpers that run commands inside WSL." -ForegroundColor Green
Write-Host ""

# PowerShell profile content
$profileContent = @'

# ============================================
# infra-deploy-scripts via WSL
# ============================================

function wslsh {
    <#
    .SYNOPSIS
    Run a command in WSL from the current Windows directory

    .EXAMPLE
    wslsh ./lib/infra-deploy-scripts/scripts/setup.sh
    wslsh "just decrypt-all"
    #>
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $wslExe = "wsl.exe"
    $cmd = $Arguments -join ' '
    if (-not $cmd) { return }

    $cwd = (Get-Location).Path
    $wslCwd = & $wslExe wslpath -a -u $cwd 2>$null
    if (-not $wslCwd) { $wslCwd = "~" }

    & $wslExe bash -lc "cd \"$wslCwd\" && $cmd"
}

Set-Alias sh wslsh

function just {
    <#
    .SYNOPSIS
    Run just commands in WSL

    .EXAMPLE
    just decrypt-all
    just encrypt outline
    #>
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $cmd = "just"
    if ($Arguments) {
        $cmd = "just " + ($Arguments -join ' ')
    }
    wslsh $cmd
}

function Encrypt-Stack {
    <#
    .SYNOPSIS
    Encrypt a single stack via just
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Stack
    )

    wslsh "just encrypt $Stack"
}

function Decrypt-Stack {
    <#
    .SYNOPSIS
    Decrypt a single stack via just
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Stack
    )

    wslsh "just decrypt $Stack"
}

function Encrypt-AllStacks {
    <#
    .SYNOPSIS
    Encrypt all stacks via just
    #>
    wslsh "just encrypt-all"
}

function Decrypt-AllStacks {
    <#
    .SYNOPSIS
    Decrypt all stacks via just
    #>
    wslsh "just decrypt-all"
}

function Show-Stacks {
    <#
    .SYNOPSIS
    List available stacks
    #>
    wslsh "just list-stacks"
}

function Show-DeploymentStatus {
    <#
    .SYNOPSIS
    Show repository status via just
    #>
    wslsh "just status"
}

Write-Host "OK: WSL helpers loaded" -ForegroundColor Green
Write-Host "Try: sh ./lib/infra-deploy-scripts/scripts/setup.sh" -ForegroundColor Cyan
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

    $existingProfile = Get-Content $PROFILE -Raw
    if ($existingProfile -match "function wslsh") {
        Write-Host "WSL helpers already installed" -ForegroundColor Yellow
        Write-Host ""
        $update = Read-Host "Update anyway? (y/N)"

        if ($update -ne 'y' -and $update -ne 'Y') {
            Write-Host "Setup cancelled" -ForegroundColor Red
            exit 0
        }
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$PROFILE.backup_$timestamp"
    Copy-Item $PROFILE $backupPath -Force
    Write-Host "OK: Existing profile backed up to:" -ForegroundColor Green
    Write-Host "  $backupPath" -ForegroundColor Cyan
    Write-Host ""
}

Add-Content -Path $PROFILE -Value $profileContent

Write-Host "OK: PowerShell profile updated" -ForegroundColor Green
Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart PowerShell" -ForegroundColor Cyan
Write-Host "  2. From your repo root, run:" -ForegroundColor Cyan
Write-Host ""
Write-Host "     # One-time setup in WSL" -ForegroundColor White
Write-Host "     PS> sh ./lib/infra-deploy-scripts/scripts/setup.sh" -ForegroundColor Green
Write-Host ""
Write-Host "     # Key setup" -ForegroundColor White
Write-Host "     PS> just setup-key" -ForegroundColor Green
Write-Host ""
Write-Host "     # Decrypt all stacks" -ForegroundColor White
Write-Host "     PS> just decrypt-all" -ForegroundColor Green
Write-Host ""
Write-Host "For more info, see README.md" -ForegroundColor Yellow
Write-Host ""
