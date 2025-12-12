#!/bin/bash
# Monitor GitHub Pages deployment status
# Following ahab development rules: DRY, functional, well-documented

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check live site version
check_live_version() {
    print_info "Checking live site version..."
    
    local live_version
    live_version=$(curl -s https://waltdundore.github.io/status.html | grep "VERSION_TRACKING" | head -1 || echo "Not found")
    
    if [[ "$live_version" == "Not found" ]]; then
        print_warning "No version tracking found on live site"
        return 1
    else
        print_info "Live version: $live_version"
        return 0
    fi
}

# Check corruption status
check_corruption_status() {
    print_info "Checking corruption status..."
    
    local main_count
    main_count=$(curl -s https://waltdundore.github.io/status.html | grep -c "main id=" || echo "0")
    
    print_info "Live site main tag count: $main_count"
    
    if [[ "$main_count" -eq 1 ]]; then
        print_success "Live site is clean (1 main tag) ✅"
        return 0
    else
        print_error "Live site still corrupted ($main_count main tags) ❌"
        return 1
    fi
}

# Check local version
check_local_version() {
    print_info "Checking local version..."
    
    local local_version
    local_version=$(grep "VERSION_TRACKING" status.html | head -1 || echo "Not found")
    
    if [[ "$local_version" == "Not found" ]]; then
        print_warning "No version tracking in local files"
        return 1
    else
        print_info "Local version: $local_version"
        return 0
    fi
}

# Main monitoring function
main() {
    print_info "=== GitHub Pages Deployment Monitor ==="
    print_info "Timestamp: $(date -u '+%Y-%m-%d %H:%M UTC')"
    echo
    
    # Check local status
    print_info "📁 LOCAL STATUS:"
    check_local_version
    
    local local_main_count
    local_main_count=$(grep -c "main id=" status.html || echo "0")
    print_info "Local main tag count: $local_main_count"
    
    echo
    
    # Check live status
    print_info "🌐 LIVE SITE STATUS:"
    local live_clean=false
    local live_version_found=false
    
    if check_live_version; then
        live_version_found=true
    fi
    
    if check_corruption_status; then
        live_clean=true
    fi
    
    echo
    
    # Summary
    print_info "📊 DEPLOYMENT STATUS SUMMARY:"
    
    if [[ "$live_clean" == true ]] && [[ "$live_version_found" == true ]]; then
        print_success "🎉 DEPLOYMENT SUCCESSFUL!"
        print_success "✅ Live site is clean and shows latest version"
        return 0
    elif [[ "$live_version_found" == true ]]; then
        print_warning "🔄 DEPLOYMENT IN PROGRESS"
        print_warning "✅ Version tracking deployed, but corruption fix pending"
        return 1
    else
        print_error "⏳ DEPLOYMENT PENDING"
        print_error "❌ GitHub Pages has not deployed our changes yet"
        return 2
    fi
}

# Run main function
main "$@"