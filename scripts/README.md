# Grex Scripts

This directory contains all automation scripts for the Grex expense splitting application, organized by category for easy navigation and maintenance.

## Script Organization

Scripts are organized by platform (Windows and Linux) to ensure cross-platform compatibility. Each script has a corresponding version for the other platform.

```
scripts/
├── README.md                    # This file - scripts overview
├── windows/                     # Windows PowerShell scripts (.ps1)
│   ├── build/                  # Build and deployment scripts
│   │   ├── build_all.ps1      # Multi-platform build script
│   │   └── release.ps1        # Automated release process
│   ├── development/           # Development workflow scripts
│   │   ├── setup-git-hooks.ps1 # Git hooks setup
│   │   └── bump_version.ps1   # Version management
│   ├── testing/               # Testing and quality assurance
│   │   ├── test_coverage.ps1  # Test coverage analysis
│   │   └── calculate_layer_coverage.ps1 # Architecture layer coverage
│   ├── maintenance/           # Project maintenance scripts
│   │   └── generate_changelog.ps1 # Changelog generation
│   ├── database/              # Database management scripts
│   │   ├── migrations/        # Migration management
│   │   ├── backup/            # Backup and restore
│   │   ├── monitoring/        # Database monitoring
│   │   ├── security/          # Security testing
│   │   ├── test/              # Database testing
│   │   └── utils/             # Database utilities
│   └── utilities/             # General utility scripts
└── linux/                      # Linux bash scripts (.sh)
    ├── build/                  # Build and deployment scripts
    │   ├── build_all.sh        # Multi-platform build script
    │   └── release.sh          # Automated release process
    ├── development/           # Development workflow scripts
    │   ├── setup-git-hooks.sh  # Git hooks setup
    │   └── bump_version.sh     # Version management
    ├── testing/               # Testing and quality assurance
    │   ├── test_coverage.sh   # Test coverage analysis
    │   └── calculate_layer_coverage.sh # Architecture layer coverage
    ├── maintenance/           # Project maintenance scripts
    │   └── generate_changelog.sh # Changelog generation
    ├── database/              # Database management scripts
    │   ├── migrations/        # Migration management
    │   ├── backup/            # Backup and restore
    │   ├── monitoring/        # Database monitoring
    │   ├── security/          # Security testing
    │   ├── test/              # Database testing
    │   └── utils/             # Database utilities
    └── utilities/             # General utility scripts
```

## Quick Reference

### Build & Deployment

**Linux/macOS:**
```bash
# Build for all platforms
./scripts/linux/build/build_all.sh production --analyze-size

# Create a release
./scripts/linux/build/release.sh minor
```

**Windows:**
```powershell
# Build for all platforms
.\scripts\windows\build\build_all.ps1 production -AnalyzeSize

# Create a release
.\scripts\windows\build\release.ps1 minor
```

### Development Workflow

**Linux/macOS:**
```bash
# Set up Git hooks
./scripts/linux/development/setup-git-hooks.sh

# Bump version
./scripts/linux/development/bump_version.sh patch
```

**Windows:**
```powershell
# Set up Git hooks
.\scripts\windows\development\setup-git-hooks.ps1

# Bump version
.\scripts\windows\development\bump_version.ps1 patch
```

### Testing & Quality

**Linux/macOS:**
```bash
# Run tests with coverage
./scripts/linux/testing/test_coverage.sh --html --open --analyze

# Calculate layer coverage
./scripts/linux/testing/calculate_layer_coverage.sh
```

**Windows:**
```powershell
# Run tests with coverage
.\scripts\windows\testing\test_coverage.ps1 -Html -Open -Analyze

# Calculate layer coverage
.\scripts\windows\testing\calculate_layer_coverage.ps1
```

### Maintenance

**Linux/macOS:**
```bash
# Generate changelog
./scripts/linux/maintenance/generate_changelog.sh
```

**Windows:**
```powershell
# Generate changelog
.\scripts\windows\maintenance\generate_changelog.ps1
```

### Database Operations

**Linux/macOS:**
```bash
# Apply migrations
./scripts/linux/database/migrations/manage-migrations.sh apply --environment development

# Create backup
./scripts/linux/database/backup/manage-backups.sh create --environment production
```

**Windows:**
```powershell
# Apply migrations
.\scripts\windows\database\migrations\manage-migrations.ps1 -Action apply -Environment development

# Create backup
.\scripts\windows\database\backup\manage-backups.ps1 -Action create -Environment production
```

## Script Categories

### Build Scripts (`build/`)
Scripts for building, packaging, and releasing the application:
- **Multi-platform builds**: Android, iOS, Web
- **Environment-specific configurations**: Development, staging, production
- **Build optimization**: Size analysis and recommendations
- **Release automation**: Version bumping, tagging, deployment

### Development Scripts (`development/`)
Scripts that support the development workflow:
- **Git hooks**: Code quality checks, commit message validation
- **Version management**: Semantic versioning, build number management
- **Development setup**: Environment configuration, dependency management

### Testing Scripts (`testing/`)
Scripts for testing, coverage analysis, and quality assurance:
- **Test execution**: Unit tests, integration tests, widget tests
- **Coverage analysis**: Overall coverage, layer-specific coverage
- **Quality metrics**: Code analysis, performance benchmarks
- **Reporting**: HTML reports, coverage visualization

### Maintenance Scripts (`maintenance/`)
Scripts for project maintenance and documentation:
- **Changelog generation**: Automated changelog from git commits
- **Documentation updates**: API docs, README updates
- **Dependency management**: Dependency updates, security audits
- **Code cleanup**: Unused code detection, formatting

### Database Scripts (`database/`)
Comprehensive database management scripts:
- **Migration management**: Apply, rollback, validate migrations
- **Backup & restore**: Automated backups, disaster recovery
- **Performance monitoring**: Query analysis, index optimization
- **Testing**: Database tests, data validation

### Utility Scripts (`utilities/`)
General-purpose utility scripts:
- **Project organization**: File reorganization, structure validation
- **Environment setup**: Configuration management, tool installation
- **Automation helpers**: Common functions, shared utilities

## Usage Guidelines

### Script Naming Conventions
- Use descriptive names with underscores: `build_all.sh` / `build_all.ps1`
- Include file extensions: `.sh` for bash, `.ps1` for PowerShell
- Use consistent prefixes for related scripts: `test_*`, `build_*`
- Maintain same base name across platforms: `build_all.sh` ↔ `build_all.ps1`
- Place Windows scripts in `windows/` directory
- Place Linux scripts in `linux/` directory

### Error Handling
All scripts implement:
- **Exit on error**: `set -e` for bash scripts
- **Input validation**: Parameter checking and validation
- **Colored output**: Success (green), warnings (yellow), errors (red)
- **Logging**: Timestamped log messages for debugging

### Cross-platform Support
Scripts are organized by platform for optimal compatibility:
- **Windows**: PowerShell scripts (.ps1) in `windows/` directory
- **Linux/macOS**: Bash scripts (.sh) in `linux/` directory
- **Corresponding Versions**: Each script has a corresponding version for the other platform
  - Some scripts are native implementations
  - Some scripts are wrappers that call the other platform's version
  - All scripts maintain the same functionality across platforms

### Environment Variables
Scripts use environment variables for configuration:
- `ENVIRONMENT`: development, staging, production
- `BASE_URL_*`: Environment-specific API URLs
- `DATABASE_URL_*`: Environment-specific database connections

## Getting Started

### Prerequisites
Ensure you have the required tools installed:
```bash
# Flutter SDK
flutter --version

# Git
git --version

# Platform-specific tools
# macOS: Xcode, CocoaPods
# Linux: Android SDK, build tools
# Windows: Android SDK, Visual Studio
```

### First-time Setup

**Linux/macOS:**
```bash
# 1. Set up Git hooks for code quality
./scripts/linux/development/setup-git-hooks.sh

# 2. Run initial tests
./scripts/linux/testing/test_coverage.sh --html

# 3. Build for your platform
./scripts/linux/build/build_all.sh development
```

**Windows:**
```powershell
# 1. Set up Git hooks for code quality
.\scripts\windows\development\setup-git-hooks.ps1

# 2. Run initial tests
.\scripts\windows\testing\test_coverage.ps1 -Html

# 3. Build for your platform
.\scripts\windows\build\build_all.ps1 development
```

### Daily Development Workflow

**Linux/macOS:**
```bash
# 1. Run tests before committing
./scripts/linux/testing/test_coverage.sh

# 2. Commit with conventional format (enforced by hooks)
git commit -m "feat(auth): add login functionality"

# 3. Before releasing
./scripts/linux/build/release.sh patch
```

**Windows:**
```powershell
# 1. Run tests before committing
.\scripts\windows\testing\test_coverage.ps1

# 2. Commit with conventional format (enforced by hooks)
git commit -m "feat(auth): add login functionality"

# 3. Before releasing
.\scripts\windows\build\release.ps1 patch
```

## Contributing

### Adding New Scripts
1. **Choose the right category**: Place scripts in appropriate directories
2. **Follow naming conventions**: Use descriptive names with proper extensions
3. **Include documentation**: Add header comments explaining purpose and usage
4. **Implement error handling**: Use consistent error handling patterns
5. **Test thoroughly**: Test on multiple platforms if applicable
6. **Update this README**: Add new scripts to the appropriate sections

### Script Template
Use this template for new bash scripts:

```bash
#!/bin/bash

# Script Name - Brief description
# Usage: ./script_name.sh [options]
# Options:
#   --option1    Description of option1
#   --option2    Description of option2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
OPTION1=""
OPTION2=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --option1=*)
      OPTION1="${1#*=}"
      shift
      ;;
    --option2)
      OPTION2=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--option1=value] [--option2]"
      exit 1
      ;;
  esac
done

# Main script logic here
echo -e "${GREEN}Script completed successfully!${NC}"
```

## Troubleshooting

### Common Issues
1. **Permission denied**: Make scripts executable with `chmod +x script_name.sh`
2. **Command not found**: Ensure required tools are installed and in PATH
3. **Environment variables**: Check that required environment variables are set
4. **Platform differences**: Some scripts may have platform-specific behavior

### Getting Help
1. **Check script documentation**: Most scripts have built-in help with `--help`
2. **Review error messages**: Scripts provide detailed error messages
3. **Check prerequisites**: Ensure all required tools are installed
4. **Consult team**: Reach out to team members for complex issues

## Maintenance

### Regular Tasks
- **Update dependencies**: Keep script dependencies current
- **Review and test**: Regularly test scripts on different platforms
- **Documentation**: Keep README and script documentation updated
- **Performance**: Monitor script execution times and optimize as needed

### Script Health Checks
Run periodic checks to ensure scripts are working correctly:

**Linux/macOS:**
```bash
# Test all build scripts
./scripts/linux/build/build_all.sh development

# Verify test coverage
./scripts/linux/testing/test_coverage.sh --analyze

# Check database scripts
./scripts/linux/database/utils/validate-structure.sh
```

**Windows:**
```powershell
# Test all build scripts
.\scripts\windows\build\build_all.ps1 development

# Verify test coverage
.\scripts\windows\testing\test_coverage.ps1 -Analyze

# Check database scripts
.\scripts\windows\database\utils\validate-structure.ps1
```

This organized script structure provides a professional, maintainable foundation for all automation needs in the Grex project.