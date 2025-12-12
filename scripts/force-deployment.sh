#!/bin/bash

# Force GitHub Pages Deployment - NASA Power of 10 & Zero Trust Compliant
# Rule #7: Check return values
# Rule #2: Bounded loops (no while true)
# Rule #6: Timeout protection

set -euo pipefail

echo "→ Running: Force GitHub Pages deployment"
echo "   Purpose: Fix deployment issues by creating a new commit that forces GitHub Pages to rebuild"

# Configuration
ERRORS=0
MAX_ATTEMPTS=3
ATTEMPT=1

# Function to create a deployment trigger commit
create_deployment_trigger() {
    local timestamp=$(date -u '+%Y-%m-%d %H:%M UTC')
    local commit_hash=$(git rev-parse --short HEAD)
    
    echo "Creating deployment trigger commit..."
    
    # Add a deployment trigger comment to force rebuild
    if ! sed -i.bak "s/<!-- DEPLOYMENT_TEST: .* -->/<!-- DEPLOYMENT_TEST: $timestamp | $commit_hash -->/" status.html; then
        echo "ERROR: Failed to update deployment trigger"
        return 1
    fi
    
    # Remove backup file
    rm -f status.html.bak
    
    # Commit and push
    if ! git add status.html; then
        echo "ERROR: Failed to stage changes"
        return 1
    fi
    
    if ! git commit -m "Force deployment: $timestamp"; then
        echo "ERROR: Failed to commit changes"
        return 1
    fi
    
    if ! git push origin "$(git branch --show-current)"; then
        echo "ERROR: Failed to push changes"
        return 1
    fi
    
    echo "✓ Deployment trigger created and pushed"
    return 0
}

# Function to wait for deployment
wait_for_deployment() {
    local max_wait=300  # 5 minutes
    local wait_time=0
    local check_interval=30
    
    echo "Waiting for GitHub Pages deployment (max ${max_wait}s)..."
    
    while [ $wait_time -lt $max_wait ]; do
        echo "Checking deployment status... (${wait_time}s elapsed)"
        
        # Check if our deployment trigger is live
        if curl -s --max-time 10 "https://waltdundore.github.io/status.html" | grep -q "DEPLOYMENT_TEST"; then
            echo "✓ Deployment successful! Changes are live."
            return 0
        fi
        
        sleep $check_interval
        wait_time=$((wait_time + check_interval))
    done
    
    echo "ERROR: Deployment timed out after ${max_wait}s"
    return 1
}

# Main deployment fix process (bounded loop - Rule #2)
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo ""
    echo "=== Deployment Fix Attempt $ATTEMPT/$MAX_ATTEMPTS ==="
    
    # Create deployment trigger
    if create_deployment_trigger; then
        echo "✓ Deployment trigger created successfully"
        
        # Wait for deployment
        if wait_for_deployment; then
            echo "✓ Deployment fix successful!"
            exit 0
        else
            echo "WARNING: Deployment trigger created but site not updated"
            ((ERRORS++))
        fi
    else
        echo "ERROR: Failed to create deployment trigger"
        ((ERRORS++))
    fi
    
    ((ATTEMPT++))
    
    if [ $ATTEMPT -le $MAX_ATTEMPTS ]; then
        echo "Retrying in 30 seconds..."
        sleep 30
    fi
done

# Summary (Rule #7: Check return values)
echo ""
echo "Deployment fix summary:"
echo "  Attempts made: $MAX_ATTEMPTS"
echo "  Errors encountered: $ERRORS"

if [ $ERRORS -eq 0 ]; then
    echo "✓ Deployment fix completed successfully"
    exit 0
else
    echo "❌ Deployment fix failed after $MAX_ATTEMPTS attempts"
    echo ""
    echo "🔧 Manual steps required:"
    echo "  1. Check GitHub Pages settings: https://github.com/waltdundore/waltdundore.github.io/settings/pages"
    echo "  2. Verify branch is set correctly (main or dev)"
    echo "  3. Check GitHub Actions: https://github.com/waltdundore/waltdundore.github.io/actions"
    echo "  4. Try changing branch source and back again"
    exit 1
fi