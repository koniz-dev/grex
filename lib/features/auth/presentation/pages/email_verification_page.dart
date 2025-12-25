import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';

/// Email verification page for unverified users.
///
/// This page is shown to users who have registered but haven't verified
/// their email address yet. It provides options to resend verification
/// email and shows verification status.
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
    // Check auth state periodically for email verification
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    // Check every 5 seconds if email has been verified
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

    // Send verification email through BLoC
    context.read<AuthBloc>().add(const AuthVerificationEmailRequested());
  }

  void _onSignOutPressed() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  void _onChangeEmailPressed() {
    // Navigate back to registration to change email
    context.goToRegister();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // Email has been verified, navigate to main app
              context.replaceWithHome();
            } else if (state is AuthUnauthenticated) {
              // User signed out, go back to login
              context.replaceWithLogin();
            } else if (state is AuthVerificationEmailSent) {
              // Verification email sent successfully
              setState(() {
                _isResendingEmail = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Email xác thực đã được gửi đến ${state.email}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AuthEmailVerified) {
              // Email verification successful
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email đã được xác thực thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AuthError) {
              // Handle verification errors
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo
                Center(
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Xác thực email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    var email = 'email của bạn';
                    if (state is AuthEmailVerificationRequired) {
                      email = state.email;
                    }

                    return Text(
                      'Chúng tôi đã gửi email xác thực đến $email. '
                      'Vui lòng kiểm tra email và nhấp vào link xác thực '
                      'để tiếp tục.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Verification Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đang chờ xác thực',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tài khoản sẽ được kích hoạt sau khi xác thực '
                              'email',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Resend Email Button
                ElevatedButton.icon(
                  onPressed: _canResendEmail && !_isResendingEmail
                      ? _onResendEmailPressed
                      : null,
                  icon: _isResendingEmail
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isResendingEmail
                        ? 'Đang gửi...'
                        : _canResendEmail
                        ? 'Gửi lại email xác thực'
                        : 'Gửi lại sau ${_remainingCooldownSeconds}s',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Change Email Button
                OutlinedButton.icon(
                  onPressed: _onChangeEmailPressed,
                  icon: const Icon(Icons.edit),
                  label: const Text('Thay đổi email'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Help Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Cần trợ giúp?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Kiểm tra thư mục spam/junk\n'
                        '• Email có thể mất vài phút để đến\n'
                        '• Đảm bảo email chính xác\n'
                        '• Link xác thực có hiệu lực trong 24 giờ',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Out Button
                TextButton(
                  onPressed: _onSignOutPressed,
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.grey),
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
