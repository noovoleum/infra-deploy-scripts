# Check PowerShell Profile Location
# This script shows where your PowerShell profile is located

Write-Host "=== PowerShell Profile Locations ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Current Profile:" -ForegroundColor Yellow
Write-Host "  $PROFILE" -ForegroundColor White
Write-Host "  " (Resolve-Path $PROFILE -ErrorAction SilentlyContinue) -ForegroundColor Cyan
Write-Host ""

Write-Host "Profile Variables:" -ForegroundColor Yellow
Write-Host "  $PROFILE.CurrentUserCurrentHost:  $PROFILE.CurrentUserCurrentHost" -ForegroundColor White
Write-Host "  $PROFILE.CurrentUserAllHosts:    $PROFILE.CurrentUserAllHosts" -ForegroundColor White
Write-Host "  $PROFILE.AllUsersCurrentHost:     $PROFILE.AllUsersCurrentHost" -ForegroundColor White
Write-Host "  $PROFILE.AllUsersAllHosts:        $PROFILE.AllUsersAllHosts" -ForegroundColor White
Write-Host ""

Write-Host "Profile Exists?" -ForegroundColor Yellow
Write-Host "  Current: " -NoNewline
if (Test-Path $PROFILE) {
    Write-Host "Yes ✓" -ForegroundColor Green
    Write-Host "  Size: $((Get-Item $PROFILE).Length) bytes"
    Write-Host "  Last Modified: $((Get-Item $PROFILE).LastWriteTime)"
} else {
    Write-Host "No ✗" -ForegroundColor Red
    Write-Host "  Run: New-Item -Path $PROFILE -ItemType File -Force"
}
Write-Host ""

Write-Host "View Profile Contents:" -ForegroundColor Yellow
Write-Host "  Get-Content $PROFILE" -ForegroundColor Cyan
Write-Host ""

Write-Host "Edit Profile:" -ForegroundColor Yellow
Write-Host "  notepad $PROFILE" -ForegroundColor Cyan
Write-Host "  code $PROFILE" -ForegroundColor Cyan
Write-Host "  ise $PROFILE" -ForegroundColor Cyan
Write-Host ""
