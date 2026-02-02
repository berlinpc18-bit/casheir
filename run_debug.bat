@echo off
title Berlin Gaming Cashier - Runner
echo.
echo ========================================
echo    Berlin Gaming Cashier
echo ========================================
echo.

REM 1. Fix "File Locked" errors by killing old instances
echo Stopping any running instances...
taskkill /F /IM cashier_app.exe >nul 2>&1

REM 2. Optional: Clean build (fixes weird build errors)
echo.
set /p run_clean="Run 'flutter clean' to fix build errors? (y/N): "
if /i "%run_clean%"=="y" (
    echo.
    echo Cleaning project...
    call flutter clean
    echo Getting dependencies...
    call flutter pub get
)

REM 3. Run the app
echo.
echo Starting app...
echo  'r' = Hot Reload
echo  'R' = Hot Restart
echo.
flutter run -d windows
