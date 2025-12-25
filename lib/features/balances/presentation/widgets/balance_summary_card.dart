import 'package:flutter/material.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Widget displaying a summary of all balances in the group
class BalanceSummaryCard extends StatelessWidget {
  /// Creates a [BalanceSummaryCard] instance
  const BalanceSummaryCard({
    required this.balances,
    required this.currency,
    super.key,
    this.onGenerateSettlement,
  });

  /// The list of balances to summarize
  final List<Balance> balances;

  /// The currency code for the balances
  final String currency;

  /// Callback to generate a settlement plan
  final VoidCallback? onGenerateSettlement;

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
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Balance Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Statistics grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Owed',
                    CurrencyFormatter.format(
                      amount: stats.totalOwed,
                      currencyCode: currency,
                    ),
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Owes',
                    CurrencyFormatter.format(
                      amount: stats.totalOwes,
                      currencyCode: currency,
                    ),
                    Theme.of(context).colorScheme.error,
                    Icons.trending_down,
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
                    'Settled',
                    '${stats.settledCount}',
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Unsettled',
                    '${stats.unsettledCount}',
                    Theme.of(context).colorScheme.primary,
                    Icons.pending,
                  ),
                ),
              ],
            ),

            // Settlement button
            if (stats.unsettledCount > 0) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onGenerateSettlement,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Generate Settlement Plan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // All settled message
            if (stats.unsettledCount == 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All members are settled up!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
