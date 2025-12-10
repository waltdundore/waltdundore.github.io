# waltdundore.github.io

Personal website and documentation for the Ahab project.

## Live Site

https://waltdundore.github.io/

## Branches

- `production` - Live site (GitHub Pages serves from this branch)
- `dev` - Development/staging

## Publishing

### Manual Publishing

```bash
# Commit and push to production
make deploy-prod MSG="Your commit message"

# Or deploy to both branches
make deploy-all MSG="Your commit message"
```

### Automatic Publishing

GitHub Actions automatically publishes changes every 5 minutes when changes are detected on the production branch.

## Local Development

```bash
# Preview locally
python3 -m http.server 8000

# Then visit: http://localhost:8000
```

## Structure

- `index.html` - Homepage
- `tutorial.html` - Complete tutorial
- `blog.html` - Blog/about page
- `style.css` - Styles
- `ahab-logo.png` - Logo

## Deployment

GitHub Pages automatically serves the `production` branch at https://waltdundore.github.io/
