import 'package:flutter/material.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// A list item widget that displays summary information about a group
class GroupListItem extends StatelessWidget {
  /// Creates a [GroupListItem] instance
  const GroupListItem({
    required this.group,
    required this.onTap,
    super.key,
  });

  /// The group entity to display
  final Group group;

  /// Callback when the item is tapped
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Group Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _getGroupInitials(group.name),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Group Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.members.length} thành viên',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.monetization_on_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          CurrencyFormatter.getCurrencySymbol(group.currency),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGroupInitials(String name) {
    if (name.isEmpty) return 'G';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1))
          .toUpperCase();
    }
  }
}
