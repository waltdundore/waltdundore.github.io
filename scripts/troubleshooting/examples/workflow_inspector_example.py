#!/usr/bin/env python3
"""
Example usage of the WorkflowInspector class.

This script demonstrates how to use the WorkflowInspector to analyze
GitHub Actions workflows for GitHub Pages deployment issues.
"""

import os
import sys
import logging
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from diagnostic.workflow_inspector import WorkflowInspector
from models import TestStatus, Severity


def setup_logging():
    """Set up logging configuration."""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )


def analyze_repository(repo_path: str):
    """
    Analyze a repository's GitHub Actions workflows.
    
    Args:
        repo_path: Path to the repository to analyze
    """
    print(f"Analyzing GitHub Actions workflows in: {repo_path}")
    print("=" * 60)
    
    # Create WorkflowInspector
    inspector = WorkflowInspector(repo_path)
    
    # Run diagnostics
    results = inspector.run_diagnostics()
    
    # Display results
    print(f"\nFound {len(results)} diagnostic results:")
    print("-" * 40)
    
    for result in results:
        status_symbol = {
            TestStatus.PASS: "✅",
            TestStatus.FAIL: "❌",
            TestStatus.WARNING: "⚠️"
        }.get(result.status, "❓")
        
        severity_color = {
            Severity.LOW: "",
            Severity.MEDIUM: "🟡",
            Severity.HIGH: "🟠",
            Severity.CRITICAL: "🔴"
        }.get(result.severity, "")
        
        print(f"{status_symbol} {severity_color} {result.test_name}")
        print(f"   {result.message}")
        
        if result.status != TestStatus.PASS:
            print(f"   Details: {result.details}")
            if result.suggested_fix:
                print(f"   Fix: {result.suggested_fix}")
        
        print()
    
    # Display summary
    summary = inspector.get_workflow_summary()
    print("Summary:")
    print("-" * 40)
    print(f"Workflows found: {summary['workflows_found']}")
    print(f"Workflows parsed: {summary['workflows_parsed']}")
    print(f"Required permissions present: {summary['has_required_permissions']}")
    
    if summary['workflow_files']:
        print(f"Workflow files: {', '.join(summary['workflow_files'])}")
    
    if summary['permissions_found']:
        print(f"Permissions found: {', '.join(summary['permissions_found'])}")


def main():
    """Main function."""
    setup_logging()
    
    # Get repository path from command line or use current directory
    if len(sys.argv) > 1:
        repo_path = sys.argv[1]
    else:
        repo_path = "."
    
    # Verify path exists
    if not Path(repo_path).exists():
        print(f"Error: Repository path '{repo_path}' does not exist")
        sys.exit(1)
    
    try:
        analyze_repository(repo_path)
    except Exception as e:
        print(f"Error analyzing repository: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()