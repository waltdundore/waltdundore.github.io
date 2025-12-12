"""
GitHub Actions Workflow Inspector for GitHub Pages troubleshooting.

This module provides the WorkflowInspector class that analyzes GitHub Actions
workflow files to validate configuration, permissions, triggers, and steps
for GitHub Pages deployment.
"""

import os
import yaml
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional, Set
from datetime import datetime

# Import from parent directory
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from base import DiagnosticComponent
from models import DiagnosticResult, TestStatus, Severity


class WorkflowInspector(DiagnosticComponent):
    """
    Analyzes GitHub Actions workflow files for GitHub Pages deployment issues.
    
    This component examines .github/workflows/ files to validate:
    - Required permissions (contents: read, pages: write, id-token: write)
    - Workflow triggers (main and prod branch pushes)
    - Step configuration and action versions
    - Deployment artifact handling
    """
    
    # Required permissions for GitHub Pages deployment
    REQUIRED_PERMISSIONS = {
        'contents': 'read',
        'pages': 'write',
        'id-token': 'write'
    }
    
    # Expected workflow triggers for GitHub Pages
    EXPECTED_TRIGGERS = ['push', 'workflow_dispatch']
    
    # Common GitHub Actions for Pages deployment
    PAGES_ACTIONS = {
        'actions/checkout': {'min_version': 'v3', 'current': 'v4'},
        'actions/configure-pages': {'min_version': 'v3', 'current': 'v4'},
        'actions/upload-pages-artifact': {'min_version': 'v2', 'current': 'v3'},
        'actions/deploy-pages': {'min_version': 'v2', 'current': 'v4'}
    }
    
    def __init__(self, repository_path: str, logger: Optional[logging.Logger] = None):
        """
        Initialize the WorkflowInspector.
        
        Args:
            repository_path: Path to the repository root
            logger: Optional logger instance
        """
        super().__init__("WorkflowInspector", logger)
        self.repository_path = Path(repository_path)
        self.workflows_path = self.repository_path / '.github' / 'workflows'
        self.workflow_files: List[Path] = []
        self.parsed_workflows: Dict[str, Dict[str, Any]] = {}
    
    def run_diagnostics(self, **kwargs) -> List[DiagnosticResult]:
        """
        Run comprehensive workflow analysis.
        
        Returns:
            List of DiagnosticResult objects with workflow validation results
        """
        results = []
        
        # Check if workflows directory exists
        results.extend(self._check_workflows_directory())
        
        if not self.workflows_path.exists():
            return results
        
        # Discover workflow files
        results.extend(self._discover_workflow_files())
        
        # Parse workflow files
        results.extend(self._parse_workflow_files())
        
        # Validate workflow configurations
        for workflow_file, workflow_config in self.parsed_workflows.items():
            results.extend(self._validate_workflow_permissions(workflow_file, workflow_config))
            results.extend(self._validate_workflow_triggers(workflow_file, workflow_config))
            results.extend(self._validate_workflow_steps(workflow_file, workflow_config))
            results.extend(self._validate_pages_deployment(workflow_file, workflow_config))
        
        # Overall workflow assessment
        results.extend(self._assess_overall_configuration())
        
        return results
    
    def _check_workflows_directory(self) -> List[DiagnosticResult]:
        """Check if .github/workflows directory exists."""
        results = []
        
        if not self.workflows_path.exists():
            result = self._create_result(
                test_name="workflows_directory_exists",
                status=TestStatus.FAIL,
                message="GitHub Actions workflows directory not found",
                details=f"Expected directory: {self.workflows_path}",
                suggested_fix="Create .github/workflows directory and add GitHub Pages deployment workflow",
                severity=Severity.HIGH,
                path=str(self.workflows_path)
            )
        else:
            result = self._create_result(
                test_name="workflows_directory_exists",
                status=TestStatus.PASS,
                message="GitHub Actions workflows directory found",
                details=f"Directory exists: {self.workflows_path}",
                severity=Severity.LOW,
                path=str(self.workflows_path)
            )
        
        results.append(result)
        return results
    
    def _discover_workflow_files(self) -> List[DiagnosticResult]:
        """Discover and catalog workflow files."""
        results = []
        
        try:
            # Find all YAML workflow files
            yaml_patterns = ['*.yml', '*.yaml']
            for pattern in yaml_patterns:
                self.workflow_files.extend(self.workflows_path.glob(pattern))
            
            if not self.workflow_files:
                result = self._create_result(
                    test_name="workflow_files_found",
                    status=TestStatus.FAIL,
                    message="No workflow files found",
                    details=f"No .yml or .yaml files in {self.workflows_path}",
                    suggested_fix="Create a GitHub Pages deployment workflow file",
                    severity=Severity.HIGH,
                    file_count=0
                )
            else:
                result = self._create_result(
                    test_name="workflow_files_found",
                    status=TestStatus.PASS,
                    message=f"Found {len(self.workflow_files)} workflow file(s)",
                    details=f"Workflow files: {[f.name for f in self.workflow_files]}",
                    severity=Severity.LOW,
                    file_count=len(self.workflow_files),
                    files=[str(f) for f in self.workflow_files]
                )
            
            results.append(result)
            
        except Exception as e:
            result = self._create_result(
                test_name="workflow_files_discovery",
                status=TestStatus.FAIL,
                message=f"Failed to discover workflow files: {str(e)}",
                details=f"Error scanning {self.workflows_path}",
                severity=Severity.MEDIUM,
                error=str(e)
            )
            results.append(result)
        
        return results
    
    def _parse_workflow_files(self) -> List[DiagnosticResult]:
        """Parse YAML workflow files."""
        results = []
        
        for workflow_file in self.workflow_files:
            try:
                with open(workflow_file, 'r', encoding='utf-8') as f:
                    workflow_content = yaml.safe_load(f)
                
                if workflow_content is None:
                    result = self._create_result(
                        test_name=f"parse_workflow_{workflow_file.name}",
                        status=TestStatus.FAIL,
                        message=f"Workflow file {workflow_file.name} is empty or invalid",
                        details="YAML file contains no content",
                        suggested_fix="Add valid workflow configuration to the file",
                        severity=Severity.HIGH,
                        file=str(workflow_file)
                    )
                else:
                    self.parsed_workflows[workflow_file.name] = workflow_content
                    result = self._create_result(
                        test_name=f"parse_workflow_{workflow_file.name}",
                        status=TestStatus.PASS,
                        message=f"Successfully parsed {workflow_file.name}",
                        details=f"Workflow contains {len(workflow_content.get('jobs', {}))} job(s)",
                        severity=Severity.LOW,
                        file=str(workflow_file),
                        job_count=len(workflow_content.get('jobs', {}))
                    )
                
                results.append(result)
                
            except yaml.YAMLError as e:
                result = self._create_result(
                    test_name=f"parse_workflow_{workflow_file.name}",
                    status=TestStatus.FAIL,
                    message=f"YAML parsing error in {workflow_file.name}",
                    details=f"YAML error: {str(e)}",
                    suggested_fix="Fix YAML syntax errors in the workflow file",
                    severity=Severity.HIGH,
                    file=str(workflow_file),
                    error=str(e)
                )
                results.append(result)
                
            except Exception as e:
                result = self._create_result(
                    test_name=f"parse_workflow_{workflow_file.name}",
                    status=TestStatus.FAIL,
                    message=f"Failed to read {workflow_file.name}: {str(e)}",
                    details=f"File access error: {str(e)}",
                    severity=Severity.MEDIUM,
                    file=str(workflow_file),
                    error=str(e)
                )
                results.append(result)
        
        return results
    
    def _validate_workflow_permissions(self, workflow_file: str, workflow_config: Dict[str, Any]) -> List[DiagnosticResult]:
        """Validate workflow permissions for GitHub Pages deployment."""
        results = []
        
        # Check for permissions at workflow level
        workflow_permissions = workflow_config.get('permissions', {})
        
        # Check for permissions at job level
        jobs = workflow_config.get('jobs', {})
        pages_jobs = []
        
        for job_name, job_config in jobs.items():
            job_permissions = job_config.get('permissions', {})
            
            # Look for jobs that might be doing Pages deployment
            steps = job_config.get('steps', [])
            has_pages_actions = any(
                step.get('uses', '').startswith(action) 
                for step in steps 
                for action in self.PAGES_ACTIONS.keys()
            )
            
            if has_pages_actions or 'pages' in job_name.lower() or 'deploy' in job_name.lower():
                pages_jobs.append({
                    'name': job_name,
                    'permissions': job_permissions,
                    'has_pages_actions': has_pages_actions
                })
        
        # Validate permissions
        all_permissions = {**workflow_permissions}
        for job in pages_jobs:
            all_permissions.update(job['permissions'])
        
        missing_permissions = []
        incorrect_permissions = []
        
        for perm_name, required_value in self.REQUIRED_PERMISSIONS.items():
            if perm_name not in all_permissions:
                missing_permissions.append(perm_name)
            elif all_permissions[perm_name] != required_value:
                incorrect_permissions.append({
                    'permission': perm_name,
                    'expected': required_value,
                    'actual': all_permissions[perm_name]
                })
        
        # Create results for permission validation
        if missing_permissions or incorrect_permissions:
            details = []
            if missing_permissions:
                details.append(f"Missing permissions: {', '.join(missing_permissions)}")
            if incorrect_permissions:
                for perm in incorrect_permissions:
                    details.append(f"{perm['permission']}: expected '{perm['expected']}', got '{perm['actual']}'")
            
            result = self._create_result(
                test_name=f"workflow_permissions_{workflow_file}",
                status=TestStatus.FAIL,
                message="Workflow permissions are incomplete or incorrect",
                details="; ".join(details),
                suggested_fix="Add required permissions: contents: read, pages: write, id-token: write",
                severity=Severity.HIGH,
                file=workflow_file,
                missing_permissions=missing_permissions,
                incorrect_permissions=incorrect_permissions
            )
        else:
            result = self._create_result(
                test_name=f"workflow_permissions_{workflow_file}",
                status=TestStatus.PASS,
                message="All required permissions are correctly configured",
                details=f"Found permissions: {', '.join(f'{k}: {v}' for k, v in self.REQUIRED_PERMISSIONS.items())}",
                severity=Severity.LOW,
                file=workflow_file,
                permissions=all_permissions
            )
        
        results.append(result)
        return results
    
    def _validate_workflow_triggers(self, workflow_file: str, workflow_config: Dict[str, Any]) -> List[DiagnosticResult]:
        """Validate workflow triggers for GitHub Pages deployment."""
        results = []
        
        # Handle YAML parsing quirk where 'on' might be parsed as boolean True
        triggers = workflow_config.get('on', {})
        if triggers is None or triggers == {}:
            # Check if 'on' was parsed as boolean True (YAML quirk)
            triggers = workflow_config.get(True, {})
        
        # Handle different trigger formats
        if isinstance(triggers, str):
            triggers = {triggers: {}}
        elif isinstance(triggers, list):
            triggers = {trigger: {} for trigger in triggers}
        
        # Check for push triggers
        has_push_trigger = 'push' in triggers
        push_branches = []
        
        if has_push_trigger:
            push_config = triggers['push']
            if isinstance(push_config, dict):
                push_branches = push_config.get('branches', [])
        
        # Check for workflow_dispatch (manual trigger)
        has_manual_trigger = 'workflow_dispatch' in triggers
        
        # Validate triggers
        issues = []
        
        if not has_push_trigger:
            issues.append("Missing 'push' trigger")
        else:
            # Check if main or prod branches are included
            expected_branches = ['main', 'prod', 'master']
            
            # If push_branches is empty, it means all branches trigger the workflow (which is fine)
            # If push_branches is specified, check if it includes main/prod branches
            if push_branches:
                found_branches = [branch for branch in expected_branches if branch in push_branches]
                if not found_branches:
                    issues.append(f"Push trigger doesn't include main/prod branches. Found: {push_branches}")
            # If push_branches is empty, that's acceptable (triggers on all branches)
        
        if not has_manual_trigger:
            issues.append("Missing 'workflow_dispatch' trigger for manual execution")
        
        # Create result
        if issues:
            result = self._create_result(
                test_name=f"workflow_triggers_{workflow_file}",
                status=TestStatus.FAIL,
                message="Workflow triggers are not properly configured",
                details="; ".join(issues),
                suggested_fix="Add 'push' trigger for main/prod branches and 'workflow_dispatch' for manual execution",
                severity=Severity.HIGH,
                file=workflow_file,
                triggers=list(triggers.keys()),
                issues=issues
            )
        else:
            result = self._create_result(
                test_name=f"workflow_triggers_{workflow_file}",
                status=TestStatus.PASS,
                message="Workflow triggers are properly configured",
                details=f"Found triggers: {', '.join(triggers.keys())}",
                severity=Severity.LOW,
                file=workflow_file,
                triggers=list(triggers.keys())
            )
        
        results.append(result)
        return results
    
    def _validate_workflow_steps(self, workflow_file: str, workflow_config: Dict[str, Any]) -> List[DiagnosticResult]:
        """Validate workflow steps and action versions."""
        results = []
        
        jobs = workflow_config.get('jobs', {})
        
        for job_name, job_config in jobs.items():
            steps = job_config.get('steps', [])
            
            # Check for outdated actions
            outdated_actions = []
            missing_actions = []
            
            used_actions = {}
            for step in steps:
                uses = step.get('uses', '')
                if uses:
                    # Extract action name and version
                    if '@' in uses:
                        action_name, version = uses.rsplit('@', 1)
                        used_actions[action_name] = version
            
            # Check against known Pages actions
            for action_name, version_info in self.PAGES_ACTIONS.items():
                if action_name in used_actions:
                    used_version = used_actions[action_name]
                    current_version = version_info['current']
                    min_version = version_info['min_version']
                    
                    # Simple version comparison (assumes vX format)
                    if used_version < min_version:
                        outdated_actions.append({
                            'action': action_name,
                            'used': used_version,
                            'minimum': min_version,
                            'current': current_version
                        })
            
            # Check for essential Pages actions
            essential_actions = ['actions/checkout', 'actions/deploy-pages']
            for essential in essential_actions:
                if essential not in used_actions:
                    missing_actions.append(essential)
            
            # Create results for this job
            if outdated_actions or missing_actions:
                issues = []
                if outdated_actions:
                    for action in outdated_actions:
                        issues.append(f"{action['action']}@{action['used']} (should be >= {action['minimum']})")
                if missing_actions:
                    issues.append(f"Missing essential actions: {', '.join(missing_actions)}")
                
                result = self._create_result(
                    test_name=f"workflow_steps_{workflow_file}_{job_name}",
                    status=TestStatus.WARNING if outdated_actions and not missing_actions else TestStatus.FAIL,
                    message=f"Job '{job_name}' has action version or configuration issues",
                    details="; ".join(issues),
                    suggested_fix="Update action versions to current releases and add missing essential actions",
                    severity=Severity.MEDIUM if outdated_actions and not missing_actions else Severity.HIGH,
                    file=workflow_file,
                    job=job_name,
                    outdated_actions=outdated_actions,
                    missing_actions=missing_actions
                )
            else:
                result = self._create_result(
                    test_name=f"workflow_steps_{workflow_file}_{job_name}",
                    status=TestStatus.PASS,
                    message=f"Job '{job_name}' uses current action versions",
                    details=f"Actions: {', '.join(f'{k}@{v}' for k, v in used_actions.items())}",
                    severity=Severity.LOW,
                    file=workflow_file,
                    job=job_name,
                    actions=used_actions
                )
            
            results.append(result)
        
        return results
    
    def _validate_pages_deployment(self, workflow_file: str, workflow_config: Dict[str, Any]) -> List[DiagnosticResult]:
        """Validate GitHub Pages specific deployment configuration."""
        results = []
        
        jobs = workflow_config.get('jobs', {})
        
        # Look for Pages deployment patterns
        has_pages_deployment = False
        deployment_issues = []
        
        for job_name, job_config in jobs.items():
            steps = job_config.get('steps', [])
            
            # Check for Pages deployment steps
            has_configure_pages = False
            has_upload_artifact = False
            has_deploy_pages = False
            
            for step in steps:
                uses = step.get('uses', '')
                if 'configure-pages' in uses:
                    has_configure_pages = True
                elif 'upload-pages-artifact' in uses:
                    has_upload_artifact = True
                elif 'deploy-pages' in uses:
                    has_deploy_pages = True
            
            if has_configure_pages or has_upload_artifact or has_deploy_pages:
                has_pages_deployment = True
                
                # Check for complete deployment workflow
                if has_configure_pages and has_upload_artifact and has_deploy_pages:
                    # Complete workflow found
                    pass
                else:
                    missing_steps = []
                    if not has_configure_pages:
                        missing_steps.append('configure-pages')
                    if not has_upload_artifact:
                        missing_steps.append('upload-pages-artifact')
                    if not has_deploy_pages:
                        missing_steps.append('deploy-pages')
                    
                    if missing_steps:
                        deployment_issues.append(f"Job '{job_name}' missing steps: {', '.join(missing_steps)}")
        
        # Create result for Pages deployment validation
        if not has_pages_deployment:
            result = self._create_result(
                test_name=f"pages_deployment_{workflow_file}",
                status=TestStatus.FAIL,
                message="No GitHub Pages deployment found in workflow",
                details="Workflow doesn't contain Pages deployment actions",
                suggested_fix="Add GitHub Pages deployment steps (configure-pages, upload-pages-artifact, deploy-pages)",
                severity=Severity.CRITICAL,
                file=workflow_file
            )
        elif deployment_issues:
            result = self._create_result(
                test_name=f"pages_deployment_{workflow_file}",
                status=TestStatus.FAIL,
                message="Incomplete GitHub Pages deployment configuration",
                details="; ".join(deployment_issues),
                suggested_fix="Complete the Pages deployment workflow with all required steps",
                severity=Severity.HIGH,
                file=workflow_file,
                issues=deployment_issues
            )
        else:
            result = self._create_result(
                test_name=f"pages_deployment_{workflow_file}",
                status=TestStatus.PASS,
                message="Complete GitHub Pages deployment workflow found",
                details="Workflow contains all required Pages deployment steps",
                severity=Severity.LOW,
                file=workflow_file
            )
        
        results.append(result)
        return results
    
    def _assess_overall_configuration(self) -> List[DiagnosticResult]:
        """Assess the overall workflow configuration."""
        results = []
        
        if not self.parsed_workflows:
            result = self._create_result(
                test_name="overall_workflow_assessment",
                status=TestStatus.FAIL,
                message="No valid workflow configurations found",
                details="Repository has no working GitHub Actions workflows",
                suggested_fix="Create a GitHub Pages deployment workflow",
                severity=Severity.CRITICAL
            )
        else:
            # Count workflows with Pages deployment
            pages_workflows = 0
            for workflow_file, workflow_config in self.parsed_workflows.items():
                jobs = workflow_config.get('jobs', {})
                for job_config in jobs.values():
                    steps = job_config.get('steps', [])
                    if any('deploy-pages' in step.get('uses', '') for step in steps):
                        pages_workflows += 1
                        break
            
            if pages_workflows == 0:
                result = self._create_result(
                    test_name="overall_workflow_assessment",
                    status=TestStatus.FAIL,
                    message="No GitHub Pages deployment workflows found",
                    details=f"Found {len(self.parsed_workflows)} workflow(s) but none deploy to Pages",
                    suggested_fix="Add GitHub Pages deployment to an existing workflow or create a new one",
                    severity=Severity.HIGH,
                    workflow_count=len(self.parsed_workflows),
                    pages_workflows=pages_workflows
                )
            else:
                result = self._create_result(
                    test_name="overall_workflow_assessment",
                    status=TestStatus.PASS,
                    message=f"Found {pages_workflows} GitHub Pages deployment workflow(s)",
                    details=f"Total workflows: {len(self.parsed_workflows)}, Pages workflows: {pages_workflows}",
                    severity=Severity.LOW,
                    workflow_count=len(self.parsed_workflows),
                    pages_workflows=pages_workflows
                )
        
        results.append(result)
        return results
    
    def get_workflow_summary(self) -> Dict[str, Any]:
        """
        Get a summary of workflow analysis results.
        
        Returns:
            Dictionary containing workflow analysis summary
        """
        summary = {
            'workflows_found': len(self.workflow_files),
            'workflows_parsed': len(self.parsed_workflows),
            'workflow_files': [f.name for f in self.workflow_files],
            'parsed_workflows': list(self.parsed_workflows.keys())
        }
        
        # Analyze permissions across all workflows
        all_permissions = set()
        for workflow_config in self.parsed_workflows.values():
            workflow_permissions = workflow_config.get('permissions', {})
            all_permissions.update(workflow_permissions.keys())
            
            jobs = workflow_config.get('jobs', {})
            for job_config in jobs.values():
                job_permissions = job_config.get('permissions', {})
                all_permissions.update(job_permissions.keys())
        
        summary['permissions_found'] = list(all_permissions)
        summary['has_required_permissions'] = all(
            perm in all_permissions for perm in self.REQUIRED_PERMISSIONS.keys()
        )
        
        return summary