import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/routing/auth_navigation_extensions.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/extensions/context_extensions.dart';

/// Profile page displaying user information.
///
/// This page shows the current user's profile information including
/// display name, email, preferred currency, and language settings.
/// It provides navigation to edit profile and handles loading/error states.
class ProfilePage extends StatefulWidget {
  /// Creates a [ProfilePage].
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Load profile data when page opens
    context.read<ProfileBloc>().add(const ProfileLoadRequested());
  }

  void _onEditProfilePressed() {
    context.goToEditProfile();
  }

  void _onSignOutPressed() {
    final l10n = context.l10n;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.signOutConfirmTitle),
          content: Text(l10n.signOutConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              child: Text(
                l10n.signOut,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onRefreshPressed() {
    context.read<ProfileBloc>().add(const ProfileRefreshRequested());
  }

  String _getCurrencyDisplayName(String currencyCode) {
    const currencyNames = {
      'VND': 'Vietnamese Dong (₫)',
      'USD': r'US Dollar ($)',
      'EUR': 'Euro (€)',
      'GBP': 'British Pound (£)',
      'JPY': 'Japanese Yen (¥)',
      'KRW': 'South Korean Won (₩)',
      'CNY': 'Chinese Yuan (¥)',
      'THB': 'Thai Baht (฿)',
      'SGD': r'Singapore Dollar (S$)',
      'MYR': 'Malaysian Ringgit (RM)',
      'IDR': 'Indonesian Rupiah (Rp)',
      'PHP': 'Philippine Peso (₱)',
    };
    return currencyNames[currencyCode] ?? currencyCode;
  }

  String _getLanguageDisplayName(String languageCode) {
    const languageNames = {
      'vi': 'Tiếng Việt',
      'en': 'English',
      'zh': '中文',
      'ja': '日本語',
      'ko': '한국어',
      'th': 'ไทย',
      'id': 'Bahasa Indonesia',
      'ms': 'Bahasa Melayu',
      'tl': 'Filipino',
    };
    return languageNames[languageCode] ?? languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileFullTitle),
        centerTitle: true,
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return IconButton(
                onPressed: state is ProfileLoading ? null : _onRefreshPressed,
                icon: state is ProfileLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: l10n.refreshTooltip,
              );
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            // User signed out, navigate to login
            context.replaceWithLogin();
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
                        onPressed: _onRefreshPressed,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Get profile from state
            final profile = state is ProfileLoaded
                ? state.profile
                : state is ProfileUpdateSuccess
                ? state.profile
                : state is ProfileUpdating
                ? state.updatedProfile
                : (state as ProfileError).profile;

            if (profile == null) {
              return Center(
                child: Text(l10n.noProfileData),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  Builder(
                    builder: (context) {
                      final onPrimary = Theme.of(context).colorScheme.onPrimary;
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: onPrimary.withValues(alpha: 0.2),
                              child: Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Display Name
                            Text(
                              profile.displayName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: onPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Email
                            Text(
                              profile.email,
                              style: TextStyle(
                                fontSize: 16,
                                color: onPrimary.withValues(alpha: 0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Profile Information Cards
                  _buildInfoCard(
                    icon: Icons.attach_money,
                    title: l10n.preferredCurrencyLabel,
                    value: _getCurrencyDisplayName(profile.preferredCurrency),
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    icon: Icons.language,
                    title: l10n.language,
                    value: _getLanguageDisplayName(profile.languageCode),
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    title: l10n.accountCreatedAt,
                    value: l10n.joinedAt(_formatDate(l10n, profile.createdAt)),
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    icon: Icons.update,
                    title: l10n.lastUpdatedAt,
                    value: _formatDate(l10n, profile.updatedAt),
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: _onEditProfilePressed,
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.editProfile),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: _onSignOutPressed,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      l10n.signOut,
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Display (if any)
                  if (state is ProfileError)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.errorWithMessage(state.message),
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return l10n.today;
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else if (difference.inDays < 30) {
      return l10n.weeksAgo((difference.inDays / 7).floor());
    } else if (difference.inDays < 365) {
      return l10n.monthsAgo((difference.inDays / 30).floor());
    } else {
      return l10n.yearsAgo((difference.inDays / 365).floor());
    }
  }
}
