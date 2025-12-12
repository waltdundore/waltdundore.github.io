#!/usr/bin/env python3
"""
Setup script for the GitHub Pages troubleshooting system.

This script sets up the Python virtual environment and installs
all required dependencies.
"""

import os
import sys
import subprocess
import venv
from pathlib import Path


def run_command(cmd, cwd=None, check=True):
    """Run a shell command and return the result."""
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=cwd, check=check, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    return result


def setup_virtual_environment():
    """Set up Python virtual environment."""
    venv_path = Path(__file__).parent / 'venv'
    
    if venv_path.exists():
        print(f"Virtual environment already exists at {venv_path}")
        return venv_path
    
    print(f"Creating virtual environment at {venv_path}")
    venv.create(venv_path, with_pip=True)
    
    return venv_path


def install_dependencies(venv_path):
    """Install Python dependencies in the virtual environment."""
    requirements_file = Path(__file__).parent / 'requirements.txt'
    
    if not requirements_file.exists():
        print(f"Requirements file not found: {requirements_file}")
        return False
    
    # Determine pip executable path
    if sys.platform == 'win32':
        pip_exe = venv_path / 'Scripts' / 'pip.exe'
    else:
        pip_exe = venv_path / 'bin' / 'pip'
    
    # Upgrade pip first
    run_command([str(pip_exe), 'install', '--upgrade', 'pip'])
    
    # Install requirements
    run_command([str(pip_exe), 'install', '-r', str(requirements_file)])
    
    return True


def create_directories():
    """Create necessary directories for the troubleshooting system."""
    base_path = Path(__file__).parent
    
    directories = [
        'logs',
        'reports',
        'backups',
        'config'
    ]
    
    for directory in directories:
        dir_path = base_path / directory
        dir_path.mkdir(exist_ok=True)
        print(f"Created directory: {dir_path}")


def create_activation_script():
    """Create a script to activate the virtual environment."""
    base_path = Path(__file__).parent
    venv_path = base_path / 'venv'
    
    if sys.platform == 'win32':
        activate_script = base_path / 'activate.bat'
        activate_content = f"""@echo off
call "{venv_path}\\Scripts\\activate.bat"
echo GitHub Pages Troubleshooting System environment activated
echo Run: python cli.py diagnose --help
"""
    else:
        activate_script = base_path / 'activate.sh'
        activate_content = f"""#!/bin/bash
source "{venv_path}/bin/activate"
echo "GitHub Pages Troubleshooting System environment activated"
echo "Run: python cli.py diagnose --help"
"""
    
    with open(activate_script, 'w') as f:
        f.write(activate_content)
    
    if not sys.platform == 'win32':
        os.chmod(activate_script, 0o755)
    
    print(f"Created activation script: {activate_script}")


def main():
    """Main setup function."""
    print("Setting up GitHub Pages Troubleshooting System...")
    
    try:
        # Set up virtual environment
        venv_path = setup_virtual_environment()
        
        # Install dependencies
        if not install_dependencies(venv_path):
            print("Failed to install dependencies")
            return 1
        
        # Create directories
        create_directories()
        
        # Create activation script
        create_activation_script()
        
        print("\nSetup completed successfully!")
        print("\nTo use the troubleshooting system:")
        if sys.platform == 'win32':
            print("1. Run: activate.bat")
        else:
            print("1. Run: source activate.sh")
        print("2. Run: python cli.py diagnose --help")
        
        return 0
    
    except Exception as e:
        print(f"Setup failed: {str(e)}", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())