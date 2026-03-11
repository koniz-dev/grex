import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grex/core/di/injection.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/pages/pages.dart';

/// Wrapper for LoginPage. AuthBloc is provided at app root.
class LoginScreenWrapper extends StatelessWidget {
  /// Creates a [LoginScreenWrapper].
  const LoginScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

/// Wrapper for RegisterPage. AuthBloc is provided at app root.
class RegisterScreenWrapper extends StatelessWidget {
  /// Creates a [RegisterScreenWrapper].
  const RegisterScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegisterPage();
  }
}

/// Wrapper for ForgotPasswordPage. AuthBloc is provided at app root.
class ForgotPasswordScreenWrapper extends StatelessWidget {
  /// Creates a [ForgotPasswordScreenWrapper].
  const ForgotPasswordScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const ForgotPasswordPage();
  }
}

/// Wrapper for EmailVerificationPage. AuthBloc is provided at app root.
class EmailVerificationScreenWrapper extends StatelessWidget {
  /// Creates an [EmailVerificationScreenWrapper].
  const EmailVerificationScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmailVerificationPage();
  }
}

/// Wrapper for ProfilePage that provides ProfileBloc. AuthBloc is at app root.
class ProfileScreenWrapper extends StatelessWidget {
  /// Creates a [ProfileScreenWrapper].
  const ProfileScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) => getIt<ProfileBloc>(),
      child: const ProfilePage(),
    );
  }
}

/// Wrapper for EditProfilePage that provides BLoC context
class EditProfileScreenWrapper extends StatelessWidget {
  /// Creates an [EditProfileScreenWrapper].
  const EditProfileScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) => getIt<ProfileBloc>(),
      child: const EditProfilePage(),
    );
  }
}
