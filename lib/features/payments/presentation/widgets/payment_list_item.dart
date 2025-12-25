import 'package:flutter/material.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Widget displaying a single payment item in the list
class PaymentListItem extends StatelessWidget {
  /// Creates a [PaymentListItem] instance
  const PaymentListItem({
    required this.payment,
    required this.onTap,
    required this.groupCurrency,
    super.key,
    this.onDelete,
  });

  /// The payment to display
  final Payment payment;

  /// Callback when the user taps on the item
  final VoidCallback onTap;

  /// Optional callback when the user wants to delete the payment
  final VoidCallback? onDelete;

  /// The currency of the group
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
              // Header row with payer -> recipient and amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payer -> Recipient
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                payment.payerName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                payment.recipientName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Description if available
                        if (payment.description != null &&
                            payment.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            payment.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                          amount: payment.amount,
                          currencyCode: payment.currency,
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (payment.currency != groupCurrency) ...[
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

              // Date and actions row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(payment.paymentDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (onDelete != null) ...[
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete payment',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
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
    final paymentDate = DateTime(date.year, date.month, date.day);

    if (paymentDate == today) {
      return 'Today';
    } else if (paymentDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
