# Website Management Makefile
# 
# ⚠️  IMPORTANT: 'make deploy' does NOT actually deploy!
# ⚠️  It only prepares for deployment (tests + staging).
# ⚠️  You must manually commit and push after 'make deploy'.
#
# Include shared configuration and common targets
include ../ahab/Makefile.config
include ../ahab/Makefile.common

.PHONY: help validate test deploy clean serve

# CRITICAL: The 'deploy' target does NOT actually deploy!
# It only prepares for deployment. You must manually commit and push.

help:
	$(call HELP_HEADER,Ahab Website Publishing)
	@echo "🚀 QUICK START:"
	@echo "  make test                 → Run all quality checks (~2-3 min)"
	@echo "  make deploy               → Prepare for publishing (tests + staging)"
	@echo "  git commit -m 'message'   → Commit your changes"
	@echo "  git push origin production → Publish to live website"
	@echo ""
	@echo "✅ TESTING & VALIDATION:"
	@echo "  make test                 → Complete test suite (~2-3 minutes)"
	@echo "                              • HTML/CSS validation"
	@echo "                              • WCAG 2.1 AA accessibility compliance"
	@echo "                              • Link checking (internal + external)"
	@echo "                              • Page performance (< 3 sec load time)"
	@echo "                              • Progressive disclosure UX validation"
	@echo "                              • Secret scanning (safety check)"
	@echo "  make validate             → HTML/CSS validation only (~30 sec)"
	@echo "                              • W3C HTML5 standards compliance"
	@echo "                              • CSS3 syntax and best practices"
	@echo "  make test-html            → HTML structure validation"
	@echo "                              • Semantic markup verification"
	@echo "                              • Accessibility markup (alt text, ARIA)"
	@echo "  make test-css             → CSS standards validation"
	@echo "                              • Syntax checking and linting"
	@echo "                              • Brand color compliance"
	@echo "  make test-accessibility   → WCAG 2.1 AA compliance testing"
	@echo "                              • Color contrast ratios (4.5:1 minimum)"
	@echo "                              • Keyboard navigation support"
	@echo "                              • Screen reader compatibility"
	@echo "  make test-links           → Link validation (~1-2 min)"
	@echo "                              • Internal navigation verification"
	@echo "                              • External resource availability"
	@echo "                              • Broken link detection"
	@echo "  make test-performance     → Page load performance testing"
	@echo "                              • Load time measurement (< 3 sec target)"
	@echo "                              • Resource optimization check"
	@echo "                              • Mobile performance validation"
	@echo "  make test-secrets         → Comprehensive secret scanning"
	@echo "                              • API keys, passwords, tokens"
	@echo "                              • May have false positives"
	@echo "  make test-secrets-simple  → Real secrets only (recommended)"
	@echo "                              • High-confidence secret detection"
	@echo "                              • Fewer false positives"
	@echo "  make test-progressive-disclosure → UX principle validation"
	@echo "                              • Progressive disclosure compliance"
	@echo "                              • Context-aware navigation"
	@echo "                              • Elevator principle adherence"
	@echo ""
	@echo "🔧 DEVELOPMENT & UTILITIES:"
	@echo "  make serve                → Start local development server"
	@echo "                              • Runs on http://localhost:8000"
	@echo "                              • Docker-based (no host dependencies)"
	@echo "                              • Auto-refresh on file changes"
	@echo "  make update-status        → Sync status page with ahab system"
	@echo "                              • Pulls real data from ahab tests"
	@echo "                              • Updates progress indicators"
	@echo "                              • Refreshes version information"
	@echo "  make compliance-report    → Generate comprehensive compliance report"
	@echo "                              • Detailed test results"
	@echo "                              • Standards compliance matrix"
	@echo "                              • Recommendations for improvements"
	@echo "  make setup-secrets        → One-time secrets detection setup"
	@echo "                              • Configures detection patterns"
	@echo "                              • Only run once per repository"
	@echo "  make clean                → Clean temporary files"
	@echo "                              • Removes test artifacts"
	@echo "                              • Clears cached data"
	@echo ""
	@echo "🚀 PUBLISHING WORKFLOW:"
	@echo "  make deploy               → PREPARE for publishing (does NOT publish!)"
	@echo "                              • Runs complete test suite"
	@echo "                              • Stages files for deployment"
	@echo "                              • ⚠️  Does NOT commit or push automatically"
	@echo "                              • You maintain full control"
	@echo "  make pre-push             → Complete pre-publication workflow"
	@echo "                              • Comprehensive validation"
	@echo "                              • Documentation updates"
	@echo "                              • Issue detection and fixing"
	@echo ""
	@echo "💡 COMMON WORKFLOWS:"
	@echo "  # Daily development:"
	@echo "  make serve                # Start local server"
	@echo "  # Edit files..."
	@echo "  make test                 # Validate changes"
	@echo ""
	@echo "  # Publish changes:"
	@echo "  make deploy               # Prepare for publishing"
	@echo "  git add ."
	@echo "  git commit -m 'Update website content'"
	@echo "  git push origin production"
	@echo ""
	@echo "  # Quality assurance:"
	@echo "  make pre-push             # Comprehensive validation"
	@echo ""
	@echo "⚠️  CRITICAL PUBLISHING NOTES:"
	@echo "  • 'make deploy' does NOT automatically publish"
	@echo "  • You must manually commit and push after 'make deploy'"
	@echo "  • Always run 'make test' before publishing"
	@echo "  • Website goes live immediately after 'git push'"
	@echo "  • Use 'production' branch for live site"
	@echo ""
	@echo "🌐 ACCESS POINTS:"
	@echo "  • Local development: http://localhost:8000"
	@echo "  • Live website: https://waltdundore.github.io"
	@echo "  • Status page: https://waltdundore.github.io/status.html"
	@echo ""
	@echo "⏱️  ESTIMATED TIMES:"
	@echo "  • Full test suite: 2-3 minutes"
	@echo "  • HTML/CSS validation: 30 seconds"
	@echo "  • Link checking: 1-2 minutes"
	@echo "  • Accessibility testing: 1 minute"

validate: test-html test-css
	$(call SHOW_COMMAND,validation complete,Ensure HTML and CSS meet Ahab standards)
	@echo "✓ All validation checks passed"

test-html:
	$(call VALIDATE_HTML)

test-css:
	$(call VALIDATE_CSS)

test-accessibility:
	$(call RUN_SHELL_TEST,./tests/test-accessibility.sh,WCAG 2.1 AA compliance and screen reader compatibility)

test-links:
	$(call CHECK_LINKS)

test-performance:
	$(call RUN_SHELL_TEST,./tests/test-performance.sh,Ensure pages load in < 3 seconds)

test-secrets:
	$(call RUN_SHELL_TEST,./tests/test-secrets.sh,Comprehensive scan for sensitive content (may have false positives))

test-secrets-simple:
	$(call SCAN_SECRETS)

test-progressive-disclosure:
	$(call RUN_SHELL_TEST,./tests/test-progressive-disclosure.sh,Validate progressive disclosure UX principles (elevator principle))

setup-secrets:
	$(call RUN_SHELL_TEST,./scripts/setup-secrets-detection.sh,One-time setup of secrets detection patterns (run once))

test: validate test-accessibility test-links test-performance test-progressive-disclosure test-secrets-simple
	@echo "→ Running: complete test suite"
	@echo "   Purpose: Comprehensive validation of website compliance"
	@echo "✓ All tests passed - website meets Ahab standards and is safe to publish"

deploy: test
	@echo "→ Running: PREPARATION ONLY - does NOT commit or push"
	@echo "   Purpose: Run tests and stage files, but requires manual commit/push"
	@echo ""
	@echo "⚠️  WARNING: 'make deploy' does NOT actually deploy!"
	@echo "⚠️  It only PREPARES for deployment by:"
	@echo "   1. Running comprehensive tests"
	@echo "   2. Staging files with 'git add .'"
	@echo "   3. Showing you what needs to be committed"
	@echo ""
	@echo "📋 Preparing deployment..."
	@git add .
	@git status
	@echo ""
	@echo "🚀 TO ACTUALLY DEPLOY:"
	@echo "   git commit -m \"your commit message\""
	@echo "   git push origin main"
	@echo ""
	@echo "💡 TIP: This two-step process prevents accidental deployments"

serve:
	@echo "→ Running: docker run --rm -p 8000:8000 -v \$$(pwd):/app:ro -w /app python:3.11-slim python3 -m http.server 8000"
	@echo "   Purpose: Start local development server in Docker container (secure, isolated)"
	@echo "   Access at: http://localhost:8000"
	@echo "   Press Ctrl+C to stop"
	@docker run --rm -p 8000:8000 -v $$(pwd):/app:ro -w /app python:3.11-slim python3 -m http.server 8000

compliance-report:
	@echo "→ Running: compliance status report generation"
	@echo "   Purpose: Generate comprehensive compliance status report"
	@echo ""
	@echo "=== AHAB WEBSITE COMPLIANCE REPORT ==="
	@echo "Generated: $$(date)"
	@echo ""
	@echo "Progressive Disclosure Compliance:"
	@./tests/test-progressive-disclosure.sh | grep -E "(✓|ERROR|WARNING)" || true
	@echo ""
	@echo "Technical Standards Compliance:"
	@./tests/test-html.sh | grep -E "(✓|ERROR|WARNING)" | head -3 || true
	@./tests/test-css.sh | grep -E "(✓|ERROR|WARNING)" | head -3 || true
	@echo ""
	@echo "Security Compliance:"
	@./tests/test-secrets-simple.sh | grep -E "(✓|ERROR|WARNING)" | head -3 || true
	@echo ""
	@echo "Accessibility Compliance:"
	@./tests/test-accessibility.sh | grep -E "(✓|ERROR|WARNING)" | head -3 || true
	@echo ""
	@echo "Full compliance details: see COMPLIANCE_STATUS.md"
	@echo "✓ Compliance report complete"

update-status:
	@echo "→ Running: ./scripts/update-status.sh"
	@echo "   Purpose: Update status page with real data from ahab system"
	@./scripts/update-status.sh

pre-push:
	$(call SHOW_COMMAND,./scripts/pre-push-workflow.sh,Complete pre-push workflow - fix issues, run tests, update docs, prepare for deployment)
	@./scripts/pre-push-workflow.sh

clean:
	@echo "→ Running: cleanup temporary files"
	@echo "   Purpose: Remove test artifacts and temporary files"
	@rm -f *.tmp
	@rm -f tests/*.log
	@rm -f *.backup
	@echo "✓ Cleanup complete"