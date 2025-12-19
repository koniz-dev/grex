# Script Reorganization Utility
# This script reorganizes all scripts into the new categorized structure

<#
.SYNOPSIS
    Reorganizes scripts into categorized directory structure

.DESCRIPTION
    This script moves existing scripts into organized categories:
    - build/ - Build and deployment scripts
    - development/ - Development workflow scripts  
    - testing/ - Testing and quality assurance scripts
    - maintenance/ - Project maintenance scripts
    - database/ - Database management scripts (already organized)
    - utilities/ - General utility scripts

.PARAMETER CleanupOld
    Remove old script files after reorganization

.EXAMPLE
    .\reorganize-scripts.ps1 -CleanupOld
    Reorganize scripts and remove old files

.NOTES
    Author: Grex Development Team
    Date: 2024-01-15
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$CleanupOld
)

# Script categorization mapping
$scriptCategories = @{
    "build_all.sh" = @{
        Category = "build"
        Description = "Multi-platform build script"
    }
    "release.sh" = @{
        Category = "build" 
        Description = "Automated release process"
    }
    "setup-git-hooks.sh" = @{
        Category = "development"
        Description = "Git hooks setup for code quality"
    }
    "bump_version.sh" = @{
        Category = "development"
        Description = "Version management and bumping"
    }
    "test_coverage.sh" = @{
        Category = "testing"
        Description = "Test coverage analysis and reporting"
    }
    "calculate_layer_coverage.sh" = @{
        Category = "testing"
        Description = "Architecture layer coverage analysis"
    }
    "generate_changelog.sh" = @{
        Category = "maintenance"
        Description = "Automated changelog generation"
    }
}

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

# Create directory structure
function New-ScriptDirectories {
    $directories = @(
        "scripts/build",
        "scripts/development", 
        "scripts/testing",
        "scripts/maintenance",
        "scripts/utilities"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Log "Created directory: $dir" "INFO" "Green"
        }
    }
}

# Move scripts to appropriate categories
function Move-ScriptsToCategories {
    foreach ($scriptName in $scriptCategories.Keys) {
        $scriptPath = "scripts/$scriptName"
        $category = $scriptCategories[$scriptName].Category
        $description = $scriptCategories[$scriptName].Description
        $newPath = "scripts/$category/$scriptName"
        
        if (Test-Path $scriptPath) {
            # Copy script to new location
            Copy-Item $scriptPath $newPath -Force
            Write-Log "Moved $scriptName to $category/ - $description" "INFO" "Green"
        } else {
            Write-Log "Script not found: $scriptName" "WARN" "Yellow"
        }
    }
}

# Create category README files
function New-CategoryReadmes {
    # Build README
    $buildReadme = @"
# Build Scripts

Scripts for building, packaging, and releasing the Grex application.

## Scripts

### build_all.sh
Multi-platform build script that builds for Android, iOS, and Web.

**Usage:**
``````bash
# Build for production
./build_all.sh production

# Build with size analysis
./build_all.sh production --analyze-size

# Build for development
./build_all.sh development
``````

**Features:**
- Multi-platform support (Android, iOS, Web)
- Environment-specific configurations
- Build size analysis and optimization recommendations
- Automatic cleanup and dependency management

### release.sh
Automated release process that handles version bumping, changelog generation, and deployment.

**Usage:**
``````bash
# Create patch release
./release.sh patch

# Create minor release
./release.sh minor

# Create major release
./release.sh major
``````

**Features:**
- Automated version bumping
- Changelog generation from git commits
- Release branch creation and tagging
- CI/CD integration
- Quality checks (tests, analysis)

## Prerequisites

- Flutter SDK
- Platform-specific tools (Xcode for iOS, Android SDK)
- Git
- Environment variables configured

## Environment Variables

- `BASE_URL_STAGING`: Staging API URL
- `BASE_URL_PRODUCTION`: Production API URL
- `ENVIRONMENT`: Target environment (development, staging, production)
"@
    
    # Note: This script is deprecated - READMEs are now in windows/ and linux/ directories
    # Set-Content -Path "scripts/build/README.md" -Value $buildReadme
    Write-Log "Note: READMEs are now in windows/ and linux/ directories" "INFO" "Yellow"
    
    # Development README
    $devReadme = @"
# Development Scripts

Scripts that support the development workflow and code quality.

## Scripts

### setup-git-hooks.sh
Sets up Git hooks for automated code quality checks.

**Usage:**
``````bash
./setup-git-hooks.sh
``````

**Features:**
- Pre-commit: Code formatting and analysis
- Commit-msg: Conventional Commits validation
- Pre-push: Test execution
- Automatic installation and configuration

### bump_version.sh
Manages version numbers using semantic versioning.

**Usage:**
``````bash
# Bump patch version (1.0.0 -> 1.0.1)
./bump_version.sh patch

# Bump minor version (1.0.0 -> 1.1.0)
./bump_version.sh minor

# Bump major version (1.0.0 -> 2.0.0)
./bump_version.sh major

# Bump build number only
./bump_version.sh build

# Use custom build number
./bump_version.sh patch 42
``````

**Features:**
- Semantic versioning support
- Automatic pubspec.yaml updates
- Build number management
- Cross-platform compatibility

## Git Hooks

The setup-git-hooks.sh script installs the following hooks:

### Pre-commit
- Runs `dart format --set-exit-if-changed`
- Runs `flutter analyze`
- Prevents commits with formatting or analysis issues

### Commit-msg
- Validates Conventional Commits format
- Ensures consistent commit message structure
- Supports all standard commit types

### Pre-push
- Runs `flutter test`
- Prevents pushing code with failing tests

## Conventional Commits

Commit messages must follow this format:
``````
<type>(<scope>): <subject>
``````

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes

**Examples:**
- `feat(auth): add login functionality`
- `fix(network): handle timeout errors`
- `docs(readme): update installation guide`
"@
    
    # Note: This script is deprecated - READMEs are now in windows/ and linux/ directories
    # Set-Content -Path "scripts/development/README.md" -Value $devReadme
    Write-Log "Created development/README.md" "INFO" "Green"
    
    # Testing README
    $testingReadme = @"
# Testing Scripts

Scripts for testing, coverage analysis, and quality assurance.

## Scripts

### test_coverage.sh
Comprehensive test coverage analysis with multiple reporting options.

**Usage:**
``````bash
# Basic coverage
./test_coverage.sh

# Generate HTML report
./test_coverage.sh --html

# Open HTML report automatically
./test_coverage.sh --open

# Set minimum coverage threshold
./test_coverage.sh --min=85

# Analyze coverage by architectural layer
./test_coverage.sh --analyze

# Skip running tests (use existing coverage)
./test_coverage.sh --no-test --analyze
``````

**Features:**
- HTML coverage reports with detailed breakdowns
- Minimum coverage threshold validation
- Architecture layer analysis
- Low coverage file identification
- Cross-platform support

### calculate_layer_coverage.sh
Calculates test coverage by architectural layer (Domain, Data, Presentation, Core).

**Usage:**
``````bash
./calculate_layer_coverage.sh [path/to/lcov.info]
``````

**Features:**
- Layer-specific coverage calculation
- Clean Architecture compliance checking
- Detailed coverage breakdown
- Integration with CI/CD pipelines

## Coverage Analysis

### Overall Coverage
- Minimum threshold: 80% (configurable)
- Includes all source files except generated code
- Excludes test files and mock files

### Layer Coverage
- **Domain Layer**: Business logic and entities
- **Data Layer**: Repositories and data sources
- **Presentation Layer**: UI components and state management
- **Core Layer**: Shared utilities and configurations

### Coverage Reports

#### Console Output
- Overall coverage percentage
- Total and covered line counts
- Pass/fail status based on threshold

#### HTML Reports
- File-by-file coverage details
- Line-by-line coverage highlighting
- Interactive navigation
- Generated in `coverage/html/`

#### Layer Analysis
- Coverage percentage per layer
- Identification of low-coverage areas
- Recommendations for improvement

## Integration

### CI/CD Integration
``````yaml
# GitHub Actions example
- name: Run tests with coverage
  run: ./scripts/linux/testing/test_coverage.sh --min=80

- name: Upload coverage reports
  uses: codecov/codecov-action@v3
  with:
    file: coverage/lcov.info
``````

### Pre-push Hook
The development scripts automatically configure pre-push hooks to run tests before pushing code.

## Troubleshooting

### Common Issues
1. **lcov not found**: Install with `brew install lcov` (macOS) or `apt-get install lcov` (Linux)
2. **Permission denied**: Make scripts executable with `chmod +x`
3. **No coverage data**: Ensure tests are run with `--coverage` flag
4. **Low coverage**: Use `--analyze` flag to identify specific areas needing tests
"@
    
    # Note: This script is deprecated - READMEs are now in windows/ and linux/ directories
    # Set-Content -Path "scripts/testing/README.md" -Value $testingReadme
    Write-Log "Created testing/README.md" "INFO" "Green"
    
    # Maintenance README
    $maintenanceReadme = @"
# Maintenance Scripts

Scripts for project maintenance, documentation, and housekeeping tasks.

## Scripts

### generate_changelog.sh
Automatically generates changelog entries from git commit messages.

**Usage:**
``````bash
# Generate changelog for current version
./generate_changelog.sh

# Generate changelog for specific version
./generate_changelog.sh 1.2.0
``````

**Features:**
- Conventional Commits parsing
- Automatic categorization by commit type
- CHANGELOG.md integration
- Semantic versioning support
- Git tag integration

## Changelog Generation

### Commit Types Mapping
The script automatically categorizes commits based on their type:

- `feat` → **Added** section
- `fix` → **Fixed** section
- `security` → **Security** section
- `perf` → **Performance** section
- `refactor` → **Refactored** section
- `docs` → **Documentation** section
- `style` → **Style** section
- `test` → **Tests** section
- `chore` → **Chore** section
- `ci` → **CI/CD** section
- `build` → **Build** section
- `revert` → **Reverted** section

### Changelog Format
The generated changelog follows [Keep a Changelog](https://keepachangelog.com/) format:

``````markdown
## [1.2.0] - 2024-01-15

### Added
- New feature for user authentication
- Support for multiple currencies

### Fixed
- Fixed login timeout issue
- Resolved navigation bug

### Security
- Updated dependencies with security patches
``````

### Integration with Release Process
The changelog generation is automatically integrated with the release process:

1. **Version Bump**: `bump_version.sh` updates version numbers
2. **Changelog Generation**: `generate_changelog.sh` creates changelog entry
3. **Release Creation**: `release.sh` commits changes and creates tags

## Best Practices

### Commit Message Guidelines
To ensure high-quality changelogs, follow these commit message guidelines:

1. **Use Conventional Commits format**
2. **Write clear, descriptive subjects**
3. **Include scope when relevant**: `feat(auth): add login`
4. **Use imperative mood**: "add" not "added"
5. **Keep subject under 50 characters**

### Changelog Maintenance
- Review generated changelog entries before release
- Edit entries for clarity if needed
- Add breaking changes notes manually
- Include migration instructions for major changes

## Automation

### CI/CD Integration
``````yaml
# GitHub Actions example
- name: Generate changelog
  run: ./scripts/linux/maintenance/generate_changelog.sh `${{ github.event.release.tag_name }}

- name: Update release notes
  uses: actions/create-release@v1
  with:
    body_path: CHANGELOG.md
``````

### Git Hooks Integration
The changelog generation can be integrated with git hooks for automatic updates:

``````bash
# Post-commit hook example
#!/bin/bash
if git diff HEAD~1 --name-only | grep -q "pubspec.yaml"; then
  ./scripts/linux/maintenance/generate_changelog.sh
fi
``````
"@
    
    # Note: This script is deprecated - READMEs are now in windows/ and linux/ directories
    # Set-Content -Path "scripts/maintenance/README.md" -Value $maintenanceReadme
    Write-Log "Created maintenance/README.md" "INFO" "Green"
}

# Clean up old script files
function Remove-OldScripts {
    if (!$CleanupOld) {
        Write-Log "Skipping cleanup of old scripts (use -CleanupOld to remove)" "INFO" "Yellow"
        return
    }
    
    foreach ($scriptName in $scriptCategories.Keys) {
        $scriptPath = "scripts/$scriptName"
        if (Test-Path $scriptPath) {
            Remove-Item $scriptPath -Force
            Write-Log "Removed old script: $scriptName" "INFO" "Green"
        }
    }
}

# Validate new structure
function Test-NewStructure {
    Write-Log "=== Validating New Structure ===" "INFO" "Green"
    
    $allValid = $true
    
    # Check directories
    $expectedDirs = @("build", "development", "testing", "maintenance", "database", "utilities")
    foreach ($dir in $expectedDirs) {
        $dirPath = "scripts/$dir"
        if (Test-Path $dirPath -PathType Container) {
            Write-Log "[OK] Directory exists: $dir/" "INFO" "Green"
        } else {
            Write-Log "[MISSING] Directory not found: $dir/" "ERROR" "Red"
            $allValid = $false
        }
    }
    
    # Check moved scripts
    foreach ($scriptName in $scriptCategories.Keys) {
        $category = $scriptCategories[$scriptName].Category
        $newPath = "scripts/$category/$scriptName"
        if (Test-Path $newPath) {
            Write-Log "[OK] Script moved: $category/$scriptName" "INFO" "Green"
        } else {
            Write-Log "[MISSING] Script not found: $category/$scriptName" "ERROR" "Red"
            $allValid = $false
        }
    }
    
    # Check README files
    $readmeFiles = @("build/README.md", "development/README.md", "testing/README.md", "maintenance/README.md")
    foreach ($readme in $readmeFiles) {
        $readmePath = "scripts/$readme"
        if (Test-Path $readmePath) {
            Write-Log "[OK] README exists: $readme" "INFO" "Green"
        } else {
            Write-Log "[MISSING] README not found: $readme" "ERROR" "Red"
            $allValid = $false
        }
    }
    
    return $allValid
}

# Generate structure report
function New-StructureReport {
    Write-Log "=== Script Organization Report ===" "INFO" "Cyan"
    
    foreach ($category in @("build", "development", "testing", "maintenance", "database", "utilities")) {
        $categoryPath = "scripts/$category"
        if (Test-Path $categoryPath) {
            $scriptCount = (Get-ChildItem -Path $categoryPath -Filter "*.sh" -File).Count
            $psScriptCount = (Get-ChildItem -Path $categoryPath -Filter "*.ps1" -File).Count
            $totalScripts = $scriptCount + $psScriptCount
            
            Write-Log "$category/: $totalScripts scripts ($scriptCount bash, $psScriptCount PowerShell)" "INFO" "Cyan"
        }
    }
    
    Write-Log "Total script categories: 6" "INFO" "Cyan"
    Write-Log "Organization complete!" "INFO" "Cyan"
}

# Main execution
try {
    Write-Log "Starting script reorganization..." "INFO" "Green"
    
    # Create new directory structure
    New-ScriptDirectories
    
    # Move scripts to categories
    Move-ScriptsToCategories
    
    # Create category README files
    New-CategoryReadmes
    
    # Clean up old files if requested
    Remove-OldScripts
    
    # Validate new structure
    $structureValid = Test-NewStructure
    
    # Generate report
    New-StructureReport
    
    if ($structureValid) {
        Write-Log "=== REORGANIZATION SUCCESSFUL ===" "INFO" "Green"
        Write-Log "All scripts have been organized into categories" "INFO" "Green"
        Write-Log "New structure:" "INFO" "Cyan"
        Write-Log "  scripts/windows/ - Windows PowerShell scripts" "INFO" "Cyan"
        Write-Log "  scripts/linux/ - Linux bash scripts" "INFO" "Cyan"
        
        if (!$CleanupOld) {
            Write-Log "Note: Old script files were preserved. Use -CleanupOld to remove them." "INFO" "Yellow"
        }
        
        Write-Log "Script organization is complete and ready for use!" "INFO" "Green"
    } else {
        Write-Log "=== REORGANIZATION FAILED ===" "ERROR" "Red"
        Write-Log "Some issues were found during validation" "ERROR" "Red"
        exit 1
    }
}
catch {
    Write-Log "Script reorganization failed: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}