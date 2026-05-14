import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_icon_sizes.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Summary card sitting at the top of the balance page showing aggregate
/// stats and a primary CTA to generate a settlement plan.
class BalanceSummaryCard extends StatelessWidget {
  /// Creates a [BalanceSummaryCard].
  const BalanceSummaryCard({
    required this.balances,
    required this.currency,
    super.key,
    this.onGenerateSettlement,
  });

  /// All member balances to aggregate.
  final List<Balance> balances;

  /// Currency code rendered for the totals.
  final String currency;

  /// Callback invoked when the user taps the settlement plan CTA.
  final VoidCallback? onGenerateSettlement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final stats = _calculateStats();

    return Card(
      elevation: AppElevation.card,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: scheme.primary,
                  size: AppIconSizes.lg,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  l10n.balanceSummary,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.totalOwed,
                    CurrencyFormatter.format(
                      amount: stats.totalOwed,
                      currencyCode: currency,
                    ),
                    Colors.green,
                    Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.totalOwes,
                    CurrencyFormatter.format(
                      amount: stats.totalOwes,
                      currencyCode: currency,
                    ),
                    scheme.error,
                    Icons.trending_down_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.settledStat,
                    '${stats.settledCount}',
                    scheme.onSurfaceVariant,
                    Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _buildStatItem(
                    context,
                    l10n.unsettledStat,
                    '${stats.unsettledCount}',
                    scheme.primary,
                    Icons.pending_outlined,
                  ),
                ),
              ],
            ),
            if (stats.unsettledCount > 0) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onGenerateSettlement == null
                      ? null
                      : () {
                          unawaited(HapticFeedback.lightImpact());
                          onGenerateSettlement!.call();
                        },
                  icon: const Icon(Icons.calculate_rounded),
                  label: Text(l10n.generateSettlementPlan),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.brMd,
                    ),
                  ),
                ),
              ),
            ],
            if (stats.unsettledCount == 0) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brMd,
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.allMembersSettledUp,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIconSizes.sm, color: color),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BalanceStats _calculateStats() {
    double totalOwed = 0;
    double totalOwes = 0;
    var settledCount = 0;
    var unsettledCount = 0;

    for (final balance in balances) {
      if (balance.isSettled) {
        settledCount++;
      } else {
        unsettledCount++;
        if (balance.isOwedMoneyByGroup) {
          totalOwed += balance.absoluteBalance;
        } else {
          totalOwes += balance.absoluteBalance;
        }
      }
    }

    return _BalanceStats(
      totalOwed: totalOwed,
      totalOwes: totalOwes,
      settledCount: settledCount,
      unsettledCount: unsettledCount,
    );
  }
}

class _BalanceStats {
  const _BalanceStats({
    required this.totalOwed,
    required this.totalOwes,
    required this.settledCount,
    required this.unsettledCount,
  });

  final double totalOwed;
  final double totalOwes;
  final int settledCount;
  final int unsettledCount;
}
