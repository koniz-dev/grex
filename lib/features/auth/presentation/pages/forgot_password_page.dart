import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/widgets/widgets.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_fonts.dart';

/// Forgot password page for password reset.
class ForgotPasswordPage extends StatefulWidget {
  /// Creates a [ForgotPasswordPage].
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendResetLink() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthPasswordResetRequested(
          email: _emailController.text.trim(),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.goToLogin(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthPasswordResetSent) {
                      return _SuccessView(email: state.email);
                    }
                    return _FormView(
                      l10n: l10n,
                      emailController: _emailController,
                      validator: (value) => _validateEmail(l10n, value),
                      onSubmit: _onSendResetLink,
                    );
                  },
                ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ErrorBanner(message: state.message),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 32),
                Center(
                  child: GestureDetector(
                    onTap: () => context.goToLogin(),
                    child: Text(
                      l10n.backToSignIn,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.l10n,
    required this.emailController,
    required this.validator,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final TextEditingController emailController;
  final String? Function(String?) validator;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.forgotPasswordTitle,
          style: TextStyle(
            fontFamily: AppFonts.heading,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.enterEmailForResetShort,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.weWillSendLink,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        AuthTextField(
          label: l10n.email,
          placeholder: l10n.enterYourEmail,
          fieldKey: const Key('email_field'),
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: validator,
          onFieldSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 32),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return PrimaryButton(
              text: l10n.sendResetLinkShort,
              isLoading: state is AuthLoading,
              loadingText: l10n.sending,
              onPressed: state is AuthLoading ? null : onSubmit,
            );
          },
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 64, color: Color(0xFF22C55E)),
        const SizedBox(height: 24),
        Text(
          l10n.resetEmailSent,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.heading,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.pleaseCheckEmailAt(email),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () {
            context.read<AuthBloc>().add(
              AuthPasswordResetRequested(email: email),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            l10n.resend,
            style: TextStyle(
              fontFamily: AppFonts.heading,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
