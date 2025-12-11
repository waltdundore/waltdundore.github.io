# Secrets Detection System

**Purpose**: Prevent accidental publication of sensitive information to the public website.

**Status**: MANDATORY - All publishes MUST pass secrets detection.

---

## Overview

This system prevents sensitive phrases, credentials, and internal information from being accidentally published to the public GitHub Pages website. It follows Zero Trust principles - never trust that sensitive data won't accidentally get committed.

### How It Works

1. **External Patterns File**: Detection patterns are stored in `$HOME/.ahab-secrets-patterns` (never committed)
2. **Pre-Publish Scan**: Every `make test` and `make deploy` runs secrets detection
3. **Blocking Errors**: Sensitive content blocks publication until removed
4. **Security by Design**: Detection patterns themselves are kept secret

---

## Setup (One-Time)

### Initial Setup

```bash
cd waltdundore.github.io

# Run one-time setup to create detection patterns
make setup-secrets
```

This creates `$HOME/.ahab-secrets-patterns` with detection rules for:
- Network switch credentials
- Database passwords
- API keys and tokens
- SSH keys and certificates
- Internal IP addresses
- Email addresses
- Private repository references
- Configuration secrets

### Verify Setup

```bash
# Test that secrets detection works
make test-secrets

# Should output:
# ✓ No sensitive content detected - safe to publish
```

---

## Usage

### Before Every Publish

```bash
# Run complete test suite (includes secrets detection)
make test

# Or run secrets detection specifically
make test-secrets
```

### Publishing Workflow

```bash
# 1. Make changes to website
vim index.html

# 2. Test everything (including secrets)
make test

# 3. If tests pass, deploy
make deploy
```

**The secrets test is MANDATORY and will block deployment if sensitive content is found.**

---

## What Gets Detected

### Automatic Detection

The system automatically scans for:

**Credentials**:
- Passwords in configuration files
- API keys and tokens
- SSH private keys
- Database connection strings
- SNMP community strings

**Network Information**:
- Internal IP addresses (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
- Private hostnames (.local, .internal, .corp)
- URLs with embedded credentials

**Organizational Data**:
- Real email addresses (non-example domains)
- References to private repositories
- Internal system names

**Configuration Secrets**:
- Environment variables with secrets
- Vault passwords
- Encryption keys
- Service tokens

### Example Patterns Detected

```bash
# These would be BLOCKED:
password = "MySecretPassword123"
api_key = "sk_live_FAKE_KEY_FOR_DOCS"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... (real SSH key)
postgresql://user:pass@localhost:5432/db
192.168.1.100
admin@myschool.edu

# These would be ALLOWED:
password = "REPLACE_WITH_YOUR_PASSWORD"
api_key = "your_api_key_here"
ssh-rsa EXAMPLE_KEY_CONTENT
postgresql://USER:PASSWORD@HOST:PORT/DATABASE
192.168.1.100 (in documentation context)
admin@example.com
```

---

## Security Features

### Zero Trust Design

**Never Trust**:
- Assumes developers will accidentally include secrets
- Assumes copy/paste will include real data
- Assumes examples might contain real information

**Always Verify**:
- Scans every file before publication
- Uses comprehensive pattern matching
- Blocks publication on any detection

**Assume Breach**:
- Detection patterns stored outside repository
- No sensitive patterns visible in public code
- Multiple layers of detection (patterns + hardcoded checks)

### Defense in Depth

1. **Pattern-Based Detection**: Custom regex patterns for known secret types
2. **Hardcoded Checks**: Common patterns built into the script
3. **Context Analysis**: Distinguishes between examples and real data
4. **File Type Filtering**: Only scans files that get published
5. **Manual Review**: Warnings flag suspicious content for review

---

## Customization

### Adding Custom Patterns

```bash
# Add organization-specific patterns
echo 'SCHOOL_ID: [Ss]chool[Ii][Dd][[:space:]]*[:=][[:space:]]*[0-9]{6,}' >> ~/.ahab-secrets-patterns
echo 'STUDENT_ID: [Ss]tudent[Ii][Dd][[:space:]]*[:=][[:space:]]*[0-9]{8,}' >> ~/.ahab-secrets-patterns

# Add domain-specific patterns
echo 'INTERNAL_DOMAIN: @myschool\.(edu|org)' >> ~/.ahab-secrets-patterns
```

### Pattern Format

```bash
# Format: PATTERN_TYPE: regex_pattern
PATTERN_TYPE: regular_expression_here

# Examples:
PASSWORD: password[[:space:]]*[:=][[:space:]]*['\"][^'\"]{8,}
API_KEY: api[_-]?key[[:space:]]*[:=][[:space:]]*['\"][^'\"]{16,}
EMAIL: [a-zA-Z0-9._%+-]+@myorganization\.(com|org|edu)
```

---

## Troubleshooting

### Common Issues

#### 1. Patterns File Not Found

**Error**: `ERROR: Secrets patterns file not found`

**Solution**:
```bash
# Run setup again
make setup-secrets

# Verify file exists
ls -la ~/.ahab-secrets-patterns
```

#### 2. False Positives

**Error**: Legitimate content flagged as sensitive

**Solutions**:
```bash
# Option 1: Use placeholder text
# Change: password = "RealPassword123"
# To:     password = "REPLACE_WITH_YOUR_PASSWORD"

# Option 2: Add to examples context
# Change: api_key = "real_key_here"
# To:     api_key = "example_api_key_here"

# Option 3: Modify patterns (carefully)
vim ~/.ahab-secrets-patterns
```

#### 3. Real Secrets Detected

**Error**: `ERROR: Potential SECRET_TYPE detected`

**Solution**:
```bash
# DO NOT modify detection - fix the content
# Replace real secrets with placeholders
# Use sanitized examples instead of real data
# Move sensitive content to private repository
```

### Testing Detection

```bash
# Test with a known pattern (will be caught)
echo 'password = "TestPassword123"' > test-secret.html
make test-secrets
# Should show ERROR

# Clean up
rm test-secret.html
make test-secrets
# Should show ✓ No sensitive content detected
```

---

## Maintenance

### Regular Updates

**Monthly**:
- Review detection patterns for completeness
- Update patterns based on new secret types
- Test detection with known examples

**After Security Incidents**:
- Add patterns for newly discovered secret types
- Review and strengthen existing patterns
- Update documentation with lessons learned

### Pattern File Backup

```bash
# Backup patterns file (keep secure)
cp ~/.ahab-secrets-patterns ~/.ahab-secrets-patterns.backup

# Restore from backup
cp ~/.ahab-secrets-patterns.backup ~/.ahab-secrets-patterns
```

---

## Integration with CI/CD

### GitHub Actions (Future)

```yaml
# .github/workflows/publish.yml
- name: Secrets Detection
  run: |
    cd waltdundore.github.io
    make test-secrets
  # Blocks deployment if secrets found
```

### Pre-Commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
cd waltdundore.github.io
make test-secrets || exit 1
```

---

## Compliance

### Zero Trust Compliance

- ✅ **Never Trust**: Assumes secrets will be accidentally included
- ✅ **Always Verify**: Scans every file before publication
- ✅ **Assume Breach**: Detection patterns kept secret and secure

### STIG Compliance

- ✅ **V-235791**: No secrets embedded in published content
- ✅ **V-235792**: Automated detection prevents accidental exposure
- ✅ **V-235793**: Audit trail of all detection runs

---

## Related Documentation

- [Zero Trust Development](../.kiro/steering/zero-trust-development.md) - Security principles
- [Secrets Repository](../ahab/docs/SECRETS_REPOSITORY.md) - Secure credential storage
- [Website Testing](tests/) - Complete testing suite

---

## Summary

**The secrets detection system provides:**

1. **Automated Protection**: Scans every file before publication
2. **Comprehensive Coverage**: Detects credentials, keys, internal data
3. **Zero Trust Design**: Never trusts that content is safe
4. **Blocking Enforcement**: Prevents publication of sensitive content
5. **Secure Patterns**: Detection rules kept outside public repository
6. **Easy Integration**: Works seamlessly with existing workflow

**Key Commands**:
- `make setup-secrets` - One-time setup
- `make test-secrets` - Run detection scan
- `make test` - Full test suite (includes secrets)
- `make deploy` - Deploy after all tests pass

**This system is MANDATORY for all website publications.**

---

**Last Updated**: December 9, 2025  
**Status**: MANDATORY  
**Exceptions**: NONE