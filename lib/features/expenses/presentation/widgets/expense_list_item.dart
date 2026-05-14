import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_icon_sizes.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

/// Card that summarises a single [Expense] in the expense list.
///
/// Mobile UX:
///   * The whole card is a tap target — primary action lives in [InkWell],
///     not in a chevron — paired with a light selection haptic.
///   * Header packs description + optional category badge on the left and a
///     prominent amount on the right; the eye scans price first, then label.
///   * Footer condenses payer / participants / date / split-validity into two
///     subtle rows so the card stays scan-friendly without burying signal.
class ExpenseListItem extends StatelessWidget {
  /// Creates an [ExpenseListItem].
  const ExpenseListItem({
    required this.expense,
    required this.onTap,
    required this.groupCurrency,
    super.key,
  });

  /// The expense to display.
  final Expense expense;

  /// Callback invoked when the user taps the card.
  final VoidCallback onTap;

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
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  expense: expense,
                  groupCurrency: groupCurrency,
                  theme: theme,
                  groupLabel: l10n.groupCurrencyLabel(groupCurrency),
                ),
                const SizedBox(height: AppSpacing.md),
                _MetaRow(
                  leadingIcon: Icons.person_outline_rounded,
                  leadingText: l10n.paidByPerson(expense.payerName),
                  trailingIcon: Icons.group_outlined,
                  trailingText: l10n.participantsCount(
                    expense.participants.length,
                  ),
                  mutedColor: muted,
                  textStyle: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                _FooterRow(
                  expense: expense,
                  theme: theme,
                  invalidLabel: l10n.invalidSplit,
                  validLabel: l10n.validSplit,
                  mutedColor: muted,
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
    required this.expense,
    required this.groupCurrency,
    required this.theme,
    required this.groupLabel,
  });

  final Expense expense;
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
              Text(
                expense.description,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (expense.category != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _CategoryBadge(label: expense.category!, scheme: scheme),
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
                amount: expense.amount,
                currencyCode: expense.currency,
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            if (expense.currency != groupCurrency) ...[
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

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.scheme});

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppRadius.brMd,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.leadingIcon,
    required this.leadingText,
    required this.trailingIcon,
    required this.trailingText,
    required this.mutedColor,
    required this.textStyle,
  });

  final IconData leadingIcon;
  final String leadingText;
  final IconData trailingIcon;
  final String trailingText;
  final Color mutedColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final style = textStyle?.copyWith(color: mutedColor);
    return Row(
      children: [
        Icon(leadingIcon, size: AppIconSizes.sm, color: mutedColor),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            leadingText,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(trailingIcon, size: AppIconSizes.sm, color: mutedColor),
        const SizedBox(width: AppSpacing.xs),
        Text(trailingText, style: style),
      ],
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.expense,
    required this.theme,
    required this.invalidLabel,
    required this.validLabel,
    required this.mutedColor,
  });

  final Expense expense;
  final ThemeData theme;
  final String invalidLabel;
  final String validLabel;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final dateLocale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = _formatRelative(
      context,
      expense.expenseDate,
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
        if (!expense.isValidSplit) ...[
          Icon(
            Icons.warning_amber_rounded,
            size: AppIconSizes.sm,
            color: scheme.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            invalidLabel,
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.error),
          ),
        ] else ...[
          Icon(
            Icons.check_circle_outline_rounded,
            size: AppIconSizes.sm,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            validLabel,
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary),
          ),
        ],
      ],
    );
  }

  String _formatRelative(BuildContext context, DateTime date, String locale) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayOnly = DateTime(date.year, date.month, date.day);

    if (dayOnly == today) return l10n.today;
    if (dayOnly == yesterday) return l10n.yesterday;
    if (now.difference(date).inDays < 7) {
      // Locale-aware weekday abbreviation ("Mon", "Lun", "اثنين"…).
      return DateFormat.E(locale).format(date);
    }
    // Locale-aware short date ("1/9/25", "9/1/25"…).
    return DateFormat.yMd(locale).format(date);
  }
}
