import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/core/routing/navigation_extensions.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/shared/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

/// Page that reveals detailed information about a group
class GroupDetailsPage extends StatelessWidget {
  /// Creates a [GroupDetailsPage] instance
  const GroupDetailsPage({
    required this.groupId,
    super.key,
  });

  /// The ID of the group to display
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GroupBloc>()..add(const GroupsLoadRequested()),
      child: GroupDetailsView(groupId: groupId),
    );
  }
}

/// View component for the group details page
class GroupDetailsView extends StatelessWidget {
  /// Creates a [GroupDetailsView] instance
  const GroupDetailsView({
    required this.groupId,
    super.key,
  });

  /// The ID of the group to display
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupBloc, GroupState>(
      builder: (context, state) {
        final group = _getGroupFromState(state);

        return Scaffold(
          appBar: AppBar(
            title: Text(group?.name ?? 'Group Details'),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            actions: [
              // Settings button (only for administrators)
              if (group != null && _canManageGroup(state, group))
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _navigateToSettings(context),
                ),
            ],
          ),
          body: BlocListener<GroupBloc, GroupState>(
            listener: (context, state) {
              if (state is GroupError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.userFriendlyMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<GroupBloc>().add(const GroupsLoadRequested());
              },
              child: group == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGroupHeader(context, group),
                          const SizedBox(height: 24),
                          _buildQuickActions(context),
                          const SizedBox(height: 24),
                          _buildMembersSection(context, group),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupHeader(BuildContext context, Group group) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Group Avatar
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _getGroupInitials(group.name),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${CurrencyFormatter.getCurrencySymbol(
                          group.currency,
                        )} '
                        '${group.currency}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tạo ngày '
                        '${DateFormat('dd/MM/yyyy').format(group.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản lý',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.receipt_long_outlined,
                title: 'Chi phí',
                subtitle: 'Xem và thêm chi phí',
                onTap: () => _navigateToExpenses(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.payment_outlined,
                title: 'Thanh toán',
                subtitle: 'Ghi nhận thanh toán',
                onTap: () => _navigateToPayments(context),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.account_balance_outlined,
                title: 'Số dư',
                subtitle: 'Xem số dư và thanh toán',
                onTap: () => _navigateToBalances(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.share_outlined,
                title: 'Xuất dữ liệu',
                subtitle: 'Chia sẻ báo cáo',
                onTap: () => _navigateToExport(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, Group group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thành viên (${group.members.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            BlocBuilder<GroupBloc, GroupState>(
              builder: (context, state) {
                final canManage = _canManageGroup(state, group);
                if (!canManage) return const SizedBox.shrink();

                return TextButton.icon(
                  onPressed: () => _navigateToSettings(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Mời'),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Members List
        ...group.members.map(
          (member) => _buildMemberItem(context, member, group),
        ),
      ],
    );
  }

  Widget _buildMemberItem(
    BuildContext context,
    GroupMember member,
    Group group,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Member Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                _getMemberInitials(member.displayName),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (member.userId == group.creatorId) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Chủ nhóm',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getRoleIcon(member.role),
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.role.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tham gia '
                        '${DateFormat('dd/MM/yyyy').format(member.joinedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Group? _getGroupFromState(GroupState state) {
    if (state is GroupsLoaded) {
      for (final group in state.groups) {
        if (group.id == groupId) return group;
      }
    }
    return null;
  }

  bool _canManageGroup(GroupState state, Group group) {
    if (state is! GroupsLoaded) return false;

    final currentGroup = state.getGroupById(group.id);
    if (currentGroup == null) return false;

    // For now, assume current user can manage if they are the creator
    // In a real app, you'd check the current user's role
    return true; // Placeholder - should check actual user permissions
  }

  String _getGroupInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'G';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _getMemberInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  IconData _getRoleIcon(MemberRole role) {
    switch (role) {
      case MemberRole.administrator:
        return Icons.admin_panel_settings;
      case MemberRole.editor:
        return Icons.edit;
      case MemberRole.viewer:
        return Icons.visibility;
    }
  }

  // Navigation methods
  void _navigateToSettings(BuildContext context) {
    context.goToGroupSettings(groupId);
  }

  void _navigateToExpenses(BuildContext context) {
    context.goToExpenses(groupId);
  }

  void _navigateToPayments(BuildContext context) {
    context.goToPayments(groupId);
  }

  void _navigateToBalances(BuildContext context) {
    context.goToBalances(groupId);
  }

  void _navigateToExport(BuildContext context) {
    final group = _getGroupFromState(context.read<GroupBloc>().state);
    context.goToExport(groupId, groupName: group?.name);
  }
}
