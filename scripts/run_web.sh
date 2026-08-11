#!/bin/bash
set -e

echo "🌐 Starting HomeScope Web..."

cd mobile

echo "📦 Installing dependencies..."
flutter pub get

echo "🚀 Launching Chrome..."
flutter run -d chrome \
  --dart-define=BACKEND_URL=https://api-home-scope.wonderfulplant-e443a025.eastus.azurecontainerapps.io