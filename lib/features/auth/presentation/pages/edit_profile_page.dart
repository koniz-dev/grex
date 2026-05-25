import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/utils/locale_defaults.dart';

/// Edit profile page for updating user information.
///
/// This page provides a form for users to update their profile information
/// including display name, preferred currency, and language settings.
/// It includes form validation, optimistic updates, and error handling.
class EditProfilePage extends StatefulWidget {
  /// Creates an [EditProfilePage].
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();

  String _selectedCurrency = LocaleDefaults.currencyCode;
  String _selectedLanguage = LocaleDefaults.languageCode;
  bool _isFormValid = false;
  bool _hasChanges = false;

  // Original values to detect changes
  String _originalDisplayName = '';
  String _originalCurrency = '';
  String _originalLanguage = '';

  final List<Map<String, String>> _currencies = [
    {'code': 'VND', 'name': 'Vietnamese Dong (₫)'},
    {'code': 'USD', 'name': r'US Dollar ($)'},
    {'code': 'EUR', 'name': 'Euro (€)'},
    {'code': 'GBP', 'name': 'British Pound (£)'},
    {'code': 'JPY', 'name': 'Japanese Yen (¥)'},
    {'code': 'KRW', 'name': 'South Korean Won (₩)'},
    {'code': 'CNY', 'name': 'Chinese Yuan (¥)'},
    {'code': 'THB', 'name': 'Thai Baht (฿)'},
    {'code': 'SGD', 'name': r'Singapore Dollar (S$)'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit (RM)'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah (Rp)'},
    {'code': 'PHP', 'name': 'Philippine Peso (₱)'},
  ];

  final List<Map<String, String>> _languages = [
    {'code': 'vi', 'name': 'Tiếng Việt'},
    {'code': 'en', 'name': 'English'},
    {'code': 'zh', 'name': '中文'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ko', 'name': '한국어'},
    {'code': 'th', 'name': 'ไทย'},
    {'code': 'id', 'name': 'Bahasa Indonesia'},
    {'code': 'ms', 'name': 'Bahasa Melayu'},
    {'code': 'tl', 'name': 'Filipino'},
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController.addListener(_checkForChanges);

    // Load current profile data
    context.read<ProfileBloc>().add(const ProfileLoadRequested());
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _initializeFormWithProfile(UserProfile profile) {
    _displayNameController.text = profile.displayName;
    _selectedCurrency = profile.preferredCurrency;
    _selectedLanguage = profile.languageCode;

    // Store original values
    _originalDisplayName = profile.displayName;
    _originalCurrency = profile.preferredCurrency;
    _originalLanguage = profile.languageCode;

    _checkForChanges();
  }

  void _checkForChanges() {
    final hasChanges =
        _displayNameController.text.trim() != _originalDisplayName ||
        _selectedCurrency != _originalCurrency ||
        _selectedLanguage != _originalLanguage;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (hasChanges != _hasChanges || isValid != _isFormValid) {
      setState(() {
        _hasChanges = hasChanges;
        _isFormValid = isValid;
      });
    }
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      // Only send changed fields
      String? displayName;
      String? currency;
      String? language;

      if (_displayNameController.text.trim() != _originalDisplayName) {
        displayName = _displayNameController.text.trim();
      }
      if (_selectedCurrency != _originalCurrency) {
        currency = _selectedCurrency;
      }
      if (_selectedLanguage != _originalLanguage) {
        language = _selectedLanguage;
      }

      context.read<ProfileBloc>().add(
        ProfileUpdateRequested(
          displayName: displayName,
          preferredCurrency: currency,
          languageCode: language,
        ),
      );
    }
  }

  void _onCancelPressed() {
    if (_hasChanges) {
      final l10n = context.l10n;
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cancelChangesTitle),
            content: Text(l10n.unsavedChangesMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.continueEditing),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  context.goBackOrHome(); // Go back
                },
                child: Text(
                  l10n.discardChanges,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      context.goBackOrHome();
    }
  }

  String? _validateDisplayName(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.displayNameRequired;
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return l10n.displayNameTooShort(2);
    }
    if (trimmed.length > 50) {
      return l10n.displayNameTooLong;
    }
    if (!RegExp(r'^[a-zA-Z0-9\s\-_.]+$').hasMatch(trimmed)) {
      return l10n.displayNameInvalidChars;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onCancelPressed,
        ),
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              final isLoading = state is ProfileUpdating;

              return TextButton(
                onPressed: isLoading || !_hasChanges || !_isFormValid
                    ? null
                    : _onSavePressed,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              );
            },
          ),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            // Show success message and go back
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.profileUpdatedSuccess),
                backgroundColor: Colors.green,
              ),
            );
            context.goBackOrHome();
          } else if (state is ProfileLoaded) {
            // Initialize form with loaded profile data
            _initializeFormWithProfile(state.profile);
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading && state is! ProfileUpdating) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is ProfileError && state.profile == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.profileLoadFailed,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<ProfileBloc>().add(
                            const ProfileLoadRequested(),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Avatar Section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            child: Text(
                              _displayNameController.text.isNotEmpty
                                  ? _displayNameController.text[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Display Name Field
                    TextFormField(
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.displayName,
                        hintText: l10n.displayNameHint,
                        prefixIcon: const Icon(Icons.person_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => _validateDisplayName(l10n, value),
                      onChanged: (_) => _checkForChanges(),
                    ),
                    const SizedBox(height: 24),

                    // Currency Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: l10n.preferredCurrencyLabel,
                        prefixIcon: const Icon(Icons.attach_money),
                        border: const OutlineInputBorder(),
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
                          _checkForChanges();
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Language Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLanguage,
                      decoration: InputDecoration(
                        labelText: l10n.language,
                        prefixIcon: const Icon(Icons.language),
                        border: const OutlineInputBorder(),
                      ),
                      items: _languages.map((language) {
                        return DropdownMenuItem<String>(
                          value: language['code'],
                          child: Text(language['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLanguage = value;
                          });
                          _checkForChanges();
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        final isLoading = state is ProfileUpdating;

                        return ElevatedButton(
                          onPressed: isLoading || !_hasChanges || !_isFormValid
                              ? null
                              : _onSavePressed,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(l10n.saving),
                                  ],
                                )
                              : Text(
                                  l10n.saveChanges,
                                  style: const TextStyle(fontSize: 16),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    OutlinedButton(
                      onPressed: _onCancelPressed,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(height: 24),

                    // Error Display
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        if (state is ProfileError) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[700],
                                ),
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

                    // Help Text
                    const SizedBox(height: 16),
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
                                l10n.editProfileNoteTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.editProfileTipDisplayName}\n'
                            '${l10n.editProfileTipCurrency}\n'
                            '${l10n.editProfileTipLanguage}',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
