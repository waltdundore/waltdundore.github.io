#!/bin/bash

echo "Testing performance standards..."

# Track errors
ERRORS=0

for file in *.html; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    echo "Checking performance in $file..."
    
    # Check file size (should be reasonable)
    FILE_SIZE=$(wc -c < "$file")
    if [ "$FILE_SIZE" -gt 100000 ]; then  # 100KB
        echo "WARNING: Large HTML file $file (${FILE_SIZE} bytes) - consider optimization"
    fi
    
    # Count external resources
    EXTERNAL_CSS=$(grep -c 'href="https://' "$file" || echo 0)
    EXTERNAL_JS=$(grep -c 'src="https://' "$file" || echo 0)
    
    if [ "$EXTERNAL_CSS" -gt 2 ]; then
        echo "WARNING: Many external CSS files ($EXTERNAL_CSS) in $file - consider bundling"
    fi
    
    if [ "$EXTERNAL_JS" -gt 2 ]; then
        echo "WARNING: Many external JS files ($EXTERNAL_JS) in $file - consider bundling"
    fi
    
    # Check for performance best practices
    if ! grep -q 'rel="preconnect"' "$file" && grep -q 'fonts.googleapis.com' "$file"; then
        echo "INFO: Consider adding preconnect for Google Fonts in $file"
    fi
    
    # Check for lazy loading on images
    IMG_COUNT=$(grep -c '<img' "$file" || echo 0)
    LAZY_COUNT=$(grep -c 'loading="lazy"' "$file" || echo 0)
    
    if [ "$IMG_COUNT" -gt 3 ] && [ "$LAZY_COUNT" -eq 0 ]; then
        echo "INFO: Consider adding lazy loading to images in $file"
    fi
    
    echo "✓ $file performance checked"
done

# Check CSS file size
if [ -f "style.css" ]; then
    CSS_SIZE=$(wc -c < "style.css")
    echo "CSS file size: ${CSS_SIZE} bytes"
    
    if [ "$CSS_SIZE" -gt 50000 ]; then  # 50KB
        echo "WARNING: Large CSS file (${CSS_SIZE} bytes) - consider optimization"
    fi
    
    # Check for unused CSS (basic check)
    if grep -q '@import' style.css; then
        echo "WARNING: @import found in CSS - consider inlining for better performance"
    fi
fi

# Check for JavaScript files
JS_FILES=$(find . -name "*.js" -not -path "./node_modules/*" 2>/dev/null || echo "")
if [ -n "$JS_FILES" ]; then
    for js_file in $JS_FILES; do
        JS_SIZE=$(wc -c < "$js_file")
        echo "JavaScript file $js_file size: ${JS_SIZE} bytes"
        
        if [ "$JS_SIZE" -gt 30000 ]; then  # 30KB
            echo "WARNING: Large JavaScript file $js_file (${JS_SIZE} bytes)"
        fi
    done
fi

# Check image optimization (if images directory exists)
if [ -d "images" ]; then
    echo "Checking image optimization..."
    
    for img in images/*; do
        if [ -f "$img" ]; then
            IMG_SIZE=$(wc -c < "$img")
            
            # Check for large images
            if [ "$IMG_SIZE" -gt 500000 ]; then  # 500KB
                echo "WARNING: Large image file $img (${IMG_SIZE} bytes) - consider optimization"
            fi
            
            # Check image format
            case "$img" in
                *.jpg|*.jpeg)
                    echo "✓ $img (JPEG format)"
                    ;;
                *.png)
                    if [ "$IMG_SIZE" -gt 100000 ]; then  # 100KB for PNG
                        echo "INFO: Large PNG $img - consider JPEG or WebP for photos"
                    fi
                    ;;
                *.webp)
                    echo "✓ $img (WebP format - excellent choice)"
                    ;;
                *.svg)
                    echo "✓ $img (SVG format - good for icons)"
                    ;;
                *)
                    echo "INFO: $img - consider modern formats (WebP, AVIF)"
                    ;;
            esac
        fi
    done
fi

# Performance recommendations
echo ""
echo "Performance recommendations:"
echo "- Keep HTML files under 100KB"
echo "- Keep CSS files under 50KB"
echo "- Keep JavaScript files under 30KB"
echo "- Optimize images (use WebP when possible)"
echo "- Use lazy loading for images below the fold"
echo "- Minimize external resource requests"

if [ $ERRORS -eq 0 ]; then
    echo "✓ Performance validation passed"
    exit 0
else
    echo "✗ Performance validation failed with $ERRORS errors"
    exit 1
fi