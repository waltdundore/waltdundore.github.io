#!/bin/bash
# Fix HTML corruption - remove duplicate main tags
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

# Function to fix a single HTML file
fix_html_file() {
    local file="$1"
    local backup_file="${file}.backup.$(date +%s)"
    
    print_info "Processing $file"
    
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    # Count current main tags
    local main_count
    main_count=$(grep -c "main id=" "$file" || echo "0")
    
    if [[ "$main_count" -eq 1 ]]; then
        print_success "$file is already clean (1 main tag)"
        return 0
    elif [[ "$main_count" -eq 0 ]]; then
        print_warning "$file has no main tags - skipping"
        return 0
    fi
    
    print_warning "$file has $main_count main tags - fixing"
    
    # Create backup
    cp "$file" "$backup_file"
    print_info "Backup created: $backup_file"
    
    # Create temporary file
    local temp_file
    temp_file=$(mktemp)
    trap "rm -f $temp_file" EXIT
    
    # Fix the file by removing duplicate main tags
    # Use sed to remove duplicate consecutive main tags
    sed '/^[[:space:]]*<main id="main">$/{
        # If this is a main tag line
        N
        # If the next line is also a main tag, delete the first one
        /\n[[:space:]]*<main id="main">$/{
            s/.*\n//
        }
    }' "$file" > "$temp_file"
    
    # Verify the fix
    local result_count
    result_count=$(grep -c "main id=" "$temp_file" || echo "0")
    
    if [[ "$result_count" -eq 1 ]]; then
        # Success - replace original file
        mv "$temp_file" "$file"
        rm -f "$backup_file"  # Clean up backup
        print_success "Fixed $file (now has 1 main tag)"
        return 0
    else
        print_error "Fix failed - result has $result_count main tags"
        # Restore from backup
        mv "$backup_file" "$file"
        return 1
    fi
}

# Main function
main() {
    print_info "Starting HTML corruption fix"
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
    local fixed_files=0
    local clean_files=0
    local failed_files=0
    
    # Process each HTML file
    while IFS= read -r file; do
        ((total_files++))
        
        if fix_html_file "$file"; then
            local main_count
            main_count=$(grep -c "main id=" "$file" || echo "0")
            if [[ "$main_count" -eq 1 ]]; then
                ((clean_files++))
            fi
        else
            ((failed_files++))
        fi
    done <<< "$html_files"
    
    # Summary
    echo
    print_info "=== CORRUPTION FIX SUMMARY ==="
    echo "Total HTML files processed: $total_files"
    echo "Files now clean (1 main tag): $clean_files"
    echo "Files that failed to fix: $failed_files"
    
    if [[ "$failed_files" -eq 0 ]]; then
        print_success "All HTML files are now clean!"
        return 0
    else
        print_error "$failed_files files still have corruption"
        return 1
    fi
}

# Run main function
main "$@"