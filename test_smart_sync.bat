@echo off
REM اختبار نظام التحكم المشترك الذكي
REM هذا الملف يساعدك على اختبار النظام على أجهزة متعددة

setlocal enabledelayedexpansion

echo.
echo ============================================
echo اختبار نظام التحكم المشترك الذكي
echo ============================================
echo.

REM البحث عن الأجهزة المتصلة
echo جاري البحث عن الأجهزة المتصلة...
for /f "tokens=*" %%i in ('adb devices ^| findstr /v "List"') do (
    set device_line=%%i
    if not "!device_line!"=="" (
        for /f "tokens=1" %%j in ("!device_line!") do (
            set devices=!devices! %%j
        )
    )
)

echo.
echo الأجهزة المتصلة:
adb devices

echo.
echo ============================================
echo خيارات الاختبار
echo ============================================
echo.
echo 1. اختبار الجهاز الواحد (Debug)
echo 2. اختبار جهازين (مزامنة)
echo 3. تشغيل الاختبارات الوحدة
echo 4. عرض السجلات الحية
echo 5. إعادة تعيين وتنظيف
echo 6. بناء Release
echo.

set /p choice="اختر خيار (1-6): "

if "%choice%"=="1" (
    echo.
    echo جاري تشغيل الجهاز الواحد في وضع Debug...
    call flutter run
    
) else if "%choice%"=="2" (
    echo.
    echo سيتم تشغيل جهازين
    echo.
    echo اختر الجهاز الأول:
    set count=0
    for /f "tokens=*" %%i in ('adb devices ^| findstr /v "List" ^| findstr /v "^$"') do (
        set /a count=!count!+1
        set device!count!=%%i
        echo !count!. %%i
    )
    
    set /p device1_choice="أدخل رقم الجهاز الأول: "
    
    echo اختر الجهاز الثاني:
    set /p device2_choice="أدخل رقم الجهاز الثاني: "
    
    echo.
    echo جاري تشغيل الجهاز الأول...
    echo الرجاء الانتظار...
    
    REM تشغيل الجهاز الأول في نافذة منفصلة
    start "Cashier App - Device 1" cmd /c "flutter run -d !device%device1_choice%! && pause"
    
    REM انتظر قليلاً
    timeout /t 5 /nobreak
    
    echo.
    echo جاري تشغيل الجهاز الثاني...
    call flutter run -d !device%device2_choice%!
    
) else if "%choice%"=="3" (
    echo.
    echo جاري تشغيل اختبارات الوحدة...
    call flutter test test/sync_service_test.dart -v
    
) else if "%choice%"=="4" (
    echo.
    echo عرض السجلات الحية (اضغط Ctrl+C للإيقاف)...
    call flutter logs
    
) else if "%choice%"=="5" (
    echo.
    echo تنظيف المشروع...
    call flutter clean
    
    echo جاري تحديث المكتبات...
    call flutter pub get
    
    echo جاري بناء الملفات المولدة...
    call flutter pub run build_runner build --delete-conflicting-outputs
    
    echo ✓ تم التنظيف والتحديث
    
) else if "%choice%"=="6" (
    echo.
    echo بناء Release...
    call flutter build apk --release
    
    if !errorlevel! equ 0 (
        echo.
        echo ✓ تم بناء APK بنجاح
        echo الملف: build\app\outputs\flutter-apk\app-release.apk
    ) else (
        echo ✗ فشل البناء
    )
    
) else (
    echo خيار غير صحيح
    exit /b 1
)

echo.
echo ============================================
echo انتهى الاختبار
echo ============================================

pause
