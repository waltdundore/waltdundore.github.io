# Makefile for waltdundore.github.io
# GitHub Pages deployment automation

.PHONY: help status commit push deploy deploy-dev deploy-prod deploy-all test test-html test-links test-a11y serve clean

# Default target
help:
	@echo "GitHub Pages Deployment Commands:"
	@echo ""
	@echo "  make status        - Show git status"
	@echo "  make commit        - Stage and commit changes"
	@echo "  make push          - Push current branch to origin"
	@echo "  make deploy        - Commit and push current branch"
	@echo "  make deploy-dev    - Deploy to dev branch"
	@echo "  make deploy-prod   - Deploy to production branch"
	@echo "  make deploy-all    - Deploy to all branches (dev + production)"
	@echo ""
	@echo "Testing Commands:"
	@echo "  make test          - Run all tests"
	@echo "  make test-html     - Validate HTML"
	@echo "  make test-links    - Check for broken links"
	@echo "  make test-a11y     - Check accessibility"
	@echo "  make serve         - Start local server"
	@echo ""
	@echo "  make clean         - Clean up temporary files"
	@echo ""

# Show git status
status:
	@echo "==> Checking git status..."
	git status

# Stage and commit changes
commit:
	@echo "==> Staging all changes..."
	git add .
	@echo "==> Committing changes..."
	@if [ -z "$(MSG)" ]; then \
		echo "Error: Please provide a commit message with MSG='your message'"; \
		exit 1; \
	fi
	git commit -m "$(MSG)"

# Push current branch
push:
	@echo "==> Pushing to origin..."
	@BRANCH=$$(git branch --show-current); \
	echo "==> Pushing branch: $$BRANCH"; \
	git push origin $$BRANCH

# Deploy to current branch (commit + push)
deploy:
	@echo "==> Deploying to current branch..."
	@if [ -z "$(MSG)" ]; then \
		echo "Error: Please provide a commit message with MSG='your message'"; \
		exit 1; \
	fi
	@$(MAKE) commit MSG="$(MSG)"
	@$(MAKE) push

# Deploy to dev branch
deploy-dev:
	@echo "==> Deploying to dev branch..."
	@CURRENT=$$(git branch --show-current); \
	if [ "$$CURRENT" != "dev" ]; then \
		echo "==> Switching to dev branch..."; \
		git checkout dev; \
	fi
	@if [ -z "$(MSG)" ]; then \
		echo "Error: Please provide a commit message with MSG='your message'"; \
		exit 1; \
	fi
	@$(MAKE) commit MSG="$(MSG)"
	@$(MAKE) push
	@echo "==> Successfully deployed to dev branch"

# Deploy to production branch
deploy-prod:
	@echo "==> Deploying to production branch..."
	@CURRENT=$$(git branch --show-current); \
	if [ "$$CURRENT" != "production" ]; then \
		echo "==> Switching to production branch..."; \
		git checkout production; \
	fi
	@if [ -z "$(MSG)" ]; then \
		echo "Error: Please provide a commit message with MSG='your message'"; \
		exit 1; \
	fi
	@$(MAKE) commit MSG="$(MSG)"
	@$(MAKE) push
	@echo "==> Successfully deployed to production branch"

# Deploy to all branches
deploy-all:
	@echo "==> Deploying to all branches (dev + production)..."
	@if [ -z "$(MSG)" ]; then \
		echo "Error: Please provide a commit message with MSG='your message'"; \
		exit 1; \
	fi
	@ORIGINAL=$$(git branch --show-current); \
	echo "==> Current branch: $$ORIGINAL"; \
	echo ""; \
	echo "==> Deploying to dev..."; \
	git checkout dev && \
	git add . && \
	git commit -m "$(MSG)" && \
	git push origin dev && \
	echo ""; \
	echo "==> Deploying to production..."; \
	git checkout production && \
	git add . && \
	git commit -m "$(MSG)" && \
	git push origin production && \
	echo ""; \
	echo "==> Returning to original branch: $$ORIGINAL"; \
	git checkout $$ORIGINAL && \
	echo ""; \
	echo "==> Successfully deployed to all branches!"

# Test HTML validation
test-html:
	@echo "==> Validating HTML..."
	@for file in *.html; do \
		echo "Checking $$file..."; \
		if ! grep -q "<!DOCTYPE html>" $$file; then \
			echo "ERROR: $$file missing DOCTYPE"; \
			exit 1; \
		fi; \
	done
	@echo "✓ HTML validation passed"

# Test for broken links (requires linkchecker)
test-links:
	@echo "==> Checking for broken links..."
	@echo "Note: Install linkchecker: pip install linkchecker"
	@if command -v linkchecker &> /dev/null; then \
		linkchecker index.html; \
	else \
		echo "Warning: linkchecker not installed, skipping"; \
	fi

# Test accessibility (requires pa11y)
test-a11y:
	@echo "==> Checking accessibility..."
	@echo "Note: Install pa11y: npm install -g pa11y"
	@if command -v pa11y &> /dev/null; then \
		pa11y index.html; \
	else \
		echo "Warning: pa11y not installed, skipping"; \
	fi

# Run all tests
test: test-html
	@echo "==> All tests passed"

# Serve locally for testing
serve:
	@echo "==> Starting local server on http://localhost:8000"
	@python3 -m http.server 8000

# Clean up temporary files
clean:
	@echo "==> Cleaning up temporary files..."
	@find . -name ".DS_Store" -delete
	@find . -name "*.swp" -delete
	@find . -name "*~" -delete
	@echo "==> Cleanup complete"
