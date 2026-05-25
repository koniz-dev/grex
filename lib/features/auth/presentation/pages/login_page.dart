import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/entities/user.dart';
import 'package:grex/features/auth/domain/entities/user_profile.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/widgets/widgets.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/utils/locale_defaults.dart';

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

  String? _validateEmail(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.emailRequired;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.emailInvalid;
    }
    return null;
  }

  String? _validatePassword(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 8) {
      return l10n.passwordMinLength(8);
    }
    return null;
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
            preferredCurrency: LocaleDefaults.currencyCode,
            languageCode: LocaleDefaults.languageCode,
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
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        l10n.welcomeBack,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.signInToContinue,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: l10n.email,
                        placeholder: l10n.enterYourEmail,
                        fieldKey: const Key('email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) => _validateEmail(l10n, value),
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        label: l10n.password,
                        placeholder: l10n.enterYourPassword,
                        fieldKey: const Key('password_field'),
                        visibilityToggleKey: const Key(
                          'password_visibility_toggle',
                        ),
                        controller: _passwordController,
                        obscureText: true,
                        showVisibilityToggle: true,
                        textInputAction: TextInputAction.done,
                        validator: (value) => _validatePassword(l10n, value),
                        onFieldSubmitted: (_) => _onLoginPressed(),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => context.goToForgotPassword(),
                          child: Text(
                            l10n.forgotPassword,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading =
                              state is AuthLoading ||
                              state is AuthSocialLoginInProgress;
                          return PrimaryButton(
                            text: l10n.login,
                            isLoading: state is AuthLoading,
                            loadingText: l10n.signingIn,
                            onPressed: isLoading ? null : _onLoginPressed,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const OrDivider(),
                      const SizedBox(height: 12),
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
                                : () =>
                                      _onSocialLogin(SocialAuthProvider.google),
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
                                : () =>
                                      _onSocialLogin(SocialAuthProvider.apple),
                            isLoading: isAppleLoading,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthError) {
                            if (state.failure != null &&
                                (state.failure is SocialAuthFailure ||
                                    state.failure
                                        is SocialAuthCancelledFailure ||
                                    state.failure is SocialAuthNetworkFailure ||
                                    state.failure is SocialAuthTimeoutFailure ||
                                    state.failure is AccountLinkingFailure)) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: SocialAuthErrorWidget(
                                  failure: state.failure!,
                                  errorMessage: state.message,
                                  onRetry: () {},
                                  onFallback: () {
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => context.goToRegister(),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${l10n.dontHaveAccount} ',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  TextSpan(
                                    text: l10n.register,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }
}
