# Advanced Git Push Script with Technical Analysis
param([string]$CommitMessage = "")

function Get-TechnicalCommitMessage {
    $changedFiles = git diff --name-only HEAD
    $stagedFiles = git diff --cached --name-only
    $untrackedFiles = git ls-files --others --exclude-standard
    
    $allFiles = @()
    if ($stagedFiles) { $allFiles += $stagedFiles }
    if ($changedFiles) { $allFiles += $changedFiles }
    if ($untrackedFiles) { $allFiles += $untrackedFiles }
    
    $allFiles = $allFiles | Sort-Object | Get-Unique
    
    if (-not $allFiles) {
        return "chore: minor updates and maintenance"
    }
    
    # Analyze file types
    $screens = @()
    $widgets = @()
    $models = @()
    $services = @()
    $assets = @()
    $config = @()
    $scripts = @()
    
    foreach ($file in $allFiles) {
        $fileName = Split-Path $file -Leaf
        
        if ($file -match "screens/.*\.dart$") { $screens += $fileName }
        elseif ($file -match "widgets/.*\.dart$") { $widgets += $fileName }
        elseif ($file -match "models/.*\.dart$") { $models += $fileName }
        elseif ($file -match "services/.*\.dart$") { $services += $fileName }
        elseif ($file -match "assets/") { $assets += $fileName }
        elseif ($file -match "pubspec\.yaml$") { $config += $fileName }
        elseif ($file -match "\.ps1$|\.bat$|\.sh$") { $scripts += $fileName }
    }
    
    # Generate commit message
    $commitType = "feat"
    $scope = ""
    $description = ""
    $details = @()
    
    if ($screens.Count -gt 0) {
        $commitType = "feat"
        $scope = "ui"
        $screenNames = ($screens | ForEach-Object { $_ -replace "\.dart$", "" -replace "_screen$", "" }) -join ", "
        $description = "optimize $screenNames layout and styling"
        $details += "removed scroll overflow, compact design"
        $details += "reduced spacing and component sizes"
    }
    
    if ($assets.Count -gt 0) {
        if ($description) { $description += " and asset integration" }
        else { 
            $commitType = "feat"
            $scope = "assets"
            $description = "add logo and asset management"
        }
        $details += "integrated MKPro.jpg logo with error handling"
    }
    
    if ($config.Count -gt 0) {
        if ($description) { $description += " with config updates" }
        else {
            $commitType = "config"
            $description = "update project configuration"
        }
        $details += "updated pubspec.yaml for assets"
    }
    
    if ($scripts.Count -gt 0) {
        if (-not $description) {
            $commitType = "tools"
            $scope = "automation"
            $description = "add git automation scripts"
        }
        $details += "enhanced git workflow automation"
    }
    
    # Build final commit message
    $commitMessage = "$commitType"
    if ($scope) { $commitMessage += "($scope)" }
    $commitMessage += ": $description"
    
    if ($details.Count -gt 0) {
        $commitMessage += "`n`n"
        foreach ($detail in $details) {
            $commitMessage += "- $detail`n"
        }
        $commitMessage = $commitMessage.TrimEnd()
    }
    
    $commitMessage += "`n`nFiles: $($allFiles.Count) changed"
    
    return $commitMessage
}

Write-Host "=========================================="
Write-Host "   MK Rent - Advanced Git Push"
Write-Host "=========================================="

if (!(Test-Path ".git")) {
    Write-Host "Error: Not in a git repository!" -ForegroundColor Red
    exit 1
}

Write-Host "Adding changes..." -ForegroundColor Yellow
git add .

$gitStatus = git status --porcelain
if (!$gitStatus) {
    Write-Host "No changes to commit." -ForegroundColor Blue
    exit 0
}

Write-Host ""
Write-Host "Current changes:" -ForegroundColor Yellow
git status --short

if (!$CommitMessage) {
    $smartMessage = Get-TechnicalCommitMessage
    Write-Host ""
    Write-Host "Generated technical commit message:" -ForegroundColor Magenta
    Write-Host $smartMessage -ForegroundColor White
    Write-Host ""
    $userInput = Read-Host "Press Enter to use this message, or type your own"
    
    if (!$userInput) {
        $CommitMessage = $smartMessage
    } else {
        $CommitMessage = $userInput
    }
}

Write-Host ""
Write-Host "Committing..." -ForegroundColor Yellow
git commit -m $CommitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host "Commit failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
git push origin main

if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
Write-Host "Commit: '$CommitMessage'"
