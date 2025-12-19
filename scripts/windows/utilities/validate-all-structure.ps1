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
    "scripts/windows/build/README.md" = "Build scripts documentation (Windows)"
    "scripts/linux/build/README.md" = "Build scripts documentation (Linux)"
    "scripts/windows/build/build_all.ps1" = "Multi-platform build script (Windows)"
    "scripts/linux/build/build_all.sh" = "Multi-platform build script (Linux)"
    "scripts/windows/build/release.ps1" = "Release automation script (Windows)"
    "scripts/linux/build/release.sh" = "Release automation script (Linux)"
    "scripts/windows/development/README.md" = "Development scripts documentation (Windows)"
    "scripts/linux/development/README.md" = "Development scripts documentation (Linux)"
    "scripts/windows/development/setup-git-hooks.ps1" = "Git hooks setup (Windows)"
    "scripts/linux/development/setup-git-hooks.sh" = "Git hooks setup (Linux)"
    "scripts/windows/development/bump_version.ps1" = "Version management (Windows)"
    "scripts/linux/development/bump_version.sh" = "Version management (Linux)"
    "scripts/windows/testing/README.md" = "Testing scripts documentation (Windows)"
    "scripts/linux/testing/README.md" = "Testing scripts documentation (Linux)"
    "scripts/windows/testing/test_coverage.ps1" = "Test coverage analysis (Windows)"
    "scripts/linux/testing/test_coverage.sh" = "Test coverage analysis (Linux)"
    "scripts/windows/testing/calculate_layer_coverage.ps1" = "Layer coverage analysis (Windows)"
    "scripts/linux/testing/calculate_layer_coverage.sh" = "Layer coverage analysis (Linux)"
    "scripts/windows/maintenance/README.md" = "Maintenance scripts documentation (Windows)"
    "scripts/linux/maintenance/README.md" = "Maintenance scripts documentation (Linux)"
    "scripts/windows/maintenance/generate_changelog.ps1" = "Changelog generation (Windows)"
    "scripts/linux/maintenance/generate_changelog.sh" = "Changelog generation (Linux)"
    "scripts/windows/database/README.md" = "Database scripts overview (Windows)"
    "scripts/linux/database/README.md" = "Database scripts overview (Linux)"
    "scripts/windows/database/migrations/manage-migrations.ps1" = "Migration management (Windows)"
    "scripts/linux/database/migrations/manage-migrations.sh" = "Migration management (Linux)"
    "scripts/windows/database/backup/manage-backups.ps1" = "Database backup (Windows)"
    "scripts/linux/database/backup/manage-backups.sh" = "Database backup (Linux)"
    "scripts/windows/utilities/validate-all-structure.ps1" = "This validation script"
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
        "scripts/windows/build",
        "scripts/linux/build",
        "scripts/windows/development",
        "scripts/windows/testing",
        "scripts/windows/maintenance",
        "scripts/windows/database/migrations",
        "scripts/windows/database/backup",
        "scripts/windows/database/utils",
        "scripts/windows/utilities",
        "scripts/linux/development",
        "scripts/linux/testing",
        "scripts/linux/maintenance",
        "scripts/linux/database/migrations",
        "scripts/linux/database/backup",
        "scripts/linux/database/utils",
        "scripts/linux/utilities"
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
    $scriptFiles = (Get-ChildItem -Path "scripts/windows", "scripts/linux" -Recurse -File -ErrorAction SilentlyContinue).Count
    $scriptDirs = (Get-ChildItem -Path "scripts/windows", "scripts/linux" -Recurse -Directory -ErrorAction SilentlyContinue).Count
    $bashScripts = (Get-ChildItem -Path "scripts/linux" -Recurse -Filter "*.sh" -ErrorAction SilentlyContinue).Count
    $psScripts = (Get-ChildItem -Path "scripts/windows" -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue).Count
    
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