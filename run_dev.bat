@echo off
title ZR Tech - Development Mode
set "PATH=C:\src\flutter-sdk\bin;%PATH%"
cd /d "%~dp0"
if exist "zr_tech_app\pubspec.yaml" (
    cd zr_tech_app
) else if exist "Zr_tech-main\zr_tech_app\pubspec.yaml" (
    cd Zr_tech-main\zr_tech_app
)
echo ===================================================
echo Starting ZR Tech in Flutter Chrome Dev Mode...
echo Press 'r' for hot reload, 'R' for hot restart.
echo ===================================================
flutter run -d chrome
pause

