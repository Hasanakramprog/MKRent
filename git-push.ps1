# MK Rent - Git Push Script (PowerShell)
# Usage: .\git-push.ps1 [optional-commit-message]

param(
    [string]$CommitMessage = ""
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "         MK Rent - Git Push Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in a git repository!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "📋 Checking git status..." -ForegroundColor Yellow
git status

# Get commit message
if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
    Write-Host ""
    $CommitMessage = Read-Host "Enter commit message (or press Enter for auto-generated)"
    
    if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
        $timestamp = Get-Date -Format "dd/MM/yyyy HH:mm"
        $CommitMessage = "Updates - $timestamp"
    }
}

Write-Host ""
Write-Host "📁 Adding all changes to staging..." -ForegroundColor Yellow
git add .

Write-Host ""
Write-Host "💾 Committing with message: '$CommitMessage'" -ForegroundColor Yellow
$commitResult = git commit -m $CommitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ℹ️  No changes to commit." -ForegroundColor Blue
    Read-Host "Press Enter to exit"
    exit 0
}

Write-Host ""
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Yellow
git push origin main

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ Push failed! Please check your network connection and credentials." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "    ✅ Successfully pushed to GitHub!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Commit: '$CommitMessage'" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
