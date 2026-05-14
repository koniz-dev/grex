import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_icon_sizes.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// A tappable card showing a one-line summary of a [Group].
///
/// Mobile UX choices:
///   * Touch target wraps the full card via [InkWell] (no tiny chevron-only
///     hit area).
///   * Avatar uses the primary container tint so the brand colour stays
///     anchored even when group data is loading.
///   * Selection feedback uses [HapticFeedback.selectionClick] — light enough
///     to not feel intrusive on rapid scrolling, strong enough to confirm
///     the tap landed.
class GroupListItem extends StatelessWidget {
  /// Creates a [GroupListItem].
  const GroupListItem({
    required this.group,
    required this.onTap,
    super.key,
  });

  /// The group entity to display.
  final Group group;

  /// Callback invoked when the user taps the card.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(group.currency);

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
            child: Row(
              children: [
                _GroupAvatar(name: group.name),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _MetaRow(
                        membersText: context.l10n.membersCount(
                          group.members.length,
                        ),
                        currencySymbol: currencySymbol,
                        mutedColor: muted,
                        textStyle: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIconSizes.lg,
                  color: muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 24,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static String _initials(String name) {
    if (name.trim().isEmpty) return 'G';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.characters.first.toUpperCase();
    }
    return (words[0].characters.first + words[1].characters.first)
        .toUpperCase();
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.membersText,
    required this.currencySymbol,
    required this.mutedColor,
    required this.textStyle,
  });

  final String membersText;
  final String currencySymbol;
  final Color mutedColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final muted = textStyle?.copyWith(color: mutedColor);
    return Row(
      children: [
        Icon(Icons.people_outline, size: AppIconSizes.sm, color: mutedColor),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            membersText,
            style: muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Icon(
          Icons.monetization_on_outlined,
          size: AppIconSizes.sm,
          color: mutedColor,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          currencySymbol,
          style: muted?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
