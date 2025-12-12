#!/bin/bash
# Add version tracking to HTML files to monitor corruption
# Following ahab development rules: DRY, functional, well-documented

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# Generate version info
generate_version_info() {
    local timestamp=$(date -u +"%Y-%m-%d %H:%M UTC")
    local commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    
    echo "<!-- VERSION_TRACKING: ${timestamp} | ${commit_hash} | ${branch} -->"
}

# Add version tracking to HTML file
add_version_to_file() {
    local file="$1"
    local backup_file="${file}.backup.$(date +%s)"
    
    print_info "Adding version tracking to $file"
    
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    # Check current main tag count
    local main_count
    main_count=$(grep -c "main id=" "$file" || echo "0")
    
    if [[ "$main_count" -ne 1 ]]; then
        print_error "$file has $main_count main tags - fix corruption first"
        return 1
    fi
    
    # Create backup
    cp "$file" "$backup_file"
    print_info "Backup created: $backup_file"
    
    # Create temporary file
    local temp_file
    temp_file=$(mktemp)
    trap "rm -f $temp_file" EXIT
    
    # Generate version info
    local version_info
    version_info=$(generate_version_info)
    
    # Add version tracking after <head> tag
    local version_added=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # Add version tracking after <head> tag
        if [[ "$line" =~ \<head\> ]] && [[ "$version_added" == false ]]; then
            echo "    $version_info" >> "$temp_file"
            version_added=true
        fi
    done < "$file"
    
    # Verify version was added
    if grep -q "VERSION_TRACKING" "$temp_file"; then
        # Success - replace original file
        mv "$temp_file" "$file"
        rm -f "$backup_file"  # Clean up backup
        print_success "Added version tracking to $file"
        
        # Show the version info
        local version_line
        version_line=$(grep "VERSION_TRACKING" "$file" || echo "Not found")
        print_info "Version: $version_line"
        
        return 0
    else
        print_error "Failed to add version tracking to $file"
        # Restore from backup
        mv "$backup_file" "$file"
        return 1
    fi
}

# Main function
main() {
    print_info "Adding version tracking to HTML files"
    print_info "Working directory: $PROJECT_ROOT"
    
    cd "$PROJECT_ROOT"
    
    # Find all HTML files
    local html_files
    html_files=$(find . -name "*.html" -type f)
    
    if [[ -z "$html_files" ]]; then
        print_warning "No HTML files found"
        return 0
    fi
    
    local total_files=0
    local success_files=0
    local failed_files=0
    
    # Process each HTML file
    while IFS= read -r file; do
        ((total_files++))
        
        if add_version_to_file "$file"; then
            ((success_files++))
        else
            ((failed_files++))
        fi
    done <<< "$html_files"
    
    # Summary
    echo
    print_info "=== VERSION TRACKING SUMMARY ==="
    echo "Total HTML files processed: $total_files"
    echo "Files with version tracking added: $success_files"
    echo "Files that failed: $failed_files"
    
    if [[ "$failed_files" -eq 0 ]]; then
        print_success "Version tracking added to all HTML files!"
        return 0
    else
        print_error "$failed_files files failed to get version tracking"
        return 1
    fi
}

# Run main function
main "$@"