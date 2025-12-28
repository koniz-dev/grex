import 'package:flutter/material.dart';
import 'package:grex/features/groups/presentation/pages/create_group_page.dart';
import 'package:grex/shared/extensions/context_extensions.dart';

/// Widget shown when there are no groups to display
class EmptyGroupsWidget extends StatelessWidget {
  /// Creates an [EmptyGroupsWidget] instance
  const EmptyGroupsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_add_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Chưa có nhóm nào',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Tạo nhóm đầu tiên để bắt đầu chia sẻ chi phí với bạn bè và '
              'gia đình',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Create group button
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateGroup(context),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.createNewGroup),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCreateGroup(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const CreateGroupPage(),
      ),
    );

    // If group was created successfully, the parent will handle refresh
    if (result ?? false) {
      // The GroupListPage will handle the refresh
    }
  }
}
