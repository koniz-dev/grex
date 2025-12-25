import 'package:flutter/material.dart';
import 'package:grex/features/balances/domain/entities/settlement.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Widget displaying a summary of the settlement plan
class SettlementSummaryCard extends StatelessWidget {
  /// Creates a [SettlementSummaryCard] instance
  const SettlementSummaryCard({
    required this.settlements,
    required this.currency,
    super.key,
  });

  /// The list of settlements in the plan
  final List<Settlement> settlements;

  /// The currency code for the settlements
  final String currency;

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Settlement Plan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimized Settlement',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This plan minimizes the number of transactions needed '
                    'to settle all balances.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Payments',
                    '${settlements.length}',
                    Theme.of(context).colorScheme.primary,
                    Icons.payment,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Amount',
                    CurrencyFormatter.format(
                      amount: stats.totalAmount,
                      currencyCode: currency,
                    ),
                    Colors.green,
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'People Paying',
                    '${stats.uniquePayers}',
                    Theme.of(context).colorScheme.error,
                    Icons.person_remove,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'People Receiving',
                    '${stats.uniqueRecipients}',
                    Colors.green,
                    Icons.person_add,
                  ),
                ),
              ],
            ),

            // Instructions
            if (settlements.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap "Record Payment" on any settlement below to '
                        'mark it as completed.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  _SettlementStats _calculateStats() {
    double totalAmount = 0;
    final uniquePayers = <String>{};
    final uniqueRecipients = <String>{};

    for (final settlement in settlements) {
      totalAmount += settlement.amount;
      uniquePayers.add(settlement.payerId);
      uniqueRecipients.add(settlement.recipientId);
    }

    return _SettlementStats(
      totalAmount: totalAmount,
      uniquePayers: uniquePayers.length,
      uniqueRecipients: uniqueRecipients.length,
    );
  }
}

class _SettlementStats {
  const _SettlementStats({
    required this.totalAmount,
    required this.uniquePayers,
    required this.uniqueRecipients,
  });
  final double totalAmount;
  final int uniquePayers;
  final int uniqueRecipients;
}
