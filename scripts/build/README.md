# Build Scripts

Scripts for building, packaging, and releasing the Grex application.

## Scripts

### build_all.sh
Multi-platform build script that builds for Android, iOS, and Web.

**Usage:**
```bash
# Build for production
./build_all.sh production

# Build with size analysis
./build_all.sh production --analyze-size

# Build for development
./build_all.sh development
```

**Features:**
- Multi-platform support (Android, iOS, Web)
- Environment-specific configurations
- Build size analysis and optimization recommendations
- Automatic cleanup and dependency management

### release.sh
Automated release process that handles version bumping, changelog generation, and deployment.

**Usage:**
```bash
# Create patch release
./release.sh patch

# Create minor release
./release.sh minor

# Create major release
./release.sh major
```

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

- BASE_URL_STAGING: Staging API URL
- BASE_URL_PRODUCTION: Production API URL
- ENVIRONMENT: Target environment (development, staging, production)
