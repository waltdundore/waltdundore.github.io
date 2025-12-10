#!/bin/bash

# Link Validation - NASA Power of 10 & Zero Trust Compliant
# Rule #7: Check return values
# Rule #2: Bounded loops
# Rule #4: Function length ≤ 60 lines

set -euo pipefail

echo "→ Running: Link validation"
echo "   Purpose: Verify all internal and external links work correctly"

# Track errors (Rule #7: Check return values)
ERRORS=0
WARNINGS=0
CHECKED_LINKS=0

# Function to check a single link (Rule #4: ≤ 60 lines)
check_link() {
    local url="$1"
    local file="$2"
    local timeout=10
    
    # Skip anchors and javascript links
    if [[ "$url" =~ ^# ]] || [[ "$url" =~ ^javascript: ]]; then
        return 0
    fi
    
    # Check internal links (files)
    if [[ "$url" =~ ^[^http] ]] && [[ ! "$url" =~ ^mailto: ]]; then
        if [ -f "$url" ] || [ -f "${url#./}" ]; then
            echo "✓ Internal link: $url"
            return 0
        else
            echo "ERROR: Broken internal link in $file: $url"
            return 1
        fi
    fi
    
    # Check external links (HTTP/HTTPS)
    if [[ "$url" =~ ^https?:// ]]; then
        if curl -s --head --max-time "$timeout" "$url" >/dev/null 2>&1; then
            echo "✓ External link: $url"
            return 0
        else
            echo "WARNING: External link may be broken in $file: $url"
            return 2
        fi
    fi
    
    # Check mailto links
    if [[ "$url" =~ ^mailto: ]]; then
        echo "✓ Email link: $url"
        return 0
    fi
    
    return 0
}

# Function to extract links from HTML file (Rule #4: ≤ 60 lines)
extract_links() {
    local file="$1"
    
    # Extract href attributes (bounded extraction)
    grep -o 'href="[^"]*"' "$file" 2>/dev/null | \
        sed 's/href="//g' | \
        sed 's/"$//g' | \
        head -50  # Bounded to 50 links per file (Rule #2)
}

# Main validation loop (Rule #2: Bounded loops)
HTML_FILES=$(find . -name "*.html" -type f | head -10)  # Max 10 files
for file in $HTML_FILES; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    echo "Checking links in $file..."
    
    # Extract and check links (bounded loop)
    LINKS=$(extract_links "$file")
    LINK_COUNT=0
    
    while IFS= read -r link && [ $LINK_COUNT -lt 50 ]; do
        if [ -n "$link" ]; then
            ((CHECKED_LINKS++))
            ((LINK_COUNT++))
            
            if check_link "$link" "$file"; then
                continue
            elif [ $? -eq 1 ]; then
                ((ERRORS++))
            elif [ $? -eq 2 ]; then
                ((WARNINGS++))
            fi
        fi
    done <<< "$LINKS"
    
    echo "✓ $file checked ($LINK_COUNT links)"
done

# Check for common link patterns
echo "Checking for common link issues..."

# Check for hardcoded localhost links (should be relative)
if grep -r 'href="http://localhost' . --include="*.html" >/dev/null 2>&1; then
    echo "WARNING: Hardcoded localhost links found (use relative paths)"
    ((WARNINGS++))
fi

# Check for mixed content (HTTP links on HTTPS site)
if grep -r 'href="http://' . --include="*.html" >/dev/null 2>&1; then
    HTTP_COUNT=$(grep -r 'href="http://' . --include="*.html" | wc -l || echo 0)
    echo "INFO: $HTTP_COUNT HTTP links found (consider HTTPS where possible)"
fi

# Check for empty href attributes
if grep -r 'href=""' . --include="*.html" >/dev/null 2>&1; then
    echo "ERROR: Empty href attributes found"
    ((ERRORS++))
fi

# Check for missing target="_blank" on external links
EXTERNAL_WITHOUT_TARGET=$(grep -r 'href="https\?://' . --include="*.html" | \
    grep -v 'target="_blank"' | wc -l || echo 0)

if [ "$EXTERNAL_WITHOUT_TARGET" -gt 0 ]; then
    echo "INFO: $EXTERNAL_WITHOUT_TARGET external links without target='_blank'"
fi

# Summary (Rule #7: Check return values)
echo ""
echo "Link validation summary:"
echo "  Files checked: $(echo "$HTML_FILES" | wc -w)"
echo "  Links checked: $CHECKED_LINKS"
echo "  Errors: $ERRORS"
echo "  Warnings: $WARNINGS"

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo "✓ Link validation passed (all links working)"
    else
        echo "✓ Link validation passed with $WARNINGS warnings"
        echo "  External link warnings may be temporary (network issues)"
    fi
    exit 0
else
    echo "✗ Link validation failed with $ERRORS errors"
    echo "  Fix broken internal links before deployment"
    exit 1
fi