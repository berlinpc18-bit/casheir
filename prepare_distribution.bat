@echo off
chcp 65001 >nul
title إعداد النسخة للعميل - BERLIN GAMING CASHIER

echo.
echo ████████████████████████████████████████████████
echo ║     📦 إعداد النسخة للتوزيع 📦              ║
echo ║        BERLIN GAMING CASHIER v1.0            ║
echo ████████████████████████████████████████████████
echo.

echo 🎯 جاري إعداد مجلد التوزيع...
echo.

:: إنشاء مجلد التوزيع
set "DIST_FOLDER=BERLIN_GAMING_CASHIER_v1.0"
if exist "%DIST_FOLDER%" (
    echo 🗑️ حذف المجلد القديم...
    rmdir /s /q "%DIST_FOLDER%"
)

echo 📁 إنشاء مجلد جديد: %DIST_FOLDER%
mkdir "%DIST_FOLDER%"
mkdir "%DIST_FOLDER%\data"

:: نسخ ملفات التطبيق
echo 📦 نسخ ملفات التطبيق الأساسية...
copy "build\windows\x64\runner\Release\*.exe" "%DIST_FOLDER%\" >nul 2>&1
copy "build\windows\x64\runner\Release\*.dll" "%DIST_FOLDER%\" >nul 2>&1

:: نسخ مجلد assets
echo 🖼️ نسخ الموارد والصور...
if exist "build\windows\x64\runner\Release\data\flutter_assets" (
    xcopy "build\windows\x64\runner\Release\data" "%DIST_FOLDER%\data\" /E /I /Q >nul 2>&1
)

:: نسخ ملفات التوثيق
echo 📋 إضافة ملفات التوثيق...
copy "تعليمات_التشغيل.txt" "%DIST_FOLDER%\" >nul 2>&1
copy "رقم_الدعم_الفني.txt" "%DIST_FOLDER%\" >nul 2>&1
copy "شروط_الاستخدام.txt" "%DIST_FOLDER%\" >nul 2>&1

:: إنشاء ملف README للعميل
echo 📝 إنشاء دليل العميل...
echo 🎮 مرحباً بك في BERLIN GAMING CASHIER > "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo ==================================== >> "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo. >> "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo 🚀 للبدء: >> "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo 1. شغل berlin_gaming_cashier.exe >> "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo 2. انسخ Device ID من شاشة التفعيل >> "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo 3. أرسل Device ID للمطور >> "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo 4. استلم رمز التفعيل >> "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo 5. فعل البرنامج واستمتع! >> "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo. >> "%DIST_FOLDER%\اقرأني_أولاً.txt"
echo 📞 للدعم: راجع ملف رقم_الدعم_الفني.txt >> "%DIST_FOLDER%\اقرأني_أولاً.txt"

echo.
echo ✅ تم إعداد النسخة بنجاح!
echo.
echo 📂 مجلد التوزيع: %DIST_FOLDER%
echo 📋 محتويات المجلد:
dir "%DIST_FOLDER%" /b | findstr /v "^$"
echo.
echo 🎯 الخطوات التالية:
echo 1. ضغط المجلد في ملف ZIP
echo 2. رفعه على Google Drive أو Dropbox
echo 3. إرسال رابط التحميل للعميل
echo 4. انتظار Device ID من العميل
echo 5. توليد ترخيص مخصص
echo.
echo 📨 المجلد جاهز للإرسال للعميل!
echo.
pause