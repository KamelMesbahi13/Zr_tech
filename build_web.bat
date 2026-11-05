@echo off
title ZR Tech - Build Web
set "PATH=C:\src\flutter-sdk\bin;%PATH%"
cd /d "%~dp0"
if exist "zr_tech_app\pubspec.yaml" (
    cd zr_tech_app
) else if exist "Zr_tech-main\zr_tech_app\pubspec.yaml" (
    cd Zr_tech-main\zr_tech_app
)
echo ===================================================
echo Building ZR Tech Web release...
echo ===================================================
flutter build web --release
echo Done! You can now run start_app.bat to view it.
pause

