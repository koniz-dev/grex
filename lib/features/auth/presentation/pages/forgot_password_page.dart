import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/domain/validators/validators.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/widgets/widgets.dart';

/// Forgot password page for password reset.
///
/// Implements the forgot password screen design with:
/// - Back button
/// - Email input field
/// - Send reset link button
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthPasswordResetSent) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset link sent to your email'),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate back to login
              context.goToLogin();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Title section
                  const Text(
                    'Forgot Password?',
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
                    'Enter your email to receive a password reset link',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF71717A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email field
                  AuthTextField(
                    label: 'Email',
                    placeholder: 'your@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: InputValidators.validateEmail,
                    onFieldSubmitted: (_) => _onSendResetLink(),
                  ),
                  const SizedBox(height: 32),

                  // Send button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return PrimaryButton(
                        text: 'Send Reset Link',
                        isLoading: state is AuthLoading,
                        onPressed: state is AuthLoading
                            ? null
                            : _onSendResetLink,
                      );
                    },
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

                  // Spacer
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),

                  // Back to login prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Remember your password? ',
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
