#!/bin/bash

# Simple Link Verification Script for Ahab Website
# Purpose: Verify all internal and external links work properly
# Usage: ./scripts/check-links-simple.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_LINKS=0
BROKEN_LINKS=0
WARNINGS=0

echo "🔗 Starting link verification..."
echo ""

# Function to check if a URL is accessible
check_url() {
    local url="$1"
    local source_file="$2"
    
    TOTAL_LINKS=$((TOTAL_LINKS + 1))
    
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
    
    # Skip localhost links (these are examples for local development)
    if [[ "$url" =~ ^https?://localhost ]]; then
        echo "🏠 Skipping localhost: $url"
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
            BROKEN_LINKS=$((BROKEN_LINKS + 1))
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
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "${RED}✗${NC} Broken external link: $url (in $source_file)"
            BROKEN_LINKS=$((BROKEN_LINKS + 1))
        fi
    fi
}

# Process all HTML files
for html_file in *.html; do
    if [[ -f "$html_file" ]]; then
        echo "📄 Checking links in $html_file..."
        
        # Extract all links and process them
        {
            # href attributes from <a> tags
            grep -o 'href="[^"]*"' "$html_file" 2>/dev/null | sed 's/href="//;s/"//' || true
            # src attributes from <img> tags  
            grep -o 'src="[^"]*"' "$html_file" 2>/dev/null | sed 's/src="//;s/"//' || true
            # href attributes from <link> tags
            grep -o '<link[^>]*href="[^"]*"' "$html_file" 2>/dev/null | sed 's/.*href="//;s/".*//' || true
        } | while read -r link; do
            if [[ -n "$link" ]]; then
                check_url "$link" "$html_file"
            fi
        done
        
        echo ""
    fi
done

# Check CSS files
for css_file in *.css css/*.css; do
    if [[ -f "$css_file" && "$css_file" != "*.css" && "$css_file" != "css/*.css" ]]; then
        echo "📄 Checking links in $css_file..."
        
        {
            # URLs from url() functions
            grep -o 'url([^)]*)' "$css_file" 2>/dev/null | sed 's/url(//;s/)//;s/["\x27]//g;s/^ *//;s/ *$//' || true
            # @import URLs
            grep -o '@import[^;]*' "$css_file" 2>/dev/null | sed 's/@import *//;s/["\x27]//g;s/ *url(//;s/) *//;s/;.*//' || true
        } | while read -r link; do
            if [[ -n "$link" && ! "$link" =~ ^data: ]]; then
                check_url "$link" "$css_file"
            fi
        done
        
        echo ""
    fi
done

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