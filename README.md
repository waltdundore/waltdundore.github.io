# Ahab Website (waltdundore.github.io)

**Public-facing educational resource and project marketing website**

This is the GitHub Pages website for the Ahab project - one of three distinct teaching tools in the Ahab ecosystem.

## 🎯 Purpose & Audience

**Purpose**: Public-facing educational resource and project discovery  
**Audience**: General public, potential users, educators researching tools  
**Context**: First impression, discovery, and conceptual learning  

**What this website provides**:
- Project overview and value proposition
- Learning pathways for different skill levels  
- Educational resources and tutorials
- Teacher guides and curriculum alignment
- Public project status and updates

**When to use this website**: When you want to learn about infrastructure automation concepts or evaluate Ahab for your organization.

## 🔗 Related Teaching Tools

This website is part of a three-tool teaching ecosystem:

- **🌐 This Website** - Conceptual learning and discovery
- **📖 [Main README](https://github.com/waltdundore/ahab)** - Technical implementation guide
- **🖥️ [Ahab GUI](https://github.com/waltdundore/ahab-gui)** - Interactive hands-on learning

See the [Teaching Tools Overview](https://github.com/waltdundore/ahab/blob/main/TEACHING_TOOLS_OVERVIEW.md) for detailed comparisons.

## ⚠️ CRITICAL: Deployment Process

**The `make deploy` command does NOT actually deploy!**

### What `make deploy` Actually Does:
1. ✅ Runs comprehensive tests (HTML, CSS, accessibility, links, performance)
2. ✅ Stages files with `git add .`
3. ✅ Shows you what will be committed
4. ❌ **Does NOT commit**
5. ❌ **Does NOT push**
6. ❌ **Does NOT deploy**

### To Actually Deploy:
```bash
# Step 1: Prepare for deployment (runs tests, stages files)
make deploy

# Step 2: Actually deploy (manual confirmation required)
git commit -m "your commit message"
git push origin main
```

### Why This Two-Step Process?
- **Safety**: Prevents accidental deployments
- **Transparency**: You see exactly what's being deployed
- **Education**: You learn the actual git commands
- **Control**: You write your own commit message

## Available Commands

Run `make help` to see all available commands.

### Key Commands:
- `make test` - Run all validation tests
- `make serve` - Start local development server
- `make deploy` - **PREPARE** for deployment (does not commit/push)
- `make validate` - Validate HTML/CSS compliance
- `make compliance-report` - Generate compliance status report

## Development Workflow

1. Make changes to HTML/CSS files
2. Test locally: `make serve` (opens http://localhost:8000)
3. Validate changes: `make test`
4. Prepare deployment: `make deploy`
5. Review staged changes: `git status`
6. Commit and deploy: `git commit -m "description" && git push origin main`

## Standards Compliance

This website follows:
- **Ahab Branding Guidelines** (colors, fonts, logo)
- **WCAG 2.1 AA Accessibility** (contrast, alt text, keyboard navigation)
- **Progressive Disclosure UX** (elevator principle)
- **Zero Trust Security** (no hardcoded secrets, input validation)
- **NASA Power of 10** (code quality standards)

All standards are automatically validated by `make test`.