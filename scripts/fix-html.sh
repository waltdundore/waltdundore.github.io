#!/bin/bash

# HTML Auto-Fix - NASA Power of 10 & Zero Trust Compliant
# Rule #7: Check return values
# Rule #2: Bounded loops (no while true)
# Zero Trust: No inline scripts/styles
# AUTO-FIX: Modifies files to fix compliance issues

set -euo pipefail

echo "→ Running: HTML auto-fix"
echo "   Purpose: Automatically fix HTML structure, accessibility, and Zero Trust compliance issues"

# Track fixes (Rule #7: Check return values)
FIXES=0
FILES_PROCESSED=0

# Auto-fix function for missing meta tags
fix_missing_meta_tags() {
    local file="$1"
    local backup_file="${file}.backup"
    
    # Create backup
    cp "$file" "$backup_file"
    
    # Check and fix charset
    if ! grep -q 'charset="UTF-8"' "$file"; then
        echo "  → FIXING: Adding UTF-8 charset to $file"
        sed -i.tmp '/<head>/a\
    <meta charset="UTF-8">' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
    
    # Check and fix viewport
    if ! grep -q 'name="viewport"' "$file"; then
        echo "  → FIXING: Adding viewport meta tag to $file"
        sed -i.tmp '/<meta charset="UTF-8">/a\
    <meta name="viewport" content="width=device-width, initial-scale=1.0">' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
    
    # Check and fix description (add placeholder if missing)
    if ! grep -q 'name="description"' "$file"; then
        echo "  → FIXING: Adding description meta tag to $file"
        # Extract title for description
        local title=$(grep -o '<title>[^<]*</title>' "$file" | sed 's/<title>\(.*\)<\/title>/\1/' || echo "Ahab Project")
        sed -i.tmp "/<meta name=\"viewport\"/a\\
    <meta name=\"description\" content=\"$title - Learn infrastructure automation with hands-on practice\">" "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
}

# Auto-fix function for missing alt text
fix_missing_alt_text() {
    local file="$1"
    
    # Find images without alt text and add generic alt
    if grep -q '<img[^>]*>' "$file" && ! grep -q '<img[^>]*alt=' "$file"; then
        echo "  → FIXING: Adding alt text to images in $file"
        # Add alt="" to images that don't have it
        sed -i.tmp 's/<img\([^>]*\)>/<img\1 alt="Image">/' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
}

# Auto-fix function for missing semantic elements
fix_missing_semantic_elements() {
    local file="$1"
    
    # Add main element if missing
    if ! grep -q '<main>' "$file"; then
        echo "  → FIXING: Adding <main> element to $file"
        # Look for container div and wrap its content in main
        if grep -q '<div class="container">' "$file"; then
            # Add main after container div
            sed -i.tmp 's/<div class="container">/<div class="container">\
        <main id="main">/' "$file"
            # Close main before closing container div
            sed -i.tmp 's/<\/div><!-- \.container -->/<\/main>\
    <\/div><!-- \.container -->/' "$file"
        else
            # Fallback: wrap content after navigation in main
            sed -i.tmp 's/<!-- Hero Section -->/<main id="main">\
        <!-- Hero Section -->/' "$file"
            # Close main before footer
            sed -i.tmp 's/<footer>/<\/main>\
        \
        <footer>/' "$file"
        fi
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
    
    # Add skip link if missing
    if ! grep -q 'skip-link' "$file"; then
        echo "  → FIXING: Adding skip link to $file"
        sed -i.tmp '/<body>/a\
    <!-- Skip to main content link (accessibility) -->\
    <a href="#main" class="skip-link">Skip to main content</a>' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
}

# Auto-fix function for language attribute
fix_missing_lang_attribute() {
    local file="$1"
    
    if ! grep -q 'lang=' "$file"; then
        echo "  → FIXING: Adding lang attribute to $file"
        sed -i.tmp 's/<html>/<html lang="en">/' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
}

# Bounded loop over HTML files (Rule #2: No unbounded loops)
for file in *.html; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    echo "Fixing $file..."
    ((FILES_PROCESSED++))
    
    # Auto-fix missing meta tags
    fix_missing_meta_tags "$file"
    
    # Auto-fix missing alt text
    fix_missing_alt_text "$file"
    
    # Auto-fix missing semantic elements
    fix_missing_semantic_elements "$file"
    
    # Auto-fix missing lang attribute
    fix_missing_lang_attribute "$file"
    
    # Zero Trust: Remove inline styles
    if grep -q 'style=' "$file"; then
        echo "  → FIXING: Removing inline styles from $file (Zero Trust violation)"
        sed -i.tmp 's/ style="[^"]*"//g' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
    
    # Zero Trust: Remove inline JavaScript
    if grep -E '(onclick|onload|onchange|onsubmit|onmouseover)=' "$file" >/dev/null 2>&1; then
        echo "  → FIXING: Removing inline JavaScript from $file (Zero Trust violation)"
        sed -i.tmp 's/ on[a-z]*="[^"]*"//g' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
    
    echo "✓ $file processed"
done

# Summary (Rule #7: Check return values)
echo ""
echo "HTML auto-fix summary:"
echo "  Files processed: $FILES_PROCESSED"
echo "  Fixes applied: $FIXES"

if [ $FIXES -gt 0 ]; then
    echo "✓ HTML auto-fix completed - $FIXES issues resolved"
    echo "  Backup files created with .backup extension"
    echo "  Run 'make test' to verify fixes"
else
    echo "✓ No HTML fixes needed - all files already compliant"
fi

exit 0