#!/bin/bash

# Link Verification Script for Ahab Website
# Purpose: Verify all internal and external links work properly
# Usage: ./scripts/check-links.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Temporary files for counters (to handle subshell variable scope)
TEMP_DIR=$(mktemp -d)
TOTAL_FILE="$TEMP_DIR/total"
BROKEN_FILE="$TEMP_DIR/broken"
WARNINGS_FILE="$TEMP_DIR/warnings"

echo "0" > "$TOTAL_FILE"
echo "0" > "$BROKEN_FILE"
echo "0" > "$WARNINGS_FILE"

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "🔗 Starting link verification..."
echo ""

# Function to increment counters
increment_total() {
    local current=$(cat "$TOTAL_FILE")
    echo $((current + 1)) > "$TOTAL_FILE"
}

increment_broken() {
    local current=$(cat "$BROKEN_FILE")
    echo $((current + 1)) > "$BROKEN_FILE"
}

increment_warnings() {
    local current=$(cat "$WARNINGS_FILE")
    echo $((current + 1)) > "$WARNINGS_FILE"
}

# Function to check if a URL is accessible
check_url() {
    local url="$1"
    local source_file="$2"
    
    increment_total
    
    # Skip mailto links
    if [[ "$url" =~ ^mailto: ]]; then
        echo "📧 Skipping mailto: $url"
        return 0
    fi
    
    # Skip javascript links
    if [[ "$url" =~ ^javascript: ]]; then
        echo "🔧 Skipping javascript: $url"
        return 0
    fi
    
    # Skip anchor-only links (they're internal page navigation)
    if [[ "$url" =~ ^# ]]; then
        echo "⚓ Skipping anchor: $url"
        return 0
    fi
    
    # Check internal links (relative paths)
    if [[ ! "$url" =~ ^https?:// ]]; then
        # Remove leading ./ if present
        local clean_url="${url#./}"
        
        # Check if file exists
        if [[ -f "$clean_url" ]]; then
            echo -e "${GREEN}✓${NC} Internal: $url (in $source_file)"
        else
            echo -e "${RED}✗${NC} Broken internal link: $url (in $source_file)"
            increment_broken
        fi
        return 0
    fi
    
    # Check external links with curl
    if curl -s --head --max-time 10 "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} External: $url"
    else
        # Try a GET request in case HEAD is not supported
        if curl -s --max-time 10 "$url" > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠${NC} External (HEAD failed, GET ok): $url"
            increment_warnings
        else
            echo -e "${RED}✗${NC} Broken external link: $url (in $source_file)"
            increment_broken
        fi
    fi
}

# Extract links from HTML files
extract_links_from_html() {
    local file="$1"
    
    echo "📄 Checking links in $file..."
    
    # Extract href attributes from <a> tags using sed
    if grep -q 'href="' "$file" 2>/dev/null; then
        grep -o 'href="[^"]*"' "$file" 2>/dev/null | sed 's/href="//;s/"//' | while read -r link; do
            if [[ -n "$link" ]]; then
                check_url "$link" "$file"
            fi
        done
    fi
    
    # Extract src attributes from <img> tags using sed
    if grep -q 'src="' "$file" 2>/dev/null; then
        grep -o 'src="[^"]*"' "$file" 2>/dev/null | sed 's/src="//;s/"//' | while read -r link; do
            if [[ -n "$link" ]]; then
                check_url "$link" "$file"
            fi
        done
    fi
    
    # Extract href attributes from <link> tags (CSS, etc.) using sed
    if grep -q '<link[^>]*href="' "$file" 2>/dev/null; then
        grep -o '<link[^>]*href="[^"]*"' "$file" 2>/dev/null | sed 's/.*href="//;s/".*//' | while read -r link; do
            if [[ -n "$link" ]]; then
                check_url "$link" "$file"
            fi
        done
    fi
}

# Check all HTML files
echo "📋 Found HTML files: $(ls *.html 2>/dev/null | tr '\n' ' ')"
for html_file in *.html; do
    if [[ -f "$html_file" ]]; then
        echo "🔍 Processing: $html_file"
        extract_links_from_html "$html_file"
        echo ""
    else
        echo "⚠️  File not found: $html_file"
    fi
done

# Check CSS files for @import and url() references
echo "🎨 Checking CSS files..."
for css_file in *.css css/*.css 2>/dev/null; do
    if [[ -f "$css_file" ]]; then
        echo "📄 Checking links in $css_file..."
        
        # Extract URLs from url() functions using sed
        grep -o 'url([^)]*)' "$css_file" 2>/dev/null | sed 's/url(//;s/)//;s/["\x27]//g;s/^ *//;s/ *$//' | while read -r link; do
            # Skip data URLs and empty links
            if [[ -n "$link" && ! "$link" =~ ^data: ]]; then
                check_url "$link" "$css_file"
            fi
        done
        
        # Extract @import URLs using sed
        grep -o '@import[^;]*' "$css_file" 2>/dev/null | sed 's/@import *//;s/["\x27]//g;s/ *url(//;s/) *//;s/;.*//' | while read -r link; do
            if [[ -n "$link" ]]; then
                check_url "$link" "$css_file"
            fi
        done
        
        echo ""
    fi
done

# Read final counters
TOTAL_LINKS=$(cat "$TOTAL_FILE")
BROKEN_LINKS=$(cat "$BROKEN_FILE")
WARNINGS=$(cat "$WARNINGS_FILE")

# Summary
echo "=========================================="
echo "🔗 Link Verification Summary"
echo "=========================================="
echo "Total links checked: $TOTAL_LINKS"
echo "Broken links: $BROKEN_LINKS"
echo "Warnings: $WARNINGS"
echo ""

if [[ $BROKEN_LINKS -eq 0 ]]; then
    echo -e "${GREEN}✓ All links are working!${NC}"
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠ $WARNINGS warnings (sites that don't support HEAD requests)${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Found $BROKEN_LINKS broken links${NC}"
    echo ""
    echo "Please fix the broken links before deploying."
    exit 1
fi