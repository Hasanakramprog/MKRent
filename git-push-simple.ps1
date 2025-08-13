# MK Rent - Simple Smart Git Push Script
param([string]$CommitMessage = "")

function Get-SmartCommitMessage {
    $status = git status --porcelain
    $changes = @()
    
    if ($status -match "screen") { $changes += "UI updates" }
    if ($status -match "model") { $changes += "data model changes" }
    if ($status -match "service") { $changes += "service improvements" }
    if ($status -match "widget") { $changes += "widget enhancements" }
    if ($status -match "^A") { $changes += "new features" }
    if ($status -match "^D") { $changes += "cleanup" }
    
    if ($changes.Count -eq 0) {
        return "General improvements and updates"
    }
    
    return ($changes -join ", ") + " - " + (Get-Date -Format "dd/MM/yyyy")
}

Write-Host "=========================================="
Write-Host "      MK Rent - Smart Git Push"
Write-Host "=========================================="

# Check if in git repo
if (!(Test-Path ".git")) {
    Write-Host "Error: Not in a git repository!" -ForegroundColor Red
    pause
    exit 1
}

# Add all changes
Write-Host "Adding changes..." -ForegroundColor Yellow
git add .

# Check if there are changes
$gitStatus = git status --porcelain
if (!$gitStatus) {
    Write-Host "No changes to commit." -ForegroundColor Blue
    pause
    exit 0
}

# Show current status
Write-Host ""
Write-Host "Current changes:" -ForegroundColor Yellow
git status --short

# Get commit message
if (!$CommitMessage) {
    $smartMessage = Get-SmartCommitMessage
    Write-Host ""
    Write-Host "Suggested: $smartMessage" -ForegroundColor Magenta
    $userInput = Read-Host "Press Enter to use suggested message, or type your own"
    
    if (!$userInput) {
        $CommitMessage = $smartMessage
    } else {
        $CommitMessage = $userInput
    }
}

# Commit
Write-Host ""
Write-Host "Committing: '$CommitMessage'" -ForegroundColor Yellow
git commit -m $CommitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host "Commit failed!" -ForegroundColor Red
    pause
    exit 1
}

# Push
Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
git push origin main

if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed!" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
Write-Host "Commit: '$CommitMessage'"
pause
