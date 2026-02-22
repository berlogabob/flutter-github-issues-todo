#!/bin/bash

# GitDoIt - Debug Info Collector
# Collects logs, metrics, and error reports from the app

echo "🔍 GitDoIt Debug Info Collector"
echo "================================"
echo ""

# Check if device is connected
echo "📱 Checking for connected devices..."
DEVICE=$(flutter devices | grep -E "Android|iPhone" | head -1 | awk '{print $1}')

if [ -z "$DEVICE" ]; then
    echo "❌ No device found. Please connect a device or start an emulator."
    exit 1
fi

echo "✅ Device found: $DEVICE"
echo ""

# Collect Flutter logs
echo "📊 Collecting Flutter logs..."
flutter logs --timeout=10 > /tmp/gitdoit_logs.txt 2>&1

# Count log entries
LOG_COUNT=$(wc -l < /tmp/gitdoit_logs.txt)
echo "✅ Collected $LOG_COUNT log entries"
echo ""

# Extract errors
echo "❌ Extracting errors..."
grep -i "error\|exception\|failed" /tmp/gitdoit_logs.txt > /tmp/gitdoit_errors.txt 2>&1
ERROR_COUNT=$(wc -l < /tmp/gitdoit_errors.txt)
echo "✅ Found $ERROR_COUNT errors"
echo ""

# Extract warnings
echo "⚠️  Extracting warnings..."
grep -i "warning\|warn" /tmp/gitdoit_logs.txt > /tmp/gitdoit_warnings.txt 2>&1
WARN_COUNT=$(wc -l < /tmp/gitdoit_warnings.txt)
echo "✅ Found $WARN_COUNT warnings"
echo ""

# Extract GitDoIt specific logs
echo "🔍 Extracting GitDoIt logs..."
grep -i "gitdoit\|auth\|issues\|repository\|oauth" /tmp/gitdoit_logs.txt > /tmp/gitdoit_app.txt 2>&1
APP_LOGS=$(wc -l < /tmp/gitdoit_app.txt)
echo "✅ Collected $APP_LOGS app-specific logs"
echo ""

# Create summary
echo "📝 Creating debug summary..."
cat > /tmp/gitdoit_debug_summary.txt << EOF
GitDoIt Debug Report
====================
Date: $(date)
Device: $DEVICE

Log Statistics:
- Total log entries: $LOG_COUNT
- Errors: $ERROR_COUNT
- Warnings: $WARN_COUNT
- App-specific logs: $APP_LOGS

Recent Errors:
==============
$(tail -20 /tmp/gitdoit_errors.txt)

App Logs (Last 50):
==================
$(tail -50 /tmp/gitdoit_app.txt)
EOF

echo "✅ Debug summary created"
echo ""

# Display summary
echo "📊 Debug Summary:"
echo "================"
cat /tmp/gitdoit_debug_summary.txt
echo ""

# Offer to share
echo "💾 Files created:"
echo "  - /tmp/gitdoit_debug_summary.txt (main report)"
echo "  - /tmp/gitdoit_logs.txt (full logs)"
echo "  - /tmp/gitdoit_errors.txt (errors only)"
echo "  - /tmp/gitdoit_warnings.txt (warnings only)"
echo "  - /tmp/gitdoit_app.txt (app-specific logs)"
echo ""

# Copy summary to clipboard (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    cat /tmp/gitdoit_debug_summary.txt | pbcopy
    echo "📋 Summary copied to clipboard!"
fi

echo ""
echo "✅ Debug collection complete!"
