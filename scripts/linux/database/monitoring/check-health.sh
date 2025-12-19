#!/bin/bash
# Corresponding Linux version of check-health.ps1
# This script provides Linux compatibility for the PowerShell script

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOWS_SCRIPT="$SCRIPT_DIR/../../windows/database\monitoring/check-health.ps1"

# Check if PowerShell is available
if command -v pwsh &> /dev/null; then
    # Use PowerShell Core if available
    pwsh -File "$WINDOWS_SCRIPT" "$@"
elif command -v powershell &> /dev/null; then
    # Fallback to Windows PowerShell
    powershell -File "$WINDOWS_SCRIPT" "$@"
else
    echo "Error: PowerShell not found. Please install PowerShell Core (pwsh) or use the native Linux script."
    echo "For native Linux implementation, please see the script documentation."
    exit 1
fi
