import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_icon_sizes.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

/// Card that summarises a single [Payment] in the payment list.
///
/// Mobile UX:
///   * The whole card is a tap target — primary action lives in [InkWell],
///     not in the delete button — paired with a light selection haptic.
///   * Header packs payer → recipient on the left and the amount on the
///     right; the eye scans price first, then who paid whom.
///   * Date row sits at the bottom with the optional delete affordance —
///     destructive actions placed away from the primary tap target.
class PaymentListItem extends StatelessWidget {
  /// Creates a [PaymentListItem].
  const PaymentListItem({
    required this.payment,
    required this.onTap,
    required this.groupCurrency,
    super.key,
    this.onDelete,
  });

  /// The payment to display.
  final Payment payment;

  /// Callback invoked when the user taps the card.
  final VoidCallback onTap;

  /// Optional callback invoked when the user taps the delete-payment button.
  /// The delete affordance is hidden when this is `null`.
  final VoidCallback? onDelete;

  /// Currency code of the parent group — used to surface the badge when an
  /// expense was entered in a different currency.
  final String groupCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final l10n = context.l10n;

    return RepaintBoundary(
      child: Card(
        elevation: AppElevation.card,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            onTap();
          },
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  payment: payment,
                  groupCurrency: groupCurrency,
                  theme: theme,
                  groupLabel: l10n.groupCurrencyLabel(groupCurrency),
                ),
                const SizedBox(height: AppSpacing.md),
                _FooterRow(
                  payment: payment,
                  theme: theme,
                  mutedColor: muted,
                  onDelete: onDelete,
                  deleteTooltip: l10n.deletePaymentTooltip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.payment,
    required this.groupCurrency,
    required this.theme,
    required this.groupLabel,
  });

  final Payment payment;
  final String groupCurrency;
  final ThemeData theme;
  final String groupLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      horizontal: AppSpacing.sm,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: AppIconSizes.sm,
                      color: scheme.onSurfaceVariant,
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
              if (payment.description != null &&
                  payment.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  payment.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
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
                color: scheme.primary,
              ),
            ),
            if (payment.currency != groupCurrency) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                groupLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.payment,
    required this.theme,
    required this.mutedColor,
    required this.onDelete,
    required this.deleteTooltip,
  });

  final Payment payment;
  final ThemeData theme;
  final Color mutedColor;
  final VoidCallback? onDelete;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateLocale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = _formatRelative(
      l10n.today,
      l10n.yesterday,
      payment.paymentDate,
      dateLocale,
    );

    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: AppIconSizes.sm,
          color: mutedColor,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          formattedDate,
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
        const Spacer(),
        if (onDelete != null)
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: AppIconSizes.md,
              color: theme.colorScheme.error,
            ),
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              onDelete!.call();
            },
            tooltip: deleteTooltip,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  static String _formatRelative(
    String todayLabel,
    String yesterdayLabel,
    DateTime date,
    String locale,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayOnly = DateTime(date.year, date.month, date.day);

    if (dayOnly == today) return todayLabel;
    if (dayOnly == yesterday) return yesterdayLabel;
    if (now.difference(date).inDays < 7) {
      return DateFormat.E(locale).format(date);
    }
    return DateFormat.yMd(locale).format(date);
  }
}
