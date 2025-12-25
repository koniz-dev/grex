import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/domain/validators/validators.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';

/// Forgot password page for password reset requests.
///
/// This page allows users to request a password reset email by entering
/// their email address. It handles validation and displays appropriate
/// success or error messages.
class ForgotPasswordPage extends StatefulWidget {
  /// Creates a [ForgotPasswordPage].
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _onResetPasswordPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthPasswordResetRequested(
          email: _emailController.text.trim(),
        ),
      );
    }
  }

  void _onBackToLoginPressed() {
    context.goBackOrHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthPasswordResetSent) {
              // Show success dialog
              unawaited(
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    title: const Text('Email đã được gửi'),
                    content: Text(
                      'Chúng tôi đã gửi link đặt lại mật khẩu đến '
                      '${state.email}. '
                      'Vui lòng kiểm tra email và làm theo hướng dẫn.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          context.goToLogin(); // Go back to login
                        },
                        child: const Text('Đã hiểu'),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
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
                    'Đặt lại mật khẩu',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'Nhập email của bạn và chúng tôi sẽ gửi link đặt lại '
                    'mật khẩu',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Nhập email của bạn',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: InputValidators.validateEmail,
                    onChanged: (_) => _validateForm(),
                    onFieldSubmitted: (_) {
                      if (_isFormValid) {
                        _onResetPasswordPressed();
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Reset Password Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;

                      return ElevatedButton(
                        onPressed: isLoading || !_isFormValid
                            ? null
                            : _onResetPasswordPressed,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Gửi email đặt lại mật khẩu',
                                style: TextStyle(fontSize: 16),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Back to Login Button
                  TextButton(
                    onPressed: _onBackToLoginPressed,
                    child: const Text('Quay lại đăng nhập'),
                  ),
                  const SizedBox(height: 32),

                  // Error Display
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthError) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.message,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 24),

                  // Help Text
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
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Lưu ý',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Kiểm tra cả hộp thư spam/junk\n'
                          '• Link đặt lại mật khẩu có hiệu lực trong 24 giờ\n'
                          '• Nếu không nhận được email, thử lại sau 5 phút',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],
                    ),
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
