# Complete Structure Validation Script
# This script validates both documentation and script organization

param()

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

# Expected structure
$expectedStructure = @{
    "docs/README.md" = "Main documentation index"
    "docs/database/README.md" = "Database documentation overview"
    "docs/database/schema/overview.md" = "Schema overview and ER diagram"
    "docs/database/schema/tables.md" = "Detailed table documentation"
    "docs/database/schema/relationships.md" = "Table relationships"
    "docs/database/schema/indexes.md" = "Index documentation"
    "docs/database/functions/overview.md" = "Functions overview"
    "docs/database/security/rls-policies.md" = "RLS policies"
    "docs/database/operations/migrations.md" = "Migration guide"
    "docs/database/examples/queries.md" = "Common queries"
    "docs/database/examples/workflows.md" = "Business workflows"
    "scripts/README.md" = "Scripts overview"
    "scripts/build/README.md" = "Build scripts documentation"
    "scripts/build/build_all.sh" = "Multi-platform build script"
    "scripts/build/release.sh" = "Release automation script"
    "scripts/development/README.md" = "Development scripts documentation"
    "scripts/development/setup-git-hooks.sh" = "Git hooks setup"
    "scripts/development/bump_version.sh" = "Version management"
    "scripts/testing/README.md" = "Testing scripts documentation"
    "scripts/testing/test_coverage.sh" = "Test coverage analysis"
    "scripts/testing/calculate_layer_coverage.sh" = "Layer coverage analysis"
    "scripts/maintenance/README.md" = "Maintenance scripts documentation"
    "scripts/maintenance/generate_changelog.sh" = "Changelog generation"
    "scripts/database/README.md" = "Database scripts overview"
    "scripts/database/migrations/manage-migrations.ps1" = "Migration management"
    "scripts/database/backup/backup-database.ps1" = "Database backup"
    "scripts/utilities/reorganize-scripts.ps1" = "Script reorganization"
    "scripts/utilities/validate-all-structure.ps1" = "This validation script"
}

# Validate file structure
function Test-FileStructure {
    Write-Log "=== Validating File Structure ===" "INFO" "Green"
    
    $allValid = $true
    $missingFiles = @()
    $existingFiles = @()
    
    foreach ($file in $expectedStructure.Keys) {
        if (Test-Path $file -PathType Leaf) {
            $size = (Get-Item $file).Length
            $existingFiles += $file
            Write-Log "[OK] $file ($size bytes)" "INFO" "Green"
        } else {
            $missingFiles += $file
            Write-Log "[MISSING] $file" "ERROR" "Red"
            $allValid = $false
        }
    }
    
    Write-Log "Files found: $($existingFiles.Count)" "INFO" "Cyan"
    Write-Log "Files missing: $($missingFiles.Count)" "INFO" "Cyan"
    
    return $allValid
}

# Validate directory structure
function Test-DirectoryStructure {
    Write-Log "=== Validating Directory Structure ===" "INFO" "Green"
    
    $expectedDirs = @(
        "docs/database/schema",
        "docs/database/functions",
        "docs/database/security", 
        "docs/database/operations",
        "docs/database/examples",
        "scripts/build",
        "scripts/development",
        "scripts/testing",
        "scripts/maintenance",
        "scripts/database/migrations",
        "scripts/database/backup",
        "scripts/database/utilities",
        "scripts/utilities"
    )
    
    $allValid = $true
    
    foreach ($dir in $expectedDirs) {
        if (Test-Path $dir -PathType Container) {
            Write-Log "[OK] Directory: $dir/" "INFO" "Green"
        } else {
            Write-Log "[MISSING] Directory: $dir/" "ERROR" "Red"
            $allValid = $false
        }
    }
    
    return $allValid
}

# Generate comprehensive report
function New-ComprehensiveReport {
    Write-Log "=== Comprehensive Structure Report ===" "INFO" "Cyan"
    
    # Count documentation files
    $docFiles = (Get-ChildItem -Path "docs" -Recurse -File).Count
    $docDirs = (Get-ChildItem -Path "docs" -Recurse -Directory).Count
    
    # Count script files
    $scriptFiles = (Get-ChildItem -Path "scripts" -Recurse -File).Count
    $scriptDirs = (Get-ChildItem -Path "scripts" -Recurse -Directory).Count
    $bashScripts = (Get-ChildItem -Path "scripts" -Recurse -Filter "*.sh").Count
    $psScripts = (Get-ChildItem -Path "scripts" -Recurse -Filter "*.ps1").Count
    
    Write-Log "Documentation Structure:" "INFO" "Cyan"
    Write-Log "  Total files: $docFiles" "INFO" "Cyan"
    Write-Log "  Total directories: $docDirs" "INFO" "Cyan"
    
    Write-Log "Script Structure:" "INFO" "Cyan"
    Write-Log "  Total files: $scriptFiles" "INFO" "Cyan"
    Write-Log "  Total directories: $scriptDirs" "INFO" "Cyan"
    Write-Log "  Bash scripts: $bashScripts" "INFO" "Cyan"
    Write-Log "  PowerShell scripts: $psScripts" "INFO" "Cyan"
    
    Write-Log "Script Categories:" "INFO" "Cyan"
    foreach ($category in @("build", "development", "testing", "maintenance", "database", "utilities")) {
        $categoryPath = "scripts/$category"
        if (Test-Path $categoryPath) {
            $categoryFiles = (Get-ChildItem -Path $categoryPath -Recurse -File -Include "*.sh", "*.ps1").Count
            Write-Log "  $category/: $categoryFiles scripts" "INFO" "Cyan"
        }
    }
}

# Main execution
try {
    Write-Log "Starting comprehensive structure validation..." "INFO" "Green"
    Write-Log "Validating Grex project documentation and script organization" "INFO" "Cyan"
    Write-Log "" "INFO" "White"
    
    $fileValid = Test-FileStructure
    Write-Log "" "INFO" "White"
    
    $dirValid = Test-DirectoryStructure  
    Write-Log "" "INFO" "White"
    
    New-ComprehensiveReport
    Write-Log "" "INFO" "White"
    
    # Overall result
    if ($fileValid -and $dirValid) {
        Write-Log "=== VALIDATION SUCCESSFUL ===" "INFO" "Green"
        Write-Log "All files and directories are present" "INFO" "Green"
        Write-Log "Structure is ready for production use" "INFO" "Green"
        Write-Log "" "INFO" "White"
        Write-Log "Project structure reorganization is complete!" "INFO" "Green"
        Write-Log "" "INFO" "White"
        Write-Log "Next steps:" "INFO" "Cyan"
        Write-Log "  1. Review the organized documentation in docs/" "INFO" "Cyan"
        Write-Log "  2. Use categorized scripts in scripts/" "INFO" "Cyan"
        Write-Log "  3. Continue with Task 20 - Security review and hardening" "INFO" "Cyan"
        
        exit 0
    } else {
        Write-Log "=== VALIDATION FAILED ===" "ERROR" "Red"
        
        if (!$fileValid) {
            Write-Log "Some expected files are missing" "ERROR" "Red"
        }
        if (!$dirValid) {
            Write-Log "Some expected directories are missing" "ERROR" "Red"
        }
        
        exit 1
    }
}
catch {
    Write-Log "Validation failed with error: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}