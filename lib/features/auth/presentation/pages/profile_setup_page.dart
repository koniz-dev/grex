import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';
import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:grex/features/auth/presentation/widgets/widgets.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/utils/locale_defaults.dart';

/// Profile setup page for new social login users
///
/// Allows users to complete their profile information after successful
/// social authentication. Pre-fills data from OAuth provider and validates
/// user input before creating the profile.
class ProfileSetupPage extends StatefulWidget {
  /// Creates a [ProfileSetupPage] with the provided user data.
  const ProfileSetupPage({
    required this.user,
    required this.provider,
    required this.email,
    super.key,
    this.prefilledDisplayName,
  });

  /// The authenticated user from social login
  final User user;

  /// The social authentication provider used
  final SocialAuthProvider provider;

  /// Pre-filled display name from OAuth provider (optional)
  final String? prefilledDisplayName;

  /// Pre-filled email from OAuth provider
  final String email;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;

  String _selectedCurrency = LocaleDefaults.currencyCode;
  String _selectedLanguage = LocaleDefaults.languageCode;
  bool _isLoading = false;

  // Available currencies
  final List<Map<String, String>> _currencies = [
    {'code': 'VND', 'name': 'Vietnamese Dong (₫)'},
    {'code': 'USD', 'name': r'US Dollar ($)'},
    {'code': 'EUR', 'name': 'Euro (€)'},
    {'code': 'GBP', 'name': 'British Pound (£)'},
  ];

  // Available languages
  final List<Map<String, String>> _languages = [
    {'code': 'vi', 'name': 'Vietnamese'},
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'ar', 'name': 'Arabic'},
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.prefilledDisplayName ?? '',
    );
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Navigate to main screen on success
          unawaited(Navigator.of(context).pushReplacementNamed('/home'));
        } else if (state is AuthError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.completeYourProfile),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showCancelDialog,
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and description
                  Text(
                    context.l10n.completeYourProfile,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your profile to start using Grex',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Display name field
                  AuthTextField(
                    controller: _displayNameController,
                    label: context.l10n.displayName,
                    placeholder: context.l10n.enterYourName,
                    validator: ProfileSetupData.validateDisplayName,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Email field (read-only)
                  AuthTextField(
                    controller: _emailController,
                    label: context.l10n.email,
                    placeholder: context.l10n.email,
                    enabled: false,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  // Currency dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: InputDecoration(
                      labelText: context.l10n.selectCurrency,
                      border: const OutlineInputBorder(),
                      enabled: !_isLoading,
                    ),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency['code'],
                        child: Text(currency['name']!),
                      );
                    }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCurrency = value;
                              });
                            }
                          },
                    validator: ProfileSetupData.validateCurrency,
                  ),
                  const SizedBox(height: 16),

                  // Language dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: context.l10n.selectLanguage,
                      border: const OutlineInputBorder(),
                      enabled: !_isLoading,
                    ),
                    items: _languages.map((language) {
                      return DropdownMenuItem<String>(
                        value: language['code'],
                        child: Text(language['name']!),
                      );
                    }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedLanguage = value;
                              });
                            }
                          },
                    validator: ProfileSetupData.validateLanguage,
                  ),
                  const SizedBox(height: 32),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onContinuePressed,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(context.l10n.continueButton),
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

  void _onContinuePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      final profileData = ProfileSetupData(
        displayName: _displayNameController.text.trim(),
        preferredCurrency: _selectedCurrency,
        languageCode: _selectedLanguage,
        socialProvider: widget.provider,
      );

      context.read<AuthBloc>().add(
        AuthProfileSetupCompleted(
          displayName: profileData.displayName,
          preferredCurrency: profileData.preferredCurrency,
          languageCode: profileData.languageCode,
        ),
      );
    }
  }

  void _showCancelDialog() {
    unawaited(
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Profile Setup'),
          content: const Text(
            'Are you sure you want to cancel? You will be signed out and '
            'returned to the login screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continue Setup'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ).then((shouldCancel) {
        if (shouldCancel ?? false) {
          if (mounted) {
            context.read<AuthBloc>().add(const AuthProfileSetupCancelled());
            unawaited(Navigator.of(context).pushReplacementNamed('/login'));
          }
        }
      }),
    );
  }
}
