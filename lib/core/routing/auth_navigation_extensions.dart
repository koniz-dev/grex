import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/app_routes.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/entities/user.dart';

/// Arguments for profile setup page navigation
class ProfileSetupArgs {
  /// Creates [ProfileSetupArgs] with required parameters.
  const ProfileSetupArgs({
    required this.user,
    required this.provider,
    required this.email,
    this.displayName,
  });

  /// The authenticated user from social login
  final User user;

  /// The social authentication provider used
  final SocialAuthProvider provider;

  /// Pre-filled display name from OAuth provider (optional)
  final String? displayName;

  /// Pre-filled email from OAuth provider
  final String email;
}

/// Navigation extensions for authentication flows
extension AuthNavigationExtensions on BuildContext {
  /// Navigate to login page
  void goToLogin() {
    go(AppRoutes.login);
  }

  /// Navigate to register page
  void goToRegister() {
    go(AppRoutes.register);
  }

  /// Navigate to forgot password page
  void goToForgotPassword() {
    go(AppRoutes.forgotPassword);
  }

  /// Navigate to email verification page
  void goToEmailVerification() {
    go(AppRoutes.emailVerification);
  }

  /// Navigate to profile setup page for social login users
  void goToProfileSetup({
    required User user,
    required SocialAuthProvider provider,
    required String email,
    String? displayName,
  }) {
    go(
      AppRoutes.profileSetup,
      extra: ProfileSetupArgs(
        user: user,
        provider: provider,
        displayName: displayName,
        email: email,
      ),
    );
  }

  /// Navigate to profile page
  void goToProfile() {
    go(AppRoutes.profile);
  }

  /// Navigate to edit profile page
  void goToEditProfile() {
    go(AppRoutes.editProfile);
  }

  /// Navigate to home page (after successful authentication)
  void goToHome() {
    go(AppRoutes.home);
  }

  /// Navigate back or to home if no previous route
  void goBackOrHome() {
    if (canPop()) {
      pop();
    } else {
      goToHome();
    }
  }

  /// Replace current route with login (for logout)
  void replaceWithLogin() {
    go(AppRoutes.login);
  }

  /// Replace current route with home (for successful login)
  void replaceWithHome() {
    go(AppRoutes.home);
  }
}
