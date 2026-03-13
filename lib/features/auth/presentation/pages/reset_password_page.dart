import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/domain/validators/validators.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/widgets/widgets.dart';

/// Reset password page for setting new password.
///
/// Implements the reset password screen design with:
/// - New password field
/// - Confirm password field
/// - Password requirements hint
/// - Reset button
class ResetPasswordPage extends StatefulWidget {
  /// Creates a [ResetPasswordPage].
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onResetPasswordPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthPasswordUpdateRequested(
          newPassword: _passwordController.text,
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
            if (state is AuthPasswordUpdated) {
              // Show success and navigate to login
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset successfully'),
                  backgroundColor: Colors.green,
                ),
              );
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
                    'Reset Password',
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
                    'Enter your new password',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF71717A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // New password field
                  AuthTextField(
                    label: 'New Password',
                    placeholder: 'Min. 8 characters',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: InputValidators.validatePassword,
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

                  // Confirm password field
                  AuthTextField(
                    label: 'Confirm Password',
                    placeholder: 'Re-enter password',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) =>
                        InputValidators.validatePasswordConfirmation(
                          _passwordController.text,
                          value,
                        ),
                    onFieldSubmitted: (_) => _onResetPasswordPressed(),
                  ),
                  const SizedBox(height: 32),

                  // Reset button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return PrimaryButton(
                        text: 'Reset Password',
                        isLoading: state is AuthLoading,
                        onPressed: state is AuthLoading
                            ? null
                            : _onResetPasswordPressed,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
