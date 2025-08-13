@echo off
echo ==========================================
echo         MK Rent - Git Push Script
echo ==========================================

REM Check if we're in a git repository
if not exist ".git" (
    echo Error: Not in a git repository!
    pause
    exit /b 1
)

echo.
echo Checking git status...
git status

echo.
set /p commit_message="Enter commit message (or press Enter for auto-generated): "

REM If no message provided, generate one with timestamp
if "%commit_message%"=="" (
    for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
    set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
    set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
    set "commit_message=Updates - %DD%/%MM%/%YYYY% %HH%:%Min%"
)

echo.
echo Adding all changes to staging...
git add .

echo.
echo Committing with message: "%commit_message%"
git commit -m "%commit_message%"

if errorlevel 1 (
    echo.
    echo No changes to commit.
    pause
    exit /b 0
)

echo.
echo Pushing to GitHub...
git push origin main

if errorlevel 1 (
    echo.
    echo Push failed! Please check your network connection and credentials.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo    ✅ Successfully pushed to GitHub!
echo ==========================================
echo Commit: "%commit_message%"
echo.
pause
