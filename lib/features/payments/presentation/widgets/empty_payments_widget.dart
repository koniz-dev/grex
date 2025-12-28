import 'package:flutter/material.dart';
import 'package:grex/shared/extensions/context_extensions.dart';

/// Widget displayed when there are no payments to show
class EmptyPaymentsWidget extends StatelessWidget {
  /// Creates an [EmptyPaymentsWidget] instance
  const EmptyPaymentsWidget({
    required this.message,
    super.key,
    this.onAddPayment,
  });

  /// The message to display when no payments are found
  final String message;

  /// Callback when the user wants to add a payment
  final VoidCallback? onAddPayment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noPayments,
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
            if (onAddPayment != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAddPayment,
                icon: const Icon(Icons.add),
                label: Text(l10n.addFirstPayment),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
