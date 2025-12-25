import 'package:flutter/material.dart';
import 'package:grex/features/balances/domain/entities/settlement.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Widget displaying a single settlement item in the list
class SettlementListItem extends StatelessWidget {
  /// Creates a [SettlementListItem] instance
  const SettlementListItem({
    required this.settlement,
    super.key,
    this.onRecordPayment,
    this.onTap,
  });

  /// The settlement data
  final Settlement settlement;

  /// Callback when the record payment button is tapped
  final VoidCallback? onRecordPayment;

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
          child: Column(
            children: [
              // Main settlement info
              Row(
                children: [
                  // Payer avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.1),
                    child: Text(
                      settlement.payerName.isNotEmpty
                          ? settlement.payerName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Arrow and amount
                  Expanded(
                    child: Row(
                      children: [
                        // Payer name
                        Expanded(
                          child: Text(
                            settlement.payerName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),

                        // Arrow
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),

                        const SizedBox(width: 8),

                        // Amount
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            CurrencyFormatter.format(
                              amount: settlement.amount,
                              currencyCode: settlement.currency,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Arrow
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Recipient avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    child: Text(
                      settlement.recipientName.isNotEmpty
                          ? settlement.recipientName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Settlement description
              Row(
                children: [
                  Expanded(
                    child: Text(
                      settlement.recipientName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onRecordPayment,
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Record Payment'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
