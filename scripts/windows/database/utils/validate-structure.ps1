# Documentation and Script Structure Validation
# This script validates the new organized structure

<#
.SYNOPSIS
    Validates the reorganized documentation and script structure

.DESCRIPTION
    This script checks that all expected files and directories exist in the new
    organized structure and validates that the reorganization was successful.

.EXAMPLE
    .\validate-structure.ps1
    Validate the current structure

.NOTES
    Author: Grex Development Team
    Date: 2024-01-15
    Version: 1.0
#>

# Expected structure
$expectedStructure = @{
    "docs/README.md" = "Main documentation index"
    "docs/database/README.md" = "Database documentation overview"
    "docs/database/schema/overview.md" = "Schema overview and ER diagram"
    "docs/database/schema/tables.md" = "Detailed table documentation"
    "docs/database/schema/relationships.md" = "Table relationships and constraints"
    "docs/database/schema/indexes.md" = "Index documentation"
    "docs/database/functions/overview.md" = "Functions overview"
    "docs/database/security/rls-policies.md" = "RLS policies documentation"
    "docs/database/operations/migrations.md" = "Migration guide"
    "docs/database/examples/queries.md" = "Common queries"
    "docs/database/examples/workflows.md" = "Business workflows"
    "scripts/windows/database/README.md" = "Database scripts overview (Windows)"
    "scripts/linux/database/README.md" = "Database scripts overview (Linux)"
    "scripts/windows/database/migrations/manage-migrations.ps1" = "Migration management script (Windows)"
    "scripts/linux/database/migrations/manage-migrations.sh" = "Migration management script (Linux)"
    "scripts/windows/database/backup/manage-backups.ps1" = "Database backup script (Windows)"
    "scripts/linux/database/backup/manage-backups.sh" = "Database backup script (Linux)"
    "scripts/windows/database/utils/reorganize-docs.ps1" = "Documentation reorganization script (Windows)"
    "scripts/linux/database/utils/reorganize-docs.sh" = "Documentation reorganization script (Linux)"
    "scripts/windows/database/utils/validate-structure.ps1" = "This validation script"
}

$expectedDirectories = @(
    "docs/database/schema",
    "docs/database/functions", 
    "docs/database/triggers",
    "docs/database/security",
    "docs/database/operations",
    "docs/database/examples",
    "scripts/windows/database/migrations",
    "scripts/windows/database/backup",
    "scripts/windows/database/test",
    "scripts/windows/database/utils",
    "scripts/linux/database/migrations",
    "scripts/linux/database/backup",
    "scripts/linux/database/test",
    "scripts/linux/database/utils",
    "logs",
    "backups/database",
    "backups/migrations"
)

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $Color
}

# Validate directories
function Test-DirectoryStructure {
    Write-Log "=== Validating Directory Structure ===" "INFO" "Green"
    
    $allValid = $true
    
    foreach ($dir in $expectedDirectories) {
        if (Test-Path $dir -PathType Container) {
            Write-Log "[OK] Directory exists: $dir" "INFO" "Green"
        } else {
            Write-Log "[MISSING] Directory not found: $dir" "ERROR" "Red"
            $allValid = $false
        }
    }
    
    return $allValid
}

# Validate files
function Test-FileStructure {
    Write-Log "=== Validating File Structure ===" "INFO" "Green"
    
    $allValid = $true
    
    foreach ($file in $expectedStructure.Keys) {
        if (Test-Path $file -PathType Leaf) {
            $size = (Get-Item $file).Length
            Write-Log "[OK] File exists: $file ($size bytes)" "INFO" "Green"
        } else {
            Write-Log "[MISSING] File not found: $file" "ERROR" "Red"
            $allValid = $false
        }
    }
    
    return $allValid
}

# Check for old files that should have been cleaned up
function Test-OldFilesCleanup {
    Write-Log "=== Checking Old Files Cleanup ===" "INFO" "Green"
    
    $oldFiles = @(
        "docs/database-schema.md",
        "docs/functions-and-triggers.md", 
        "docs/rls-policies.md",
        "docs/migration-guide.md",
        "scripts/windows/database/migrations/manage-migrations.ps1"
    )
    
    $cleanupComplete = $true
    
    foreach ($file in $oldFiles) {
        if (Test-Path $file) {
            Write-Log "[WARNING] Old file still exists: $file" "WARN" "Yellow"
            $cleanupComplete = $false
        } else {
            Write-Log "[OK] Old file cleaned up: $file" "INFO" "Green"
        }
    }
    
    return $cleanupComplete
}

# Validate file content (basic checks)
function Test-FileContent {
    Write-Log "=== Validating File Content ===" "INFO" "Green"
    
    $contentValid = $true
    
    # Check main README
    if (Test-Path "docs/README.md") {
        $content = Get-Content "docs/README.md" -Raw
        if ($content -match "Grex Documentation" -and $content -match "database/") {
            Write-Log "[OK] Main README has expected content" "INFO" "Green"
        } else {
            Write-Log "[ERROR] Main README missing expected content" "ERROR" "Red"
            $contentValid = $false
        }
    }
    
    # Check database README
    if (Test-Path "docs/database/README.md") {
        $content = Get-Content "docs/database/README.md" -Raw
        if ($content -match "Database Documentation" -and $content -match "schema/overview.md") {
            Write-Log "[OK] Database README has expected content" "INFO" "Green"
        } else {
            Write-Log "[ERROR] Database README missing expected content" "ERROR" "Red"
            $contentValid = $false
        }
    }
    
    # Check migration script
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $migrationScript = Join-Path $scriptDir "../migrations/manage-migrations.ps1"
    if (Test-Path $migrationScript) {
        $content = Get-Content $migrationScript -Raw
        if ($content -match "Migration Management Script" -and $content -match "param\(") {
            Write-Log "[OK] Migration script has expected content" "INFO" "Green"
        } else {
            Write-Log "[ERROR] Migration script missing expected content" "ERROR" "Red"
            $contentValid = $false
        }
    }
    
    return $contentValid
}

# Generate structure report
function New-StructureReport {
    Write-Log "=== Structure Report ===" "INFO" "Cyan"
    
    # Count files and directories
    $docFiles = (Get-ChildItem -Path "docs" -Recurse -File).Count
    $scriptFiles = (Get-ChildItem -Path "scripts/windows/database" -Recurse -File).Count + (Get-ChildItem -Path "scripts/linux/database" -Recurse -File).Count
    $totalDirs = $expectedDirectories.Count
    $totalFiles = $expectedStructure.Count
    
    Write-Log "Documentation files: $docFiles" "INFO" "Cyan"
    Write-Log "Database script files: $scriptFiles" "INFO" "Cyan"
    Write-Log "Expected directories: $totalDirs" "INFO" "Cyan"
    Write-Log "Expected key files: $totalFiles" "INFO" "Cyan"
    
    # Show directory tree
    Write-Log "Directory structure:" "INFO" "Cyan"
    if (Get-Command tree -ErrorAction SilentlyContinue) {
        tree docs/database /F
        tree scripts/windows/database /F
        tree scripts/linux/database /F
    } else {
        Write-Log "Install 'tree' command for better directory visualization" "INFO" "Yellow"
    }
}

# Main execution
try {
    Write-Log "Starting structure validation..." "INFO" "Green"
    
    $dirValid = Test-DirectoryStructure
    $fileValid = Test-FileStructure
    $cleanupValid = Test-OldFilesCleanup
    $contentValid = Test-FileContent
    
    New-StructureReport
    
    # Overall result
    if ($dirValid -and $fileValid -and $contentValid) {
        Write-Log "=== VALIDATION SUCCESSFUL ===" "INFO" "Green"
        Write-Log "All expected files and directories are present with valid content" "INFO" "Green"
        
        if (!$cleanupValid) {
            Write-Log "Note: Some old files still exist but this doesn't affect functionality" "INFO" "Yellow"
        }
        
        Write-Log "Documentation structure is ready for use!" "INFO" "Green"
        exit 0
    } else {
        Write-Log "=== VALIDATION FAILED ===" "ERROR" "Red"
        
        if (!$dirValid) {
            Write-Log "Some expected directories are missing" "ERROR" "Red"
        }
        if (!$fileValid) {
            Write-Log "Some expected files are missing" "ERROR" "Red"
        }
        if (!$contentValid) {
            Write-Log "Some files have invalid or missing content" "ERROR" "Red"
        }
        
        Write-Log "Please run the reorganization script to fix issues" "ERROR" "Red"
        exit 1
    }
}
catch {
    Write-Log "Validation failed with error: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}