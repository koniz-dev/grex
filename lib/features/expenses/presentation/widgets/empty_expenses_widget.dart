import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_icon_sizes.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';

/// Empty-state widget shown on the expense list.
///
/// Renders a centred illustration, a localised title, a context-aware
/// description (driven by [hasActiveFilters]), and an optional primary CTA
/// to add the first expense. Wrapping in a [SingleChildScrollView] keeps the
/// state scrollable so the surrounding [RefreshIndicator] still works and
/// nothing overflows on small phones.
class EmptyExpensesWidget extends StatelessWidget {
  /// Creates an [EmptyExpensesWidget].
  const EmptyExpensesWidget({
    this.hasActiveFilters = false,
    this.onAddExpense,
    super.key,
  });

  /// Whether the page currently has active search or filters. Controls which
  /// description is shown — "no expenses yet" vs "no results match".
  final bool hasActiveFilters;

  /// Optional callback invoked when the user taps the add-first-expense CTA.
  /// The CTA is hidden when this is `null` (e.g. in filtered states where
  /// adding an expense isn't the right next step).
  final VoidCallback? onAddExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxxl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: AppIconSizes.illustration,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.noExpensesTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    hasActiveFilters
                        ? l10n.noExpensesMatchFilters
                        : l10n.noExpensesDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onAddExpense != null) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    ElevatedButton.icon(
                      onPressed: () {
                        unawaited(HapticFeedback.lightImpact());
                        onAddExpense!();
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.addFirstExpense),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.md,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
