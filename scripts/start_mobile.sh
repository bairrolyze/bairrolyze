#!/bin/bash
set -e

echo "📱 Starting HomeScope Mobile App..."

cd mobile

echo "📦 Installing Flutter dependencies..."
flutter pub get

echo "🔨 Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "📱 Launching on iPhone Simulator..."
flutter run -d "iPhone" --dart-define=BACKEND_URL=http://localhost:8000

# Fallback: list available devices
if [ $? -ne 0 ]; then
  echo ""
  echo "Available devices:"
  flutter devices
  echo ""
  echo "Run: flutter run -d <device-id>"
fi
