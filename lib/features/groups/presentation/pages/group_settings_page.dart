import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/shared/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

/// Page for viewing and editing group settings
class GroupSettingsPage extends StatelessWidget {
  /// Creates a [GroupSettingsPage] instance
  const GroupSettingsPage({
    required this.groupId,
    super.key,
  });

  /// The ID of the group to manage
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GroupBloc>()..add(const GroupsLoadRequested()),
      child: GroupSettingsView(groupId: groupId),
    );
  }
}

/// View component for group settings
class GroupSettingsView extends StatefulWidget {
  /// Creates a [GroupSettingsView] instance
  const GroupSettingsView({
    required this.groupId,
    super.key,
  });

  /// The ID of the group to manage
  final String groupId;

  @override
  State<GroupSettingsView> createState() => _GroupSettingsViewState();
}

class _GroupSettingsViewState extends State<GroupSettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _inviteNameController = TextEditingController();

  String _selectedCurrency = 'VND';
  MemberRole _selectedInviteRole = MemberRole.editor;
  bool _isLoading = false;
  Group? _currentGroup;

  @override
  void initState() {
    super.initState();
    // Group will be loaded asynchronously from Bloc
    // Form fields will be initialized when group is available
  }

  /// Get the group from the current Bloc state
  Group? _getGroupFromState(GroupState state) {
    if (state is GroupsLoaded) {
      return state.getGroupById(widget.groupId);
    }
    return null;
  }

  /// Initialize form fields when group is loaded
  void _initializeFormFields(Group group) {
    if (_nameController.text.isEmpty) {
      _nameController.text = group.name;
    }
    if (_selectedCurrency == 'VND') {
      _selectedCurrency = group.currency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _inviteEmailController.dispose();
    _inviteNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt nhóm'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          // Save button
          TextButton(
            onPressed: _isLoading ? null : _saveGroupSettings,
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: BlocListener<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state is GroupLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }

          // Initialize form fields when group is loaded
          if (state is GroupsLoaded) {
            final group = state.getGroupById(widget.groupId);
            if (group != null && _currentGroup != group) {
              _currentGroup = group;
              _initializeFormFields(group);
            }
          }

          if (state is GroupOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );

            // Clear invite form if member was invited
            if (state.operationType == 'invite') {
              _inviteEmailController.clear();
              _inviteNameController.clear();
              setState(() => _selectedInviteRole = MemberRole.editor);
            }
          } else if (state is GroupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.userFriendlyMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<GroupBloc, GroupState>(
          builder: (context, state) {
            final group = _getGroupFromState(state);

            if (group == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Information Section
                    _buildGroupInfoSection(group),

                    const SizedBox(height: 32),

                    // Member Management Section
                    _buildMemberManagementSection(group),

                    const SizedBox(height: 32),

                    // Danger Zone Section
                    _buildDangerZoneSection(group),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGroupInfoSection(Group group) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin nhóm',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            // Group Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm',
                hintText: 'Nhập tên nhóm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên nhóm';
                }
                if (value.trim().length < 2) {
                  return 'Tên nhóm phải có ít nhất 2 ký tự';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Currency Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Tiền tệ mặc định',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              items: CurrencyFormatter.getSupportedCurrencies().map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Row(
                    children: [
                      Text(CurrencyFormatter.getCurrencySymbol(currency)),
                      const SizedBox(width: 8),
                      Text(currency),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCurrency = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Group Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thành viên',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '${group.memberCount}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo ngày',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(group.createdAt),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberManagementSection(Group group) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý thành viên',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            // Invite Member Section
            _buildInviteMemberSection(),

            const SizedBox(height: 24),

            // Members List
            _buildMembersList(group),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteMemberSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Mời thành viên mới',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _inviteEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'user@example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Display Name Field
          TextFormField(
            controller: _inviteNameController,
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị',
              hintText: 'Nhập tên hiển thị',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên hiển thị';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Role Selection
          DropdownButtonFormField<MemberRole>(
            initialValue: _selectedInviteRole,
            decoration: const InputDecoration(
              labelText: 'Vai trò',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.admin_panel_settings),
            ),
            items: const [
              DropdownMenuItem(
                value: MemberRole.viewer,
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20),
                    SizedBox(width: 8),
                    Text('Người xem'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: MemberRole.editor,
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Biên tập viên'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: MemberRole.administrator,
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 20),
                    SizedBox(width: 8),
                    Text('Quản trị viên'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedInviteRole = value);
              }
            },
          ),

          const SizedBox(height: 16),

          // Invite Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _inviteMember,
              icon: const Icon(Icons.send),
              label: const Text('Gửi lời mời'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(Group group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách thành viên (${group.memberCount})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        ...group.members.map((member) => _buildMemberItem(member, group)),
      ],
    );
  }

  Widget _buildMemberItem(GroupMember member, Group group) {
    final isCreator = member.userId == group.creatorId;
    final canModify = !isCreator; // Can't modify creator

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Member Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                _getMemberInitials(member.displayName),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 16),

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
                      if (isCreator) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Tạo nhóm',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
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
                        _getRoleDisplayName(member.role),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(member.joinedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            if (canModify) ...[
              PopupMenuButton<String>(
                onSelected: (action) => _handleMemberAction(action, member),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz),
                        SizedBox(width: 8),
                        Text('Đổi vai trò'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Xóa khỏi nhóm',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection(Group group) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vùng nguy hiểm',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 16),

            // Leave Group Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _showLeaveGroupDialog,
                icon: const Icon(Icons.exit_to_app, color: Colors.orange),
                label: const Text(
                  'Rời khỏi nhóm',
                  style: TextStyle(color: Colors.orange),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Delete Group Button (only for creator)
            if (group.creatorId == 'current-user-id')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _showDeleteGroupDialog,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'Xóa nhóm',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getMemberInitials(String name) {
    if (name.isEmpty) return 'U';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words.last.substring(0, 1))
          .toUpperCase();
    }
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

  String _getRoleDisplayName(MemberRole role) {
    switch (role) {
      case MemberRole.administrator:
        return 'Quản trị viên';
      case MemberRole.editor:
        return 'Biên tập viên';
      case MemberRole.viewer:
        return 'Người xem';
    }
  }

  void _saveGroupSettings() {
    if (!_formKey.currentState!.validate()) return;
    if (_currentGroup == null) return;

    final hasChanges =
        _nameController.text.trim() != _currentGroup!.name ||
        _selectedCurrency != _currentGroup!.currency;

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có thay đổi nào để lưu')),
      );
      return;
    }

    context.read<GroupBloc>().add(
      GroupUpdateRequested(
        groupId: _currentGroup!.id,
        name: _nameController.text.trim(),
        currency: _selectedCurrency,
      ),
    );
  }

  void _inviteMember() {
    if (!_formKey.currentState!.validate()) return;
    if (_currentGroup == null) return;

    context.read<GroupBloc>().add(
      GroupMemberInvited(
        groupId: _currentGroup!.id,
        email: _inviteEmailController.text.trim(),
        displayName: _inviteNameController.text.trim(),
        role: _selectedInviteRole,
      ),
    );
  }

  void _handleMemberAction(String action, GroupMember member) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(member);
      case 'remove':
        _showRemoveMemberDialog(member);
    }
  }

  void _showChangeRoleDialog(GroupMember member) {
    var selectedRole = member.role;

    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Đổi vai trò - ${member.displayName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Chọn vai trò mới cho ${member.displayName}:'),
                const SizedBox(height: 16),
                RadioGroup<MemberRole>(
                  groupValue: selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: MemberRole.values
                        .map(
                          (role) => RadioListTile<MemberRole>(
                            title: Text(_getRoleDisplayName(role)),
                            subtitle: Text(_getRoleDescription(role)),
                            value: role,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: selectedRole == member.role
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        context.read<GroupBloc>().add(
                          GroupMemberRoleChanged(
                            groupId: _currentGroup!.id,
                            userId: member.userId,
                            newRole: selectedRole,
                          ),
                        );
                      },
                child: const Text('Cập nhật'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(GroupMember member) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa thành viên'),
          content: Text(
            'Bạn có chắc chắn muốn xóa ${member.displayName} khỏi nhóm?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<GroupBloc>().add(
                  GroupMemberRemoved(
                    groupId: _currentGroup!.id,
                    userId: member.userId,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveGroupDialog() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rời khỏi nhóm'),
          content: Text(
            'Bạn có chắc chắn muốn rời khỏi nhóm '
            '"${_currentGroup?.name ?? ''}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<GroupBloc>().add(
                  GroupLeaveRequested(groupId: _currentGroup!.id),
                );
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Rời nhóm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteGroupDialog() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa nhóm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn xóa nhóm '
                '"${_currentGroup?.name ?? ''}"?',
              ),
              const SizedBox(height: 8),
              const Text(
                'Hành động này không thể hoàn tác. '
                'Tất cả dữ liệu của nhóm sẽ bị xóa vĩnh viễn.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<GroupBloc>().add(
                  GroupDeleteRequested(groupId: _currentGroup!.id),
                );
                Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst); // Go back to home
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa nhóm'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(MemberRole role) {
    switch (role) {
      case MemberRole.administrator:
        return 'Có thể quản lý nhóm và thành viên';
      case MemberRole.editor:
        return 'Có thể thêm và chỉnh sửa chi phí';
      case MemberRole.viewer:
        return 'Chỉ có thể xem thông tin';
    }
  }
}
