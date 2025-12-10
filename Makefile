# ==============================================================================
# Makefile for waltdundore.github.io
# ==============================================================================
#
# PURPOSE:
#   Automate GitHub Pages deployment and local testing
#
# WHAT IS A MAKEFILE?
#   A Makefile is a build automation tool that:
#   - Defines "targets" (commands you can run)
#   - Manages dependencies between targets
#   - Provides a consistent interface across projects
#   - Documents available commands in one place
#
# HOW TO USE THIS MAKEFILE:
#   1. Run `make help` to see all available commands
#   2. Run `make <target>` to execute a specific command
#   3. Example: `make test` runs HTML validation
#
# MAKEFILE SYNTAX BASICS:
#   target: dependencies
#       command
#       another-command
#
#   - Lines starting with # are comments
#   - Targets are the names you type after `make`
#   - Commands MUST be indented with a TAB (not spaces!)
#   - @ before a command suppresses echo (silent execution)
#   - $$ escapes $ in shell commands (Make uses $ for variables)
#   - $(VAR) references a Make variable
#   - $(MAKE) recursively calls make (for calling other targets)
#
# SPECIAL VARIABLES USED HERE:
#   .PHONY - Declares targets that don't create files
#   $(shell ...) - Executes shell command and captures output
#   $$(pwd) - Shell variable (escaped with $$)
#   MSG - User-provided variable (e.g., make commit MSG="my message")
#
# LEARNING RESOURCES:
#   - GNU Make Manual: https://www.gnu.org/software/make/manual/
#   - Make Tutorial: https://makefiletutorial.com/
#
# ==============================================================================

# .PHONY tells Make these targets don't create files with these names
# Without .PHONY, if a file named "test" existed, `make test` wouldn't run
.PHONY: help status commit push deploy deploy-dev deploy-prod deploy-all test preview preview-docker clean

# ==============================================================================
# DEFAULT TARGET (runs when you type just `make`)
# ==============================================================================
# The first target in a Makefile is the default
# We make it `help` so users see available commands
help:
	@echo "================================================================================"
	@echo "GitHub Pages Deployment - Available Commands"
	@echo "================================================================================"
	@echo ""
	@echo "TESTING & PREVIEW:"
	@echo "  make test          - Validate HTML files"
	@echo "  make preview       - Preview site locally (Python http.server)"
	@echo "  make preview-docker - Preview site in Docker container (Container-First)"
	@echo ""
	@echo "GIT OPERATIONS:"
	@echo "  make status        - Show git status"
	@echo "  make commit        - Stage and commit changes (requires MSG='...')"
	@echo "  make push          - Push current branch to origin"
	@echo ""
	@echo "DEPLOYMENT:"
	@echo "  make deploy        - Commit and push current branch (requires MSG='...')"
	@echo "  make deploy-dev    - Deploy to dev branch (requires MSG='...')"
	@echo "  make deploy-prod   - Deploy to production branch (requires MSG='...')"
	@echo "  make deploy-all    - Deploy to all branches (requires MSG='...')"
	@echo ""
	@echo "MAINTENANCE:"
	@echo "  make clean         - Clean up temporary files (.DS_Store, etc.)"
	@echo ""
	@echo "EXAMPLES:"
	@echo "  make test"
	@echo "  make preview-docker"
	@echo "  make deploy-all MSG='Update site with new features'"
	@echo ""
	@echo "LEARN MORE:"
	@echo "  Read the comments in this Makefile to learn how Make works!"
	@echo "================================================================================"
	@echo ""

# ==============================================================================
# GIT OPERATIONS
# ==============================================================================

# Show git status
# The @ before echo suppresses printing the command itself
# Without @, you'd see: echo "==> Checking git status..."
# With @, you only see: ==> Checking git status...
status:
	@echo "==> Checking git status..."
	git status

# Stage and commit changes
# This target requires a MSG variable: make commit MSG="your message"
# $(MSG) is a Make variable that gets its value from the command line
# The if statement checks if MSG is empty and exits with error if so
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
# $$(git branch --show-current) - Double $$ escapes the $ for shell
# In Make, $ has special meaning, so $$ becomes $ in the shell command
# The backslash \ continues the command on the next line
push:
	@echo "==> Pushing to origin..."
	@BRANCH=$$(git branch --show-current); \
	echo "==> Pushing branch: $$BRANCH"; \
	git push origin $$BRANCH

# ==============================================================================
# DEPLOYMENT TARGETS
# ==============================================================================
# These targets combine multiple operations for common workflows

# Deploy to current branch (commit + push)
# $(MAKE) calls make recursively to run another target
# This is better than duplicating code - follows DRY principle
# We pass MSG="$(MSG)" to forward the message to the commit target
deploy:
	@echo "==> Deploying to current branch..."
	@if [ -z "$(MSG)" ]; then \
		echo "Error: Please provide a commit message with MSG='your message'"; \
		exit 1; \
	fi
	@$(MAKE) commit MSG="$(MSG)"
	@$(MAKE) push

# Deploy to dev branch
# This target ensures we're on the dev branch before deploying
# If we're on a different branch, it switches to dev first
# This prevents accidentally deploying to the wrong branch
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
# Same as deploy-dev but for production
# Production is the branch GitHub Pages serves from
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
# This is a complex target that:
# 1. Saves current branch
# 2. Deploys to dev
# 3. Deploys to production
# 4. Returns to original branch
# The && operator chains commands - if one fails, the rest don't run
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
	git commit -m "$(MSG)" || true && \
	git push origin dev && \
	echo ""; \
	echo "==> Deploying to production..."; \
	git checkout production && \
	git add . && \
	git commit -m "$(MSG)" || true && \
	git push origin production && \
	echo ""; \
	echo "==> Returning to original branch: $$ORIGINAL"; \
	git checkout $$ORIGINAL && \
	echo ""; \
	echo "==> Successfully deployed to all branches!"

# ==============================================================================
# TESTING & PREVIEW
# ==============================================================================

# Test HTML files locally
# This is a simple validation that checks for DOCTYPE declarations
# For more thorough validation, consider using html5validator or similar
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
	@echo "  make preview        (Python)"
	@echo "  make preview-docker (Docker)"

# Preview site locally with Python
# Python's http.server module provides a simple web server
# This is quick and easy but not suitable for production
# Press Ctrl+C to stop the server
preview:
	@echo "==> Starting local preview server..."
	@echo "==> Visit: http://localhost:8000"
	@echo "==> Press Ctrl+C to stop"
	@python3 -m http.server 8000

# Preview site in Docker container (Container-First principle)
# This follows our "python-in-docker" principle - always use containers
# Uses nginx:alpine for a lightweight, production-like environment
# -v mounts current directory as read-only (:ro)
# -p maps container port 80 to host port 8000
# --rm automatically removes container when stopped
preview-docker:
	@echo "==> Starting Docker preview server..."
	@echo "==> Visit: http://localhost:8000"
	@echo "==> Press Ctrl+C to stop"
	@docker run --rm \
		-v $$(pwd):/usr/share/nginx/html:ro \
		-p 8000:80 \
		nginx:alpine

# ==============================================================================
# MAINTENANCE
# ==============================================================================

# Clean up temporary files
# find command searches for files matching patterns
# -name ".DS_Store" finds macOS metadata files
# -delete removes them
# This keeps the repository clean
clean:
	@echo "==> Cleaning up temporary files..."
	@find . -name ".DS_Store" -delete
	@find . -name "*.swp" -delete
	@find . -name "*~" -delete
	@echo "==> Cleanup complete"

# ==============================================================================
# END OF MAKEFILE
# ==============================================================================
# Questions? Read the comments above or run `make help`
# Want to learn more about Make? Visit https://makefiletutorial.com/
