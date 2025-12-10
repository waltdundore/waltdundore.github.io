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
	$(call HELP_HEADER,Website Management)
	@echo "Available commands:"
	@echo "  validate        - Validate HTML/CSS compliance"
	@echo "  test           - Run all tests (HTML, accessibility, links, performance)"
	@echo "  test-html      - Validate HTML structure and standards"
	@echo "  test-css       - Validate CSS standards"
	@echo "  test-accessibility - Test WCAG 2.1 AA compliance"
	@echo "  test-links     - Check all internal and external links"
	@echo "  test-performance - Test page load performance"
	@echo "  test-secrets   - Scan for sensitive content before publish (comprehensive)"
	@echo "  test-secrets-simple - Scan for real secrets only (recommended for regular use)"
	@echo "  test-progressive-disclosure - Validate progressive disclosure UX principles"
	@echo "  compliance-report - Generate comprehensive compliance status report"
	@echo "  setup-secrets  - One-time setup of secrets detection patterns"
	@echo "  serve          - Start local development server (Docker-based)"
	@echo ""
	@echo "⚠️  DEPLOYMENT (READ CAREFULLY):"
	@echo "  deploy         - PREPARE for deployment (runs tests, stages files)"
	@echo "                   ⚠️  Does NOT commit or push - you must do that manually!"
	@echo "                   After 'make deploy', run: git commit -m \"msg\" && git push origin main"
	@echo ""
	@echo "  clean          - Clean temporary files"

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

clean:
	@echo "→ Running: cleanup temporary files"
	@echo "   Purpose: Remove test artifacts and temporary files"
	@rm -f *.tmp
	@rm -f tests/*.log
	@rm -f *.backup
	@echo "✓ Cleanup complete"