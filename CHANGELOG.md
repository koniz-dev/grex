# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Completed
- ✅ Backend schema with PostgreSQL, RLS, audit logging, real-time subscriptions
- ✅ Complete authentication system with email/password
- ✅ Social login integration (Google OAuth, Apple Sign In) - 98% complete
- ✅ Main app features: groups, expenses, payments, balances, data export
- ✅ Localization standardization across 4 languages (EN, VI, ES, AR)
- ✅ Real-time synchronization with Supabase
- ✅ Comprehensive testing with 87 property-based tests

### In Progress
- 🔄 Social login final device testing (Tasks 22-23)
- 🔄 Production readiness validation

### Known Issues
Findings from the [2026-08-04 code audit](docs/audit/2026-08-04-code-audit.md),
all reproduced against the working tree:

- ❗ **Equal expense splits do not conserve the total** — splitting 100.00 among
  6 or 7 people is rejected outright; other combinations silently lose or gain a
  cent, so balances never settle to zero (F1)
- ❗ **`SplitMethod.exact` is unusable** — any amount with cents throws
  `ArgumentError` after the form has already reported the input as valid (F2)
- ❗ `ExpenseCalculator.validateSplit` returns `false` for correct splits (F3)
- ⚠️ `.env` ships as an app asset while `.env.example` and the key-rotation
  script populate `SUPABASE_SERVICE_ROLE_KEY` into it (F4)
- ⚠️ A fresh clone cannot build — `.env` is gitignored but a required asset (F5)
- ⚠️ `recalculateSplit` corrupts share ratios when an expense amount changes (F6)
- ⚠️ The Dio network layer is unreferenced dead code, though documented as a
  feature (F7)

## [0.0.1] - 2025-12-26

### Added
- Initial release of Grex expense sharing app
- Project structure with Flutter clean architecture
- Supabase integration for backend (PostgreSQL + Auth + Real-time)
- Multi-platform support (Android, iOS, Web, Linux, macOS, Windows)
- Initial deployment documentation
- CI/CD workflows for Android, iOS, and Web
- Helper scripts for version management and releases
- Monitoring and analytics setup guides
- Localization support (Vietnamese and English)
- State management with BLoC pattern
- Secure storage for sensitive data
- Environment configuration system

