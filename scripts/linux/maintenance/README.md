# Maintenance Scripts

Scripts for project maintenance, documentation, and housekeeping tasks.

## Scripts

### generate_changelog.sh
Automatically generates changelog entries from git commit messages.

**Usage:**
```bash
# Generate changelog for current version
./generate_changelog.sh

# Generate changelog for specific version
./generate_changelog.sh 1.2.0
```

**Features:**
- Conventional Commits parsing
- Automatic categorization by commit type
- CHANGELOG.md integration
- Semantic versioning support
- Git tag integration

## Changelog Generation

### Commit Types Mapping
The script automatically categorizes commits based on their type:

- eat → **Added** section
- ix → **Fixed** section
- security → **Security** section
- perf → **Performance** section
- 
efactor → **Refactored** section
- docs → **Documentation** section
- style → **Style** section
- 	est → **Tests** section
- chore → **Chore** section
- ci → **CI/CD** section
- uild → **Build** section
- 
evert → **Reverted** section

### Changelog Format
The generated changelog follows [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [1.2.0] - 2024-01-15

### Added
- New feature for user authentication
- Support for multiple currencies

### Fixed
- Fixed login timeout issue
- Resolved navigation bug

### Security
- Updated dependencies with security patches
```

### Integration with Release Process
The changelog generation is automatically integrated with the release process:

1. **Version Bump**: ump_version.sh updates version numbers
2. **Changelog Generation**: generate_changelog.sh creates changelog entry
3. **Release Creation**: 
elease.sh commits changes and creates tags

## Best Practices

### Commit Message Guidelines
To ensure high-quality changelogs, follow these commit message guidelines:

1. **Use Conventional Commits format**
2. **Write clear, descriptive subjects**
3. **Include scope when relevant**: eat(auth): add login
4. **Use imperative mood**: "add" not "added"
5. **Keep subject under 50 characters**

### Changelog Maintenance
- Review generated changelog entries before release
- Edit entries for clarity if needed
- Add breaking changes notes manually
- Include migration instructions for major changes

## Automation

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Generate changelog
  run: ./scripts/linux/maintenance/generate_changelog.sh ${{ github.event.release.tag_name }}

- name: Update release notes
  uses: actions/create-release@v1
  with:
    body_path: CHANGELOG.md
```

### Git Hooks Integration
The changelog generation can be integrated with git hooks for automatic updates:

```bash
# Post-commit hook example
#!/bin/bash
if git diff HEAD~1 --name-only | grep -q "pubspec.yaml"; then
  ./scripts/linux/maintenance/generate_changelog.sh
fi
```
