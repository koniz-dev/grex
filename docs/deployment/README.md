# Deployment Documentation

Complete deployment documentation for Grex across all platforms.

> ⚠️ **Before any production submission, work through
> [pre-deployment-checklist.md](./pre-deployment-checklist.md).**
> The repo still uses the Flutter scaffolding package name
> `com.example.grex`, a placeholder Firebase config, and `.env.example`
> values in CI — none of those will fly on the App Store or Play Store.

## Quick Start

1. **Pre-deployment checklist**:
   [pre-deployment-checklist.md](./pre-deployment-checklist.md)
2. **Read the main guide**: [deployment.md](./deployment.md)
3. **Platform-specific guides**:
   - [Android Deployment](./android-deployment.md)
   - [iOS Deployment](./ios-deployment.md)
   - [Web Deployment](./web-deployment.md)
4. **Release process**: [release-process.md](./release-process.md)
5. **Monitoring setup**: [monitoring-analytics.md](./monitoring-analytics.md)

## Documentation Structure

```
docs/deployment/
├── README.md                       # This file
├── pre-deployment-checklist.md     # Things to settle BEFORE first prod build
├── deployment.md                   # Main deployment guide
├── android-deployment.md           # Android-specific guide
├── ios-deployment.md               # iOS-specific guide
├── web-deployment.md               # Web-specific guide
├── release-process.md              # Release workflow
└── monitoring-analytics.md         # Monitoring setup
```

## CI/CD Workflows

GitHub Actions workflows are located in `.github/workflows/`:

- **test.yml**: Tests + analyze + coverage on push/PR to main
- **ci.yml**: Manual dev builds (APK/iOS/web artifacts)
- **deploy-android.yml**: Android deployment to Play Store (template — see
  per-file activation checklist at the top of the workflow)
- **deploy-ios.yml**: iOS deployment to App Store (template)
- **deploy-web.yml**: Web deployment to Firebase / Netlify / Vercel
  (template, pick one platform)

For workflow configuration, see the [Deployment Guide](./deployment.md#cicd-pipeline) section.

## Helper Scripts

Scripts are located in `scripts/`:

- **bump_version.sh**: Bump version in pubspec.yaml
- **generate_changelog.sh**: Generate changelog from git commits
- **release.sh**: Complete release automation
- **build_all.sh**: Build for all platforms

## Getting Help

- Check platform-specific guides for detailed instructions
- Review [Troubleshooting Guide](../guides/support/troubleshooting.md)
- Check GitHub Actions logs for CI/CD issues

## Next Steps

1. Set up code signing (Android & iOS)
2. Configure GitHub Actions secrets
3. Set up Firebase projects
4. Test build process locally
5. Create your first release

