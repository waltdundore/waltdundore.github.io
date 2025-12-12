"""
Main diagnostic orchestrator for the GitHub Pages troubleshooting system.

This module coordinates the execution of all diagnostic components
and manages the overall troubleshooting workflow.
"""

import uuid
import logging
from datetime import datetime
from typing import List, Dict, Any, Optional
from models import DiagnosticSession, DiagnosticResult, RepositoryStatus, TestStatus, Severity
from base import DiagnosticComponent
from config import TroubleshootingConfig


class DiagnosticOrchestrator:
    """
    Main orchestrator for coordinating diagnostic components.
    
    Manages the execution of diagnostic, validation, testing, and repair
    components in the correct order and aggregates results.
    """
    
    def __init__(self, config: TroubleshootingConfig):
        """
        Initialize the diagnostic orchestrator.
        
        Args:
            config: Configuration manager instance
        """
        self.config = config
        self.logger = logging.getLogger('troubleshooting.orchestrator')
        self.components: List[DiagnosticComponent] = []
        self.current_session: Optional[DiagnosticSession] = None
    
    def register_component(self, component: DiagnosticComponent) -> None:
        """
        Register a diagnostic component with the orchestrator.
        
        Args:
            component: Diagnostic component to register
        """
        self.components.append(component)
        self.logger.info(f"Registered component: {component.name}")
    
    def start_session(self, repository_path: str = ".") -> DiagnosticSession:
        """
        Start a new diagnostic session.
        
        Args:
            repository_path: Path to the repository to diagnose
            
        Returns:
            New DiagnosticSession instance
        """
        session_id = str(uuid.uuid4())
        self.current_session = DiagnosticSession(
            session_id=session_id,
            start_time=datetime.now(),
            metadata={'repository_path': repository_path}
        )
        
        self.logger.info(f"Started diagnostic session: {session_id}")
        return self.current_session
    
    def run_diagnostics(self, **kwargs) -> DiagnosticSession:
        """
        Run all registered diagnostic components.
        
        Args:
            **kwargs: Configuration parameters for components
            
        Returns:
            Completed DiagnosticSession with all results
        """
        if not self.current_session:
            raise RuntimeError("No active session. Call start_session() first.")
        
        self.logger.info(f"Running diagnostics with {len(self.components)} components")
        
        for component in self.components:
            try:
                self.logger.info(f"Executing component: {component.name}")
                results = component.execute(**kwargs)
                
                # Add results to session
                for result in results:
                    self.current_session.add_result(result)
                
                self.logger.info(f"Component {component.name} completed with {len(results)} results")
                
            except Exception as e:
                self.logger.error(f"Component {component.name} failed: {str(e)}")
                
                # Create error result for failed component
                error_result = DiagnosticResult(
                    timestamp=datetime.now(),
                    test_name=f"{component.name}_execution",
                    status=TestStatus.FAIL,
                    message=f"Component execution failed: {str(e)}",
                    details=f"Exception in {component.name}",
                    severity=Severity.HIGH
                )
                self.current_session.add_result(error_result)
        
        # Complete the session
        self.current_session.end_time = datetime.now()
        self.logger.info(f"Diagnostics completed. Session: {self.current_session.session_id}")
        
        return self.current_session
    
    def get_session_summary(self) -> Dict[str, Any]:
        """
        Get a summary of the current diagnostic session.
        
        Returns:
            Dictionary containing session summary information
        """
        if not self.current_session:
            return {"status": "no_active_session"}
        
        total_results = len(self.current_session.diagnostic_results)
        critical_issues = len(self.current_session.get_critical_issues())
        failed_tests = len(self.current_session.get_failed_tests())
        
        return {
            "session_id": self.current_session.session_id,
            "start_time": self.current_session.start_time.isoformat(),
            "end_time": self.current_session.end_time.isoformat() if self.current_session.end_time else None,
            "total_results": total_results,
            "critical_issues": critical_issues,
            "failed_tests": failed_tests,
            "components_executed": len(self.components),
            "status": "completed" if self.current_session.end_time else "running"
        }