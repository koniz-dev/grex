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

/// Registration page for new user sign up.
///
/// Implements the register screen design with:
/// - Display name, email, password fields
/// - Currency selector
/// - Social login options (Google, Apple)
/// - Password requirements hint
class RegisterPage extends StatefulWidget {
  /// Creates a [RegisterPage].
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedCurrency = 'VND';

  final List<Map<String, String>> _currencies = [
    {'code': 'VND', 'name': 'VND - Vietnamese Dong'},
    {'code': 'USD', 'name': 'USD - US Dollar'},
    {'code': 'EUR', 'name': 'EUR - Euro'},
    {'code': 'GBP', 'name': 'GBP - British Pound'},
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
          preferredCurrency: _selectedCurrency,
          languageCode: 'en', // Default language
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
            if (state is AuthEmailVerificationRequired) {
              context.goToEmailVerification();
            } else if (state is AuthAuthenticated) {
              context.replaceWithHome();
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
                  const SizedBox(height: 40),

                  // Title section
                  const Text(
                    'Create Account',
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
                    'Join Grex to start splitting expenses',
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
                    label: 'Display Name',
                    placeholder: 'Your name',
                    controller: _displayNameController,
                    textInputAction: TextInputAction.next,
                    validator: InputValidators.validateDisplayName,
                  ),
                  const SizedBox(height: 16),

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
                    placeholder: 'Min. 8 characters',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: InputValidators.validatePassword,
                    onFieldSubmitted: (_) => _onRegisterPressed(),
                  ),
                  const SizedBox(height: 8),

                  // Password hint
                  const Text(
                    'Must be at least 8 characters with mixed case and numbers',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFFA1A1AA),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Currency selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferred Currency',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF71717A),
                              size: 20,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                            items: _currencies.map((currency) {
                              return DropdownMenuItem<String>(
                                value: currency['code'],
                                child: Text(currency['name']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCurrency = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading =
                          state is AuthLoading ||
                          state is AuthSocialLoginInProgress;
                      return PrimaryButton(
                        text: 'Create Account',
                        isLoading: state is AuthLoading,
                        onPressed: isLoading ? null : _onRegisterPressed,
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

                  // Login prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.goToLogin(),
                        child: const Text(
                          'Sign In',
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
