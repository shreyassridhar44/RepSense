@echo off
echo ========================================
echo RepSense Mobile App Runner
echo ========================================
echo.
echo Make sure:
echo   1. Backend services are running (use START_BACKEND.bat)
echo   2. An emulator is running or device is connected
echo.
echo Checking Flutter setup...
echo.

cd mobile

echo Running flutter doctor...
flutter doctor
echo.

echo Available devices:
flutter devices
echo.

echo ========================================
echo Starting Flutter app...
echo ========================================
flutter run
