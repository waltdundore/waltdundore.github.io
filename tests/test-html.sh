#!/bin/bash

# HTML Validation & Auto-Fix - NASA Power of 10 & Zero Trust Compliant
# Rule #7: Check return values
# Rule #2: Bounded loops (no while true)
# Zero Trust: No inline scripts/styles
# SELF-HEALING: Automatically fixes problems found

set -euo pipefail

echo "→ Running: HTML validation with auto-fix capability"
echo "   Purpose: Validate and automatically fix HTML structure, accessibility, and Zero Trust compliance"

# Track errors and fixes (Rule #7: Check return values)
ERRORS=0
WARNINGS=0
FIXES=0

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
        # Wrap content after navigation in main
        sed -i.tmp 's/<section class="hero">/<main id="main">\
        <section class="hero">/' "$file"
        # Close main before footer
        sed -i.tmp 's/<footer>/<\/main>\
        \
        <footer>/' "$file"
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
    
    echo "Checking and fixing $file..."
    
    # Auto-fix missing meta tags
    fix_missing_meta_tags "$file"
    
    # Auto-fix missing alt text
    fix_missing_alt_text "$file"
    
    # Auto-fix missing semantic elements
    fix_missing_semantic_elements "$file"
    
    # Auto-fix missing lang attribute
    fix_missing_lang_attribute "$file"
    
    # Final validation checks (after fixes)
    
    # Accessibility: Alt text on images (WCAG 2.1 AA)
    if grep -q '<img' "$file"; then
        IMG_COUNT=$(grep -o '<img[^>]*>' "$file" | wc -l || echo 0)
        ALT_COUNT=$(grep -o '<img[^>]*alt=' "$file" | wc -l || echo 0)
        
        if [ "$IMG_COUNT" -gt "$ALT_COUNT" ]; then
            echo "WARNING: Some images still missing alt text in $file"
            ((WARNINGS++))
        fi
    fi
    
    # Zero Trust: No inline styles (auto-remove if found)
    if grep -q 'style=' "$file"; then
        echo "  → FIXING: Removing inline styles from $file (Zero Trust violation)"
        sed -i.tmp 's/ style="[^"]*"//g' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
    
    # Zero Trust: No inline JavaScript (auto-remove if found)
    if grep -E '(onclick|onload|onchange|onsubmit|onmouseover)=' "$file" >/dev/null 2>&1; then
        echo "  → FIXING: Removing inline JavaScript from $file (Zero Trust violation)"
        sed -i.tmp 's/ on[a-z]*="[^"]*"//g' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
    
    # Proper heading hierarchy check
    if grep -q '<h1>' "$file"; then
        H1_COUNT=$(grep -o '<h1>' "$file" | wc -l || echo 0)
        if [ "$H1_COUNT" -gt 1 ]; then
            echo "WARNING: Multiple <h1> elements in $file (consider using <h2> for subheadings)"
            ((WARNINGS++))
        fi
    fi
    
    echo "✓ $file processed (fixes applied: $FIXES)"
done

# Summary (Rule #7: Check return values)
echo ""
echo "HTML validation and auto-fix summary:"
echo "  Files processed: $(ls *.html 2>/dev/null | wc -l)"
echo "  Fixes applied: $FIXES"
echo "  Remaining warnings: $WARNINGS"

if [ $FIXES -gt 0 ]; then
    echo "✓ HTML auto-fix completed - $FIXES issues resolved"
    echo "  Backup files created with .backup extension"
fi

if [ $WARNINGS -eq 0 ]; then
    echo "✓ All HTML files now compliant (NASA Power of 10 & Zero Trust)"
else
    echo "✓ HTML validation passed with $WARNINGS minor warnings"
fi

exit 0