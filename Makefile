.PHONY: help validate test deploy clean serve

help:
	@echo "→ Running: help command"
	@echo "   Purpose: Show available commands for website management"
	@echo ""
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
	@echo "  setup-secrets  - One-time setup of secrets detection patterns"
	@echo "  serve          - Start local development server (Docker-based)"
	@echo "  deploy         - Deploy to GitHub Pages (after tests pass)"
	@echo "  clean          - Clean temporary files"

validate: test-html test-css
	@echo "→ Running: validation complete"
	@echo "   Purpose: Ensure HTML and CSS meet Ahab standards"
	@echo "✓ All validation checks passed"

test-html:
	@echo "→ Running: ./tests/test-html.sh"
	@echo "   Purpose: Validate HTML structure, meta tags, and accessibility"
	@./tests/test-html.sh

test-css:
	@echo "→ Running: ./tests/test-css.sh"
	@echo "   Purpose: Validate CSS standards and no inline styles"
	@./tests/test-css.sh

test-accessibility:
	@echo "→ Running: ./tests/test-accessibility.sh"
	@echo "   Purpose: Test WCAG 2.1 AA compliance and screen reader compatibility"
	@./tests/test-accessibility.sh

test-links:
	@echo "→ Running: ./tests/test-links.sh"
	@echo "   Purpose: Verify all internal and external links work"
	@./tests/test-links.sh

test-performance:
	@echo "→ Running: ./tests/test-performance.sh"
	@echo "   Purpose: Ensure pages load in < 3 seconds"
	@./tests/test-performance.sh

test-secrets:
	@echo "→ Running: ./tests/test-secrets.sh"
	@echo "   Purpose: Comprehensive scan for sensitive content (may have false positives)"
	@./tests/test-secrets.sh

test-secrets-simple:
	@echo "→ Running: ./tests/test-secrets-simple.sh"
	@echo "   Purpose: Scan for real secrets only (MANDATORY before publish)"
	@./tests/test-secrets-simple.sh

test-progressive-disclosure:
	@echo "→ Running: ./tests/test-progressive-disclosure.sh"
	@echo "   Purpose: Validate progressive disclosure UX principles (elevator principle)"
	@./tests/test-progressive-disclosure.sh

setup-secrets:
	@echo "→ Running: ./scripts/setup-secrets-detection.sh"
	@echo "   Purpose: One-time setup of secrets detection patterns (run once)"
	@./scripts/setup-secrets-detection.sh

test: validate test-accessibility test-links test-performance test-progressive-disclosure test-secrets-simple
	@echo "→ Running: complete test suite"
	@echo "   Purpose: Comprehensive validation of website compliance"
	@echo "✓ All tests passed - website meets Ahab standards and is safe to publish"

deploy: test
	@echo "→ Running: git push origin main"
	@echo "   Purpose: Deploy to GitHub Pages after all tests pass"
	@echo "Deploying to GitHub Pages..."
	@git add .
	@git status
	@echo "Ready to deploy. Run 'git commit -m \"message\" && git push origin main' to complete."

serve:
	@echo "→ Running: docker run --rm -p 8000:8000 -v \$$(pwd):/app:ro -w /app python:3.11-slim python3 -m http.server 8000"
	@echo "   Purpose: Start local development server in Docker container (secure, isolated)"
	@echo "   Access at: http://localhost:8000"
	@echo "   Press Ctrl+C to stop"
	@docker run --rm -p 8000:8000 -v $$(pwd):/app:ro -w /app python:3.11-slim python3 -m http.server 8000

clean:
	@echo "→ Running: cleanup temporary files"
	@echo "   Purpose: Remove test artifacts and temporary files"
	@rm -f *.tmp
	@rm -f tests/*.log
	@echo "✓ Cleanup complete"