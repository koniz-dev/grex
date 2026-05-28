import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/widgets/widgets.dart';
import 'package:grex/shared/theme/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Email verification page for unverified users.
///
/// Implements the email verification screen design with:
/// - Mail icon centered at top
/// - Title and instructions
/// - Resend email button
/// - Back to login option
class EmailVerificationPage extends StatefulWidget {
  /// Creates an [EmailVerificationPage].
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isResendingEmail = false;
  DateTime? _lastResendTime;

  static const int _resendCooldownSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthSessionChecked());
        _startVerificationCheck();
      }
    });
  }

  bool get _canResendEmail {
    if (_lastResendTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastResendTime!);
    return difference.inSeconds >= _resendCooldownSeconds;
  }

  int get _remainingCooldownSeconds {
    if (_lastResendTime == null) return 0;
    final now = DateTime.now();
    final difference = now.difference(_lastResendTime!);
    final remaining = _resendCooldownSeconds - difference.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void _onResendEmailPressed() {
    if (!_canResendEmail || _isResendingEmail) return;

    setState(() {
      _isResendingEmail = true;
      _lastResendTime = DateTime.now();
    });

    context.read<AuthBloc>().add(const AuthVerificationEmailRequested());
  }

  void _onBackToLoginPressed() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  Future<void> _openEmailApp() async {
    try {
      // Try to open default email app
      final emailUri = Uri(scheme: 'mailto');
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback: show a message if no email app is available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No email app found. Please check your email manually.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } on Exception {
      // Handle any errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open email app. Please check your email manually.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.replaceWithHome();
            } else if (state is AuthUnauthenticated) {
              context.replaceWithLogin();
            } else if (state is AuthVerificationEmailSent) {
              setState(() {
                _isResendingEmail = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Verification email sent to ${state.email}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AuthError) {
              setState(() {
                _isResendingEmail = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Mail icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.mail_outline,
                      size: 40,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontFamily: AppFonts.heading,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Instructions
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    var email = 'your email';
                    if (state is AuthEmailVerificationRequired) {
                      email = state.email;
                    }

                    return Text(
                      'We sent a verification link to $email. '
                      'Click the link to verify your account.',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Resend email button
                PrimaryButton(
                  text: _isResendingEmail
                      ? 'Sending...'
                      : _canResendEmail
                      ? 'Resend Email'
                      : 'Resend in ${_remainingCooldownSeconds}s',
                  isLoading: _isResendingEmail,
                  onPressed: _canResendEmail && !_isResendingEmail
                      ? _onResendEmailPressed
                      : null,
                ),
                const SizedBox(height: 16),

                // Open email app button (optional)
                OutlinedButton(
                  onPressed: _openEmailApp,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Open Email App',
                    style: TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Error display
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthError) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ErrorBanner(message: state.message),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Help text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Didn't receive the email?",
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Check your spam folder\n'
                        '• Make sure the email address is correct\n'
                        '• Wait a few minutes for the email to arrive',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Wrong email? ',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: _onBackToLoginPressed,
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
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
    );
  }
}
