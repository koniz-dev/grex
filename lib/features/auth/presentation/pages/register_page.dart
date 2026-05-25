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

/// Registration page for new user sign up.
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
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
          preferredCurrency: LocaleDefaults.currencyCode,
          languageCode: LocaleDefaults.languageCode,
        ),
      );
    }
  }

  void _onSocialLogin(SocialAuthProvider provider) {
    context.read<AuthBloc>().add(AuthSocialLoginRequested(provider.name));
  }

  String? _validateDisplayName(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) {
      return l10n.displayNameRequired;
    }
    if (value.trim().isEmpty) {
      return l10n.displayNameEmpty;
    }
    if (value.trim().length > 50) {
      return l10n.displayNameTooLong;
    }
    return null;
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
    if (!value.contains(RegExp('[A-Z]'))) {
      return l10n.pwdReqUppercase;
    }
    if (!value.contains(RegExp('[0-9]'))) {
      return l10n.pwdReqNumber;
    }
    if (!value.contains(RegExp(r'[^a-zA-Z0-9\s]'))) {
      return l10n.pwdReqSpecial;
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                    const SizedBox(height: 20),
                    Text(
                      l10n.registerAccount,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.joinGrexExpenseShare,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: l10n.displayName,
                      placeholder: l10n.yourNameHint,
                      fieldKey: const Key('display_name_field'),
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validateDisplayName(l10n, value),
                    ),
                    const SizedBox(height: 12),
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
                      placeholder: l10n.passwordHintShort,
                      fieldKey: const Key('password_field'),
                      visibilityToggleKey: const Key(
                        'password_visibility_toggle',
                      ),
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: true,
                      showVisibilityToggle: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) => _validatePassword(l10n, value),
                      onFieldSubmitted: (_) => _onRegisterPressed(),
                    ),
                    PasswordRequirementIndicator(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                    ),

                    const SizedBox(height: 16),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading =
                            state is AuthLoading ||
                            state is AuthSocialLoginInProgress;
                        return PrimaryButton(
                          text: l10n.register,
                          isLoading: state is AuthLoading,
                          loadingText: l10n.registering,
                          onPressed: isLoading ? null : _onRegisterPressed,
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
                    const SizedBox(height: 16),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthError) {
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
                          onTap: () => context.goToLogin(),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: l10n.alreadyHaveAccountPrefix,
                                  style: const TextStyle(
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                                TextSpan(
                                  text: l10n.signIn,
                                  style: const TextStyle(
                                    color: Colors.black,
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
    );
  }
}
