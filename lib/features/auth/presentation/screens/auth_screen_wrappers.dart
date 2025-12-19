import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grex/core/di/injection.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/pages/pages.dart';

/// Wrapper for LoginPage that provides BLoC context
class LoginScreenWrapper extends StatelessWidget {
  /// Creates a [LoginScreenWrapper].
  const LoginScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>(),
        ),
      ],
      child: const LoginPage(),
    );
  }
}

/// Wrapper for RegisterPage that provides BLoC context
class RegisterScreenWrapper extends StatelessWidget {
  /// Creates a [RegisterScreenWrapper].
  const RegisterScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>(),
        ),
      ],
      child: const RegisterPage(),
    );
  }
}

/// Wrapper for ForgotPasswordPage that provides BLoC context
class ForgotPasswordScreenWrapper extends StatelessWidget {
  /// Creates a [ForgotPasswordScreenWrapper].
  const ForgotPasswordScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => getIt<AuthBloc>(),
      child: const ForgotPasswordPage(),
    );
  }
}

/// Wrapper for EmailVerificationPage that provides BLoC context
class EmailVerificationScreenWrapper extends StatelessWidget {
  /// Creates an [EmailVerificationScreenWrapper].
  const EmailVerificationScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => getIt<AuthBloc>(),
      child: const EmailVerificationPage(),
    );
  }
}

/// Wrapper for ProfilePage that provides BLoC context
class ProfileScreenWrapper extends StatelessWidget {
  /// Creates a [ProfileScreenWrapper].
  const ProfileScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => getIt<ProfileBloc>(),
        ),
      ],
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
