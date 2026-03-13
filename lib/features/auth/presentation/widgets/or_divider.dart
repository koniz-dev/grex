import 'package:flutter/material.dart';
import 'package:grex/shared/extensions/context_extensions.dart';

/// Horizontal divider widget with "or" text in the center
///
/// Used to separate different authentication methods on login/register screens.
/// Uses theme colors and proper spacing for consistent appearance.
class OrDivider extends StatelessWidget {
  /// Creates an [OrDivider] widget.
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.dividerColor,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            context.l10n.orContinueWith,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.dividerColor,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
