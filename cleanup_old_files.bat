@echo off
echo تنظيف الملفات القديمة للتطبيق...
echo.

cd /d "%~dp0"

echo حذف ملفات emergency_backup القديمة...
for /f "skip=3 delims=" %%f in ('dir /b /o-d emergency_backup_*.json 2^>nul') do (
    echo حذف: %%f
    del "%%f" 2>nul
)

echo.
echo حذف ملفات .hive القديمة من مجلد data...
cd data 2>nul
if exist "data" (
    for /f "skip=3 delims=" %%f in ('dir /b /o-d *_*.hive 2^>nul ^| findstr /v /c:"devicesbox.hive" /c:"reservationsbox.hive"') do (
        echo حذف: %%f
        del "%%f" 2>nul
    )
)
cd ..

echo.
echo حذف مجلدات safe_data القديمة...
for /f "delims=" %%d in ('dir /b /ad safe_data_* 2^>nul') do (
    echo حذف مجلد: %%d
    rmdir /s /q "%%d" 2>nul
)

echo.
echo ✅ تم إكمال التنظيف بنجاح!
echo المساحة المحررة: تم حذف الملفات المؤقتة والاحتياطية القديمة
echo.
pause