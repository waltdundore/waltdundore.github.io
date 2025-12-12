"""
Configuration management for the GitHub Pages troubleshooting system.

This module handles loading, validating, and managing configuration
for all diagnostic and repair components.
"""

import os
import yaml
import logging
from typing import Dict, Any, Optional
from pathlib import Path


class TroubleshootingConfig:
    """
    Configuration manager for the troubleshooting system.
    
    Handles loading configuration from files, environment variables,
    and providing default values for all system components.
    """
    
    DEFAULT_CONFIG = {
        'logging': {
            'level': 'INFO',
            'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            'file': None,  # None means log to console only
            'max_file_size': 10485760,  # 10MB
            'backup_count': 5
        },
        'github': {
            'api_base_url': 'https://api.github.com',
            'pages_base_url': 'https://pages.github.com',
            'timeout': 30,
            'retries': 3,
            'retry_delay': 1.0
        },
        'testing': {
            'http_timeout': 30,
            'http_retries': 3,
            'http_retry_delay': 1.0,
            'user_agent': 'GitHub-Pages-Troubleshooter/1.0',
            'max_concurrent_requests': 10
        },
        'validation': {
            'html_validator_url': 'https://validator.w3.org/nu/',
            'check_external_links': True,
            'external_link_timeout': 10,
            'max_link_check_depth': 3
        },
        'repair': {
            'dry_run': True,
            'backup_enabled': True,
            'backup_directory': './backups',
            'max_backup_age_days': 30
        },
        'reporting': {
            'output_directory': './reports',
            'report_format': 'json',  # json, yaml, html
            'include_metadata': True,
            'compress_reports': False
        },
        'repository': {
            'default_branch': 'main',
            'pages_branch': 'gh-pages',
            'clone_timeout': 300,
            'max_file_size_mb': 100
        }
    }
    
    def __init__(self, config_file: Optional[str] = None):
        """
        Initialize configuration manager.
        
        Args:
            config_file: Optional path to configuration file
        """
        self.config = self.DEFAULT_CONFIG.copy()
        self.config_file = config_file
        self.logger = logging.getLogger('troubleshooting.config')
        
        # Load configuration from file if provided
        if config_file and os.path.exists(config_file):
            self.load_from_file(config_file)
        
        # Override with environment variables
        self.load_from_environment()
        
        # Validate configuration
        self.validate_config()
    
    def load_from_file(self, config_file: str) -> None:
        """
        Load configuration from a YAML file.
        
        Args:
            config_file: Path to the configuration file
        """
        try:
            with open(config_file, 'r') as f:
                file_config = yaml.safe_load(f)
            
            if file_config:
                self._deep_update(self.config, file_config)
                self.logger.info(f"Loaded configuration from {config_file}")
        
        except Exception as e:
            self.logger.error(f"Failed to load configuration from {config_file}: {str(e)}")
            raise
    
    def load_from_environment(self) -> None:
        """
        Load configuration from environment variables.
        
        Environment variables should be prefixed with 'GHPAGES_TROUBLESHOOT_'
        and use double underscores to separate nested keys.
        
        Example: GHPAGES_TROUBLESHOOT_LOGGING__LEVEL=DEBUG
        """
        prefix = 'GHPAGES_TROUBLESHOOT_'
        
        for key, value in os.environ.items():
            if key.startswith(prefix):
                # Remove prefix and convert to lowercase
                config_key = key[len(prefix):].lower()
                
                # Split on double underscores for nested keys
                key_parts = config_key.split('__')
                
                # Navigate to the correct nested dictionary
                current_dict = self.config
                for part in key_parts[:-1]:
                    if part not in current_dict:
                        current_dict[part] = {}
                    current_dict = current_dict[part]
                
                # Set the value, attempting to convert to appropriate type
                final_key = key_parts[-1]
                current_dict[final_key] = self._convert_env_value(value)
                
                self.logger.debug(f"Set config from environment: {config_key} = {value}")
    
    def _convert_env_value(self, value: str) -> Any:
        """
        Convert environment variable string to appropriate Python type.
        
        Args:
            value: String value from environment variable
            
        Returns:
            Converted value (bool, int, float, or string)
        """
        # Boolean values
        if value.lower() in ('true', 'yes', '1', 'on'):
            return True
        elif value.lower() in ('false', 'no', '0', 'off'):
            return False
        
        # Numeric values
        try:
            if '.' in value:
                return float(value)
            else:
                return int(value)
        except ValueError:
            pass
        
        # Return as string
        return value
    
    def _deep_update(self, base_dict: Dict[str, Any], update_dict: Dict[str, Any]) -> None:
        """
        Recursively update a nested dictionary.
        
        Args:
            base_dict: Dictionary to update
            update_dict: Dictionary with updates
        """
        for key, value in update_dict.items():
            if key in base_dict and isinstance(base_dict[key], dict) and isinstance(value, dict):
                self._deep_update(base_dict[key], value)
            else:
                base_dict[key] = value
    
    def validate_config(self) -> None:
        """
        Validate the loaded configuration.
        
        Raises:
            ValueError: If configuration is invalid
        """
        # Validate logging level
        valid_log_levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']
        log_level = self.config['logging']['level'].upper()
        if log_level not in valid_log_levels:
            raise ValueError(f"Invalid logging level: {log_level}")
        
        # Validate timeout values
        github_timeout = self.config['github'].get('timeout', 0)
        if github_timeout <= 0:
            raise ValueError(f"Invalid timeout in github: {github_timeout}")
        
        testing_timeout = self.config['testing'].get('http_timeout', 0)
        if testing_timeout <= 0:
            raise ValueError(f"Invalid http_timeout in testing: {testing_timeout}")
        
        # Validate retry values
        github_retries = self.config['github'].get('retries', 0)
        if github_retries < 0:
            raise ValueError(f"Invalid retries in github: {github_retries}")
        
        testing_retries = self.config['testing'].get('http_retries', 0)
        if testing_retries < 0:
            raise ValueError(f"Invalid http_retries in testing: {testing_retries}")
        
        # Validate report format
        valid_formats = ['json', 'yaml', 'html']
        report_format = self.config['reporting']['report_format']
        if report_format not in valid_formats:
            raise ValueError(f"Invalid report format: {report_format}")
        
        self.logger.info("Configuration validation passed")
    
    def get(self, key_path: str, default: Any = None) -> Any:
        """
        Get a configuration value using dot notation.
        
        Args:
            key_path: Dot-separated path to the configuration key
            default: Default value if key is not found
            
        Returns:
            Configuration value or default
        """
        keys = key_path.split('.')
        current = self.config
        
        try:
            for key in keys:
                current = current[key]
            return current
        except (KeyError, TypeError):
            return default
    
    def set(self, key_path: str, value: Any) -> None:
        """
        Set a configuration value using dot notation.
        
        Args:
            key_path: Dot-separated path to the configuration key
            value: Value to set
        """
        keys = key_path.split('.')
        current = self.config
        
        # Navigate to the parent dictionary
        for key in keys[:-1]:
            if key not in current:
                current[key] = {}
            current = current[key]
        
        # Set the final value
        current[keys[-1]] = value
        self.logger.debug(f"Set config value: {key_path} = {value}")
    
    def get_section(self, section: str) -> Dict[str, Any]:
        """
        Get an entire configuration section.
        
        Args:
            section: Name of the configuration section
            
        Returns:
            Dictionary containing the section configuration
        """
        return self.config.get(section, {}).copy()
    
    def save_to_file(self, config_file: str) -> None:
        """
        Save current configuration to a YAML file.
        
        Args:
            config_file: Path to save the configuration file
        """
        try:
            # Ensure directory exists
            Path(config_file).parent.mkdir(parents=True, exist_ok=True)
            
            with open(config_file, 'w') as f:
                yaml.dump(self.config, f, default_flow_style=False, indent=2)
            
            self.logger.info(f"Saved configuration to {config_file}")
        
        except Exception as e:
            self.logger.error(f"Failed to save configuration to {config_file}: {str(e)}")
            raise
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Get the complete configuration as a dictionary.
        
        Returns:
            Complete configuration dictionary
        """
        return self.config.copy()


def setup_logging(config: TroubleshootingConfig) -> logging.Logger:
    """
    Set up logging based on configuration.
    
    Args:
        config: Configuration manager instance
        
    Returns:
        Configured root logger for the troubleshooting system
    """
    log_config = config.get_section('logging')
    
    # Set up root logger
    root_logger = logging.getLogger('troubleshooting')
    root_logger.setLevel(getattr(logging, log_config['level'].upper()))
    
    # Clear any existing handlers
    root_logger.handlers.clear()
    
    # Create formatter
    formatter = logging.Formatter(log_config['format'])
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)
    
    # File handler (if configured)
    log_file = log_config.get('file')
    if log_file:
        try:
            # Ensure log directory exists
            Path(log_file).parent.mkdir(parents=True, exist_ok=True)
            
            # Use rotating file handler to manage log file size
            from logging.handlers import RotatingFileHandler
            file_handler = RotatingFileHandler(
                log_file,
                maxBytes=log_config['max_file_size'],
                backupCount=log_config['backup_count']
            )
            file_handler.setFormatter(formatter)
            root_logger.addHandler(file_handler)
            
            root_logger.info(f"Logging to file: {log_file}")
        
        except Exception as e:
            root_logger.error(f"Failed to set up file logging: {str(e)}")
    
    return root_logger


def load_config(config_file: Optional[str] = None) -> TroubleshootingConfig:
    """
    Load and return a configuration instance.
    
    Args:
        config_file: Optional path to configuration file
        
    Returns:
        Configured TroubleshootingConfig instance
    """
    # Look for default config file if none specified
    if not config_file:
        default_locations = [
            './troubleshooting.yml',
            './config/troubleshooting.yml',
            '~/.config/github-pages-troubleshoot/config.yml'
        ]
        
        for location in default_locations:
            expanded_path = os.path.expanduser(location)
            if os.path.exists(expanded_path):
                config_file = expanded_path
                break
    
    return TroubleshootingConfig(config_file)