@echo off
title Berlin Gaming Cashier - Clean & Restart
echo.
echo ========================================
echo    Clean & Restart
echo ========================================
echo.

echo 1. Stopping any running instances...
taskkill /F /IM cashier_app.exe >nul 2>&1

echo 2. Cleaning project (fixes build errors)...
call flutter clean

echo 3. Getting dependencies...
call flutter pub get

echo 4. Starting app...
call flutter run -d windows
