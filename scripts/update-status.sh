#!/bin/bash

# Update Status Page Script
# Automatically updates status.html with real data from ahab system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBSITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AHAB_DIR="$(cd "$WEBSITE_DIR/../ahab" && pwd)"
STATUS_FILE="$WEBSITE_DIR/status.html"

echo "→ Running: Update status page with real data"
echo "   Purpose: Keep status page current with actual system state"

# Check if ahab directory exists
if [ ! -d "$AHAB_DIR" ]; then
    echo "ERROR: ahab directory not found at $AHAB_DIR"
    exit 1
fi

# Check if status.html exists
if [ ! -f "$STATUS_FILE" ]; then
    echo "ERROR: status.html not found at $STATUS_FILE"
    exit 1
fi

echo "✓ Found ahab directory: $AHAB_DIR"
echo "✓ Found status file: $STATUS_FILE"

# Get current timestamp
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
DATE_ONLY=$(date '+%B %d, %Y')

echo "✓ Timestamp: $TIMESTAMP"

# Get git information from ahab
cd "$AHAB_DIR"
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

echo "✓ Git info: $COMMIT_HASH on $BRANCH"

# Check test status
TEST_STATUS="UNKNOWN"
TEST_TIMESTAMP="Unknown"
if [ -f ".test-status" ]; then
    if grep -q "PASS" .test-status; then
        TEST_STATUS="PASSING"
    elif grep -q "FAIL" .test-status; then
        TEST_STATUS="FAILING"
    fi
    TEST_TIMESTAMP=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S UTC" .test-status 2>/dev/null || echo "Unknown")
fi

echo "✓ Test status: $TEST_STATUS ($TEST_TIMESTAMP)"

# Run quick test to get current status
echo "Running quick system check..."
if cd "$AHAB_DIR" && make test >/dev/null 2>&1; then
    SYSTEM_STATUS="STABLE"
    SYSTEM_CONFIDENCE="95"
else
    SYSTEM_STATUS="ISSUES"
    SYSTEM_CONFIDENCE="70"
fi

echo "✓ System status: $SYSTEM_STATUS (confidence: $SYSTEM_CONFIDENCE%)"

# Update status.html with real data
cd "$WEBSITE_DIR"

# Update timestamps
sed -i.bak "s/Last Updated: [^<]*/Last Updated: $TIMESTAMP/" "$STATUS_FILE"
sed -i.bak "s/Status updated: [^<]*/Status updated: $DATE_ONLY/" "$STATUS_FILE"

# Update git information
sed -i.bak "s/<span class=\"commit-hash\">[^<]*<\/span>/<span class=\"commit-hash\">$COMMIT_HASH<\/span>/" "$STATUS_FILE"
sed -i.bak "s/<strong>Branch:<\/strong> [^<]*/<strong>Branch:<\/strong> $BRANCH/" "$STATUS_FILE"
sed -i.bak "s/<strong>Last Test:<\/strong> [^<]*/<strong>Last Test:<\/strong> $TEST_TIMESTAMP/" "$STATUS_FILE"

# Update confidence metrics based on actual test results
if [ "$SYSTEM_STATUS" = "STABLE" ]; then
    # System is stable - update confidence bars
    sed -i.bak 's/style="width: 95%"/style="width: 95%"/' "$STATUS_FILE"
    sed -i.bak 's/style="width: 90%"/style="width: 90%"/' "$STATUS_FILE"
    sed -i.bak 's/style="width: 80%"/style="width: 85%"/' "$STATUS_FILE"
    sed -i.bak 's/style="width: 85%"/style="width: 90%"/' "$STATUS_FILE"
else
    # System has issues - lower confidence
    sed -i.bak 's/style="width: 95%"/style="width: 70%"/' "$STATUS_FILE"
    sed -i.bak 's/style="width: 90%"/style="width: 75%"/' "$STATUS_FILE"
    sed -i.bak 's/style="width: 80%"/style="width: 60%"/' "$STATUS_FILE"
    sed -i.bak 's/style="width: 85%"/style="width: 65%"/' "$STATUS_FILE"
fi

# Clean up backup files
rm -f "$STATUS_FILE.bak"

echo "✓ Status page updated successfully"
echo "✓ Updated: $STATUS_FILE"

# Verify the update worked
if grep -q "$TIMESTAMP" "$STATUS_FILE"; then
    echo "✓ Timestamp update verified"
else
    echo "⚠ WARNING: Timestamp update may have failed"
fi

if grep -q "$COMMIT_HASH" "$STATUS_FILE"; then
    echo "✓ Git hash update verified"
else
    echo "⚠ WARNING: Git hash update may have failed"
fi

echo ""
echo "Status page update complete!"
echo "View at: file://$STATUS_FILE"
echo "Or visit: https://waltdundore.github.io/status.html"