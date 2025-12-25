import 'package:equatable/equatable.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';

/// Base class for all group events
abstract class GroupEvent extends Equatable {
  /// Creates a [GroupEvent] instance
  const GroupEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request loading of user's groups
class GroupsLoadRequested extends GroupEvent {
  /// Creates a [GroupsLoadRequested] instance
  const GroupsLoadRequested();
}

/// Event to request creation of a new group
class GroupCreateRequested extends GroupEvent {
  /// Creates a [GroupCreateRequested] instance
  const GroupCreateRequested({
    required this.name,
    required this.currency,
    this.description,
  });

  /// The name of the group
  final String name;

  /// The currency code for the group
  final String currency;

  /// Optional description for the group
  final String? description;

  @override
  List<Object?> get props => [name, currency, description];
}

/// Event to request updating group information
class GroupUpdateRequested extends GroupEvent {
  /// Creates a [GroupUpdateRequested] instance
  const GroupUpdateRequested({
    required this.groupId,
    this.name,
    this.currency,
    this.description,
  });

  /// The unique identifier of the group
  final String groupId;

  /// The updated name of the group
  final String? name;

  /// The updated currency code for the group
  final String? currency;

  /// The updated description for the group
  final String? description;

  @override
  List<Object?> get props => [groupId, name, currency, description];
}

/// Event to invite a member to a group
class GroupMemberInvited extends GroupEvent {
  /// Creates a [GroupMemberInvited] instance
  const GroupMemberInvited({
    required this.groupId,
    required this.email,
    required this.displayName,
    this.role = MemberRole.editor,
  });

  /// The unique identifier of the group
  final String groupId;

  /// The email of the person to invite
  final String email;

  /// The display name for the new member
  final String displayName;

  /// The role to assign to the new member
  final MemberRole role;

  @override
  List<Object?> get props => [groupId, email, displayName, role];
}

/// Event to change a member's role
class GroupMemberRoleChanged extends GroupEvent {
  /// Creates a [GroupMemberRoleChanged] instance
  const GroupMemberRoleChanged({
    required this.groupId,
    required this.userId,
    required this.newRole,
  });

  /// The unique identifier of the group
  final String groupId;

  /// The unique user identifier whose role is changing
  final String userId;

  /// The new role to assign
  final MemberRole newRole;

  @override
  List<Object?> get props => [groupId, userId, newRole];
}

/// Event to remove a member from a group
class GroupMemberRemoved extends GroupEvent {
  /// Creates a [GroupMemberRemoved] instance
  const GroupMemberRemoved({
    required this.groupId,
    required this.userId,
  });

  /// The unique identifier of the group
  final String groupId;

  /// The unique user identifier to remove
  final String userId;

  @override
  List<Object?> get props => [groupId, userId];
}

/// Event to leave a group (for current user)
class GroupLeaveRequested extends GroupEvent {
  /// Creates a [GroupLeaveRequested] instance
  const GroupLeaveRequested({
    required this.groupId,
  });

  /// The unique identifier of the group to leave
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

/// Event to delete a group (administrator only)
class GroupDeleteRequested extends GroupEvent {
  /// Creates a [GroupDeleteRequested] instance
  const GroupDeleteRequested({
    required this.groupId,
  });

  /// The unique identifier of the group to delete
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

/// Event to refresh group data
class GroupRefreshRequested extends GroupEvent {
  // If null, refresh all groups

  /// Creates a [GroupRefreshRequested] instance
  const GroupRefreshRequested({
    this.groupId,
  });

  /// Optional group identifier to refresh specifically
  final String? groupId;

  @override
  List<Object?> get props => [groupId];
}
