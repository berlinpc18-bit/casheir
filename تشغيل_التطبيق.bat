@echo off
title Berlin Gaming Cashier - تشغيل التطبيق
echo.
echo ========================================
echo    Berlin Gaming Cashier v1.0.0
echo    نظام إدارة صالة الألعاب
echo ========================================
echo.
echo جاري تشغيل التطبيق...
echo.

REM تحقق من وجود ملف التطبيق
if exist "build\windows\x64\runner\Release\cashier_app.exe" (
    echo تم العثور على التطبيق، جاري التشغيل...
    echo.
    start "Berlin Gaming Cashier" "build\windows\x64\runner\Release\cashier_app.exe"
    echo التطبيق يعمل الآن!
    echo يمكنك إغلاق هذا النافذة بأمان.
) else (
    echo.
    echo خطأ: لم يتم العثور على ملف التطبيق!
    echo يرجى التأكد من اكتمال عملية البناء.
    echo.
    echo إذا كانت هذه المرة الأولى، يرجى تشغيل:
    echo flutter build windows --release
    echo.
    pause
)

timeout /t 3 >nul