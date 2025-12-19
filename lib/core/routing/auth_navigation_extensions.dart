import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:grex/core/routing/app_routes.dart';

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
