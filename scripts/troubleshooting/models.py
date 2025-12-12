"""
Data models for the GitHub Pages troubleshooting system.

This module defines the core data structures used throughout the diagnostic
and repair system, following the design specifications.
"""

from datetime import datetime
from enum import Enum
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field


class TestStatus(Enum):
    """Status of a diagnostic test or operation."""
    PASS = "pass"
    FAIL = "fail"
    WARNING = "warning"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class Severity(Enum):
    """Severity level for issues and diagnostics."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class RepairCategory(Enum):
    """Category of repair action."""
    CONFIGURATION = "configuration"
    CONTENT = "content"
    WORKFLOW = "workflow"
    BRANCH = "branch"


@dataclass
class DiagnosticResult:
    """
    Result of a diagnostic test or check.
    
    Represents the outcome of any diagnostic operation, including
    test results, validation checks, and system status reports.
    """
    timestamp: datetime
    test_name: str
    status: TestStatus
    message: str
    details: str
    suggested_fix: Optional[str] = None
    severity: Severity = Severity.MEDIUM
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            'timestamp': self.timestamp.isoformat(),
            'test_name': self.test_name,
            'status': self.status.value,
            'message': self.message,
            'details': self.details,
            'suggested_fix': self.suggested_fix,
            'severity': self.severity.value,
            'metadata': self.metadata
        }


@dataclass
class RepositoryStatus:
    """
    Status information about a GitHub repository.
    
    Contains configuration and state information for GitHub Pages
    deployment analysis.
    """
    name: str
    visibility: str  # 'public' or 'private'
    default_branch: str
    pages_enabled: bool
    pages_source: Dict[str, str]  # {'branch': str, 'path': str}
    custom_domain: Optional[str] = None
    https_enforced: bool = False
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            'name': self.name,
            'visibility': self.visibility,
            'default_branch': self.default_branch,
            'pages_enabled': self.pages_enabled,
            'pages_source': self.pages_source,
            'custom_domain': self.custom_domain,
            'https_enforced': self.https_enforced,
            'metadata': self.metadata
        }


@dataclass
class Test:
    """Individual test within a test suite."""
    name: str
    url: str
    expected_status: int
    actual_status: Optional[int] = None
    response_time: Optional[float] = None
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class TestSuite:
    """
    Collection of related tests with execution metadata.
    
    Represents a group of tests that are executed together,
    such as all HTTP status checks or all link validation tests.
    """
    name: str
    description: str
    tests: List[Test] = field(default_factory=list)
    execution_time: float = 0.0
    pass_rate: float = 0.0
    status: TestStatus = TestStatus.RUNNING
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def calculate_pass_rate(self) -> float:
        """Calculate the percentage of tests that passed."""
        if not self.tests:
            return 0.0
        
        passed = sum(1 for test in self.tests 
                    if test.actual_status == test.expected_status)
        return (passed / len(self.tests)) * 100.0
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            'name': self.name,
            'description': self.description,
            'tests': [test.__dict__ for test in self.tests],
            'execution_time': self.execution_time,
            'pass_rate': self.pass_rate,
            'status': self.status.value,
            'metadata': self.metadata
        }


@dataclass
class RepairAction:
    """
    Represents an automated or manual repair action.
    
    Contains information about how to fix a detected issue,
    including commands to run and instructions to follow.
    """
    id: str
    name: str
    description: str
    category: RepairCategory
    severity: Severity
    automated: bool
    command: Optional[str] = None
    instructions: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'category': self.category.value,
            'severity': self.severity.value,
            'automated': self.automated,
            'command': self.command,
            'instructions': self.instructions,
            'metadata': self.metadata
        }


@dataclass
class DiagnosticSession:
    """
    Complete diagnostic session with all results and metadata.
    
    Represents a full troubleshooting session, including all
    tests run, issues found, and repair actions suggested.
    """
    session_id: str
    start_time: datetime
    end_time: Optional[datetime] = None
    repository_status: Optional[RepositoryStatus] = None
    diagnostic_results: List[DiagnosticResult] = field(default_factory=list)
    test_suites: List[TestSuite] = field(default_factory=list)
    repair_actions: List[RepairAction] = field(default_factory=list)
    summary: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def add_result(self, result: DiagnosticResult) -> None:
        """Add a diagnostic result to the session."""
        self.diagnostic_results.append(result)
    
    def add_test_suite(self, suite: TestSuite) -> None:
        """Add a test suite to the session."""
        self.test_suites.append(suite)
    
    def add_repair_action(self, action: RepairAction) -> None:
        """Add a repair action to the session."""
        self.repair_actions.append(action)
    
    def get_critical_issues(self) -> List[DiagnosticResult]:
        """Get all critical severity issues."""
        return [r for r in self.diagnostic_results 
                if r.severity == Severity.CRITICAL]
    
    def get_failed_tests(self) -> List[DiagnosticResult]:
        """Get all failed diagnostic tests."""
        return [r for r in self.diagnostic_results 
                if r.status == TestStatus.FAIL]
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            'session_id': self.session_id,
            'start_time': self.start_time.isoformat(),
            'end_time': self.end_time.isoformat() if self.end_time else None,
            'repository_status': self.repository_status.to_dict() if self.repository_status else None,
            'diagnostic_results': [r.to_dict() for r in self.diagnostic_results],
            'test_suites': [s.to_dict() for s in self.test_suites],
            'repair_actions': [a.to_dict() for a in self.repair_actions],
            'summary': self.summary,
            'metadata': self.metadata
        }