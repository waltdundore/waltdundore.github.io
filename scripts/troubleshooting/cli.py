#!/usr/bin/env python3
"""
Command-line interface for the GitHub Pages troubleshooting system.

This module provides a simple CLI for running diagnostics and repairs
on GitHub Pages repositories.
"""

import argparse
import sys
import json
from pathlib import Path

# Add the current directory to Python path for imports
sys.path.insert(0, str(Path(__file__).parent))

from config import load_config, setup_logging
from orchestrator import DiagnosticOrchestrator


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description='GitHub Pages Troubleshooting System',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s diagnose                    # Run diagnostics on current directory
  %(prog)s diagnose --config custom.yml  # Use custom configuration
  %(prog)s diagnose --output report.json # Save results to file
        """
    )
    
    parser.add_argument(
        'command',
        choices=['diagnose', 'repair', 'validate'],
        help='Command to execute'
    )
    
    parser.add_argument(
        '--config', '-c',
        help='Path to configuration file'
    )
    
    parser.add_argument(
        '--repository', '-r',
        default='.',
        help='Path to repository (default: current directory)'
    )
    
    parser.add_argument(
        '--output', '-o',
        help='Output file for results (default: print to console)'
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose logging'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Simulate operations without making changes'
    )
    
    args = parser.parse_args()
    
    try:
        # Load configuration
        config = load_config(args.config)
        
        # Override log level if verbose
        if args.verbose:
            config.set('logging.level', 'DEBUG')
        
        # Set up logging
        logger = setup_logging(config)
        logger.info("GitHub Pages Troubleshooting System starting")
        
        # Create orchestrator
        orchestrator = DiagnosticOrchestrator(config)
        
        # Execute command
        if args.command == 'diagnose':
            session = orchestrator.start_session(args.repository)
            results = orchestrator.run_diagnostics()
            
            # Output results
            if args.output:
                with open(args.output, 'w') as f:
                    json.dump(results.to_dict(), f, indent=2)
                logger.info(f"Results saved to {args.output}")
            else:
                print(json.dumps(results.to_dict(), indent=2))
        
        else:
            logger.error(f"Command '{args.command}' not yet implemented")
            return 1
    
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        return 1
    
    return 0


if __name__ == '__main__':
    sys.exit(main())