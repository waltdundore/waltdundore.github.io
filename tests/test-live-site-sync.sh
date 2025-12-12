#!/bin/bash

# Live Site Synchronization Test - NASA Power of 10 & Zero Trust Compliant
# Rule #7: Check return values
# Rule #2: Bounded loops (no while true)
# Rule #6: Timeout protection (30s max per curl)
# Zero Trust: Verify live site matches local repo

set -euo pipefail

echo "→ Running: Live site synchronization test"
echo "   Purpose: Verify GitHub Pages site matches local repository content"

# Configuration
LIVE_SITE="https://waltdundore.github.io"
TIMEOUT=30
ERRORS=0
FILES_CHECKED=0
TEMP_DIR=$(mktemp -d)

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Function to normalize HTML for comparison
normalize_html() {
    local file="$1"
    # Remove timestamps, version info, and other dynamic content
    sed -E \
        -e 's/<!-- Generated: [^>]+ -->/<!-- Generated: [TIMESTAMP] -->/g' \
        -e 's/Last updated: [^<]+/Last updated: [TIMESTAMP]/g' \
        -e 's/Version: [0-9a-f]+/Version: [VERSION]/g' \
        -e 's/Build: [0-9-]+ [0-9:]+/Build: [TIMESTAMP]/g' \
        -e '/^\s*$/d' \
        "$file" | \
    # Sort CSS classes for consistent comparison
    sed -E 's/class="([^"]+)"/class="\1"/g' | \
    # Remove extra whitespace
    tr -s ' ' | \
    # Sort lines for consistent comparison (except HTML structure)
    sort
}

# Function to check if a file should be tested
should_test_file() {
    local file="$1"
    
    # Skip if file doesn't exist
    [ -f "$file" ] || return 1
    
    # Only test HTML files
    [[ "$file" == *.html ]] || return 1
    
    # Skip test files and temporary files
    [[ "$file" != *test* ]] || return 1
    [[ "$file" != *.tmp ]] || return 1
    [[ "$file" != *.backup ]] || return 1
    
    return 0
}

# Function to test a single file
test_file_sync() {
    local local_file="$1"
    local remote_url="$LIVE_SITE/$local_file"
    local temp_local="$TEMP_DIR/local_$(basename "$local_file")"
    local temp_remote="$TEMP_DIR/remote_$(basename "$local_file")"
    
    echo "Testing $local_file..."
    
    # Normalize local file
    if ! normalize_html "$local_file" > "$temp_local"; then
        echo "ERROR: Failed to normalize local file $local_file"
        return 1
    fi
    
    # Download and normalize remote file with timeout
    if ! curl -s -f --max-time "$TIMEOUT" "$remote_url" > "$temp_remote.raw" 2>/dev/null; then
        echo "ERROR: Failed to download $remote_url (timeout: ${TIMEOUT}s)"
        echo "  Checking if site is accessible..."
        if curl -I -s --max-time 10 "$LIVE_SITE" >/dev/null 2>&1; then
            echo "  Site is accessible, but $remote_url may not exist"
        else
            echo "  Site appears to be down or inaccessible"
        fi
        return 1
    fi
    
    if ! normalize_html "$temp_remote.raw" > "$temp_remote"; then
        echo "ERROR: Failed to normalize remote file from $remote_url"
        return 1
    fi
    
    # Compare normalized files
    if ! diff -q "$temp_local" "$temp_remote" >/dev/null 2>&1; then
        echo "ERROR: $local_file differs from live site"
        echo "  Local:  $local_file"
        echo "  Remote: $remote_url"
        echo "  Diff preview (first 10 lines):"
        diff "$temp_local" "$temp_remote" | head -10 | sed 's/^/    /'
        echo "  Run 'make deploy' to sync changes to live site"
        return 1
    fi
    
    echo "✓ $local_file matches live site"
    return 0
}

# Test main pages (bounded loop - Rule #2)
MAIN_FILES=("index.html" "status.html")

for file in "${MAIN_FILES[@]}"; do
    if should_test_file "$file"; then
        ((FILES_CHECKED++))
        if ! test_file_sync "$file"; then
            ((ERRORS++))
        fi
    else
        echo "Skipping $file (not found or not testable)"
    fi
done

# Test additional HTML files in current directory
for file in *.html; do
    # Skip if already tested in main files
    skip=false
    for main_file in "${MAIN_FILES[@]}"; do
        if [ "$file" = "$main_file" ]; then
            skip=true
            break
        fi
    done
    
    if [ "$skip" = true ]; then
        continue
    fi
    
    if should_test_file "$file"; then
        ((FILES_CHECKED++))
        if ! test_file_sync "$file"; then
            ((ERRORS++))
        fi
    fi
done

# Test site availability
echo ""
echo "Testing site availability..."
if curl -I -s --max-time "$TIMEOUT" "$LIVE_SITE" >/dev/null 2>&1; then
    echo "✓ Live site is accessible at $LIVE_SITE"
else
    echo "ERROR: Live site is not accessible at $LIVE_SITE"
    ((ERRORS++))
fi

# Test status page specifically
if curl -I -s --max-time "$TIMEOUT" "$LIVE_SITE/status.html" >/dev/null 2>&1; then
    echo "✓ Status page is accessible at $LIVE_SITE/status.html"
else
    echo "ERROR: Status page is not accessible at $LIVE_SITE/status.html"
    ((ERRORS++))
fi

# Summary (Rule #7: Check return values)
echo ""
echo "Live site synchronization summary:"
echo "  Files checked: $FILES_CHECKED"
echo "  Errors found: $ERRORS"
echo "  Live site: $LIVE_SITE"

if [ $ERRORS -eq 0 ]; then
    echo "✓ All files are synchronized with live site"
    exit 0
else
    echo "❌ Live site synchronization failed - $ERRORS errors found"
    echo ""
    echo "🔧 To fix synchronization issues:"
    echo "  1. Review differences shown above"
    echo "  2. Commit your local changes: git add . && git commit -m 'Update content'"
    echo "  3. Deploy to live site: make publish"
    echo "  4. Wait 1-2 minutes for GitHub Pages deployment"
    echo "  5. Re-run this test: make test-live-sync"
    exit 1
fi