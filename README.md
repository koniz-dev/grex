# 🚀 Grex

A production-ready Grex project with **Clean Architecture**, enterprise-grade configuration management, and comprehensive developer tooling.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-160%20files-success)](test/)
[![Architecture](https://img.shields.io/badge/architecture-Clean%20Architecture-blue)](docs/architecture/)
[![codecov](https://codecov.io/gh/koniz-dev/grex/graph/badge.svg?token=WJ4JJ4D20V)](https://codecov.io/gh/koniz-dev/grex)

## ✨ Features

### 🏗️ Architecture & Code Quality
- ✅ **Clean Architecture** - Separation of concerns with Domain, Data, and Presentation layers
- ✅ **State Management** - BLoC for feature logic, Riverpod for infrastructure and
  routing, GetIt for repositories — see
  [docs/architecture/state-management.md](docs/architecture/state-management.md)
- ✅ **Code Generation** - Freezed for immutable classes and JSON serialization
- ✅ **Linting** - Very Good Analysis (`flutter analyze` is clean)
- ✅ **Testing** - 160 test files including property-based tests (100+ iterations each)

### ⚙️ Configuration & Environment
- ✅ **Multi-Environment Support** - Development, Staging, Production
- ✅ **Flexible Configuration** - `.env` files for local dev, `--dart-define` for CI/CD
- ✅ **Feature Flags** - Local and remote (Firebase Remote Config) feature flags
- ✅ **Environment-Aware Defaults** - Smart defaults based on environment
- ✅ **Type-Safe Configuration** - Typed getters with fallback chain

### 🌐 Internationalization
- ✅ **Multi-Language Support** - English, Vietnamese, Spanish, Arabic
- ✅ **RTL Support** - Right-to-left language support for Arabic
- ✅ **Locale Persistence** - Save and restore user language preference
- ✅ **Standardized Localization** - Context extension for easy access (`context.l10n`)

### 🔐 Security & Storage
- ✅ **Secure Storage** - Flutter Secure Storage for sensitive data
- ✅ **Shared Preferences** - Simple key-value storage for non-sensitive data
- ✅ **Storage Migration** - Version-based storage migration system
- ✅ **Error Handling** - Comprehensive error handling with custom exceptions

### 🔐 Authentication & Social Login
- ✅ **Email/Password Authentication** - Complete auth system with email verification
- ✅ **Social Login** - Google OAuth and Apple Sign In integration (98% complete)
- ✅ **Account Linking** - Link social providers to existing accounts
- ✅ **Profile Setup** - Guided profile completion for new social users
- ✅ **Deep Link Handling** - OAuth callback processing with performance optimization
- ✅ **Session Management** - Persistent sessions across app restarts
- ✅ **Security Compliance** - HTTPS-only, minimal scopes, secure token storage

### 💰 Expense Sharing Features
- ✅ **Group Management** - Create and manage expense groups with role-based permissions
- ✅ **Expense Tracking** - Record expenses with 4 split methods (equal, percentage, exact, shares)
- ✅ **Payment Recording** - Track payments between group members
- ✅ **Balance Calculation** - Real-time balance calculations with settlement plan generation
- ✅ **Data Export** - Export group data in CSV/PDF formats
- ✅ **Search & Filter** - Advanced search and filtering across expenses

### 🌐 Network Layer — ⚠️ scaffolding, not wired up
All data access goes through the Supabase client directly. The Dio layer below
is built but **not referenced by any repository** (`apiClientProvider` has no
callers). Keep it only if you plan to call non-Supabase APIs; see
[F7 in the code audit](docs/audit/2026-08-04-code-audit.md#f7--the-dio-network-layer-is-dead-code-medium).
- 🚧 **HTTP Client** - Dio with interceptors support
- 🚧 **Configurable Timeouts** - Environment-based timeout configuration
- 🚧 **Request/Response Logging** - Debug-friendly HTTP logging
- 🚧 **Error Interceptors** - Automatic error handling and conversion
- 🚧 **Auth Interceptors** - Automatic token injection and refresh

### 🎨 UI & UX
- ✅ **Material Design** - Material 3 theme support
- ✅ **Dark Mode** - Built-in dark theme support
- ✅ **Accessibility** - Semantic labels and accessibility support
- ✅ **Responsive Design** - Adaptive layouts for different screen sizes

### 🧭 Routing & Navigation
- ✅ **Type-Safe Routing** - GoRouter with type-safe route definitions
- ✅ **Deep Linking** - Support for deep links and URL navigation
- ✅ **Auth-Based Routing** - Protected routes with authentication redirects
- ✅ **Navigation Logging** - Automatic route tracking and logging

### 📊 Logging & Monitoring
- ✅ **Comprehensive Logging** - Multi-level logging with file and console output
- ✅ **Log Rotation** - Automatic log file rotation
- ✅ **Structured Logging** - JSON formatting for production
- ✅ **Performance Monitoring** - Firebase Performance integration
- ✅ **Screen Tracking** - Automatic screen load time tracking

### 🚀 Deployment & CI/CD
- ✅ **Multi-Platform** - Android, iOS, Web, Linux, macOS, Windows support
- ✅ **CI/CD Ready** - GitHub Actions workflows included (disabled by default, uncomment triggers to enable)
- ✅ **Version Management** - Automated version bumping scripts
- ✅ **Fastlane Integration** - iOS and Android deployment automation

### 📚 Documentation
- ✅ **Comprehensive Docs** - Architecture, guides, API documentation
- ✅ **Migration Guides** - From MVC, GetX, Bloc, and other architectures
- ✅ **Best Practices** - Code examples and patterns
- ✅ **API Documentation** - Complete API reference
- ✅ **Example Features** - Complete features demonstrating Clean Architecture (Auth, Groups, Expenses, Balances, etc.)

### 🧪 Testing
- ✅ **160 Test Files** - 1308 passing, 572 skipped, 0 failing (2026-08-04)
- ✅ **Unit Tests** - Domain and data layer testing
- ✅ **Widget Tests** - UI component testing
- ✅ **Integration Tests** - End-to-end flow testing
- ✅ **Test Helpers** - Reusable test utilities and fixtures

## 🛠️ Tech Stack

### Core Dependencies
- **Flutter** - UI framework
- **flutter_bloc** - State management for all feature logic (auth, groups, expenses, payments, balances)
- **Riverpod** - Infrastructure providers, routing, and the auth→router bridge
- **GetIt** - Service locator for repositories and BLoC construction
- **Supabase** - PostgreSQL, Auth, and Realtime backend (all data access goes through it)
- **Dio** - HTTP client (scaffolding only — currently unused, see Network Layer above)
- **Freezed** - Code generation for immutable classes
- **Equatable** - Value equality comparison

### Firebase
- **Firebase Core** - Firebase initialization
- **Firebase Remote Config** - Remote feature flags
- **Firebase Performance** - Performance monitoring and tracking

### Storage
- **flutter_secure_storage** - Secure storage for sensitive data
- **shared_preferences** - Simple key-value storage

### Localization
- **flutter_localizations** - Flutter localization support
- **intl** - Internationalization utilities

### Routing & Navigation
- **go_router** - Declarative routing with deep linking

### Logging & Monitoring
- **logger** - Comprehensive logging solution
- **path_provider** - File system access for log files

### Development Tools
- **build_runner** - Code generation runner
- **very_good_analysis** - Linting rules
- **mocktail** - Testing and mocking

## 📁 Project Structure

```
lib/
├── core/                    # Core infrastructure
│   ├── config/             # Configuration system
│   ├── constants/          # App constants
│   ├── di/                 # Dependency injection (Riverpod providers + GetIt)
│   ├── errors/             # Error handling
│   ├── feature_flags/      # Feature flags infrastructure
│   ├── localization/       # Localization service
│   ├── logging/            # Logging service
│   ├── network/            # Network layer (Dio setup)
│   ├── performance/        # Performance monitoring
│   ├── routing/            # Routing system (go_router)
│   ├── storage/            # Storage services (with migration)
│   └── utils/              # Utility functions
│
├── features/                # Feature modules (Clean Architecture)
│   ├── auth/               # Authentication feature with social login
│   │   ├── data/          # Data layer (models, data sources, repositories)
│   │   │   ├── handlers/  # OAuth deep link handlers
│   │   │   ├── models/    # User, profile, social auth models
│   │   │   └── repositories/ # Social auth and user repositories
│   │   ├── domain/        # Domain layer (entities, use cases, repository interfaces)
│   │   │   ├── entities/  # User, SocialAuthProvider, ProfileSetupData
│   │   │   └── repositories/ # SocialAuthRepository interface
│   │   └── presentation/  # Presentation layer (screens, widgets, providers)
│   │       ├── pages/     # Login, register, profile setup pages
│   │       └── widgets/   # Social login buttons, dialogs, error widgets
│   ├── feature_flags/      # Feature flags feature
│   │   └── presentation/   # Feature flags UI
│   ├── groups/             # Group management
│   ├── expenses/           # Expense tracking
│   ├── payments/           # Built-in payments tracking
│   ├── balances/           # Balance calculation engine
│   └── export/             # Data export utilities
│
├── shared/                  # Shared resources
│   ├── accessibility/      # Accessibility utilities
│   ├── extensions/         # Dart extensions
│   ├── theme/              # App theme configuration
│   └── widgets/            # Reusable widgets
│
├── l10n/                   # Localization files (generated)
└── main.dart               # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code with Flutter extensions
- Xcode (for iOS development on macOS)

### Local Development with Supabase

For fully offline development using a local Supabase instance:

1. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Start local Supabase**
   ```bash
   supabase start
   ```
   The CLI will print the API URL and anon key once running.

3. **Configure `.env` for local**
   ```env
   ENVIRONMENT=development
   SUPABASE_URL=http://localhost:54321
   SUPABASE_ANON_KEY=<anon key from supabase start output>
   ```
   > The default anon key is already available in `.env.example` under `SUPABASE_LOCAL_ANON_KEY`.

4. **Apply migrations (if any)**
   ```bash
   supabase db reset
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

6. **Stop local Supabase when done**
   ```bash
   supabase stop
   ```

> **Note**: When using Android Emulator, replace `localhost` with `10.0.2.2`:
> ```env
> SUPABASE_URL=http://10.0.2.2:54321
> ```

---

### Installation

1. **Create repository from template** (if using GitHub template)
   - Click "Use this template" button on GitHub
   - Create a new repository from this template
   - Clone your new repository:
   ```bash
   git clone <your-repository-url>
   cd <your-project-name>
   ```

   **OR clone directly** (if not using template):
   ```bash
   git clone <repository-url>
   cd grex
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (Freezed, JSON serialization)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Set up environment configuration** — **required, the build fails without it**
   ```bash
   # Copy the example environment file
   cp .env.example .env
   
   # Edit .env with your configuration — at minimum SUPABASE_URL and
   # SUPABASE_ANON_KEY. See Configuration System section below.
   ```

   `.env` is gitignored but declared as a Flutter asset in `pubspec.yaml`, so a
   fresh clone without it fails at bundle time with
   `No file or variants found for asset: .env` — before any Dart code runs.
   Creating the file (even empty) is mandatory; `--dart-define` alone is not
   enough. See [SETUP.md](SETUP.md).

   > ⚠️ Do **not** put `SUPABASE_SERVICE_ROLE_KEY` in `.env`. Because `.env`
   > ships as an app asset, that key would be extractable from any release
   > build and bypasses all RLS. See
   > [F4 in the code audit](docs/audit/2026-08-04-code-audit.md#f4--env-is-bundled-into-the-app-while-documenting-a-service-role-key-high).

5. **Set up Git hooks** (optional but recommended)
   
   **Linux/macOS:**
   ```bash
   ./scripts/linux/development/setup-git-hooks.sh
   ```
   
   **Windows:**
   ```powershell
   .\scripts\windows\development\setup-git-hooks.ps1
   ```
   This will install Git hooks for:
   - Code formatting checks (pre-commit)
   - Commit message validation (commit-msg)
   - Test execution (pre-push)

6. **Run the app**
   ```bash
   flutter run
   ```

### Social Login Setup

The app includes comprehensive social login integration with Google OAuth and Apple Sign In.

#### OAuth Provider Configuration

1. **Google OAuth Setup**:
   - Create OAuth 2.0 Client ID in [Google Cloud Console](https://console.cloud.google.com/)
   - Add authorized redirect URIs: `https://[project-id].supabase.co/auth/v1/callback`
   - Configure in Supabase Dashboard → Authentication → Providers

2. **Apple Sign In Setup**:
   - Create Services ID in [Apple Developer Portal](https://developer.apple.com/)
   - Configure Sign In with Apple
   - Generate private key (.p8 file)
   - Configure in Supabase Dashboard → Authentication → Providers

#### Deep Link Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.grex"
          android:host="login-callback" />
</intent-filter>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>io.supabase.grex</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.grex</string>
        </array>
    </dict>
</array>
```

#### Features

- **OAuth Integration**: Google and Apple OAuth with external browser launch
- **Account Linking**: Link social providers to existing email accounts
- **Profile Setup**: Guided profile completion for new social users
- **Deep Link Handling**: Fast OAuth callback processing (< 1 second)
- **Session Management**: Persistent sessions with automatic refresh
- **Error Handling**: User-friendly error messages with retry options
- **Localization**: Multi-language support for all social login UI
- **Security**: HTTPS-only, minimal scopes, secure token storage
- **Performance**: OAuth flow completion < 5 seconds after authorization

For detailed implementation guide, see [Social Login Developer Guide](docs/social-login-developer-guide.md).

### First Steps

1. **Rename the project** (if needed) - Update package name from `grex` to your project name
2. **Configure your environment** - See [Configuration System](#-configuration-system) below
3. **Set up Firebase** (optional) - For remote feature flags and performance monitoring
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Initialize Firebase in your app
4. **Customize the theme** - Edit `lib/shared/theme/app_theme.dart`
5. **Explore example features** - Check out `lib/features/` for examples:
   - **Auth** - Authentication flow with social login
   - **Groups & Expenses** - Core expense sharing implementation
   - **Feature Flags** - Conditional UI rendering based on flags
6. **Add your first feature** - Follow the pattern in example features
7. **Read the documentation** - Check out `docs/` folder for detailed guides

## ⚙️ Configuration System

This project includes a production-ready, multi-environment configuration system that supports:

- **Local Development**: `.env` files for easy local configuration
- **CI/CD**: `--dart-define` flags for build-time configuration
- **Fallback Chain**: `.env` → `--dart-define` → defaults
- **Environment-Aware Defaults**: Different configurations per environment
- **Feature Flags**: Enable/disable features per environment
- **Network Configuration**: Timeout settings for API calls
- **Debug Utilities**: Tools for inspecting configuration

### Architecture

The configuration system consists of two main classes:

1. **`EnvConfig`** (`lib/core/config/env_config.dart`): Low-level environment variable loader
   - Loads from `.env` files using `flutter_dotenv`
   - Reads from `--dart-define` flags
   - Provides fallback chain: `.env` → `--dart-define` → defaults

2. **`AppConfig`** (`lib/core/config/app_config.dart`): High-level application configuration
   - Uses `EnvConfig` to get values
   - Provides typed getters (String, bool, int)
   - Environment-aware defaults
   - Feature flags
   - Network timeout configuration
   - Debug utilities

### Setup

#### 1. Create `.env` file for local development

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your values
# The .env file is gitignored and won't be committed
```

#### 2. Configure your environment variables

Edit `.env` with your configuration:

```env
ENVIRONMENT=development
BASE_URL=http://localhost:3000
ENABLE_LOGGING=true
ENABLE_ANALYTICS=false
```

### Usage Examples

#### Local Development (using `.env` file)

1. Create `.env` file from `.env.example`
2. Fill in your values
3. Run the app normally:

```bash
flutter run
```

The app will automatically load values from `.env`.

#### Staging Build (using `--dart-define`)

For CI/CD or when you don't want to use `.env` files:

```bash
flutter run \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=BASE_URL=https://api-staging.example.com \
  --dart-define=ENABLE_ANALYTICS=true
```

#### Production Build (using `--dart-define`)

```bash
flutter build apk \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BASE_URL=https://api.example.com \
  --dart-define=ENABLE_ANALYTICS=true \
  --dart-define=ENABLE_CRASH_REPORTING=true
```

### Using Configuration in Code

#### Basic Usage

```dart
import 'package:grex/core/config/app_config.dart';

// Get environment
final env = AppConfig.environment; // 'development', 'staging', or 'production'

// Check environment
if (AppConfig.isDevelopment) {
  // Development-specific code
}

// Get API base URL
final baseUrl = AppConfig.baseUrl;

// Check feature flags
if (AppConfig.enableLogging) {
  logger.info('App started');
}

if (AppConfig.enableAnalytics) {
  analytics.trackEvent('app_opened');
}
```

#### Network Configuration

```dart
import 'package:grex/core/config/app_config.dart';
import 'package:dio/dio.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: Duration(seconds: AppConfig.apiConnectTimeout),
    receiveTimeout: Duration(seconds: AppConfig.apiReceiveTimeout),
    sendTimeout: Duration(seconds: AppConfig.apiSendTimeout),
  ),
);
```

#### Debug Utilities

```dart
import 'package:grex/core/config/app_config.dart';

// Print configuration to console (only in debug mode)
AppConfig.printConfig();

// Get configuration as a map
final config = AppConfig.getDebugInfo();
print(config);
```

### Available Configuration Options

#### Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENVIRONMENT` | String | `development` | Environment name: `development`, `staging`, or `production` |
| `BASE_URL` | String | Environment-aware | API base URL (see defaults below) |
| `API_TIMEOUT` | int | `30` | API timeout in seconds |
| `API_CONNECT_TIMEOUT` | int | `10` | API connect timeout in seconds |
| `API_RECEIVE_TIMEOUT` | int | `30` | API receive timeout in seconds |
| `API_SEND_TIMEOUT` | int | `30` | API send timeout in seconds |
| `ENABLE_LOGGING` | bool | Environment-aware | Enable logging (default: true in dev/staging) |
| `ENABLE_ANALYTICS` | bool | Environment-aware | Enable analytics (default: true in staging/prod) |
| `ENABLE_CRASH_REPORTING` | bool | Environment-aware | Enable crash reporting (default: true in staging/prod) |
| `ENABLE_PERFORMANCE_MONITORING` | bool | Environment-aware | Enable performance monitoring (default: true in staging/prod) |
| `ENABLE_DEBUG_FEATURES` | bool | Environment-aware | Enable debug features (default: true in dev) |
| `ENABLE_HTTP_LOGGING` | bool | Environment-aware | Enable HTTP request/response logging (default: true in dev) |
| `APP_VERSION` | String | `0.0.1` | App version |
| `APP_BUILD_NUMBER` | String | `1` | App build number |

#### Environment-Aware Defaults

**BASE_URL defaults:**
- Development: `http://localhost:3000`
- Staging: `https://api-staging.example.com`
- Production: `https://api.example.com`

**Feature Flag defaults:**
- Logging: Enabled in `development` and `staging`
- Analytics: Enabled in `staging` and `production`
- Crash Reporting: Enabled in `staging` and `production`
- Performance Monitoring: Enabled in `staging` and `production`
- Debug Features: Enabled in `development` only
- HTTP Logging: Enabled in `development` only

### Best Practices

1. **Never commit `.env` files**: They contain sensitive information and are gitignored
2. **Use `.env.example` as a template**: Commit this file with placeholder values
3. **Use `.env` for local development**: Easy to change values without rebuilding
4. **Use `--dart-define` for CI/CD**: More secure and doesn't require file management
5. **Set environment-specific defaults**: Let the system handle defaults based on environment
6. **Use feature flags**: Enable/disable features per environment without code changes

### Troubleshooting

#### Configuration not loading

1. Ensure `EnvConfig.load()` is called in `main()` before `runApp()`
2. Check that `.env` file exists in the project root
3. Verify `pubspec.yaml` includes `.env` in assets
4. Run `flutter pub get` after adding `flutter_dotenv`

#### Values not updating

1. Hot reload doesn't reload environment variables - do a full restart
2. For `--dart-define` values, rebuild the app
3. Check that you're using the correct variable name (case-sensitive)

#### Debug configuration

Use `AppConfig.printConfig()` in debug mode to see all configuration values:

```dart
if (AppConfig.isDebugMode) {
  AppConfig.printConfig();
}
```

This will print all configuration values to the console, helping you verify what values are being used.

## 🧪 Testing

### Run Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/auth/domain/usecases/login_test.dart
```

### Test Structure

Tests follow the same structure as the source code:
- **160 test files** — 1308 passing, 572 skipped, 0 failing (2026-08-04)
- Unit tests for use cases and utilities
- Widget tests for UI components
- Integration tests for end-to-end flows
- **Property-based tests** for social login (35 properties with 100+ iterations each)
- Test helpers and fixtures for reusable test utilities

#### Social Login Testing

The social login feature includes extensive testing:

```bash
# Run social login tests specifically
flutter test test/features/auth/data/repositories/social_auth_repository_test.dart
flutter test test/features/auth/presentation/widgets/social_login_button_test.dart

# Run property-based tests (100+ iterations each)
flutter test test/features/auth/property_tests/
```

**Property Tests Include**:
- OAuth flow completion within performance requirements
- Profile setup data preservation
- Account linking detection and handling
- Session persistence across app restarts
- Error handling for all failure scenarios

### Test Coverage

The project includes:
- ✅ Domain layer tests (use cases, entities)
- ✅ Data layer tests (repositories, data sources, models)
- ✅ Presentation layer tests (screens, widgets, providers)
- ✅ Core infrastructure tests (config, network, storage, logging, performance)
- ✅ Integration tests for complete flows

## 🏗️ Building

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

### Web

```bash
# Debug
flutter build web --debug

# Release
flutter build web --release
```

## 📚 Documentation

### Architecture

- **[Architecture Documentation](docs/architecture/README.md)** - Complete architecture documentation index
- **[Architecture Overview](docs/architecture/overview.md)** - Why Clean Architecture, benefits, trade-offs, and learning resources
- **[Design Decisions](docs/architecture/design-decisions.md)** - Detailed rationale for routing, state management, error handling, logging, storage, and HTTP client choices

### Guides

- **[Getting Started](docs/guides/getting-started.md)** - Step-by-step setup guide
- **[Understanding the Codebase](docs/guides/understanding-codebase.md)** - Architecture and patterns
- **[Common Tasks](docs/guides/common-tasks.md)** - Frequently performed tasks
- **[Routing Guide](docs/guides/routing.md)** - GoRouter navigation and deep linking
- **[Git Hooks Setup](docs/guides/git-hooks-setup.md)** - Setup Git hooks for code quality (similar to Husky)
- **[Adding Features](docs/api/examples/adding-features.md)** - How to add new features

### Migration Guides

- **[From MVC to Clean Architecture](docs/guides/migration/from-mvc-to-clean-architecture.md)**
- **[From GetX to This Setup](docs/guides/migration/from-getx-to-this-setup.md)**
- **[Customization Guide](docs/guides/migration/customization-guide.md)**

### Features

- **[Social Login](docs/social-login-developer-guide.md)** - Complete social login implementation guide
- **[Feature Flags](docs/features/feature-flags.md)** - Feature flags system documentation
- **[Expense Sharing Engine]** - Core sharing models
  - **[Groups](docs/features/groups.md)** - Group management
  - **[Expenses](docs/features/expenses.md)** - Expense tracking
  - **[Balances](docs/features/balances.md)** - Real-time calculation engine
  - **[Payments](docs/features/payments.md)** - P2P payment tracking
  - **[Export](docs/features/export.md)** - Data export utilities
- **[Localization](docs/guides/internationalization-guide.md)** - i18n setup and usage
- **[Logging](docs/guides/README.md)** - Logging system documentation
- **[Performance](docs/guides/performance/README.md)** - Performance monitoring guides
- **[Routing](docs/guides/routing.md)** - Routing and navigation guide

### Deployment

- **[Deployment Guide](docs/deployment/deployment.md)** - Complete deployment documentation
- **[Quick Start](docs/deployment/quick-start.md)** - Get started in 5 minutes
- **[Android Deployment](docs/deployment/android-deployment.md)** - Android-specific guide
- **[iOS Deployment](docs/deployment/ios-deployment.md)** - iOS-specific guide
- **[Web Deployment](docs/deployment/web-deployment.md)** - Web-specific guide
- **[Release Process](docs/deployment/release-process.md)** - Version management and releases
- **[Monitoring & Analytics](docs/deployment/monitoring-analytics.md)** - Crashlytics and analytics setup

### API Documentation

- **[API Overview](docs/api/README.md)** - API documentation index
- **[Examples](docs/api/examples/)** - Code examples and patterns

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- How to report bugs
- How to suggest enhancements
- Development setup and workflow
- Coding standards and guidelines
- Testing requirements
- Commit message conventions

### Quick Start

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following our [coding standards](CONTRIBUTING.md#coding-standards)
4. Write or update tests
5. Commit your changes using [conventional commits](CONTRIBUTING.md#commit-message-guidelines)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

For detailed guidelines, please read [CONTRIBUTING.md](CONTRIBUTING.md).

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - The framework
- [Riverpod](https://riverpod.dev) - State management
- [Very Good Ventures](https://verygood.ventures) - Linting rules and best practices
- [Freezed](https://pub.dev/packages/freezed) - Code generation

## 📞 Support

For questions, issues, or contributions, please open an issue on GitHub.

---

**Made with ❤️ using Flutter**
