#!/bin/bash

# Pre-publish secrets detection test
# This script MUST pass before any publish operation
# Detection patterns are stored outside the published repository

set -euo pipefail

echo "→ Running: Pre-publish secrets detection"
echo "   Purpose: Prevent accidental publication of sensitive information"

# Track errors
ERRORS=0
WARNINGS=0

# Define paths
WEBSITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_PATTERNS_FILE="$HOME/.ahab-secrets-patterns"

# Check if patterns file exists (created separately, never committed)
if [ ! -f "$SECRETS_PATTERNS_FILE" ]; then
    echo "ERROR: Secrets patterns file not found: $SECRETS_PATTERNS_FILE"
    echo "This file must be created manually and contains detection patterns."
    echo "Contact system administrator for setup instructions."
    exit 1
fi

echo "Scanning website files for sensitive content..."

# Get list of files to scan (exclude .git, tests, and other non-published content)
FILES_TO_SCAN=$(find "$WEBSITE_ROOT" -type f \
    -name "*.html" -o -name "*.css" -o -name "*.js" -o -name "*.md" \
    | grep -v "/.git/" \
    | grep -v "/tests/" \
    | grep -v "/.github/" \
    | grep -v "/scripts/")

# Documentation files get more lenient checking
DOC_FILES=$(echo "$FILES_TO_SCAN" | grep -E "(SECRETS_DETECTION\.md|README\.md|TUTORIAL|\.md$)")

# Load detection patterns from external file
# This file is never committed to any repository
while IFS= read -r pattern || [ -n "$pattern" ]; do
    # Skip empty lines and comments
    [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
    
    # Extract pattern type and regex
    if [[ "$pattern" =~ ^([A-Z_]+):[[:space:]]*(.+)$ ]]; then
        PATTERN_TYPE="${BASH_REMATCH[1]}"
        PATTERN_REGEX="${BASH_REMATCH[2]}"
        
        # Scan all files for this pattern
        for file in $FILES_TO_SCAN; do
            if grep -q -E "$PATTERN_REGEX" "$file" 2>/dev/null; then
                # Check if this is a documentation file or website content
                if echo "$DOC_FILES" | grep -q "$file" || [[ "$file" =~ \.(html|css)$ ]]; then
                    # For documentation and website files, be more lenient
                    # Skip common false positives for website content
                    if [[ "$PATTERN_TYPE" == "LOCALHOST_VARIANT" ]] && grep -q "localhost:8080" "$file"; then
                        # localhost:8080 is expected in tutorials
                        continue
                    fi
                    if [[ "$PATTERN_TYPE" == "ENCRYPTION_KEY" ]] && [[ "$file" =~ \.css$ ]]; then
                        # CSS files may contain @keyframes which triggers false positives
                        continue
                    fi
                    
                    # Only flag if it looks like real credentials
                    if grep -E "$PATTERN_REGEX" "$file" | grep -v -i -E "(example|template|replace_with|your_|sample|demo|documentation|tutorial|sanitized|placeholder|localhost|keyframes)" | grep -q -v -E "(REPLACE|EXAMPLE|TEMPLATE)"; then
                        echo "WARNING: Potential real $PATTERN_TYPE in documentation file $file"
                        echo "  Review to ensure this is a sanitized example"
                        ((WARNINGS++))
                    fi
                else
                    # For other files, be strict but still allow some exceptions
                    if [[ "$PATTERN_TYPE" == "LOCALHOST_VARIANT" ]] && grep -q "localhost" "$file"; then
                        echo "INFO: Localhost reference found in $file (likely safe for tutorials)"
                        continue
                    fi
                    echo "ERROR: Potential $PATTERN_TYPE detected in $file"
                    echo "  Pattern matched (details not shown for security)"
                    ((ERRORS++))
                fi
            fi
        done
    fi
done < "$SECRETS_PATTERNS_FILE"

# Additional hardcoded checks for common patterns (safe to include)
echo "Checking for common sensitive patterns..."

# Check for potential passwords (basic patterns only)
for file in $FILES_TO_SCAN; do
    # Look for password-like strings (but not the word "password" itself)
    if grep -i -E "(password|passwd|pwd)[[:space:]]*[:=][[:space:]]*['\"][^'\"]{8,}" "$file" 2>/dev/null | grep -v -E "(REPLACE_WITH|EXAMPLE|TEMPLATE|your_|sample|demo)"; then
        echo "WARNING: Potential password assignment in $file"
        ((WARNINGS++))
    fi
    
    # Look for API key patterns (generic)
    if grep -E "['\"][a-zA-Z0-9]{32,}['\"]" "$file" 2>/dev/null | grep -v "REPLACE_WITH\|EXAMPLE\|TEMPLATE"; then
        echo "WARNING: Potential API key in $file"
        ((WARNINGS++))
    fi
    
    # Look for IP addresses that might be internal
    if grep -E "192\.168\.[0-9]{1,3}\.[0-9]{1,3}" "$file" 2>/dev/null; then
        echo "WARNING: Internal IP address found in $file"
        ((WARNINGS++))
    fi
    
    # Look for email addresses that might be real
    if grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$file" 2>/dev/null | grep -v "example\|test\|demo\|sample"; then
        echo "WARNING: Potential real email address in $file"
        ((WARNINGS++))
    fi
done

# Check for references to private repositories or internal systems
for file in $FILES_TO_SCAN; do
    # Look for GitHub private repo references
    if grep -E "github\.com/[^/]+/[^/]*secret[^/]*" "$file" 2>/dev/null; then
        echo "ERROR: Reference to private repository in $file"
        ((ERRORS++))
    fi
    
    # Look for internal hostnames
    if grep -E "\.(local|internal|corp|lan)\b" "$file" 2>/dev/null; then
        echo "WARNING: Internal hostname reference in $file"
        ((WARNINGS++))
    fi
done

# Check for TODO/FIXME comments that might contain sensitive info
for file in $FILES_TO_SCAN; do
    if grep -i -E "(TODO|FIXME|HACK).*[Pp]assword" "$file" 2>/dev/null; then
        echo "WARNING: TODO/FIXME with password reference in $file"
        ((WARNINGS++))
    fi
done

# Verify sanitized examples are actually sanitized
for file in $FILES_TO_SCAN; do
    # Check that examples use placeholder text
    if grep -E "(username|password|key|token|secret)" "$file" 2>/dev/null | grep -v -E "(REPLACE_WITH|EXAMPLE|TEMPLATE|your_|placeholder|sample)" | grep -v -i "example"; then
        echo "WARNING: Potentially unsanitized example in $file"
        ((WARNINGS++))
    fi
done

# Summary
echo ""
echo "Secrets detection scan complete:"
echo "  Files scanned: $(echo "$FILES_TO_SCAN" | wc -l)"
echo "  Errors found: $ERRORS"
echo "  Warnings found: $WARNINGS"

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo "✓ No sensitive content detected - safe to publish"
        exit 0
    else
        echo "⚠ Warnings found - review before publishing"
        echo "  Warnings are not blocking but should be reviewed"
        exit 0
    fi
else
    echo "✗ ERRORS found - DO NOT PUBLISH"
    echo "  Fix all errors before attempting to publish"
    exit 1
fi