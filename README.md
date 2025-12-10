# Ahab Website

**URL**: https://waltdundore.github.io

## Quick Start

```bash
# Test locally
make serve

# Test before deploy
make test

# Deploy to all branches
make deploy-all MSG="Update website"
```

## Structure

- `index.html` - Landing page (compressed, 5 sections)
- `tutorial.html` - Complete tutorial
- `blog.html` - About Walt (compressed, 4 sections)
- `learn.html` - Learning resources (compressed, 3 sections)
- `style.css` - All styles
- `Makefile` - All commands

## Principles

1. **iPod Fish Tank** - No air bubbles, compress ruthlessly
2. **Make Commands** - Use Makefile, not direct commands
3. **Testing** - Test before deploy
4. **Accessibility** - WCAG 2.1 AA compliance

## Testing

```bash
make test-html    # Validate HTML
make test-links   # Check links (requires linkchecker)
make test-a11y    # Accessibility (requires pa11y)
make test         # All tests
```

## Deployment

```bash
make deploy-all MSG="Your message"
```

Deploys to:
- dev branch (testing)
- production branch (live site)

## Compression Status

Applied iPod Fish Tank principle:

### index.html
- **Before**: 11 sections, ~1200 lines
- **After**: 5 sections, ~150 lines
- **Removed**: Value Proposition, How It Works, Transparency boxes, Documentation cards, Repository Links, Recent Milestones

### blog.html
- **Before**: 6 sections with role cards, process flow, success timeline
- **After**: 4 sections, ~150 lines
- **Removed**: Role grid (6 cards), process flow, success timeline, get involved section, learning resources (moved to learn.html)

### learn.html
- **Before**: 5 sections, 20+ resource cards
- **After**: 3 sections, 9 resource cards
- **Removed**: Philosophy section, detailed teachable moments, learning paths, CTA grid

## Maintenance

### Every Month
1. Run fish tank test (look for new bubbles)
2. Run all tests (`make test`)
3. Check for broken links
4. Verify accessibility

### Every Feature
1. Add to appropriate section (don't create new sections)
2. Compress existing content if needed
3. Test before deploy
4. Update README if needed

## Rules

- **No new sections** - Add to existing sections only
- **Links over paragraphs** - Compress explanations to links
- **Value before process** - Show results, not how it works
- **One concept per section** - No repetition
- **Test before deploy** - Always run `make test`

---

**Last Updated**: 2025-12-09  
**Status**: Ahab compliant  
**Principles**: iPod Fish Tank applied