#!/bin/bash

# Simplified secrets detection for website publishing
# Focuses on actual secrets, not legitimate development content

set -euo pipefail

echo "→ Running: Simplified pre-publish secrets detection"
echo "   Purpose: Prevent accidental publication of real sensitive information"

# Track errors
ERRORS=0
WARNINGS=0

# Define paths
WEBSITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Get list of files to scan (exclude .git, tests, and other non-published content)
FILES_TO_SCAN=$(find "$WEBSITE_ROOT" -type f \
    -name "*.html" -o -name "*.css" -o -name "*.js" -o -name "*.md" \
    | grep -v "/.git/" \
    | grep -v "/tests/" \
    | grep -v "/.github/" \
    | grep -v "/scripts/")

echo "Scanning website files for real secrets..."

# Check for actual secrets (high confidence patterns only)
for file in $FILES_TO_SCAN; do
    
    # Real API keys (high confidence patterns)
    if grep -E "(sk_live_|pk_live_|rk_live_)[a-zA-Z0-9]{20,}" "$file" 2>/dev/null; then
        echo "ERROR: Real API key detected in $file"
        ((ERRORS++))
    fi
    
    # Real AWS keys
    if grep -E "AKIA[0-9A-Z]{16}" "$file" 2>/dev/null; then
        echo "ERROR: Real AWS access key detected in $file"
        ((ERRORS++))
    fi
    
    # Real GitHub tokens
    if grep -E "ghp_[a-zA-Z0-9]{36}" "$file" 2>/dev/null; then
        echo "ERROR: Real GitHub token detected in $file"
        ((ERRORS++))
    fi
    
    # Real SSH private keys
    if grep -E "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----" "$file" 2>/dev/null; then
        echo "ERROR: SSH private key detected in $file"
        ((ERRORS++))
    fi
    
    # Real database connection strings with credentials
    if grep -E "(mysql|postgresql|mongodb)://[^:]+:[^@/]+@[^/]+" "$file" 2>/dev/null | grep -v -E "(USER|PASSWORD|REPLACE|EXAMPLE|user:pass)"; then
        echo "ERROR: Real database connection string detected in $file"
        ((ERRORS++))
    fi
    
    # Real passwords in configuration (not examples)
    if grep -E "password[[:space:]]*[:=][[:space:]]*['\"][^'\"]{12,}['\"]" "$file" 2>/dev/null | grep -v -E "(REPLACE|EXAMPLE|your_|sample|demo|test|password123)"; then
        echo "WARNING: Potential real password in $file"
        ((WARNINGS++))
    fi
    
    # Real email addresses (not examples)
    if grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$file" 2>/dev/null | grep -v -E "(example\.(com|org)|test@|demo@|sample@|your@|admin@example|user@example)"; then
        # Skip if it's clearly documentation
        if ! grep -B2 -A2 -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$file" | grep -q -i -E "(example|template|replace|your_|sample|demo)"; then
            echo "WARNING: Potential real email address in $file"
            ((WARNINGS++))
        fi
    fi
    
    # Internal IP addresses (but allow common examples)
    if grep -E "(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)" "$file" 2>/dev/null | grep -v -E "(192\.168\.1\.1|10\.0\.0\.1|example|documentation)"; then
        echo "WARNING: Internal IP address in $file"
        ((WARNINGS++))
    fi
    
done

# Check for references to private repositories
for file in $FILES_TO_SCAN; do
    if grep -E "github\.com/[^/]+/[^/]*secret[^/]*" "$file" 2>/dev/null; then
        echo "ERROR: Reference to private repository in $file"
        ((ERRORS++))
    fi
done

# Summary
echo ""
echo "Simplified secrets detection complete:"
echo "  Files scanned: $(echo "$FILES_TO_SCAN" | wc -l)"
echo "  Errors found: $ERRORS"
echo "  Warnings found: $WARNINGS"

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo "✓ No real secrets detected - safe to publish"
        exit 0
    else
        echo "⚠ Warnings found - review before publishing"
        echo "  Warnings indicate potentially sensitive content that should be reviewed"
        exit 0
    fi
else
    echo "✗ REAL SECRETS DETECTED - DO NOT PUBLISH"
    echo "  Fix all errors before attempting to publish"
    exit 1
fi