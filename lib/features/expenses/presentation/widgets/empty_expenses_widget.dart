import 'package:flutter/material.dart';

/// Widget displayed when there are no expenses to show
class EmptyExpensesWidget extends StatelessWidget {
  /// Creates an [EmptyExpensesWidget] instance
  const EmptyExpensesWidget({
    required this.message,
    super.key,
    this.onAddExpense,
  });

  /// The message to display when the list is empty
  final String message;

  /// Callback triggered when the "Add First Expense" button is pressed
  final VoidCallback? onAddExpense;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Expenses',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAddExpense != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAddExpense,
                icon: const Icon(Icons.add),
                label: const Text('Add First Expense'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
