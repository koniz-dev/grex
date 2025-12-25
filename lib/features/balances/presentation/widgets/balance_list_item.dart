import 'package:flutter/material.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Widget displaying a single balance item in the list
class BalanceListItem extends StatelessWidget {
  /// Creates a [BalanceListItem] instance
  const BalanceListItem({
    required this.balance,
    super.key,
    this.onTap,
  });

  /// The balance data for a member
  final Balance balance;

  /// Callback when the item is tapped
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Member avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: _getBalanceColor(
                  context,
                  balance.status,
                ).withValues(alpha: 0.1),
                child: Text(
                  balance.displayName.isNotEmpty
                      ? balance.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getBalanceColor(context, balance.status),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Member info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getBalanceStatusText(balance),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Balance amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(
                      amount: balance.absoluteBalance,
                      currencyCode: balance.currency,
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getBalanceColor(context, balance.status),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getBalanceColor(
                        context,
                        balance.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(balance.status),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getBalanceColor(context, balance.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // Chevron icon
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBalanceStatusText(Balance balance) {
    if (balance.isSettled) {
      return 'All settled up';
    } else if (balance.owesMoneyToGroup) {
      return 'Owes money to group';
    } else {
      return 'Is owed money by group';
    }
  }

  String _getStatusLabel(BalanceStatus status) {
    switch (status) {
      case BalanceStatus.owes:
        return 'OWES';
      case BalanceStatus.owed:
        return 'OWED';
      case BalanceStatus.settled:
        return 'SETTLED';
    }
  }

  Color _getBalanceColor(BuildContext context, BalanceStatus status) {
    switch (status) {
      case BalanceStatus.owes:
        return Theme.of(context).colorScheme.error;
      case BalanceStatus.owed:
        return Colors.green;
      case BalanceStatus.settled:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
