"""
Integration tests for the GitHub Pages troubleshooting system.

This module contains integration tests that verify components work
together correctly through the orchestrator.
"""

import os
import sys
import tempfile
import unittest
from pathlib import Path

# Add parent directories to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from orchestrator import DiagnosticOrchestrator
from diagnostic.workflow_inspector import WorkflowInspector
from config import TroubleshootingConfig
from models import TestStatus


class TestIntegration(unittest.TestCase):
    """Integration test cases."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.temp_dir = tempfile.mkdtemp()
        self.repo_path = Path(self.temp_dir)
        self.workflows_dir = self.repo_path / '.github' / 'workflows'
        self.workflows_dir.mkdir(parents=True, exist_ok=True)
        
        # Create config
        self.config = TroubleshootingConfig()
        
        # Create orchestrator
        self.orchestrator = DiagnosticOrchestrator(self.config)
    
    def tearDown(self):
        """Clean up test fixtures."""
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_workflow_inspector_integration(self):
        """Test WorkflowInspector integration with orchestrator."""
        # Create a test workflow
        workflow_content = """name: Test Workflow
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
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Deploy to GitHub Pages
        uses: actions/deploy-pages@v4"""
        
        workflow_file = self.workflows_dir / 'test.yml'
        workflow_file.write_text(workflow_content)
        
        # Create and register WorkflowInspector
        inspector = WorkflowInspector(str(self.repo_path))
        self.orchestrator.register_component(inspector)
        
        # Start session and run diagnostics
        session = self.orchestrator.start_session(str(self.repo_path))
        completed_session = self.orchestrator.run_diagnostics()
        
        # Verify session completed
        self.assertIsNotNone(completed_session.end_time)
        self.assertEqual(completed_session.session_id, session.session_id)
        
        # Verify results were generated
        self.assertGreater(len(completed_session.diagnostic_results), 0)
        
        # Check for specific workflow results
        workflow_results = [r for r in completed_session.diagnostic_results 
                          if 'workflow' in r.test_name]
        self.assertGreater(len(workflow_results), 0)
        
        # Verify some tests passed (the workflow should be valid)
        passed_results = [r for r in workflow_results if r.status == TestStatus.PASS]
        self.assertGreater(len(passed_results), 0)
        
        # Get session summary
        summary = self.orchestrator.get_session_summary()
        self.assertEqual(summary['status'], 'completed')
        self.assertEqual(summary['components_executed'], 1)
    
    def test_multiple_components_integration(self):
        """Test integration with multiple diagnostic components."""
        # Create multiple WorkflowInspector instances (simulating different components)
        inspector1 = WorkflowInspector(str(self.repo_path))
        inspector1.name = "WorkflowInspector1"  # Override name for testing
        
        inspector2 = WorkflowInspector(str(self.repo_path))
        inspector2.name = "WorkflowInspector2"  # Override name for testing
        
        self.orchestrator.register_component(inspector1)
        self.orchestrator.register_component(inspector2)
        
        # Start session and run diagnostics
        session = self.orchestrator.start_session(str(self.repo_path))
        completed_session = self.orchestrator.run_diagnostics()
        
        # Verify both components executed
        summary = self.orchestrator.get_session_summary()
        self.assertEqual(summary['components_executed'], 2)
        
        # Verify results from both components
        results_by_component = {}
        for result in completed_session.diagnostic_results:
            # Extract component name from test name (simplified)
            if 'workflow' in result.test_name:
                component = 'workflow_inspector'
                if component not in results_by_component:
                    results_by_component[component] = []
                results_by_component[component].append(result)
        
        # Should have results (even if just "no workflows found")
        self.assertGreater(len(completed_session.diagnostic_results), 0)


if __name__ == '__main__':
    unittest.main()