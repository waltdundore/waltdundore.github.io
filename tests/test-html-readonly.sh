#!/bin/bash

# HTML Validation (READ-ONLY) - NASA Power of 10 & Zero Trust Compliant
# Rule #7: Check return values
# Rule #2: Bounded loops (no while true)
# Zero Trust: No inline scripts/styles
# READ-ONLY: Only validates, NEVER modifies files

set -euo pipefail

echo "→ Running: HTML validation (read-only)"
echo "   Purpose: Validate HTML structure, accessibility, and Zero Trust compliance WITHOUT modifying files"

# Track errors and warnings (Rule #7: Check return values)
ERRORS=0
WARNINGS=0
FILES_CHECKED=0

# Validation function for meta tags
check_meta_tags() {
    local file="$1"
    local issues=0
    
    # Check charset
    if ! grep -q 'charset="UTF-8"' "$file"; then
        echo "ERROR: Missing UTF-8 charset in $file"
        ((issues++))
    fi
    
    # Check viewport
    if ! grep -q 'name="viewport"' "$file"; then
        echo "ERROR: Missing viewport meta tag in $file"
        ((issues++))
    fi
    
    # Check description
    if ! grep -q 'name="description"' "$file"; then
        echo "WARNING: Missing description meta tag in $file"
        ((WARNINGS++))
    fi
    
    return $issues
}

# Validation function for alt text
check_alt_text() {
    local file="$1"
    local issues=0
    
    # Find images without alt text
    if grep -q '<img' "$file"; then
        IMG_COUNT=$(grep -o '<img[^>]*>' "$file" | wc -l || echo 0)
        ALT_COUNT=$(grep -o '<img[^>]*alt=' "$file" | wc -l || echo 0)
        
        if [ "$IMG_COUNT" -gt "$ALT_COUNT" ]; then
            echo "ERROR: Images missing alt text in $file ($((IMG_COUNT - ALT_COUNT)) images)"
            ((issues++))
        fi
    fi
    
    return $issues
}

# Validation function for semantic elements
check_semantic_elements() {
    local file="$1"
    local issues=0
    
    # Check for main element
    if ! grep -q '<main' "$file"; then
        echo "ERROR: Missing <main> element in $file"
        ((issues++))
    fi
    
    # Check for skip link
    if ! grep -q 'skip-link' "$file"; then
        echo "WARNING: Missing skip link in $file"
        ((WARNINGS++))
    fi
    
    return $issues
}

# Validation function for language attribute
check_lang_attribute() {
    local file="$1"
    local issues=0
    
    if ! grep -q 'lang=' "$file"; then
        echo "ERROR: Missing lang attribute in $file"
        ((issues++))
    fi
    
    return $issues
}

# Bounded loop over HTML files (Rule #2: No unbounded loops)
for file in *.html; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    echo "Validating $file..."
    ((FILES_CHECKED++))
    
    # Validate meta tags
    check_meta_tags "$file"
    ERRORS=$((ERRORS + $?))
    
    # Validate alt text
    check_alt_text "$file"
    ERRORS=$((ERRORS + $?))
    
    # Validate semantic elements
    check_semantic_elements "$file"
    ERRORS=$((ERRORS + $?))
    
    # Validate lang attribute
    check_lang_attribute "$file"
    ERRORS=$((ERRORS + $?))
    
    # Zero Trust: Check for inline styles
    if grep -q 'style=' "$file"; then
        echo "ERROR: Inline styles found in $file (Zero Trust violation)"
        ((ERRORS++))
    fi
    
    # Zero Trust: Check for inline JavaScript
    if grep -E '(onclick|onload|onchange|onsubmit|onmouseover)=' "$file" >/dev/null 2>&1; then
        echo "ERROR: Inline JavaScript found in $file (Zero Trust violation)"
        ((ERRORS++))
    fi
    
    # Proper heading hierarchy check
    if grep -q '<h1>' "$file"; then
        H1_COUNT=$(grep -o '<h1>' "$file" | wc -l || echo 0)
        if [ "$H1_COUNT" -gt 1 ]; then
            echo "WARNING: Multiple <h1> elements in $file (consider using <h2> for subheadings)"
            ((WARNINGS++))
        fi
    fi
    
    if [ $ERRORS -eq 0 ]; then
        echo "✓ $file validation passed"
    fi
done

# Summary (Rule #7: Check return values)
echo ""
echo "HTML validation summary:"
echo "  Files checked: $FILES_CHECKED"
echo "  Errors found: $ERRORS"
echo "  Warnings found: $WARNINGS"

if [ $ERRORS -eq 0 ]; then
    echo "✓ All HTML files are compliant (NASA Power of 10 & Zero Trust)"
    exit 0
else
    echo "❌ HTML validation failed - $ERRORS errors found"
    echo "   Run 'make fix-html' to automatically fix these issues"
    exit 1
fi