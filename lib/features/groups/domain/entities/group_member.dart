import 'package:equatable/equatable.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';

/// Entity representing a member of a group
class GroupMember extends Equatable {
  /// Creates a [GroupMember] instance
  const GroupMember({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  /// Create from JSON from Supabase
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      role: MemberRole.fromJson(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  /// Unique identifier for the group membership record
  final String id;

  /// User ID of the member
  final String userId;

  /// Display name of the member
  final String displayName;

  /// Role of the member in the group
  final MemberRole role;

  /// Date when the member joined the group
  final DateTime joinedAt;

  /// Create a copy of this GroupMember with updated fields
  GroupMember copyWith({
    String? id,
    String? userId,
    String? displayName,
    MemberRole? role,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'role': role.toJson(),
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// Check if this member can perform a specific action
  bool canManageGroup() => role.canManageGroup;

  /// Whether this member can edit expenses
  bool canEditExpenses() => role.canEditExpenses;

  /// Whether this member can invite new members
  bool canInviteMembers() => role.canInviteMembers;

  /// Whether this member can change roles of other members
  bool canChangeMemberRoles() => role.canChangeMemberRoles;

  /// Whether this member can remove members from the group
  bool canRemoveMembers() => role.canRemoveMembers;

  @override
  List<Object?> get props => [id, userId, displayName, role, joinedAt];

  @override
  String toString() {
    return 'GroupMember(id: $id, userId: $userId, displayName: $displayName, '
        'role: $role, joinedAt: $joinedAt)';
  }
}
