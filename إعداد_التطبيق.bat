@echo off
chcp 65001 >nul
title Berlin Gaming Cashier - إعداد سريع
color 0A
echo.
echo ╔══════════════════════════════════════╗
echo ║     Berlin Gaming Cashier v1.0.0    ║
echo ║        إعداد سريع للتطبيق           ║
echo ╚══════════════════════════════════════╝
echo.

echo 🔧 جاري التحقق من متطلبات النظام...
echo.

REM تحقق من Flutter
flutter --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Flutter مثبت
) else (
    echo ❌ Flutter غير مثبت
    echo يرجى تثبيت Flutter من: https://flutter.dev
    pause
    exit
)

echo ✅ النظام جاهز للبناء
echo.
echo 📦 هل تريد بناء التطبيق الآن؟ (y/n)
set /p choice="اختر (y للموافقة، n للإلغاء): "

if /i "%choice%"=="y" (
    echo.
    echo 🚀 جاري بناء التطبيق...
    echo هذا قد يستغرق بضع دقائق...
    echo.
    
    flutter build windows --release
    
    if %errorlevel% equ 0 (
        echo.
        echo ✅ تم بناء التطبيق بنجاح!
        echo 📍 مكان الملف: build\windows\x64\runner\Release\cashier_app.exe
        echo.
        echo 🎮 هل تريد تشغيل التطبيق الآن؟ (y/n)
        set /p run_choice="اختر (y للتشغيل، n للإغلاق): "
        
        if /i "!run_choice!"=="y" (
            echo.
            echo 🚀 جاري تشغيل التطبيق...
            start "Berlin Gaming Cashier" "build\windows\x64\runner\Release\cashier_app.exe"
            echo ✅ تم تشغيل التطبيق!
        )
    ) else (
        echo.
        echo ❌ فشل في بناء التطبيق!
        echo يرجى التحقق من الأخطاء أعلاه.
    )
) else (
    echo.
    echo تم الإلغاء. يمكنك بناء التطبيق لاحقاً باستخدام:
    echo flutter build windows --release
)

echo.
echo اضغط أي مفتاح للإغلاق...
pause >nul