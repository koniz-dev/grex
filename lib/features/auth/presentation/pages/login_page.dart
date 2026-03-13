import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/entities/user.dart';
import 'package:grex/features/auth/domain/entities/user_profile.dart';
import 'package:grex/features/auth/domain/validators/validators.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/widgets/widgets.dart';

/// Login page for user authentication.
///
/// Implements the login screen design with:
/// - App logo and branding
/// - Email and password fields
/// - Social login options (Google, Apple)
/// - Loading, error, and success states
class LoginPage extends StatefulWidget {
  /// Creates a [LoginPage].
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _onSocialLogin(SocialAuthProvider provider) {
    context.read<AuthBloc>().add(AuthSocialLoginRequested(provider.name));
  }

  void showAccountLinkingDialog({
    required BuildContext context,
    required String email,
    required SocialAuthProvider provider,
    required VoidCallback onLink,
    required VoidCallback onCreateNew,
  }) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AccountLinkingDialog(
          newUser: User(
            id: '',
            email: email,
            createdAt: DateTime.now(),
          ),
          existingProfile: UserProfile(
            id: '',
            email: email,
            displayName: '',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          provider: provider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.replaceWithHome();
            } else if (state is AuthEmailVerificationRequired) {
              context.goToEmailVerification();
            } else if (state is AuthProfileSetupRequired) {
              context.goToProfileSetup(
                user: state.user,
                provider: state.provider,
                displayName: state.displayName,
                email: state.email,
              );
            } else if (state is AuthAccountLinkingRequired) {
              showAccountLinkingDialog(
                context: context,
                email: state.existingProfile.email,
                provider: state.provider,
                onLink: () {
                  context.read<AuthBloc>().add(
                    AuthAccountLinkingConfirmed(state.existingProfile.id),
                  );
                },
                onCreateNew: () {
                  context.read<AuthBloc>().add(
                    const AuthAccountLinkingDeclined(),
                  );
                },
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Spacer
                  const SizedBox(height: 60),

                  // Logo section
                  const AppLogo(),
                  const SizedBox(height: 32),

                  // Title section
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form section
                  AuthTextField(
                    label: 'Email',
                    placeholder: 'your@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: InputValidators.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    label: 'Password',
                    placeholder: '••••••••',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _onLoginPressed(),
                  ),
                  const SizedBox(height: 16),

                  // Forgot password link
                  GestureDetector(
                    onTap: () => context.goToForgotPassword(),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading =
                          state is AuthLoading ||
                          state is AuthSocialLoginInProgress;
                      return PrimaryButton(
                        text: 'Sign In',
                        isLoading: state is AuthLoading,
                        onPressed: isLoading ? null : _onLoginPressed,
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Or divider
                  const OrDivider(),
                  const SizedBox(height: 12),

                  // Social login buttons
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading =
                          state is AuthLoading ||
                          state is AuthSocialLoginInProgress;
                      final isGoogleLoading =
                          state is AuthSocialLoginInProgress &&
                          state.provider == SocialAuthProvider.google;

                      return SocialLoginButton(
                        provider: SocialAuthProvider.google,
                        onPressed: isLoading
                            ? null
                            : () => _onSocialLogin(SocialAuthProvider.google),
                        isLoading: isGoogleLoading,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading =
                          state is AuthLoading ||
                          state is AuthSocialLoginInProgress;
                      final isAppleLoading =
                          state is AuthSocialLoginInProgress &&
                          state.provider == SocialAuthProvider.apple;

                      return SocialLoginButton(
                        provider: SocialAuthProvider.apple,
                        onPressed: isLoading
                            ? null
                            : () => _onSocialLogin(SocialAuthProvider.apple),
                        isLoading: isAppleLoading,
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Error display
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthError) {
                        // Check if it's a social auth error
                        if (state.failure != null &&
                            (state.failure is SocialAuthFailure ||
                                state.failure is SocialAuthCancelledFailure ||
                                state.failure is SocialAuthNetworkFailure ||
                                state.failure is SocialAuthTimeoutFailure ||
                                state.failure is AccountLinkingFailure)) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: SocialAuthErrorWidget(
                              failure: state.failure!,
                              onRetry: () {
                                // Retry the last attempted social login
                                // This would need to be tracked in the BLoC
                                // state
                              },
                              onFallback: () {
                                // Focus on email field for fallback
                                FocusScope.of(context).requestFocus();
                              },
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: ErrorBanner(message: state.message),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Register prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.goToRegister(),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
