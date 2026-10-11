@echo off
REM deploy.bat - One-click deployment script for Windows
REM Run this from project root: C:\Users\Umesh\shelfsense_new\deploy.bat

echo ==========================================
echo ShelfSense - Deployment Script
echo ==========================================
echo.

echo [1/5] Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: flutter pub get failed
    pause
    exit /b 1
)

echo.
echo [2/5] Running tests...
flutter test
if errorlevel 1 (
    echo WARNING: Tests failed, continuing anyway...
)

echo.
echo [3/5] Building WEB (release)...
flutter build web --release
if errorlevel 1 (
    echo ERROR: Web build failed
    pause
    exit /b 1
)

echo.
echo [4/5] Building ANDROID APK (release)...
flutter build apk --release
if errorlevel 1 (
    echo ERROR: APK build failed
    pause
    exit /b 1
)

echo.
echo [5/5] Building ANDROID App Bundle (release)...
flutter build appbundle --release
if errorlevel 1 (
    echo ERROR: App Bundle build failed
    pause
    exit /b 1
)

echo.
echo ==========================================
echo BUILD SUCCESSFUL!
echo ==========================================
echo.
echo Web output: build\web
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo AAB: build\app\outputs\bundle\release\app-release.aab
echo.
echo To deploy web to Firebase Hosting, run:
echo   firebase deploy --only hosting
echo.
pause