# Publishing Workflow Documentation

**Date**: December 12, 2025  
**Status**: Active  
**Audience**: Developers, Contributors  

---

## Overview

The Ahab website uses a **two-stage publishing process** to ensure quality and prevent accidental deployment of untested changes. This document explains the difference between `make publish` and `make publish-production` and why both are necessary.

---

## The Two-Stage Process

### Stage 1: Production Branch (Staging)
```bash
make publish-production
```

**Purpose**: Stage changes for review and testing  
**What it does**:
- Pushes current changes to the `production` branch
- Creates a staging environment for review
- Allows testing before live deployment
- Does NOT deploy to the live website

**When to use**:
- After making changes locally
- Before deploying to the live site
- When you want to stage changes for review

### Stage 2: Main Branch (Live Deployment)
```bash
make publish
```

**Purpose**: Deploy to the live website  
**What it does**:
- Runs complete test suite (HTML, CSS, accessibility, links, performance)
- Merges `production` branch → `main` branch
- Pushes `main` branch to GitHub
- Triggers GitHub Pages deployment
- Website goes live at https://waltdundore.github.io/

**When to use**:
- After reviewing changes on production branch
- When ready to deploy to live website
- Only after `make publish-production` has been run

---

## Why Two Commands?

### Safety and Quality Control

1. **Prevents Accidental Deployment**
   - Changes must be explicitly staged first
   - Two-step process reduces mistakes
   - Allows review before going live

2. **Testing and Validation**
   - `make publish` runs full test suite
   - Catches issues before deployment
   - Ensures website quality standards

3. **Branch Management**
   - `production` = staging/review branch
   - `main` = live deployment source
   - Clear separation of concerns

4. **Educational Transparency**
   - Shows the deployment process step-by-step
   - Follows ahab-development.md transparency principle
   - Users learn the workflow by using it

---

## Branch Architecture

```
Local Changes
     ↓
production branch (staging)
     ↓ (after review)
main branch (live)
     ↓ (automatic)
GitHub Pages (https://waltdundore.github.io/)
```

### Branch Purposes

- **`production`**: Staging area for changes awaiting deployment
- **`main`**: Source branch for GitHub Pages deployment
- **Local**: Development and testing environment

---

## Complete Workflow

### Daily Development
```bash
# 1. Make changes locally
vim status.html
vim style.css

# 2. Test changes
make test

# 3. Commit changes
git add .
git commit -m "Add version information to status page"

# 4. Stage for deployment
make publish-production

# 5. Review changes (optional)
# - Check production branch on GitHub
# - Verify changes are correct
# - Test staging environment if available

# 6. Deploy to live site
make publish
```

### Emergency Fixes
```bash
# For urgent fixes, you can combine steps:
make publish-production && make publish
```

### Checking Status
```bash
# See current branch sync status
make publish-status
```

---

## Command Reference

### `make publish-production`

**Full Command**: `git push origin production`  
**Purpose**: Update production branch (staging for main)  
**Output**:
```
==========================================
Publishing to Production Branch
==========================================

→ Running: git push origin production
   Purpose: Update production branch (staging for main)
Everything up-to-date
✅ Production branch updated
💡 Run 'make publish' to deploy to live site
```

**What happens**:
1. Pushes current local commits to `production` branch
2. Updates remote production branch
3. Prepares for main deployment
4. Does NOT trigger live deployment

### `make publish`

**Full Command**: Complete GitHub Pages deployment workflow  
**Purpose**: Deploy enhanced status page and website updates to live site  
**Output**:
```
==========================================
Publishing Website to GitHub Pages
==========================================

→ Running: GitHub Pages deployment workflow
   Purpose: Deploy enhanced status page and website updates to live site

📋 Deployment Steps:
  1. Merge production → main (GitHub Pages source)
  2. Push main to GitHub
  3. Verify deployment status

→ Switching to production branch
→ Merging production changes to main branch
→ Pushing main branch to GitHub (triggers GitHub Pages deployment)

✅ Website published successfully!
🌐 Live at: https://waltdundore.github.io/
📊 Status: https://waltdundore.github.io/status.html

⏱️  GitHub Pages deployment typically takes 1-2 minutes
🔄 Check deployment status: https://github.com/waltdundore/waltdundore.github.io/actions
```

**What happens**:
1. Runs complete test suite (HTML, CSS, accessibility, links, performance, security)
2. Switches to production branch
3. Merges production → main
4. Pushes main to GitHub
5. GitHub Pages automatically deploys the site
6. Website goes live

### `make publish-status`

**Purpose**: Show current publishing status  
**Output**:
```
==========================================
GitHub Pages Publishing Status
==========================================

📊 Repository Status:
  Current branch: main
  Last commit: f019804 - Auto-fix HTML and CSS validation issues (5 minutes ago)

📋 Branch Status:
  ✅ production: f019804 - Auto-fix HTML and CSS validation issues (5 minutes ago)
  ✅ main: f019804 - Auto-fix HTML and CSS validation issues (5 minutes ago)

🔄 Sync Status:
  ✅ production and main are in sync

🌐 Live Site: https://waltdundore.github.io/
📊 Status Page: https://waltdundore.github.io/status.html
🔄 Deployment Actions: https://github.com/waltdundore/waltdundore.github.io/actions
```

---

## Auto-Fix Process

Both commands include an **auto-fix process** that ensures compliance:

### What Gets Auto-Fixed
- HTML validation issues (missing `<main>` elements, etc.)
- CSS organization and standards compliance
- Accessibility improvements
- NASA Power of 10 compliance
- Zero Trust security standards

### Why Auto-Fix Happens
- Ensures consistent quality
- Prevents deployment of non-compliant code
- Maintains accessibility standards
- Follows development rules automatically

### Handling Auto-Fix Changes
If auto-fix makes changes, you'll need to commit them:
```bash
# Auto-fix creates changes
make publish

# If it fails due to uncommitted changes:
git add .
git commit -m "Auto-fix: HTML/CSS compliance updates"
make publish  # Try again
```

---

## Troubleshooting

### "Your local changes would be overwritten by checkout"
**Problem**: Auto-fix made changes that need to be committed  
**Solution**:
```bash
git add .
git commit -m "Auto-fix: compliance updates"
make publish  # Try again
```

### "Everything up-to-date" when running `make publish-production`
**Problem**: No new changes to push  
**Solution**: This is normal if no changes were made since last push

### GitHub Pages deployment not updating
**Problem**: Live site not showing changes after `make publish`  
**Solutions**:
1. Wait 1-2 minutes for GitHub Pages deployment
2. Check deployment status: https://github.com/waltdundore/waltdundore.github.io/actions
3. Hard refresh browser (Ctrl+F5 or Cmd+Shift+R)
4. Check if changes were actually pushed: `make publish-status`

---

## Integration with Development Rules

This workflow follows **ahab-development.md** principles:

### Transparency Principle
- Every command shows what it's running
- Users see the actual git commands
- Purpose is explained for each step
- Educational value in every interaction

### Make Command Pattern
```makefile
.PHONY: publish
publish: test
	@echo "→ Running: GitHub Pages deployment workflow"
	@echo "   Purpose: Deploy enhanced status page and website updates to live site"
	@# Actual deployment commands...
```

### Quick Iterative Testing
- `make publish` runs full test suite
- Catches issues before deployment
- Fast feedback on quality problems
- Prevents broken deployments

---

## Version Information

The status page now includes **version transparency**:

- **Production Version**: Current stable release (v0.2.0-alpha)
- **Build Hash**: Git commit hash of current deployment
- **Build Date**: When the current version was deployed
- **Live Site**: Link to verify deployment

This information is automatically updated with each deployment and matches the git repository state.

---

## Summary

**Two commands, two purposes:**

1. **`make publish-production`** = Stage changes (safe, reviewable)
2. **`make publish`** = Deploy to live site (tested, validated)

**Why both are needed:**
- Safety: Prevents accidental deployment
- Quality: Full testing before going live
- Transparency: Clear workflow steps
- Education: Users learn the process

**Typical usage:**
```bash
# Daily workflow
make publish-production  # Stage
make publish            # Deploy

# Emergency workflow  
make publish-production && make publish  # Stage and deploy immediately
```

This two-stage process ensures high-quality deployments while maintaining the educational transparency that's core to the Ahab project.

---

**Last Updated**: December 12, 2025  
**Status**: Active  
**Next Review**: When publishing workflow changes