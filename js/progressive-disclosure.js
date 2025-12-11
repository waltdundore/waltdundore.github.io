/**
 * Progressive Disclosure Enhancement
 * Follows Ahab's elevator principle - show only what's needed, when needed
 */

// Progressive Enhancement - only run if JavaScript is available
document.addEventListener('DOMContentLoaded', function() {
    initProgressiveDisclosure();
    enhanceAccessibility();
    addKeyboardSupport();
});

/**
 * Initialize progressive disclosure features
 */
function initProgressiveDisclosure() {
    // Enhance proof of concept interaction
    const proofCode = document.querySelector('.proof code');
    const proofResult = document.querySelector('.proof .result');
    
    if (proofCode && proofResult) {
        proofCode.addEventListener('mouseenter', function() {
            proofResult.style.opacity = '1';
        });
        
        proofCode.addEventListener('mouseleave', function() {
            proofResult.style.opacity = '0.8';
        });
        
        // Keyboard support for proof interaction
        proofCode.addEventListener('focus', function() {
            proofResult.style.opacity = '1';
        });
        
        proofCode.addEventListener('blur', function() {
            proofResult.style.opacity = '0.8';
        });
    }
    
    // Progressive form enhancement (if forms exist)
    enhanceForms();
    
    // State-aware button management
    manageButtonStates();
}

/**
 * Enhance forms with progressive disclosure
 */
function enhanceForms() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(form => {
        const inputs = form.querySelectorAll('input, select, textarea');
        const submitBtn = form.querySelector('button[type="submit"], input[type="submit"]');
        
        if (submitBtn) {
            // Initially disable submit button
            submitBtn.disabled = true;
            
            // Enable when form is valid
            inputs.forEach(input => {
                input.addEventListener('input', function() {
                    updateSubmitButton(form, submitBtn);
                });
                
                input.addEventListener('change', function() {
                    updateSubmitButton(form, submitBtn);
                });
            });
        }
    });
}

/**
 * Update submit button state based on form validity
 */
function updateSubmitButton(form, submitBtn) {
    const isValid = form.checkValidity();
    submitBtn.disabled = !isValid;
    
    // Update button text to provide context
    if (isValid) {
        submitBtn.textContent = submitBtn.dataset.enabledText || submitBtn.textContent;
        submitBtn.setAttribute('aria-describedby', 'form-ready');
    } else {
        submitBtn.textContent = submitBtn.dataset.disabledText || submitBtn.textContent;
        submitBtn.setAttribute('aria-describedby', 'form-incomplete');
    }
}

/**
 * Manage button states throughout the page
 */
function manageButtonStates() {
    const buttons = document.querySelectorAll('button[data-requires]');
    
    buttons.forEach(button => {
        const requirements = button.dataset.requires.split(',');
        
        // Check if requirements are met
        const requirementsMet = requirements.every(req => {
            const element = document.querySelector(req);
            return element && (element.checked || element.value);
        });
        
        button.disabled = !requirementsMet;
        
        // Listen for changes in requirements
        requirements.forEach(req => {
            const element = document.querySelector(req);
            if (element) {
                element.addEventListener('change', function() {
                    manageButtonStates();
                });
            }
        });
    });
}

/**
 * Enhance accessibility features
 */
function enhanceAccessibility() {
    // Add live regions for dynamic content
    if (!document.getElementById('live-region')) {
        const liveRegion = document.createElement('div');
        liveRegion.id = 'live-region';
        liveRegion.setAttribute('aria-live', 'polite');
        liveRegion.setAttribute('aria-atomic', 'true');
        liveRegion.style.position = 'absolute';
        liveRegion.style.left = '-10000px';
        liveRegion.style.width = '1px';
        liveRegion.style.height = '1px';
        liveRegion.style.overflow = 'hidden';
        document.body.appendChild(liveRegion);
    }
    
    // Enhance details/summary elements
    const detailsElements = document.querySelectorAll('details');
    detailsElements.forEach(details => {
        const summary = details.querySelector('summary');
        if (summary) {
            summary.addEventListener('click', function() {
                // Announce state change to screen readers
                setTimeout(() => {
                    const liveRegion = document.getElementById('live-region');
                    if (details.open) {
                        liveRegion.textContent = 'Section expanded';
                    } else {
                        liveRegion.textContent = 'Section collapsed';
                    }
                }, 100);
            });
        }
    });
}

/**
 * Add keyboard navigation support
 */
function addKeyboardSupport() {
    document.addEventListener('keydown', function(e) {
        // Escape key closes open details elements
        if (e.key === 'Escape') {
            const openDetails = document.querySelectorAll('details[open]');
            openDetails.forEach(details => {
                details.open = false;
            });
        }
        
        // Enter key on proof code shows result
        if (e.key === 'Enter' && e.target.matches('.proof code')) {
            const result = e.target.nextElementSibling;
            if (result && result.classList.contains('result')) {
                result.style.opacity = result.style.opacity === '1' ? '0.8' : '1';
            }
        }
    });
}

/**
 * Error handling with recovery options
 */
class ErrorHandler {
    static showError(message, recoveryOptions = []) {
        const errorContainer = document.getElementById('error-container') || this.createErrorContainer();
        
        errorContainer.innerHTML = `
            <div class="error-message" role="alert">
                <h3>Something went wrong</h3>
                <p>${message}</p>
                <div class="recovery-options">
                    ${recoveryOptions.map(option => 
                        `<button onclick="${option.action}" class="btn btn-secondary">${option.label}</button>`
                    ).join('')}
                </div>
            </div>
        `;
        
        errorContainer.style.display = 'block';
        
        // Focus the first recovery option for accessibility
        const firstButton = errorContainer.querySelector('button');
        if (firstButton) {
            firstButton.focus();
        }
    }
    
    static createErrorContainer() {
        const container = document.createElement('div');
        container.id = 'error-container';
        container.style.display = 'none';
        container.style.position = 'fixed';
        container.style.top = '20px';
        container.style.left = '50%';
        container.style.transform = 'translateX(-50%)';
        container.style.zIndex = '1000';
        container.style.maxWidth = '500px';
        container.style.padding = '20px';
        container.style.backgroundColor = 'var(--danger)';
        container.style.color = 'white';
        container.style.borderRadius = '8px';
        container.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.3)';
        document.body.appendChild(container);
        return container;
    }
    
    static clearError() {
        const errorContainer = document.getElementById('error-container');
        if (errorContainer) {
            errorContainer.style.display = 'none';
        }
    }
}

// Export for use in other scripts
window.ProgressiveDisclosure = {
    ErrorHandler,
    initProgressiveDisclosure,
    enhanceAccessibility,
    addKeyboardSupport
};