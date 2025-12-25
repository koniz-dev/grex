import 'package:flutter/material.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';

/// Widget displaying action buttons for an expense
class ExpenseActionsWidget extends StatelessWidget {
  /// Creates an [ExpenseActionsWidget] instance
  const ExpenseActionsWidget({
    required this.expense,
    super.key,
    this.onEditPressed,
    this.onDeletePressed,
    this.onDuplicatePressed,
  });

  /// The expense entity to perform actions on
  final Expense expense;

  /// Callback when edit is pressed
  final VoidCallback? onEditPressed;

  /// Callback when delete is pressed
  final VoidCallback? onDeletePressed;

  /// Callback when duplicate is pressed
  final VoidCallback? onDuplicatePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Edit expense
        if (onEditPressed != null)
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Expense'),
            subtitle: const Text('Modify description, amount, or participants'),
            onTap: onEditPressed,
            trailing: const Icon(Icons.chevron_right),
          ),

        // Duplicate expense
        if (onDuplicatePressed != null) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Duplicate Expense'),
            subtitle: const Text('Create a copy of this expense'),
            onTap: onDuplicatePressed,
            trailing: const Icon(Icons.chevron_right),
          ),
        ],

        // Delete expense
        if (onDeletePressed != null) ...[
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete Expense',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            subtitle: const Text('This action cannot be undone'),
            onTap: onDeletePressed,
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
