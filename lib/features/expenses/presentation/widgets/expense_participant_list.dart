import 'package:flutter/material.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Widget displaying the list of participants in an expense with their share
/// amounts
class ExpenseParticipantList extends StatelessWidget {
  /// Creates an [ExpenseParticipantList] instance
  const ExpenseParticipantList({
    required this.expense,
    super.key,
    this.showAmounts = true,
    this.showPercentages = false,
  });

  /// The expense entity containing participants
  final Expense expense;

  /// Whether to show the share amount for each participant
  final bool showAmounts;

  /// Whether to show the share percentage for each participant
  final bool showPercentages;

  @override
  Widget build(BuildContext context) {
    if (expense.participants.isEmpty) {
      return const Text('No participants');
    }

    return Column(
      children: expense.participants.map((participant) {
        final isPayer = participant.userId == expense.payerId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: isPayer
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  participant.displayName.isNotEmpty
                      ? participant.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: isPayer
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Name and payer indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          participant.displayName,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: isPayer
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                        ),
                        if (isPayer) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PAYER',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (showPercentages) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${participant.sharePercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Amount
              if (showAmounts)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        amount: participant.shareAmount,
                        currencyCode: expense.currency,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPayer
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    if (showPercentages) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${participant.sharePercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
