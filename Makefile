# Makefile for waltdundore.github.io
# GitHub Pages deployment automation

.PHONY: help status commit push deploy deploy-dev deploy-prod deploy-all test clean

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
	@echo "  make test          - Test HTML files locally"
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

# Test HTML files locally
test:
	@echo "==> Testing HTML files..."
	@echo "==> Checking for HTML syntax errors..."
	@for file in *.html; do \
		echo "Checking $$file..."; \
		if ! grep -q "<!DOCTYPE html>" $$file; then \
			echo "Warning: $$file missing DOCTYPE"; \
		fi; \
	done
	@echo "==> HTML files checked"
	@echo ""
	@echo "To preview locally, run:"
	@echo "  python3 -m http.server 8000"
	@echo "Then visit: http://localhost:8000"

# Clean up temporary files
clean:
	@echo "==> Cleaning up temporary files..."
	@find . -name ".DS_Store" -delete
	@find . -name "*.swp" -delete
	@find . -name "*~" -delete
	@echo "==> Cleanup complete"
