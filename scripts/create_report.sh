#!/bin/bash
set -e

# HomeScope Report Generator
# Usage: ./scripts/create_report.sh "Address, City"

if [ -z "$1" ]; then
  echo "Usage: ./scripts/create_report.sh \"Address, City\""
  echo "Example: ./scripts/create_report.sh \"Rossio, Lisboa\""
  exit 1
fi

ADDRESS="$1"
API_URL="http://localhost:8001/api/v1"

echo "🏠 Creating HomeScope Report for: $ADDRESS"
echo ""

# Step 1: Analyze the address
echo "📊 Analyzing neighborhood..."
ANALYSIS=$(curl -s -X POST "$API_URL/analyze" \
  -H "Content-Type: application/json" \
  -d "{\"address\":\"$ADDRESS\",\"country_code\":\"pt\",\"radius\":2000}")

if echo "$ANALYSIS" | jq -e '.error' > /dev/null 2>&1; then
  echo "❌ Error: $(echo "$ANALYSIS" | jq -r '.detail')"
  exit 1
fi

SCORE=$(echo "$ANALYSIS" | jq -r '.score.overall // "N/A"')
echo "✅ Score: $SCORE/100"

# Step 2: Create shareable link
echo ""
echo "🔗 Creating shareable link..."
SHARE_RESPONSE=$(curl -s -X POST "$API_URL/share" \
  -H "Content-Type: application/json" \
  -d "$ANALYSIS")

SHARE_TOKEN=$(echo "$SHARE_RESPONSE" | jq -r '.share_token // empty')

if [ -z "$SHARE_TOKEN" ]; then
  echo "❌ Error creating share link"
  exit 1
fi

# Step 3: Generate URLs
ENHANCED_URL="file://$(pwd)/landing/report-enhanced.html?token=$SHARE_TOKEN"
SIMPLE_URL="file://$(pwd)/landing/report.html?token=$SHARE_TOKEN"

echo "✅ Report created successfully!"
echo ""
echo "📋 Share Token: $SHARE_TOKEN"
echo ""
echo "🔗 View Reports:"
echo "   Enhanced: $ENHANCED_URL"
echo "   Simple:   $SIMPLE_URL"
echo ""

# Step 4: Open in browser
read -p "Open enhanced report in browser? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  open "$ENHANCED_URL"
  echo "✅ Opened in browser"
fi
