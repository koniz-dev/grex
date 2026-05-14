import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_icon_sizes.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Card that summarises a single member's balance in the balance list.
class BalanceListItem extends StatelessWidget {
  /// Creates a [BalanceListItem].
  const BalanceListItem({
    required this.balance,
    super.key,
    this.onTap,
  });

  /// The balance data to render.
  final Balance balance;

  /// Optional callback invoked when the user taps the card.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = _statusColor(theme, balance.status);

    return RepaintBoundary(
      child: Card(
        margin: EdgeInsets.zero,
        elevation: AppElevation.card,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!.call();
                },
          child: Padding(
            padding: AppSpacing.card,
            child: Row(
              children: [
                _Avatar(name: balance.displayName, accent: accent),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balance.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _statusSubtitle(l10n, balance),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        amount: balance.absoluteBalance,
                        currencyCode: balance.currency,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _StatusBadge(
                      label: _statusBadge(l10n, balance.status),
                      accent: accent,
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIconSizes.lg,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _statusSubtitle(AppLocalizations l10n, Balance balance) {
    if (balance.isSettled) return l10n.balanceStatusSettled;
    if (balance.owesMoneyToGroup) return l10n.balanceStatusOwes;
    return l10n.balanceStatusOwed;
  }

  static String _statusBadge(AppLocalizations l10n, BalanceStatus status) {
    return switch (status) {
      BalanceStatus.owes => l10n.balanceBadgeOwes,
      BalanceStatus.owed => l10n.balanceBadgeOwed,
      BalanceStatus.settled => l10n.balanceBadgeSettled,
    };
  }

  static Color _statusColor(ThemeData theme, BalanceStatus status) {
    return switch (status) {
      BalanceStatus.owes => theme.colorScheme.error,
      BalanceStatus.owed => Colors.green,
      BalanceStatus.settled => theme.colorScheme.onSurfaceVariant,
    };
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: accent.withValues(alpha: 0.1),
      child: Text(
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: AppRadius.brMd,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
