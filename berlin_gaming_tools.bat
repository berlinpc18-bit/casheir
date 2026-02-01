@echo off
chcp 65001 >nul
title BERLIN GAMING - أدوات البيع والإدارة

:MAIN_MENU
cls
echo.
echo ████████████████████████████████████████████████
echo ║        🎮 BERLIN GAMING CASHIER 🎮           ║
echo ║              أدوات البيع والإدارة              ║
echo ████████████████████████████████████████████████
echo.
echo 📋 اختر العملية المطلوبة:
echo.
echo [1] 🔧 بناء النسخة للتوزيع (Build Release)
echo [2] 🔑 توليد ترخيص للعميل (Generate License)  
echo [3] 🧪 اختبار النظام (Test System)
echo [4] 🚀 تشغيل التطبيق (Run App)
echo [5] 📊 عرض حالة النظام (System Status)
echo [6] 📖 دليل البيع الأول (First Sale Guide)
echo [0] ❌ خروج (Exit)
echo.
set /p choice=👆 أدخل رقم اختيارك: 

if "%choice%"=="1" goto BUILD_RELEASE
if "%choice%"=="2" goto GENERATE_LICENSE
if "%choice%"=="3" goto TEST_SYSTEM
if "%choice%"=="4" goto RUN_APP
if "%choice%"=="5" goto SYSTEM_STATUS
if "%choice%"=="6" goto SALE_GUIDE
if "%choice%"=="0" goto EXIT
goto INVALID_CHOICE

:BUILD_RELEASE
cls
echo 🔧 بناء النسخة للتوزيع...
echo ================================
echo.
echo 📦 جاري إنشاء نسخة الإنتاج...
flutter build windows --release
echo.
echo ✅ تم بناء النسخة بنجاح!
echo 📁 الملفات في: build\windows\x64\runner\Release\
echo.
pause
goto MAIN_MENU

:GENERATE_LICENSE
cls
echo 🔑 مولد تراخيص العملاء
echo ========================
echo.
echo 💡 سيتم تشغيل مولد الترخيص...
echo 📝 ستحتاج إلى: اسم العميل + Device ID
echo.
dart run license_generator_simple.dart
pause
goto MAIN_MENU

:TEST_SYSTEM
cls
echo 🧪 اختبار النظام
echo =================
echo.
dart run test_license.dart
pause
goto MAIN_MENU

:RUN_APP
cls
echo 🚀 تشغيل التطبيق
echo ================
echo.
flutter run -d windows
pause
goto MAIN_MENU

:SYSTEM_STATUS
cls
echo 📊 حالة النظام
echo ==============
echo.
type SYSTEM_STATUS.md
echo.
pause
goto MAIN_MENU

:SALE_GUIDE
cls
echo 📖 دليل البيع الأول
echo ==================
echo.
start notepad FIRST_SALE_GUIDE.md
goto MAIN_MENU

:INVALID_CHOICE
cls
echo ❌ اختيار غير صحيح!
timeout /t 2 >nul
goto MAIN_MENU

:EXIT
cls
echo 👋 شكراً لاستخدام BERLIN GAMING CASHIER
echo 🚀 بالتوفيق في مبيعاتك!
timeout /t 3 >nul
exit