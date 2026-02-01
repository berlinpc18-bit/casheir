@echo off
REM تطبيق الكاشير - نظام التحكم المشترك الذكي
REM هذا الملف يقوم ببناء التطبيق للأجهزة المحمولة

setlocal enabledelayedexpansion

echo.
echo ============================================
echo نظام التحكم المشترك الذكي بين الأجهزة
echo ============================================
echo.

REM التحقق من وجود Flutter
where flutter >nul 2>nul
if !errorlevel! neq 0 (
    echo خطأ: Flutter غير مثبت أو غير موجود في متغير البيئة
    pause
    exit /b 1
)

echo ✓ تم العثور على Flutter

REM تحديث المشروع
echo.
echo جاري تحديث المكتبات...
call flutter pub get
if !errorlevel! neq 0 (
    echo خطأ في تحديث المكتبات
    pause
    exit /b 1
)
echo ✓ تم تحديث المكتبات بنجاح

REM إنشاء ملفات الكود المولد
echo.
echo جاري بناء الملفات المولدة...
call flutter pub run build_runner build --delete-conflicting-outputs
if !errorlevel! neq 0 (
    echo ⚠ تنبيه: قد لا تكون جميع الملفات المولدة محدثة
)
echo ✓ تم بناء الملفات المولدة

REM اختيار المنصة المستهدفة
echo.
echo اختر المنصة المستهدفة:
echo 1. Android
echo 2. iOS
echo 3. Web
echo 4. Windows
echo 5. Linux
echo 6. macOS

set /p platform="أدخل رقم المنصة (1-6): "

set target_platform=android
if "%platform%"=="1" (
    set target_platform=android
) else if "%platform%"=="2" (
    set target_platform=ios
) else if "%platform%"=="3" (
    set target_platform=web
) else if "%platform%"=="4" (
    set target_platform=windows
) else if "%platform%"=="5" (
    set target_platform=linux
) else if "%platform%"=="6" (
    set target_platform=macos
) else (
    echo اختيار غير صحيح، سيتم استخدام Android
    set target_platform=android
)

echo.
echo هل تريد البناء في وضع Release؟
echo 1. نعم (Release - للإنتاج)
echo 2. لا (Debug - للتطوير)

set /p build_type="أدخل الخيار (1-2): "

set build_flags=
if "%build_type%"=="1" (
    set build_flags=--release
    echo سيتم البناء في وضع Release
) else (
    echo سيتم البناء في وضع Debug
)

REM بناء التطبيق
echo.
echo جاري بناء التطبيق للمنصة: %target_platform%
echo هذا قد يستغرق عدة دقائق...
echo.

if "%target_platform%"=="android" (
    call flutter build apk %build_flags%
    if !errorlevel! neq 0 (
        echo خطأ في بناء APK
        pause
        exit /b 1
    )
    echo ✓ تم بناء APK بنجاح
    echo الملف: build\app\outputs\flutter-apk\app-%build_type%-obfuscated.apk
    
) else if "%target_platform%"=="ios" (
    call flutter build ios %build_flags%
    if !errorlevel! neq 0 (
        echo خطأ في بناء iOS
        pause
        exit /b 1
    )
    echo ✓ تم بناء iOS بنجاح
    
) else if "%target_platform%"=="web" (
    call flutter build web %build_flags%
    if !errorlevel! neq 0 (
        echo خطأ في بناء Web
        pause
        exit /b 1
    )
    echo ✓ تم بناء Web بنجاح
    echo المجلد: build\web
    
) else if "%target_platform%"=="windows" (
    call flutter build windows %build_flags%
    if !errorlevel! neq 0 (
        echo خطأ في بناء Windows
        pause
        exit /b 1
    )
    echo ✓ تم بناء Windows بنجاح
    
) else if "%target_platform%"=="linux" (
    call flutter build linux %build_flags%
    if !errorlevel! neq 0 (
        echo خطأ في بناء Linux
        pause
        exit /b 1
    )
    echo ✓ تم بناء Linux بنجاح
    
) else if "%target_platform%"=="macos" (
    call flutter build macos %build_flags%
    if !errorlevel! neq 0 (
        echo خطأ في بناء macOS
        pause
        exit /b 1
    )
    echo ✓ تم بناء macOS بنجاح
)

echo.
echo ============================================
echo ✓ تم البناء بنجاح!
echo ============================================
echo.
echo الخطوة التالية:
if "%target_platform%"=="android" (
    echo - قم بنسخ ملف APK إلى أجهزتك المحمولة
    echo - قم بتثبيت التطبيق على كل جهاز
    echo - تأكد من أن جميع الأجهزة على نفس الشبكة المحلية
    echo - سيتم اكتشاف الأجهزة تلقائياً والربط بينها
)

pause
