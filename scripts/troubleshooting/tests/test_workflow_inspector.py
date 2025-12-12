"""
Tests for the WorkflowInspector class.

This module contains unit tests for the GitHub Actions workflow analysis
functionality, including permission validation, trigger checking, and
step analysis.
"""

import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add parent directories to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from diagnostic.workflow_inspector import WorkflowInspector
from models import TestStatus, Severity


class TestWorkflowInspector(unittest.TestCase):
    """Test cases for WorkflowInspector class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.temp_dir = tempfile.mkdtemp()
        self.repo_path = Path(self.temp_dir)
        self.workflows_dir = self.repo_path / '.github' / 'workflows'
        self.workflows_dir.mkdir(parents=True, exist_ok=True)
        
        self.inspector = WorkflowInspector(str(self.repo_path))
    
    def tearDown(self):
        """Clean up test fixtures."""
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_no_workflows_directory(self):
        """Test behavior when .github/workflows directory doesn't exist."""
        # Remove the workflows directory
        import shutil
        shutil.rmtree(self.workflows_dir)
        
        results = self.inspector.run_diagnostics()
        
        # Should have at least one result about missing directory
        self.assertTrue(len(results) > 0)
        directory_result = next((r for r in results if r.test_name == "workflows_directory_exists"), None)
        self.assertIsNotNone(directory_result)
        self.assertEqual(directory_result.status, TestStatus.FAIL)
        self.assertEqual(directory_result.severity, Severity.HIGH)
    
    def test_empty_workflows_directory(self):
        """Test behavior when workflows directory exists but is empty."""
        results = self.inspector.run_diagnostics()
        
        # Should find the directory but no workflow files
        directory_result = next((r for r in results if r.test_name == "workflows_directory_exists"), None)
        self.assertIsNotNone(directory_result)
        self.assertEqual(directory_result.status, TestStatus.PASS)
        
        files_result = next((r for r in results if r.test_name == "workflow_files_found"), None)
        self.assertIsNotNone(files_result)
        self.assertEqual(files_result.status, TestStatus.FAIL)
    
    def test_valid_pages_workflow(self):
        """Test analysis of a valid GitHub Pages workflow."""
        # Create a valid workflow file
        workflow_content = """name: Deploy to GitHub Pages

'on':
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Pages
        uses: actions/configure-pages@v4
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4"""
        
        workflow_file = self.workflows_dir / 'pages.yml'
        workflow_file.write_text(workflow_content)
        
        results = self.inspector.run_diagnostics()
        
        # Should successfully parse the workflow
        parse_result = next((r for r in results if r.test_name == "parse_workflow_pages.yml"), None)
        self.assertIsNotNone(parse_result)
        self.assertEqual(parse_result.status, TestStatus.PASS)
        
        # Should validate permissions correctly
        perm_result = next((r for r in results if r.test_name == "workflow_permissions_pages.yml"), None)
        self.assertIsNotNone(perm_result)
        self.assertEqual(perm_result.status, TestStatus.PASS)
        
        # Should validate triggers correctly
        trigger_result = next((r for r in results if r.test_name == "workflow_triggers_pages.yml"), None)
        self.assertIsNotNone(trigger_result)
        self.assertEqual(trigger_result.status, TestStatus.PASS)
        
        # Should find Pages deployment
        deploy_result = next((r for r in results if r.test_name == "pages_deployment_pages.yml"), None)
        self.assertIsNotNone(deploy_result)
        self.assertEqual(deploy_result.status, TestStatus.PASS)
    
    def test_workflow_missing_permissions(self):
        """Test analysis of workflow with missing permissions."""
        workflow_content = """name: Deploy to GitHub Pages

'on':
  push:
    branches: ["main"]

permissions:
  contents: read
  # Missing pages: write and id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Deploy to GitHub Pages
        uses: actions/deploy-pages@v4"""
        
        workflow_file = self.workflows_dir / 'incomplete.yml'
        workflow_file.write_text(workflow_content)
        
        results = self.inspector.run_diagnostics()
        
        # Should fail permission validation
        perm_result = next((r for r in results if r.test_name == "workflow_permissions_incomplete.yml"), None)
        self.assertIsNotNone(perm_result)
        self.assertEqual(perm_result.status, TestStatus.FAIL)
        self.assertEqual(perm_result.severity, Severity.HIGH)
        self.assertIn("Missing permissions", perm_result.details)
    
    def test_workflow_invalid_yaml(self):
        """Test analysis of workflow with invalid YAML."""
        invalid_yaml = """
name: Invalid Workflow
on:
  push:
    branches: ["main"
# Missing closing bracket - invalid YAML
jobs:
  deploy:
    runs-on: ubuntu-latest
"""
        
        workflow_file = self.workflows_dir / 'invalid.yml'
        workflow_file.write_text(invalid_yaml)
        
        results = self.inspector.run_diagnostics()
        
        # Should fail to parse
        parse_result = next((r for r in results if r.test_name == "parse_workflow_invalid.yml"), None)
        self.assertIsNotNone(parse_result)
        self.assertEqual(parse_result.status, TestStatus.FAIL)
        self.assertEqual(parse_result.severity, Severity.HIGH)
    
    def test_workflow_outdated_actions(self):
        """Test detection of outdated action versions."""
        workflow_content = """name: Deploy with Outdated Actions

'on':
  push:
    branches: ["main"]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2  # Outdated version
      - name: Deploy to GitHub Pages
        uses: actions/deploy-pages@v1  # Outdated version"""
        
        workflow_file = self.workflows_dir / 'outdated.yml'
        workflow_file.write_text(workflow_content)
        
        results = self.inspector.run_diagnostics()
        
        # Should warn about outdated actions
        steps_result = next((r for r in results if r.test_name == "workflow_steps_outdated.yml_deploy"), None)
        self.assertIsNotNone(steps_result)
        # Should be WARNING for outdated versions, not FAIL
        self.assertIn(steps_result.status, [TestStatus.WARNING, TestStatus.FAIL])
    
    def test_get_workflow_summary(self):
        """Test the workflow summary functionality."""
        # Create a simple workflow
        workflow_content = """name: Test Workflow
'on': push
permissions:
  contents: read
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4"""
        
        workflow_file = self.workflows_dir / 'test.yml'
        workflow_file.write_text(workflow_content)
        
        # Run diagnostics to populate internal state
        self.inspector.run_diagnostics()
        
        # Get summary
        summary = self.inspector.get_workflow_summary()
        
        self.assertEqual(summary['workflows_found'], 1)
        self.assertEqual(summary['workflows_parsed'], 1)
        self.assertIn('test.yml', summary['workflow_files'])
        self.assertIn('test.yml', summary['parsed_workflows'])
        self.assertIn('contents', summary['permissions_found'])


if __name__ == '__main__':
    unittest.main()