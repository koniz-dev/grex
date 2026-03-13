import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';

/// Dialog for confirming account linking when a social login email
/// matches an existing account.
///
/// This dialog appears when a user signs in with a social provider using
/// an email address that already exists in the system. It provides clear
/// options for the user to either link their social account to the existing
/// account or create a new separate account.
///
/// ## Account Linking Flow
///
/// 1. User signs in with social provider (Google/Apple)
/// 2. System detects existing account with same email
/// 3. Dialog appears with linking options
/// 4. User chooses to link accounts or create new account
/// 5. System processes the choice and navigates appropriately
///
/// ## Features
///
/// - **Non-dismissible**: Prevents accidental dismissal
/// - **Clear messaging**: Explains the situation and options
/// - **Visual benefits**: Shows advantages of account linking
/// - **Accessible**: Proper contrast and semantic structure
///
/// ## Usage Example
///
/// ```dart
/// // Show dialog when account linking is detected
/// await AccountLinkingDialog.show(
///   context,
///   newUser: oauthUser,
///   existingProfile: existingUserProfile,
///   provider: SocialAuthProvider.google,
/// );
/// ```
///
/// **Requirements:** 5.2, 5.3, 5.4
class AccountLinkingDialog extends StatelessWidget {
  /// Creates an [AccountLinkingDialog] with the provided data.
  ///
  /// **Parameters:**
  /// - [newUser]: The user object from successful OAuth authentication
  /// - [existingProfile]: The existing user profile with matching email
  /// - [provider]: The social provider used for authentication
  const AccountLinkingDialog({
    required this.newUser,
    required this.existingProfile,
    required this.provider,
    super.key,
  });

  /// The new user from social authentication.
  ///
  /// Contains OAuth provider data including email, display name,
  /// and provider-specific metadata.
  final User newUser;

  /// The existing user profile with matching email.
  ///
  /// This is the profile that would be linked to the social provider
  /// if the user chooses to link accounts.
  final UserProfile existingProfile;

  /// The social authentication provider.
  ///
  /// Used to display provider-specific messaging and branding
  /// in the dialog content.
  final SocialAuthProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Link Your Account',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'An account with email ${newUser.email} already exists.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Would you like to link your ${provider.displayName} account to '
            'your existing account?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will allow you to sign in with either method.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<AuthBloc>().add(const AuthAccountLinkingDeclined());
          },
          child: Text(
            'Create New Account',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<AuthBloc>().add(
              AuthAccountLinkingConfirmed(existingProfile.id),
            );
          },
          child: const Text('Link Accounts'),
        ),
      ],
    );
  }

  /// Shows the account linking dialog.
  ///
  /// This static method provides a convenient way to display the dialog
  /// with proper configuration. The dialog is non-dismissible to ensure
  /// the user makes an explicit choice.
  ///
  /// **Parameters:**
  /// - [context]: Build context for dialog display
  /// - [newUser]: OAuth authenticated user
  /// - [existingProfile]: Existing user profile with matching email
  /// - [provider]: Social authentication provider
  ///
  /// **Returns:**
  /// Future that completes when the dialog is dismissed
  ///
  /// **Example:**
  /// ```dart
  /// await AccountLinkingDialog.show(
  ///   context,
  ///   newUser: user,
  ///   existingProfile: profile,
  ///   provider: SocialAuthProvider.google,
  /// );
  /// ```
  static Future<void> show(
    BuildContext context, {
    required User newUser,
    required UserProfile existingProfile,
    required SocialAuthProvider provider,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => AccountLinkingDialog(
        newUser: newUser,
        existingProfile: existingProfile,
        provider: provider,
      ),
    );
  }
}
