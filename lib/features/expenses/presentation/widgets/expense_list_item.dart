import 'package:flutter/material.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Widget displaying a single expense item in the list
class ExpenseListItem extends StatelessWidget {
  /// Creates an [ExpenseListItem] instance
  const ExpenseListItem({
    required this.expense,
    required this.onTap,
    required this.groupCurrency,
    super.key,
  });

  /// The expense entity to display
  final Expense expense;

  /// Callback triggered when the item is tapped
  final VoidCallback onTap;

  /// The currency code used by the group
  final String groupCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with description and amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (expense.category != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              expense.category!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(
                          amount: expense.amount,
                          currencyCode: expense.currency,
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (expense.currency != groupCurrency) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Group: $groupCurrency',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Payer and participants info
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Paid by ${expense.payerName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.group,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    expense.participantCountText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Date and validation status
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(expense.expenseDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (!expense.isValidSplit) ...[
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Invalid split',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Valid',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return 'Today';
    } else if (expenseDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
