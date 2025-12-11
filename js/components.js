// Ahab Website Components - Progressive Enhancement with Accessibility
// Educational transparency: Show users how we build maintainable, accessible websites

// Navigation component - enhanced version with JavaScript
function createNavigation(activePage = '') {
    return `
    <nav class="tutorial-nav sticky-nav js-enhanced" role="navigation" aria-label="Main navigation">
        <div class="nav-brand">
            <img src="images/ahab-logo.png" alt="Ahab Logo" class="nav-logo">
            <span>Ahab</span>
        </div>
        <div class="nav-links">
            <a href="index.html" ${activePage === 'home' ? 'class="active" aria-current="page"' : ''}>Home</a>
            <a href="tutorial.html" ${activePage === 'tutorial' ? 'class="active" aria-current="page"' : ''}>Tutorial</a>
            <a href="learn.html" ${activePage === 'learn' ? 'class="active" aria-current="page"' : ''}>Learn More</a>
            <a href="teachers.html" ${activePage === 'teachers' ? 'class="active" aria-current="page"' : ''}>For Teachers</a>
            <a href="status.html" ${activePage === 'status' ? 'class="status-link active" aria-current="page"' : 'class="status-link"'}><i class="fas fa-chart-line" aria-hidden="true"></i> Status</a>
            <a href="https://github.com/waltdundore/ahab" target="_blank" rel="noopener"><i class="fab fa-github" aria-hidden="true"></i> GitHub</a>
        </div>
    </nav>`;
}

// Breadcrumb component - enhanced version with JavaScript
function createBreadcrumb(currentPage, parentPage = null) {
    let breadcrumb = '<nav class="breadcrumb js-enhanced" role="navigation" aria-label="Breadcrumb"><a href="index.html">Home</a>';
    
    if (parentPage) {
        breadcrumb += ` → <a href="${parentPage.url}">${parentPage.name}</a>`;
    }
    
    breadcrumb += ` → <span aria-current="page">${currentPage}</span></nav>`;
    return breadcrumb;
}

// Footer component - enhanced version with JavaScript
function createFooter() {
    return `
    <footer class="js-enhanced" role="contentinfo">
        <div class="footer-content">
            <div class="footer-section">
                <h3>Ahab Project</h3>
                <p>Infrastructure automation for K-12 schools and non-profits</p>
                <p>Built with transparency, tested with care, documented with purpose. Free for education forever.</p>
                <div class="footer-links">
                    <a href="https://github.com/waltdundore/ahab" target="_blank" rel="noopener">
                        <i class="fab fa-github" aria-hidden="true"></i> Main Repository
                    </a>
                    <a href="https://github.com/waltdundore/ahab-gui" target="_blank" rel="noopener">
                        <i class="fas fa-desktop" aria-hidden="true"></i> Web Interface
                    </a>
                    <a href="https://github.com/waltdundore/ahab/blob/main/LESSONS_LEARNED.md" target="_blank" rel="noopener">
                        <i class="fas fa-book" aria-hidden="true"></i> Lessons Learned
                    </a>
                </div>
            </div>
            <div class="footer-section">
                <div class="footer-meta">
                    <p>
                        <i class="fas fa-clock" aria-hidden="true"></i>
                        Status updated: <span class="last-updated">December 11, 2025</span>
                    </p>
                    <p>
                        <i class="fas fa-code-branch" aria-hidden="true"></i>
                        Version: v0.2.0-alpha (Development)
                    </p>
                    <p>
                        <i class="fas fa-shield-alt" aria-hidden="true"></i>
                        License: CC BY-NC-SA 4.0
                    </p>
                </div>
            </div>
        </div>
        <div class="footer-bottom">
            <p>
                "We're not here forever, but what we teach can be." - 
                <em>Committed to educational excellence and open source values</em>
            </p>
        </div>
    </footer>`;
}

// Initialize components when page loads - Progressive Enhancement
function initializeComponents(config) {
    try {
        // Mark that JavaScript is available
        document.body.classList.add('js-enabled');
        
        // Announce to screen readers that enhanced features are loading
        announceToScreenReader('Loading enhanced navigation and features...');
        
        // Activate fallback components first (for immediate accessibility)
        activateFallbackComponents(config);
        
        // Insert enhanced navigation
        const navPlaceholder = document.getElementById('navigation-placeholder');
        if (navPlaceholder) {
            navPlaceholder.innerHTML = createNavigation(config.activePage);
        }
        
        // Insert enhanced breadcrumb
        const breadcrumbPlaceholder = document.getElementById('breadcrumb-placeholder');
        if (breadcrumbPlaceholder && config.currentPage) {
            breadcrumbPlaceholder.innerHTML = createBreadcrumb(config.currentPage, config.parentPage);
        }
        
        // Insert enhanced footer
        const footerPlaceholder = document.getElementById('footer-placeholder');
        if (footerPlaceholder) {
            footerPlaceholder.innerHTML = createFooter();
        }
        
        // Update timestamps
        updateTimestamps();
        
        // Initialize enhanced features
        initializeAccessibility();
        initializeSmoothScroll();
        
        // Announce completion to screen readers
        announceToScreenReader('Enhanced navigation loaded successfully.');
        
    } catch (error) {
        // If JavaScript fails, ensure fallbacks remain visible
        console.warn('Enhanced components failed to load, using fallback components:', error);
        document.body.classList.remove('js-enabled');
        activateFallbackComponents(config);
    }
}

// Activate and configure fallback components
function activateFallbackComponents(config) {
    // Set active page in fallback navigation
    const fallbackNavLinks = document.querySelectorAll('#navigation-fallback a[data-page]');
    fallbackNavLinks.forEach(link => {
        if (link.dataset.page === config.activePage) {
            link.classList.add('active');
            link.setAttribute('aria-current', 'page');
        }
    });
    
    // Set current page in fallback breadcrumb
    const currentPageSpan = document.querySelector('#breadcrumb-fallback [data-current-page]');
    if (currentPageSpan && config.currentPage) {
        currentPageSpan.textContent = config.currentPage;
        currentPageSpan.setAttribute('aria-current', 'page');
    }
    
    // Update timestamps in fallback footer
    const fallbackTimestamps = document.querySelectorAll('#footer-fallback .last-updated');
    const now = new Date();
    const timestamp = now.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long', 
        day: 'numeric'
    });
    fallbackTimestamps.forEach(el => {
        if (el) el.textContent = timestamp;
    });
}

// Update all timestamps to current date
function updateTimestamps() {
    const now = new Date();
    const timestamp = now.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long', 
        day: 'numeric'
    });
    
    const elements = document.querySelectorAll('.last-updated');
    elements.forEach(el => {
        if (el) el.textContent = timestamp;
    });
}

// Accessibility improvements
function initializeAccessibility() {
    // Skip to main content link
    const skipLink = document.querySelector('.skip-link');
    if (skipLink) {
        skipLink.addEventListener('click', function(e) {
            e.preventDefault();
            const main = document.getElementById('main');
            if (main) {
                main.focus();
                main.scrollIntoView();
            }
        });
    }
}

// Smooth scroll for anchor links
function initializeSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Screen reader announcements for accessibility
function announceToScreenReader(message) {
    const announcement = document.createElement('div');
    announcement.setAttribute('aria-live', 'polite');
    announcement.setAttribute('aria-atomic', 'true');
    announcement.className = 'sr-only';
    announcement.textContent = message;
    
    document.body.appendChild(announcement);
    
    // Remove after announcement
    setTimeout(() => {
        if (announcement.parentNode) {
            announcement.parentNode.removeChild(announcement);
        }
    }, 1000);
}

// Error handling for component loading
function handleComponentError(error, componentName) {
    console.error(`Failed to load ${componentName}:`, error);
    announceToScreenReader(`${componentName} failed to load. Using basic navigation.`);
    
    // Ensure fallback remains visible
    document.body.classList.remove('js-enabled');
}

// Graceful degradation check
function checkJavaScriptSupport() {
    // Test basic JavaScript features needed for components
    try {
        const testElement = document.createElement('div');
        testElement.innerHTML = '<span>test</span>';
        testElement.querySelector('span');
        return true;
    } catch (error) {
        return false;
    }
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { 
        initializeComponents, 
        createNavigation, 
        createBreadcrumb, 
        createFooter,
        activateFallbackComponents,
        announceToScreenReader 
    };
}