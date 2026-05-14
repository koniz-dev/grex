import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grex/features/groups/presentation/pages/create_group_page.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_icon_sizes.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';

/// Empty-state shown on the group list when the user has no groups.
///
/// UX choices:
///   * Centred illustration + title + body + primary CTA — the standard
///     "what / why / how" empty-state pattern users learn from iOS Mail,
///     Linear, Notion.
///   * CTA uses `ElevatedButton.icon` so the action and its meaning land in
///     the same scan — pairs with light haptic feedback to feel decisive.
///   * The widget is scroll-aware via [SingleChildScrollView] so it never
///     overflows on small phones (320pt) or when the keyboard is open.
class EmptyGroupsWidget extends StatelessWidget {
  /// Creates an [EmptyGroupsWidget].
  const EmptyGroupsWidget({super.key});

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
                      Icons.group_add_outlined,
                      size: AppIconSizes.illustration,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.noGroupsTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.noGroupsDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateGroup(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.createNewGroup),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateGroup(BuildContext context) async {
    unawaited(HapticFeedback.lightImpact());
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CreateGroupPage()),
    );
  }
}
