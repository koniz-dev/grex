import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/router_delegate.dart';

/// Widget for displaying breadcrumb navigation
class BreadcrumbNavigation extends StatelessWidget {
  /// Creates a [BreadcrumbNavigation] widget.
  const BreadcrumbNavigation({
    super.key,
    this.customBreadcrumbs,
    this.showHome = true,
    this.textColor,
    this.separatorColor,
  });

  /// Optional list of custom breadcrumbs to display.
  /// If null, breadcrumbs will be generated from the current route.
  final List<BreadcrumbItem>? customBreadcrumbs;

  /// Whether to show the 'Home' link at the beginning.
  final bool showHome;

  /// Color for the breadcrumb text.
  final Color? textColor;

  /// Color for the separator icon.
  final Color? separatorColor;

  @override
  Widget build(BuildContext context) {
    final breadcrumbs =
        customBreadcrumbs ?? AppRouterDelegate.generateBreadcrumbs(context);

    if (breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (showHome) ...[
            _buildBreadcrumbItem(
              context,
              const BreadcrumbItem(title: 'Home', path: '/'),
              isLast: false,
            ),
            _buildSeparator(context),
          ],
          ...breadcrumbs.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == breadcrumbs.length - 1;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBreadcrumbItem(context, item, isLast: isLast),
                if (!isLast) _buildSeparator(context),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    BreadcrumbItem item, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final effectiveTextColor =
        textColor ??
        (isLast ? theme.colorScheme.onSurface : theme.colorScheme.primary);

    return InkWell(
      onTap: isLast ? null : () => context.go(item.path),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          item.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: effectiveTextColor,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
            decoration: isLast ? null : TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSeparatorColor =
        separatorColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: effectiveSeparatorColor,
      ),
    );
  }
}

/// Compact breadcrumb navigation for app bars
class CompactBreadcrumbNavigation extends StatelessWidget {
  /// Creates a [CompactBreadcrumbNavigation] widget.
  const CompactBreadcrumbNavigation({
    super.key,
    this.maxItems = 2,
    this.customBreadcrumbs,
  });

  /// Maximum number of items to show before truncating.
  final int maxItems;

  /// Optional list of custom breadcrumbs to display.
  final List<BreadcrumbItem>? customBreadcrumbs;

  @override
  Widget build(BuildContext context) {
    final breadcrumbs =
        customBreadcrumbs ?? AppRouterDelegate.generateBreadcrumbs(context);

    if (breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show only the last few items
    final visibleBreadcrumbs = breadcrumbs.length > maxItems
        ? breadcrumbs.sublist(breadcrumbs.length - maxItems)
        : breadcrumbs;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (breadcrumbs.length > maxItems) ...[
          Icon(
            Icons.more_horiz,
            size: 16,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
        ],
        ...visibleBreadcrumbs.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == visibleBreadcrumbs.length - 1;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactItem(context, item, isLast: isLast),
              if (!isLast) _buildSeparator(context),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCompactItem(
    BuildContext context,
    BreadcrumbItem item, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isLast ? null : () => context.go(item.path),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          item.title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isLast
                ? theme.colorScheme.onSurface
                : theme.colorScheme.primary,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(
        Icons.chevron_right,
        size: 12,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
