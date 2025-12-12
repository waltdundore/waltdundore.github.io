"""
Base classes for the GitHub Pages troubleshooting system.

This module provides abstract base classes and common functionality
for all diagnostic, validation, testing, and repair components.
"""

import logging
import time
from abc import ABC, abstractmethod
from datetime import datetime
from typing import List, Dict, Any, Optional
from models import DiagnosticResult, TestStatus, Severity, DiagnosticSession


class DiagnosticComponent(ABC):
    """
    Abstract base class for all diagnostic components.
    
    Provides common functionality for logging, error handling,
    and result reporting that all diagnostic components should use.
    """
    
    def __init__(self, name: str, logger: Optional[logging.Logger] = None):
        """
        Initialize the diagnostic component.
        
        Args:
            name: Human-readable name for this component
            logger: Optional logger instance (will create one if not provided)
        """
        self.name = name
        self.logger = logger or logging.getLogger(f"troubleshooting.{name}")
        self.results: List[DiagnosticResult] = []
        self.start_time: Optional[datetime] = None
        self.end_time: Optional[datetime] = None
    
    @abstractmethod
    def run_diagnostics(self, **kwargs) -> List[DiagnosticResult]:
        """
        Run the diagnostic checks for this component.
        
        This method must be implemented by all diagnostic components.
        It should perform the actual diagnostic work and return results.
        
        Args:
            **kwargs: Component-specific configuration parameters
            
        Returns:
            List of DiagnosticResult objects representing the outcomes
        """
        pass
    
    def _create_result(
        self,
        test_name: str,
        status: TestStatus,
        message: str,
        details: str = "",
        suggested_fix: Optional[str] = None,
        severity: Severity = Severity.MEDIUM,
        **metadata
    ) -> DiagnosticResult:
        """
        Create a standardized diagnostic result.
        
        Args:
            test_name: Name of the test or check performed
            status: Pass/fail/warning status
            message: Brief description of the result
            details: Detailed information about the result
            suggested_fix: Optional suggestion for fixing issues
            severity: Severity level of any issues found
            **metadata: Additional metadata to include
            
        Returns:
            DiagnosticResult object
        """
        result = DiagnosticResult(
            timestamp=datetime.now(),
            test_name=test_name,
            status=status,
            message=message,
            details=details,
            suggested_fix=suggested_fix,
            severity=severity,
            metadata=metadata
        )
        
        # Log the result
        log_level = {
            TestStatus.PASS: logging.INFO,
            TestStatus.FAIL: logging.ERROR,
            TestStatus.WARNING: logging.WARNING
        }.get(status, logging.INFO)
        
        self.logger.log(log_level, f"{test_name}: {message}")
        
        return result
    
    def _safe_execute(self, operation_name: str, operation_func, *args, **kwargs) -> Any:
        """
        Safely execute an operation with error handling and logging.
        
        Args:
            operation_name: Human-readable name for the operation
            operation_func: Function to execute
            *args: Arguments to pass to the function
            **kwargs: Keyword arguments to pass to the function
            
        Returns:
            Result of the operation, or None if it failed
        """
        try:
            self.logger.debug(f"Starting {operation_name}")
            start_time = time.time()
            
            result = operation_func(*args, **kwargs)
            
            execution_time = time.time() - start_time
            self.logger.debug(f"Completed {operation_name} in {execution_time:.2f}s")
            
            return result
            
        except Exception as e:
            self.logger.error(f"Failed to execute {operation_name}: {str(e)}")
            return None
    
    def execute(self, **kwargs) -> List[DiagnosticResult]:
        """
        Execute the diagnostic component with timing and error handling.
        
        This is the main entry point for running diagnostics. It handles
        timing, logging, and error recovery around the actual diagnostic work.
        
        Args:
            **kwargs: Component-specific configuration parameters
            
        Returns:
            List of DiagnosticResult objects
        """
        self.start_time = datetime.now()
        self.results = []
        
        self.logger.info(f"Starting diagnostic component: {self.name}")
        
        try:
            self.results = self.run_diagnostics(**kwargs)
            self.logger.info(f"Completed {self.name}: {len(self.results)} results")
            
        except Exception as e:
            self.logger.error(f"Diagnostic component {self.name} failed: {str(e)}")
            
            # Create an error result
            error_result = self._create_result(
                test_name=f"{self.name}_execution",
                status=TestStatus.FAIL,
                message=f"Component execution failed: {str(e)}",
                details=f"Exception occurred while running {self.name}",
                severity=Severity.HIGH,
                exception_type=type(e).__name__
            )
            self.results = [error_result]
        
        finally:
            self.end_time = datetime.now()
            execution_time = (self.end_time - self.start_time).total_seconds()
            self.logger.info(f"Component {self.name} completed in {execution_time:.2f}s")
        
        return self.results
    
    def get_summary(self) -> Dict[str, Any]:
        """
        Get a summary of this component's execution.
        
        Returns:
            Dictionary containing execution summary information
        """
        if not self.start_time:
            return {"status": "not_executed"}
        
        execution_time = None
        if self.end_time:
            execution_time = (self.end_time - self.start_time).total_seconds()
        
        pass_count = sum(1 for r in self.results if r.status == TestStatus.PASS)
        fail_count = sum(1 for r in self.results if r.status == TestStatus.FAIL)
        warning_count = sum(1 for r in self.results if r.status == TestStatus.WARNING)
        
        return {
            "component_name": self.name,
            "start_time": self.start_time.isoformat(),
            "end_time": self.end_time.isoformat() if self.end_time else None,
            "execution_time": execution_time,
            "total_results": len(self.results),
            "pass_count": pass_count,
            "fail_count": fail_count,
            "warning_count": warning_count,
            "status": "completed" if self.end_time else "running"
        }


class ValidationComponent(DiagnosticComponent):
    """
    Base class for content validation components.
    
    Extends DiagnosticComponent with validation-specific functionality
    for checking HTML, links, resources, and accessibility.
    """
    
    def __init__(self, name: str, logger: Optional[logging.Logger] = None):
        super().__init__(name, logger)
        self.validation_rules: Dict[str, Any] = {}
    
    def add_validation_rule(self, rule_name: str, rule_config: Dict[str, Any]) -> None:
        """
        Add a validation rule to this component.
        
        Args:
            rule_name: Name of the validation rule
            rule_config: Configuration for the rule
        """
        self.validation_rules[rule_name] = rule_config
        self.logger.debug(f"Added validation rule: {rule_name}")
    
    def _validate_against_rules(self, content: Any, content_type: str) -> List[DiagnosticResult]:
        """
        Validate content against configured rules.
        
        Args:
            content: Content to validate
            content_type: Type of content being validated
            
        Returns:
            List of validation results
        """
        results = []
        
        for rule_name, rule_config in self.validation_rules.items():
            if rule_config.get('content_type') == content_type:
                # This is a placeholder for rule execution
                # Specific validation components will implement actual rule logic
                result = self._create_result(
                    test_name=f"{content_type}_validation_{rule_name}",
                    status=TestStatus.PASS,
                    message=f"Validation rule {rule_name} passed",
                    details=f"Content validated against {rule_name} rule"
                )
                results.append(result)
        
        return results


class TestingComponent(DiagnosticComponent):
    """
    Base class for testing components.
    
    Extends DiagnosticComponent with testing-specific functionality
    for HTTP testing, performance monitoring, and integration testing.
    """
    
    def __init__(self, name: str, logger: Optional[logging.Logger] = None):
        super().__init__(name, logger)
        self.test_config: Dict[str, Any] = {
            'timeout': 30,
            'retries': 3,
            'retry_delay': 1.0
        }
    
    def configure_testing(self, **config) -> None:
        """
        Configure testing parameters.
        
        Args:
            **config: Testing configuration parameters
        """
        self.test_config.update(config)
        self.logger.debug(f"Updated test configuration: {config}")
    
    def _execute_with_retry(self, operation_func, *args, **kwargs) -> Any:
        """
        Execute an operation with retry logic.
        
        Args:
            operation_func: Function to execute
            *args: Arguments to pass to the function
            **kwargs: Keyword arguments to pass to the function
            
        Returns:
            Result of the operation
            
        Raises:
            Exception: If all retry attempts fail
        """
        retries = self.test_config.get('retries', 3)
        retry_delay = self.test_config.get('retry_delay', 1.0)
        
        last_exception = None
        
        for attempt in range(retries + 1):
            try:
                return operation_func(*args, **kwargs)
            except Exception as e:
                last_exception = e
                if attempt < retries:
                    self.logger.warning(f"Attempt {attempt + 1} failed: {str(e)}, retrying in {retry_delay}s")
                    time.sleep(retry_delay)
                else:
                    self.logger.error(f"All {retries + 1} attempts failed")
        
        raise last_exception


class RepairComponent(DiagnosticComponent):
    """
    Base class for repair components.
    
    Extends DiagnosticComponent with repair-specific functionality
    for fixing configuration, content, workflow, and branch issues.
    """
    
    def __init__(self, name: str, logger: Optional[logging.Logger] = None):
        super().__init__(name, logger)
        self.dry_run = True  # Default to dry run for safety
        self.backup_enabled = True
    
    def configure_repair(self, dry_run: bool = True, backup_enabled: bool = True) -> None:
        """
        Configure repair behavior.
        
        Args:
            dry_run: If True, only simulate repairs without making changes
            backup_enabled: If True, create backups before making changes
        """
        self.dry_run = dry_run
        self.backup_enabled = backup_enabled
        self.logger.info(f"Repair configuration: dry_run={dry_run}, backup_enabled={backup_enabled}")
    
    def _create_backup(self, file_path: str) -> Optional[str]:
        """
        Create a backup of a file before modifying it.
        
        Args:
            file_path: Path to the file to backup
            
        Returns:
            Path to the backup file, or None if backup failed
        """
        if not self.backup_enabled:
            return None
        
        # This is a placeholder for backup logic
        # Specific repair components will implement actual backup functionality
        backup_path = f"{file_path}.backup.{int(time.time())}"
        self.logger.info(f"Would create backup: {file_path} -> {backup_path}")
        return backup_path
    
    def _apply_repair(self, repair_operation: str, **kwargs) -> DiagnosticResult:
        """
        Apply a repair operation.
        
        Args:
            repair_operation: Description of the repair operation
            **kwargs: Operation-specific parameters
            
        Returns:
            DiagnosticResult indicating success or failure
        """
        if self.dry_run:
            return self._create_result(
                test_name=f"repair_{repair_operation}",
                status=TestStatus.PASS,
                message=f"Dry run: Would perform {repair_operation}",
                details="Repair operation simulated (dry run mode)",
                severity=Severity.LOW
            )
        else:
            # This is a placeholder for actual repair logic
            # Specific repair components will implement actual repair functionality
            return self._create_result(
                test_name=f"repair_{repair_operation}",
                status=TestStatus.PASS,
                message=f"Successfully performed {repair_operation}",
                details="Repair operation completed",
                severity=Severity.LOW
            )