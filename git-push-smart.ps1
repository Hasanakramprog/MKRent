# MK Rent - Smart Git Push Script
# Automatically detects changes and suggests meaningful commit messages

param(
    [string]$CommitMessage = ""
)

function Get-SmartCommitMessage {
    $status = git status --porcelain
    $changes = @()
    
    # Analyze different types of changes
    $newFiles = $status | Where-Object { $_ -match "^A " }
    $modifiedFiles = $status | Where-Object { $_ -match "^M " }
    $deletedFiles = $status | Where-Object { $_ -match "^D " }
    
    # Check for specific file patterns
    $screenFiles = $status | Where-Object { $_ -match "screen" }
    $modelFiles = $status | Where-Object { $_ -match "model" }
    $serviceFiles = $status | Where-Object { $_ -match "service" }
    $widgetFiles = $status | Where-Object { $_ -match "widget" }
    
    # Generate smart suggestions
    if ($screenFiles) { $changes += "UI updates" }
    if ($modelFiles) { $changes += "data model changes" }
    if ($serviceFiles) { $changes += "service improvements" }
    if ($widgetFiles) { $changes += "widget enhancements" }
    if ($newFiles) { $changes += "new features" }
    if ($deletedFiles) { $changes += "cleanup" }
    
    if ($changes.Count -eq 0) {
        return "General improvements and updates"
    }
    
    return ($changes -join ", ") + " - " + (Get-Date -Format "dd/MM/yyyy")
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      MK Rent - Smart Git Push" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in a git repository!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check for changes
Write-Host "🔍 Analyzing changes..." -ForegroundColor Yellow
git add .

# Check if there are changes to commit
git diff --cached --quiet
$hasChanges = $LASTEXITCODE -ne 0

if (-not $hasChanges) {
    Write-Host "ℹ️  No changes to commit." -ForegroundColor Blue
    Read-Host "Press Enter to exit"
    exit 0
}

# Show status
Write-Host ""
Write-Host "📋 Current status:" -ForegroundColor Yellow
git status --short

# Get or suggest commit message
if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
    $smartMessage = Get-SmartCommitMessage
    Write-Host ""
    Write-Host "💡 Suggested commit message: " -ForegroundColor Magenta -NoNewline
    Write-Host "$smartMessage" -ForegroundColor White
    Write-Host ""
    
    $userInput = Read-Host "Press Enter to use suggested message, or type your own"
    
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $CommitMessage = $smartMessage
    } else {
        $CommitMessage = $userInput
    }
}

Write-Host ""
Write-Host "💾 Committing changes..." -ForegroundColor Yellow
Write-Host "Message: '$CommitMessage'" -ForegroundColor Gray

git commit -m $CommitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Commit failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Yellow
git push origin main

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Push failed! Check your connection and credentials." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "    ✅ Successfully pushed to GitHub!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "📝 Commit: '$CommitMessage'" -ForegroundColor Green
Write-Host "🌐 Repository: MKRent" -ForegroundColor Green
Write-Host ""
Read-Host "✨ All done! Press Enter to exit"
