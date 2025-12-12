# GitHub Pages Troubleshooting System

A comprehensive diagnostic and repair system for GitHub Pages deployment issues.

## Overview

This system provides automated diagnostics, validation, testing, and repair capabilities for GitHub Pages websites. It can identify common deployment issues, validate content, test functionality, and suggest or apply fixes.

## Features

- **Diagnostic Engine**: Analyzes repository configuration, GitHub Actions, DNS, and deployment status
- **Content Validation**: Validates HTML, checks links, verifies resources, and tests accessibility
- **Testing Framework**: Performs HTTP testing, branch validation, and performance monitoring
- **Repair Engine**: Provides automated fixes for common configuration and content issues
- **Comprehensive Reporting**: Generates detailed reports with root cause analysis and repair suggestions

## Quick Start

1. **Setup the environment:**
   ```bash
   python3 setup.py
   ```

2. **Activate the environment:**
   ```bash
   # On Linux/macOS:
   source activate.sh
   
   # On Windows:
   activate.bat
   ```

3. **Run diagnostics:**
   ```bash
   python cli.py diagnose
   ```

## Installation

### Prerequisites

- Python 3.8 or higher
- Git
- Internet connection for GitHub API access

### Setup

The setup script will create a virtual environment and install all dependencies:

```bash
cd waltdundore.github.io/scripts/troubleshooting
python3 setup.py
```

This will:
- Create a Python virtual environment in `./venv`
- Install required packages (requests, PyYAML, beautifulsoup4, GitPython, hypothesis)
- Create necessary directories (logs, reports, backups, config)
- Generate activation scripts

## Usage

### Basic Diagnostics

Run diagnostics on the current repository:
```bash
python cli.py diagnose
```

Run diagnostics on a specific repository:
```bash
python cli.py diagnose --repository /path/to/repo
```

Save results to a file:
```bash
python cli.py diagnose --output results.json
```

### Configuration

The system uses a YAML configuration file. You can:

1. Use the default configuration (recommended for most cases)
2. Create a custom configuration file:
   ```bash
   cp config/default.yml my-config.yml
   # Edit my-config.yml as needed
   python cli.py diagnose --config my-config.yml
   ```

### Environment Variables

You can override configuration using environment variables with the prefix `GHPAGES_TROUBLESHOOT_`:

```bash
export GHPAGES_TROUBLESHOOT_LOGGING__LEVEL=DEBUG
export GHPAGES_TROUBLESHOOT_TESTING__HTTP_TIMEOUT=60
python cli.py diagnose
```

## Architecture

The system follows a modular architecture:

```
troubleshooting/
├── models.py          # Data models and structures
├── base.py            # Base classes for components
├── config.py          # Configuration management
├── orchestrator.py    # Main diagnostic coordinator
├── cli.py             # Command-line interface
├── diagnostic/        # Diagnostic components
├── validation/        # Content validation components
├── testing/           # Testing framework components
├── repair/            # Repair engine components
└── reporting/         # Report generation components
```

## Components

### Diagnostic Engine
- **Repository Analyzer**: Checks repository settings and configuration
- **GitHub Actions Inspector**: Validates workflow files and permissions
- **DNS/Network Tester**: Tests domain resolution and connectivity
- **Configuration Validator**: Verifies GitHub Pages settings

### Content Validation Engine
- **HTML Validator**: Validates markup and structure
- **Link Checker**: Tests internal and external links
- **Resource Validator**: Verifies CSS, JavaScript, and images
- **Accessibility Tester**: Checks WCAG compliance

### Testing Framework
- **Curl Test Suite**: HTTP status and performance testing
- **Branch Validator**: Git branch analysis and validation
- **Deployment Tester**: GitHub Actions workflow testing
- **Performance Monitor**: Page load and optimization analysis

### Repair Engine
- **Configuration Fixer**: Repairs GitHub Pages settings
- **Branch Synchronizer**: Fixes branch and merge issues
- **Workflow Updater**: Updates GitHub Actions configurations
- **Content Repairer**: Fixes HTML and link issues

## Configuration Reference

See `config/default.yml` for the complete configuration reference with all available options.

## Troubleshooting

### Common Issues

1. **Import errors**: Make sure the virtual environment is activated
2. **Permission errors**: Ensure you have read access to the repository
3. **Network timeouts**: Check your internet connection and firewall settings
4. **GitHub API rate limits**: The system respects rate limits automatically

### Logging

Logs are written to `./logs/troubleshooting.log` by default. You can:
- Change the log level: `--verbose` or set `GHPAGES_TROUBLESHOOT_LOGGING__LEVEL=DEBUG`
- Change the log file location in the configuration

## Development

### Adding New Components

1. Create a new component class inheriting from the appropriate base class
2. Implement the required methods
3. Register the component with the orchestrator
4. Add tests for the new functionality

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-cov hypothesis

# Run tests
pytest tests/

# Run with coverage
pytest --cov=troubleshooting tests/
```

## License

This project is part of the waltdundore.github.io repository and follows the same license terms.