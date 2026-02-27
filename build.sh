#!/bin/bash
set -e

# Install Flutter SDK
echo "Installing Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter-sdk
export PATH="$PWD/flutter-sdk/bin:$PATH"

# Verify Flutter installation
flutter --version
flutter doctor -v

# Navigate to the Flutter app directory
cd zr_tech_app

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build for web
echo "Building Flutter web app..."
flutter build web --release --base-href "/"

echo "Build completed successfully!"
