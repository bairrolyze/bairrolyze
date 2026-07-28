#!/bin/bash
# HomeScope Tutorial Generator — one-time setup

set -e
cd "$(dirname "$0")"

echo ""
echo "🏠  HomeScope Tutorial Generator Setup"
echo "======================================="
echo ""

# Install Appium + XCUITest driver
echo "📦  Installing Appium server..."
npm install

echo ""
echo "🔧  Installing XCUITest driver..."
npx appium driver install xcuitest 2>/dev/null || ./node_modules/.bin/appium driver install xcuitest

echo ""
echo "🐍  Installing Python dependencies..."
pip3 install -r requirements.txt

echo ""
echo "📁  Creating output directories..."
mkdir -p screenshots/search-property screenshots/explore screenshots/settings
mkdir -p logs
mkdir -p ../docs/tutorials ../docs/html

echo ""
echo "✅  Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Set your Anthropic API key:"
echo "     export ANTHROPIC_API_KEY=your_key_here"
echo ""
echo "  2. Start the app on the simulator:"
echo "     cd ../mobile && flutter run -d FD6472FA-4941-4CF4-A142-0C7EE9D88E4D"
echo ""
echo "  3. Generate tutorials:"
echo "     cd .. && python generate_tutorials.py"
echo ""
