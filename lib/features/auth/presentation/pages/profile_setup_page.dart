import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/app_routes.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';
import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
// Hide the BLoC `AuthState` symbol so it doesn't clash with the freezed
// Riverpod `AuthState` from auth_provider.dart — we reference the concrete
// BLoC state subclasses unprefixed, and `bloc.AuthState` for the
// BlocListener type parameter.
import 'package:grex/features/auth/presentation/bloc/auth_state.dart'
    hide AuthState;
import 'package:grex/features/auth/presentation/bloc/auth_state.dart' as bloc;
import 'package:grex/features/auth/presentation/providers/auth_provider.dart';
import 'package:grex/features/auth/presentation/widgets/widgets.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/utils/locale_defaults.dart';

/// Profile setup page for new social-login users.
///
/// Renders a hero header (Google avatar / initials), a single editable
/// display-name field, and two preference rows (currency, language) that
/// open searchable modal pickers. Currency defaults follow the chosen
/// language until the user explicitly picks a currency themselves.
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

  late String _selectedCurrency;
  late String _selectedLanguage;
  bool _currencyTouched = false;
  bool _isLoading = false;

  static const Map<String, String> _languageToCurrency = {
    'vi': 'VND',
    'en': 'USD',
    'es': 'EUR',
    'ar': 'USD',
  };

  static const List<_CurrencyOption> _currencies = [
    _CurrencyOption('VND', 'Vietnamese Dong', '₫', '🇻🇳'),
    _CurrencyOption('USD', 'US Dollar', r'$', '🇺🇸'),
    _CurrencyOption('EUR', 'Euro', '€', '🇪🇺'),
    _CurrencyOption('GBP', 'British Pound', '£', '🇬🇧'),
    _CurrencyOption('JPY', 'Japanese Yen', '¥', '🇯🇵'),
    _CurrencyOption('KRW', 'South Korean Won', '₩', '🇰🇷'),
    _CurrencyOption('SGD', 'Singapore Dollar', r'S$', '🇸🇬'),
    _CurrencyOption('THB', 'Thai Baht', '฿', '🇹🇭'),
    _CurrencyOption('CNY', 'Chinese Yuan', '¥', '🇨🇳'),
    _CurrencyOption('TWD', 'Taiwan Dollar', r'NT$', '🇹🇼'),
    _CurrencyOption('AUD', 'Australian Dollar', r'A$', '🇦🇺'),
    _CurrencyOption('CAD', 'Canadian Dollar', r'C$', '🇨🇦'),
  ];

  static const List<_LanguageOption> _languages = [
    _LanguageOption('vi', 'Tiếng Việt', 'Vietnamese', '🇻🇳'),
    _LanguageOption('en', 'English', 'English', '🇺🇸'),
    _LanguageOption('es', 'Español', 'Spanish', '🇪🇸'),
    _LanguageOption('ar', 'العربية', 'Arabic', '🇸🇦'),
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.prefilledDisplayName ?? '',
    );
    _selectedLanguage = LocaleDefaults.languageCode;
    _selectedCurrency =
        _languageToCurrency[_selectedLanguage] ?? LocaleDefaults.currencyCode;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  String? _photoUrl() {
    final meta = widget.user.userMetadata;
    if (meta == null) return null;
    final candidate = (meta['avatar_url'] ?? meta['picture']) as String?;
    if (candidate == null || candidate.isEmpty) return null;
    return candidate;
  }

  String _initials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  Future<void> _finishProfileSetup(BuildContext context) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container
          .read(authNotifierProvider.notifier)
          .refreshProfileExistence();
      if (!context.mounted) return;
      context.go(AppRoutes.groups);
    } on Object {
      if (!context.mounted) return;
      unawaited(Navigator.of(context).pushReplacementNamed('/home'));
    }
  }

  String? _validateDisplayName(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.displayNameRequired;
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) return l10n.displayNameTooShort(2);
    if (trimmed.length > 50) return l10n.displayNameTooLong;
    return null;
  }

  Future<void> _pickCurrency() async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PickerSheet(
        title: l10n.selectCurrency,
        searchHint: l10n.searchHint,
        selectedCode: _selectedCurrency,
        items: _currencies
            .map(
              (c) => _PickerItem(
                code: c.code,
                primary: '${c.flag}  ${c.code}',
                secondary: '${c.name} · ${c.symbol}',
                searchHaystack: '${c.code} ${c.name} ${c.symbol}'.toLowerCase(),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (selected != null && selected != _selectedCurrency) {
      setState(() {
        _selectedCurrency = selected;
        _currencyTouched = true;
      });
    }
  }

  Future<void> _pickLanguage() async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PickerSheet(
        title: l10n.selectLanguage,
        searchHint: l10n.searchHint,
        selectedCode: _selectedLanguage,
        items: _languages
            .map(
              (lang) => _PickerItem(
                code: lang.code,
                primary: '${lang.flag}  ${lang.nativeName}',
                secondary: lang.englishName,
                searchHaystack: '${lang.nativeName} ${lang.englishName}'
                    .toLowerCase(),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (selected != null && selected != _selectedLanguage) {
      setState(() {
        _selectedLanguage = selected;
        if (!_currencyTouched) {
          _selectedCurrency =
              _languageToCurrency[selected] ?? _selectedCurrency;
        }
      });
    }
  }

  void _onContinuePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = ProfileSetupData(
        displayName: _displayNameController.text.trim(),
        preferredCurrency: _selectedCurrency,
        languageCode: _selectedLanguage,
        socialProvider: widget.provider,
      );
      context.read<AuthBloc>().add(
        AuthProfileSetupCompleted(
          displayName: data.displayName,
          preferredCurrency: data.preferredCurrency,
          languageCode: data.languageCode,
        ),
      );
    }
  }

  void _onUseDifferentAccount() {
    context.read<AuthBloc>().add(const AuthProfileSetupCancelled());
    try {
      context.go(AppRoutes.login);
    } on Object {
      unawaited(Navigator.of(context).pushReplacementNamed('/login'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<AuthBloc, bloc.AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          unawaited(_finishProfileSetup(context));
        } else if (state is AuthError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        } else if (state is AuthLoading) {
          setState(() => _isLoading = true);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                _HeroHeader(
                  photoUrl: _photoUrl(),
                  fallbackInitials: _initials(
                    _displayNameController.text.isEmpty
                        ? widget.email
                        : _displayNameController.text,
                  ),
                  email: widget.email,
                  provider: widget.provider,
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.completeYourProfile,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.profileSetupDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                _SectionLabel(text: l10n.yourNameSectionTitle),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _displayNameController,
                  label: l10n.displayName,
                  placeholder: l10n.enterYourName,
                  validator: (value) => _validateDisplayName(l10n, value),
                  enabled: !_isLoading,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.displayNameHelper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                _SectionLabel(text: l10n.preferencesSectionTitle),
                const SizedBox(height: 8),
                _PreferenceTile(
                  icon: Icons.attach_money_rounded,
                  label: l10n.selectCurrency,
                  value: _currencySummary(),
                  enabled: !_isLoading,
                  onTap: _pickCurrency,
                ),
                const SizedBox(height: 8),
                _PreferenceTile(
                  icon: Icons.language_rounded,
                  label: l10n.selectLanguage,
                  value: _languageSummary(),
                  enabled: !_isLoading,
                  onTap: _pickLanguage,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onContinuePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.onSurface,
                      foregroundColor: colorScheme.surface,
                      disabledBackgroundColor: colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                      disabledForegroundColor: colorScheme.surface.withValues(
                        alpha: 0.7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.surface,
                              ),
                            ),
                          )
                        : Text(
                            l10n.continueButton,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _onUseDifferentAccount,
                    child: Text(
                      l10n.useDifferentAccount,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
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

  String _currencySummary() {
    final option = _currencies.firstWhere(
      (c) => c.code == _selectedCurrency,
      orElse: () => _currencies.first,
    );
    return '${option.flag}  ${option.code} · ${option.symbol}';
  }

  String _languageSummary() {
    final option = _languages.firstWhere(
      (l) => l.code == _selectedLanguage,
      orElse: () => _languages.first,
    );
    return '${option.flag}  ${option.nativeName}';
  }
}

class _CurrencyOption {
  const _CurrencyOption(this.code, this.name, this.symbol, this.flag);
  final String code;
  final String name;
  final String symbol;
  final String flag;
}

class _LanguageOption {
  const _LanguageOption(
    this.code,
    this.nativeName,
    this.englishName,
    this.flag,
  );
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.photoUrl,
    required this.fallbackInitials,
    required this.email,
    required this.provider,
  });

  final String? photoUrl;
  final String fallbackInitials;
  final String email;
  final SocialAuthProvider provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                foregroundImage: photoUrl == null
                    ? null
                    : NetworkImage(photoUrl!),
                child: photoUrl == null
                    ? Text(
                        fallbackInitials,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    provider == SocialAuthProvider.apple
                        ? Icons.apple
                        : Icons.g_mobiledata_rounded,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  email,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerItem {
  const _PickerItem({
    required this.code,
    required this.primary,
    required this.secondary,
    required this.searchHaystack,
  });

  final String code;
  final String primary;
  final String secondary;
  final String searchHaystack;
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.searchHint,
    required this.selectedCode,
    required this.items,
  });

  final String title;
  final String searchHint;
  final String selectedCode;
  final List<_PickerItem> items;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
              .where((item) => item.searchHaystack.contains(_query))
              .toList(growable: false);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final isSelected = item.code == widget.selectedCode;
                return Material(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(item.code),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.primary,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.secondary,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
