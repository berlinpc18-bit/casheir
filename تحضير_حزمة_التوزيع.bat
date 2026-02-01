@echo off
chcp 65001 >nul
title Berlin Gaming Cashier - تحضير حزمة التوزيع
color 0B

echo.
echo ╔════════════════════════════════════════════╗
echo ║     Berlin Gaming Cashier v1.0.0          ║
echo ║        تحضير حزمة التوزيع للعملاء         ║
echo ╚════════════════════════════════════════════╝
echo.

echo 📦 جاري تحضير حزمة التوزيع...
echo.

REM التحقق من وجود ملف التطبيق المبني
if not exist "build\windows\x64\runner\Release\cashier_app.exe" (
    echo ❌ خطأ: لم يتم العثور على ملف التطبيق المبني!
    echo.
    echo يرجى أولاً بناء التطبيق باستخدام:
    echo flutter build windows --release
    echo.
    echo أو تشغيل ملف: إعداد_التطبيق.bat
    echo.
    pause
    exit
)

echo ✅ تم العثور على ملف التطبيق

REM إنشاء مجلد التوزيع
set DIST_FOLDER=berlin_gaming_cashier_v1.0_distribution
if exist "%DIST_FOLDER%" (
    echo 🗑️ حذف المجلد القديم...
    rmdir /s /q "%DIST_FOLDER%"
)

echo 📁 إنشاء مجلد التوزيع...
mkdir "%DIST_FOLDER%"
mkdir "%DIST_FOLDER%\assets"
mkdir "%DIST_FOLDER%\data"

REM نسخ الملفات الأساسية
echo 📋 نسخ الملفات...
copy "build\windows\x64\runner\Release\cashier_app.exe" "%DIST_FOLDER%\berlin_gaming_cashier.exe" >nul
if %errorlevel% neq 0 (
    echo ❌ فشل في نسخ ملف التطبيق
    pause
    exit
)

REM نسخ مجلد الأصول
echo 📸 نسخ مجلد الأصول...
xcopy "assets\*.png" "%DIST_FOLDER%\assets\" /Y >nul 2>&1
xcopy "assets\sounds" "%DIST_FOLDER%\assets\sounds\" /E /I >nul 2>&1

REM نسخ ملفات البيانات إن وجدت
if exist "data" (
    echo 💾 نسخ ملفات البيانات...
    xcopy "data\*" "%DIST_FOLDER%\data\" /E /I >nul 2>&1
)

REM نسخ ملفات الوثائق
echo 📚 نسخ الوثائق...
copy "README_CUSTOMER.md" "%DIST_FOLDER%\دليل_المستخدم.md" >nul
copy "تشغيل_التطبيق.bat" "%DIST_FOLDER%\" >nul

REM إنشاء ملف تشغيل محدث للتوزيع
echo 🚀 إنشاء ملف التشغيل...
(
echo @echo off
echo title Berlin Gaming Cashier - تشغيل التطبيق
echo echo.
echo echo ========================================
echo echo    Berlin Gaming Cashier v1.0.0
echo echo    نظام إدارة صالة الألعاب
echo echo ========================================
echo echo.
echo echo جاري تشغيل التطبيق...
echo echo.
echo.
echo if exist "berlin_gaming_cashier.exe" ^(
echo     start "Berlin Gaming Cashier" "berlin_gaming_cashier.exe"
echo     echo ✅ التطبيق يعمل الآن!
echo     echo يمكنك إغلاق هذا النافذة بأمان.
echo ^) else ^(
echo     echo ❌ خطأ: لم يتم العثور على ملف التطبيق!
echo     pause
echo ^)
echo.
echo timeout /t 3 ^>nul
) > "%DIST_FOLDER%\تشغيل_التطبيق.bat"

REM إنشاء ملف معلومات التطبيق
echo 📋 إنشاء ملف المعلومات...
(
echo Berlin Gaming Cashier v1.0.0
echo ============================
echo.
echo نظام إدارة صالة ألعاب برلين الإلكترونية
echo.
echo تاريخ البناء: %date% %time%
echo النظام: Windows 10/11
echo.
echo الملفات المطلوبة:
echo - berlin_gaming_cashier.exe ^(الملف الرئيسي^)
echo - assets/ ^(مجلد الأصول^)
echo - data/ ^(مجلد البيانات^)
echo.
echo للبدء:
echo 1. تشغيل "تشغيل_التطبيق.bat"
echo 2. أو النقر المزدوج على "berlin_gaming_cashier.exe"
echo.
echo للدعم الفني:
echo support@berlingame.com
echo.
echo © 2025 Berlin Game - جميع الحقوق محفوظة
) > "%DIST_FOLDER%\معلومات_التطبيق.txt"

REM حساب حجم المجلد
echo 📊 معلومات الحزمة:
for /f "tokens=3" %%a in ('dir "%DIST_FOLDER%" /s /-c ^| find "ملف"') do set size=%%a
echo    📁 الحجم: %size% بايت تقريباً
dir "%DIST_FOLDER%" /b | find /c /v "" > temp_count.txt
set /p file_count=<temp_count.txt
del temp_count.txt
echo    📄 عدد الملفات: %file_count%
echo    📍 المكان: %CD%\%DIST_FOLDER%

echo.
echo ✅ تم تحضير حزمة التوزيع بنجاح!
echo.
echo 📦 مجلد التوزيع: %DIST_FOLDER%
echo.
echo 🎯 الخطوات التالية:
echo 1. فحص المحتويات في المجلد
echo 2. اختبار التطبيق
echo 3. إنشاء أرشيف ZIP للإرسال
echo 4. إرسال للعميل مع دليل المستخدم
echo.

echo 🗂️ هل تريد فتح مجلد التوزيع؟ (y/n)
set /p open_choice="اختر (y للفتح، n للإغلاق): "

if /i "%open_choice%"=="y" (
    explorer "%DIST_FOLDER%"
)

echo.
echo 🎉 حزمة التوزيع جاهزة للتسليم!
echo اضغط أي مفتاح للإغلاق...
pause >nul