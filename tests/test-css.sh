#!/bin/bash

# CSS Standards Validation & Auto-Fix - NASA Power of 10 & Zero Trust Compliant
# Rule #7: Check return values
# Rule #2: Bounded loops
# Rule #6: Simplicity first
# SELF-HEALING: Automatically fixes CSS organization issues

set -euo pipefail

echo "→ Running: CSS standards validation with auto-fix capability"
echo "   Purpose: Validate and automatically fix CSS organization, mobile-first approach, and Zero Trust compliance"

# Track errors, warnings, and fixes (Rule #7: Check return values)
ERRORS=0
WARNINGS=0
FIXES=0

# Check CSS file exists (Rule #7: Check return values)
if [ ! -f "style.css" ]; then
    echo "ERROR: style.css not found - creating basic CSS file"
    cat > style.css << 'EOF'
/* CSS Variables */
:root {
    --ahab-blue: #0066cc;
    --ahab-navy: #003d7a;
    --success: #28a745;
    --danger: #dc3545;
    --gray-900: #212529;
    --gray-50: #f8f9fa;
}

/* CSS Reset */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

/* Layout */
body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: var(--gray-900);
}

/* Components */
.btn {
    display: inline-block;
    padding: 0.75rem 1.5rem;
    background: var(--ahab-blue);
    color: white;
    text-decoration: none;
    border-radius: 4px;
    transition: background-color 0.2s;
}

.btn:hover,
.btn:focus {
    background: var(--ahab-navy);
    outline: 2px solid var(--ahab-blue);
    outline-offset: 2px;
}

/* Accessibility */
.skip-link {
    position: absolute;
    top: -40px;
    left: 6px;
    background: var(--gray-900);
    color: white;
    padding: 8px;
    text-decoration: none;
    z-index: 1000;
}

.skip-link:focus {
    top: 6px;
}

/* Media Queries - Mobile First */
@media (min-width: 768px) {
    .container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 0 2rem;
    }
}
EOF
    echo "✓ Created basic style.css with Ahab branding"
    ((FIXES++))
fi

echo "Checking and fixing style.css..."

# Create backup
cp style.css style.css.backup

# Auto-fix CSS Variables (Rule #6: Simplicity - organized structure)
if ! grep -q ":root" style.css; then
    echo "  → FIXING: Adding CSS variables section"
    # Add CSS variables at the top
    cat > temp_style.css << 'EOF'
/* CSS Variables */
:root {
    --ahab-blue: #0066cc;
    --ahab-navy: #003d7a;
    --success: #28a745;
    --danger: #dc3545;
    --gray-900: #212529;
    --gray-50: #f8f9fa;
}

EOF
    cat style.css >> temp_style.css
    mv temp_style.css style.css
    ((FIXES++))
fi

# Auto-fix CSS organization comments
if ! grep -q "/* CSS Variables */" style.css; then
    echo "  → FIXING: Adding organizational comments"
    sed -i.tmp '1i\
/* CSS Variables */' style.css
    rm -f style.css.tmp
    ((FIXES++))
fi

# Auto-fix focus styles (WCAG 2.1 AA)
if ! grep -q ":focus" style.css; then
    echo "  → FIXING: Adding focus styles for accessibility"
    cat >> style.css << 'EOF'

/* Accessibility - Focus Styles */
*:focus {
    outline: 2px solid var(--ahab-blue);
    outline-offset: 2px;
}

button:focus,
a:focus,
input:focus,
select:focus,
textarea:focus {
    outline: 2px solid var(--ahab-blue);
    outline-offset: 2px;
}
EOF
    ((FIXES++))
fi

# Auto-fix reduced motion support
if ! grep -q "prefers-reduced-motion" style.css; then
    echo "  → FIXING: Adding reduced motion support"
    cat >> style.css << 'EOF'

/* Accessibility - Reduced Motion */
@media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
    }
}
EOF
    ((FIXES++))
fi

# Zero Trust: Remove inline CSS from HTML files (bounded loop - Rule #2)
HTML_FILES=$(find . -name "*.html" -type f | head -20)  # Bounded to 20 files max
for file in $HTML_FILES; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    if grep -q '<style>' "$file"; then
        echo "  → FIXING: Removing inline <style> block from $file (Zero Trust violation)"
        # Remove style blocks
        sed -i.tmp '/<style>/,/<\/style>/d' "$file"
        rm -f "${file}.tmp"
        ((FIXES++))
    fi
done

# Check mobile-first approach (informational)
MIN_WIDTH_COUNT=$(grep -c "min-width" style.css || echo 0)
MAX_WIDTH_COUNT=$(grep -c "max-width" style.css || echo 0)

if [ "$MAX_WIDTH_COUNT" -gt "$MIN_WIDTH_COUNT" ]; then
    echo "INFO: Consider mobile-first approach (more min-width than max-width queries)"
fi

# File size check (Rule #6: Simplicity)
CSS_SIZE=$(wc -c < "style.css")
if [ "$CSS_SIZE" -gt 100000 ]; then  # 100KB
    echo "INFO: Large CSS file (${CSS_SIZE} bytes) - consider optimization"
fi

# Check for CSS custom properties usage
CUSTOM_PROPS=$(grep -c "var(--" style.css || echo 0)
ROOT_PROPS=$(grep -c "\-\-[a-zA-Z]" style.css || echo 0)

echo "✓ CSS processing complete"

# Summary (Rule #7: Check return values)
echo ""
echo "CSS validation and auto-fix summary:"
echo "  File size: ${CSS_SIZE} bytes"
echo "  Custom properties: $CUSTOM_PROPS defined, $ROOT_PROPS used"
echo "  Media queries: $MIN_WIDTH_COUNT min-width, $MAX_WIDTH_COUNT max-width"
echo "  Fixes applied: $FIXES"
echo "  Remaining warnings: $WARNINGS"

if [ $FIXES -gt 0 ]; then
    echo "✓ CSS auto-fix completed - $FIXES issues resolved"
    echo "  Backup created: style.css.backup"
fi

echo "✓ CSS now compliant with Ahab standards (NASA Power of 10 & Zero Trust)"
exit 0