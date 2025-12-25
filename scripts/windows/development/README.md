# Development Scripts

Scripts that support the development workflow and code quality.

## Scripts

### setup-git-hooks.sh
Sets up Git hooks for automated code quality checks.

**Usage:**
```bash
./setup-git-hooks.sh
```

**Features:**
- Pre-commit: Code formatting and analysis
- Commit-msg: Conventional Commits validation
- Pre-push: Test execution
- Automatic installation and configuration

### bump_version.sh
Manages version numbers using semantic versioning.

**Usage:**
```bash
# Bump patch version (0.0.1 -> 0.0.1)
./bump_version.sh patch

# Bump minor version (0.0.1 -> 0.1.0)
./bump_version.sh minor

# Bump major version (0.0.1 -> 1.0.0)
./bump_version.sh major

# Bump build number only
./bump_version.sh build

# Use custom build number
./bump_version.sh patch 42
```

**Features:**
- Semantic versioning support
- Automatic pubspec.yaml updates
- Build number management
- Cross-platform compatibility

## Git Hooks

The setup-git-hooks.sh script installs the following hooks:

### Pre-commit
- Runs dart format --set-exit-if-changed
- Runs lutter analyze
- Prevents commits with formatting or analysis issues

### Commit-msg
- Validates Conventional Commits format
- Ensures consistent commit message structure
- Supports all standard commit types

### Pre-push
- Runs lutter test
- Prevents pushing code with failing tests

## Conventional Commits

Commit messages must follow this format:
```
<type>(<scope>): <subject>
```

**Types:**
- eat: New feature
- ix: Bug fix
- docs: Documentation
- style: Code style changes
- 
efactor: Code refactoring
- 	est: Test changes
- chore: Maintenance tasks
- perf: Performance improvements
- ci: CI/CD changes

**Examples:**
- eat(auth): add login functionality
- ix(network): handle timeout errors
- docs(readme): update installation guide

