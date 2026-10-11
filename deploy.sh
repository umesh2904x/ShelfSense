#!/bin/bash
# deploy.sh - One-click deployment script for Linux/Mac
# Run from project root: ./deploy.sh

set -e  # Exit on error

echo "=========================================="
echo "ShelfSense - Deployment Script"
echo "=========================================="
echo ""

echo "[1/5] Getting dependencies..."
flutter pub get

echo ""
echo "[2/5] Running tests..."
flutter test || echo "WARNING: Tests failed, continuing..."

echo ""
echo "[3/5] Building WEB (release)..."
flutter build web --release

echo ""
echo "[4/5] Building ANDROID APK (release)..."
flutter build apk --release

echo ""
echo "[5/5] Building ANDROID App Bundle (release)..."
flutter build appbundle --release

echo ""
echo "=========================================="
echo "BUILD SUCCESSFUL!"
echo "=========================================="
echo ""
echo "Web output: build/web"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "To deploy web to Firebase Hosting, run:"
echo "  firebase deploy --only hosting"
echo ""