#!/bin/bash

# Setup script for secrets detection patterns
# This script creates the patterns file outside the repository
# The patterns file is NEVER committed to any repository

set -euo pipefail

PATTERNS_FILE="$HOME/.ahab-secrets-patterns"

echo "Setting up secrets detection patterns..."
echo "Patterns file: $PATTERNS_FILE"

# Create the patterns file with detection rules
# This file stays on the local machine and is never committed
cat > "$PATTERNS_FILE" << 'EOF'
# Secrets Detection Patterns
# This file contains patterns to detect sensitive information
# NEVER commit this file to any repository
# Created: $(date)

# Network switch credentials patterns
SWITCH_PASSWORD: (aruba|ruckus|cisco).*password[[:space:]]*[:=][[:space:]]*['\"][^'\"]{8,}
ENABLE_PASSWORD: enable.*password[[:space:]]*[:=][[:space:]]*['\"][^'\"]{8,}
SNMP_COMMUNITY: snmp.*community[[:space:]]*[:=][[:space:]]*['\"][^'\"]{4,}

# Database credentials patterns  
DB_PASSWORD: (postgres|mysql|mongodb).*password[[:space:]]*[:=][[:space:]]*['\"][^'\"]{8,}
DB_CONNECTION: (postgresql|mysql|mongodb)://[^:]+:[^@]+@[^/]+
ROOT_PASSWORD: root.*password[[:space:]]*[:=][[:space:]]*['\"][^'\"]{8,}

# API keys and tokens
AWS_KEY: (AKIA|aws_access_key)[A-Z0-9]{16,}
GITHUB_TOKEN: ghp_[a-zA-Z0-9]{36}
DOCKER_TOKEN: dckr_pat_[a-zA-Z0-9_-]{36,}
SLACK_WEBHOOK: hooks\.slack\.com/services/[A-Z0-9]{9}/[A-Z0-9]{9}/[a-zA-Z0-9]{24}

# SSH keys and certificates
PRIVATE_KEY: -----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----
SSH_KEY_CONTENT: ssh-rsa [A-Za-z0-9+/]{300,}
CERTIFICATE_KEY: -----BEGIN CERTIFICATE-----

# Internal network information
INTERNAL_IP: 10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}
PRIVATE_SUBNET: 172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}
LOCALHOST_VARIANT: (localhost|127\.0\.0\.1):[0-9]{4,5}

# Specific organizational patterns (customize for your environment)
SCHOOL_DOMAIN: @[a-zA-Z0-9.-]*\.edu
INTERNAL_DOMAIN: @[a-zA-Z0-9.-]*\.(local|internal|corp)
REAL_EMAIL: @(gmail|yahoo|hotmail|outlook)\.(com|org)

# Vault and encryption patterns
VAULT_PASSWORD: vault.*password[[:space:]]*[:=][[:space:]]*['\"][^'\"]{12,}
ENCRYPTION_KEY: [A-Za-z0-9+/]{32,}={0,2}
GPG_KEY: -----BEGIN PGP (PUBLIC|PRIVATE) KEY BLOCK-----

# Configuration file patterns
CONFIG_SECRET: (secret|token|key)[[:space:]]*[:=][[:space:]]*['\"][^'\"]{16,}
ENV_VAR_SECRET: [A-Z_]+_(PASSWORD|SECRET|KEY|TOKEN)[[:space:]]*[:=][[:space:]]*['\"][^'\"]{8,}

# URLs with credentials
URL_WITH_CREDS: https?://[^:]+:[^@]+@[^/]+
FTP_WITH_CREDS: ftp://[^:]+:[^@]+@[^/]+

# Specific service patterns
DATADOG_KEY: [a-f0-9]{32}
NEWRELIC_KEY: [a-f0-9]{40}
SENDGRID_KEY: SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}

# Hardware serial numbers (might be sensitive)
SERIAL_NUMBER: (S/N|Serial|SN)[[:space:]]*[:=][[:space:]]*[A-Z0-9]{8,}
MAC_ADDRESS: ([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})

# Comments that might contain secrets
SECRET_COMMENT: #.*[Pp]assword.*[A-Za-z0-9]{8,}
TODO_SECRET: (TODO|FIXME).*[Pp]assword.*[A-Za-z0-9]{8,}
EOF

# Set restrictive permissions on the patterns file
chmod 600 "$PATTERNS_FILE"

echo "✓ Secrets detection patterns file created: $PATTERNS_FILE"
echo "✓ File permissions set to 600 (owner read/write only)"
echo ""
echo "IMPORTANT SECURITY NOTES:"
echo "1. This file contains detection patterns and should NEVER be committed"
echo "2. The file is stored outside any git repository"
echo "3. Customize the patterns for your specific environment"
echo "4. Review and update patterns regularly"
echo "5. Keep this file secure and backed up separately"
echo ""
echo "To test the detection:"
echo "  cd waltdundore.github.io"
echo "  ./tests/test-secrets.sh"
echo ""
echo "To add custom patterns:"
echo "  echo 'CUSTOM_PATTERN: your_regex_here' >> $PATTERNS_FILE"