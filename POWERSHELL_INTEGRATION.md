# PowerShell Integration for Shell Scripts

This guide shows how to run `.sh` scripts directly from PowerShell without opening Git Bash separately.

## Option 1: Using Git Bash from PowerShell (Recommended)

Git Bash can be invoked directly from PowerShell to run shell scripts.

### Quick Setup

Create a PowerShell profile function to run shell scripts easily:

**Add to your PowerShell profile (`$PROFILE`):**

```powershell
# Function to run shell scripts via Git Bash
function sh {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $bashPath = "C:\Program Files\Git\bin\bash.exe"

    if (Test-Path $bashPath) {
        & $bashPath -c @Arguments
    } else {
        Write-Error "Git Bash not found at $bashPath. Please install Git for Windows."
    }
}

# Alias for just
function just {
    sh "just $args"
}
```

**Then you can run:**

```powershell
# Run shell scripts directly
PS> ./scripts/encrypt-env.sh outline

# Or use the sh function
PS> sh ./scripts/encrypt-env.sh outline

# Use just commands
PS> just encrypt-all
PS> just decrypt-all
```

## Option 2: Add .SH to PATHEXT (Make scripts executable)

You can configure Windows to treat `.sh` files as executable by adding them to the PATHEXT environment variable.

### One-Time Setup

```powershell
# Add .sh to PATHEXT (run as Administrator)
$pathext = [Environment]::GetEnvironmentVariable("PATHEXT", "Machine")
$pathext += ";.SH"
[Environment]::SetEnvironmentVariable("PATHEXT", $pathext, "Machine")
```

Then create a registry entry to associate `.sh` files with Git Bash:

```powershell
# Create file association (run as Administrator)
New-Item -Path "HKCU:\Software\Classes\.sh" -Value "sh.file" -Force
New-Item -Path "HKCU:\Software\Classes\sh.file\shell\open\command" -Value '"C:\Program Files\Git\bin\bash.exe" "%1" %*' -Force
```

**Now you can run:**

```powershell
PS> ./scripts/encrypt-env.sh outline
```

**Note:** You may need to restart PowerShell for changes to take effect.

## Option 3: Create PowerShell Wrapper Scripts

Create simple PowerShell wrappers that call the shell scripts:

**Create `scripts/Encrypt-Env.ps1`:**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$StackName,

    [string]$SecretKey
)

$bashPath = "C:\Program Files\Git\bin\bash.exe"
$scriptPath = Join-Path $PSScriptRoot "encrypt-env.sh"

& $bashPath $scriptPath $StackName $SecretKey
```

**Then run from PowerShell:**

```powershell
PS> ./scripts/Encrypt-Env.ps1 -StackName outline
```

**Pros:**
- PowerShell-style parameters with tab completion
- Can add parameter validation
- Familiar to PowerShell users

**Cons:**
- Need to maintain wrapper scripts
- Defeats the purpose of single script set

## Option 4: Use a PowerShell Module

Create a reusable PowerShell module:

**Create `InfraDeploy.psm1`:**

```powershell
$bashPath = "C:\Program Files\Git\bin\bash.exe"

function Invoke-ShellScript {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $fullPath = Resolve-Path $ScriptPath
    & $bashPath -c "`"$fullPath`" $Arguments"
}

function Encrypt-Env {
    param(
        [Parameter(Mandatory=$true)]
        [string]$StackName,

        [string]$SecretKey
    )

    $scriptPath = Join-Path $PSScriptRoot "scripts/encrypt-env.sh"
    Invoke-ShellScript $scriptPath $StackName $SecretKey
}

function Decrypt-Env {
    param(
        [Parameter(Mandatory=$true)]
        [string]$StackName,

        [string]$SecretKey
    )

    $scriptPath = Join-Path $PSScriptRoot "scripts/decrypt-env.sh"
    Invoke-ShellScript $scriptPath $StackName $SecretKey
}

function Invoke-JustCommand {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    & $bashPath -c "just $Arguments"
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-ShellScript',
    'Encrypt-Env',
    'Decrypt-Env',
    'Invoke-JustCommand'
)
```

**Install and use:**

```powershell
# Copy to PowerShell modules path
Copy-Item InfraDeploy.psm1 $env:USERPROFILE\Documents\WindowsPowerShell\Modules\InfraDeploy\

# Import module
Import-Module InfraDeploy

# Use functions
PS> Encrypt-Env -StackName outline
PS> Decrypt-Env -StackName outline
PS> Invoke-JustCommand encrypt-all
```

## Option 5: Direct Bash Invocation (Simplest)

Just call bash directly with the script:

```powershell
PS> bash ./scripts/encrypt-env.sh outline
```

Or if `bash` is in your PATH:

```powershell
PS> sh ./scripts/encrypt-env.sh outline
```

**Pros:**
- No setup required
- Works immediately if Git Bash is installed

**Cons:**
- Need to type `bash` or `sh` every time
- No tab completion for script parameters

## Recommended Approach

**For most users:** Use **Option 1** (PowerShell profile function)

It provides:
- Simple one-time setup
- Clean syntax: `sh ./script.sh args`
- Works with any shell script
- Easy to use just commands

**For developers:** Use **Option 2** (PATHEXT modification)

It provides:
- Native `./script.sh` execution
- Most Unix-like experience
- Works with tab completion

**For team consistency:** Stick with Git Bash

If your team uses both PowerShell and Git Bash, consider:
1. Documenting both approaches
2. Recommending Git Bash for consistency
3. Providing PowerShell wrapper for convenience

## PowerShell Profile Setup Script

**Save as `setup-powershell.ps1`:**

```powershell
# PowerShell Profile Setup for Shell Script Support
# Run: .\setup-powershell.ps1

$profileContent = @'
# Shell script support via Git Bash
function sh {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $bashPath = "C:\Program Files\Git\bin\bash.exe"

    if (Test-Path $bashPath) {
        & $bashPath -c @Arguments
    } else {
        Write-Error "Git Bash not found at $bashPath. Please install Git for Windows."
    }
}

# Just command runner
function just {
    sh "just $args"
}

# Encryption shortcuts
function Encrypt-Stack {
    param([string]$Stack)
    sh "./scripts/encrypt-env.sh $Stack"
}

function Decrypt-Stack {
    param([string]$Stack)
    sh "./scripts/decrypt-env.sh $Stack"
}

function Encrypt-AllStacks {
    sh "just encrypt-all"
}

function Decrypt-AllStacks {
    sh "just decrypt-all"
}
'@

# Create profile directory if it doesn't exist
$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Backup existing profile
if (Test-Path $PROFILE) {
    $backupPath = "$PROFILE.backup"
    Copy-Item $PROFILE $backupPath -Force
    Write-Host "Existing profile backed up to: $backupPath" -ForegroundColor Yellow
}

# Append to profile
Add-Content -Path $PROFILE -Value $profileContent

Write-Host "PowerShell profile updated!" -ForegroundColor Green
Write-Host "Restart PowerShell and try:"
Write-Host "  PS> sh ./scripts/encrypt-env.sh outline"
Write-Host "  PS> just encrypt-all"
Write-Host "  PS> Encrypt-Stack outline"
```

**Run it:**

```powershell
PS> .\setup-powershell.ps1
PS> # Restart PowerShell
PS> sh ./scripts/encrypt-env.sh outline
```

## Verification

Test that your setup works:

```powershell
# Test basic shell execution
PS> bash --version
PS> sh --version

# Test script execution
PS> sh ./scripts/check-requirements.sh

# Test just
PS> just --list

# Test encryption
PS> sh ./scripts/encrypt-env.sh outline
```

## Troubleshooting

### "bash: command not found"

Make sure Git for Windows is installed and in your PATH:

```powershell
PS> $env:PATH -split ';' | Select-String git
```

If not found, install Git for Windows from https://git-scm.com/download/win

### "Scripts won't run"

Check file permissions (shouldn't matter on Windows):

```powershell
PS> Get-Content .\scripts\encrypt-env.sh | Select-Object -First 1
```

Should show `#!/bin/sh`

### Path issues with Git Bash

Git Bash uses Unix-style paths. If you have path issues:

```powershell
# Use relative paths
PS> sh ./scripts/encrypt-env.sh outline

# Or convert Windows path to Git Bash path
$wslPath = "C:\Users\Name\Project" -replace '^C:', '/c' -replace '\\', '/'
```

## Comparison

| Option | Setup | UX | Maintenance |
|--------|-------|-----|-------------|
| Git Bash UI | None | ⭐⭐⭐ | None |
| PS Profile Function | Low | ⭐⭐⭐⭐ | None |
| PATHEXT Modification | Medium | ⭐⭐⭐⭐⭐ | None |
| PowerShell Wrappers | High | ⭐⭐ | High |
| PowerShell Module | Medium | ⭐⭐⭐⭐ | Low |
| Direct bash call | None | ⭐⭐ | None |

## Recommendation

**For Windows users who prefer PowerShell:**

Use the PowerShell profile function approach (Option 1). It's:
- Simple to set up
- Works with all scripts
- Easy to maintain
- No duplicate scripts needed

**For teams:**

Document both approaches and let users choose:
1. Use Git Bash for full Unix experience
2. Use PowerShell with profile functions for convenience

Either way, you only need to maintain the `.sh` scripts!
