#!/bin/bash
# tests/test-progressive-disclosure.sh

echo "Testing progressive disclosure implementation..."

# Test 1: Context-aware content
test_context_awareness() {
    echo "→ Testing context-aware content"
    
    for file in *.html; do
        echo "  Checking $file..."
        
        # Landing page should only show entry points
        if [[ "$file" == "index.html" ]]; then
            # Check for overly complex content that should be in tutorial/docs
            if grep -q "docker run\|ansible-playbook\|vagrant ssh" "$file"; then
                echo "WARNING: Landing page shows complex commands (should be in tutorial)"
            fi
            # Landing page should focus on getting started, not advanced topics
            if grep -q "API documentation\|Advanced configuration\|Troubleshooting guide" "$file"; then
                echo "ERROR: Landing page shows advanced content"
                exit 1
            fi
        fi
        
        # Tutorial pages should show step navigation
        if [[ "$file" == tutorial-*.html ]]; then
            if ! grep -q "step-nav\|breadcrumb" "$file"; then
                echo "ERROR: Tutorial page missing navigation context"
                exit 1
            fi
        fi
    done
    
    echo "  ✓ Context awareness passed"
}

# Test 2: Input constraints
test_input_constraints() {
    echo "→ Testing input constraints"
    
    for file in *.html; do
        # Forms should use constrained inputs (select, radio) not free-form text
        if grep -q '<form' "$file"; then
            if grep -q 'type="text"' "$file" && ! grep -q 'pattern=\|list=' "$file"; then
                echo "WARNING: $file has unconstrained text input"
            fi
            
            # Forms should have validation
            if ! grep -q 'required\|pattern=\|data-validate' "$file"; then
                echo "ERROR: $file form lacks input validation"
                exit 1
            fi
        fi
    done
    
    echo "  ✓ Input constraints passed"
}

# Test 3: State management
test_state_management() {
    echo "→ Testing state management"
    
    for file in *.html; do
        # Interactive pages should have state classes
        if grep -q 'progressive-form\|deployment-form' "$file"; then
            if ! grep -q 'state-\|data-state' "$file"; then
                echo "ERROR: $file missing state management"
                exit 1
            fi
        fi
        
        # Buttons should have state constraints
        if grep -q '<button' "$file"; then
            if ! grep -q 'disabled\|data-valid-states' "$file"; then
                echo "WARNING: $file buttons lack state constraints"
            fi
        fi
    done
    
    echo "  ✓ State management passed"
}

# Test 4: Navigation context
test_navigation_context() {
    echo "→ Testing navigation context"
    
    for file in *.html; do
        # Every page should have breadcrumb or context indicator
        if ! grep -q 'breadcrumb\|nav.*context\|back-to' "$file"; then
            echo "ERROR: $file missing navigation context"
            exit 1
        fi
        
        # Every page should have escape routes
        if ! grep -q 'href="index.html"\|href="tutorial.html"' "$file"; then
            echo "ERROR: $file missing escape routes"
            exit 1
        fi
    done
    
    echo "  ✓ Navigation context passed"
}

# Test 5: Layered complexity
test_layered_complexity() {
    echo "→ Testing layered complexity"
    
    for file in *.html; do
        # Advanced options should be hidden by default
        if grep -q 'advanced\|expert\|debug' "$file"; then
            if ! grep -q 'details>\|style="display: none"\|hidden' "$file"; then
                echo "ERROR: $file shows advanced options by default"
                exit 1
            fi
        fi
    done
    
    echo "  ✓ Layered complexity passed"
}

# Run all tests
test_context_awareness
test_input_constraints
test_state_management
test_navigation_context
test_layered_complexity

echo "✓ Progressive disclosure tests passed"