import 'package:equatable/equatable.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';

/// Entity representing an expense sharing group
class Group extends Equatable {
  /// Creates a [Group] instance
  const Group({
    required this.id,
    required this.name,
    required this.currency,
    required this.creatorId,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.currentUserRole,
  });

  /// Create from JSON from Supabase
  factory Group.fromJson(Map<String, dynamic> json) {
    // Handle members from joined query
    final membersData = json['group_members'] as List<dynamic>? ?? [];
    final members = membersData
        .map(
          (memberJson) =>
              GroupMember.fromJson(memberJson as Map<String, dynamic>),
        )
        .toList();

    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String,
      creatorId: json['creator_id'] as String,
      members: members,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Unique identifier for the group
  final String id;

  /// Name of the group
  final String name;

  /// Default currency for the group
  final String currency;

  /// User ID of the group creator
  final String creatorId;

  /// List of group members
  final List<GroupMember> members;

  /// Date when the group was created
  final DateTime createdAt;

  /// Date when the group was last updated
  final DateTime updatedAt;

  /// Current user's role in this group (computed property)
  final MemberRole? currentUserRole;

  /// Create a copy of this Group with updated fields
  Group copyWith({
    String? id,
    String? name,
    String? currency,
    String? creatorId,
    List<GroupMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    MemberRole? currentUserRole,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      creatorId: creatorId ?? this.creatorId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentUserRole: currentUserRole ?? this.currentUserRole,
    );
  }

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currency': currency,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // Note: members are stored in a separate table (group_members)
      // and joined when fetching groups
    };
  }

  /// Get member by user ID
  GroupMember? getMemberByUserId(String userId) {
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  /// Check if user is a member of this group
  bool isMember(String userId) {
    return getMemberByUserId(userId) != null;
  }

  /// Check if user is the creator of this group
  bool isCreator(String userId) {
    return creatorId == userId;
  }

  /// Get all administrators of this group
  List<GroupMember> get administrators {
    return members
        .where((member) => member.role == MemberRole.administrator)
        .toList();
  }

  /// Get all editors of this group
  List<GroupMember> get editors {
    return members.where((member) => member.role == MemberRole.editor).toList();
  }

  /// Get all viewers of this group
  List<GroupMember> get viewers {
    return members.where((member) => member.role == MemberRole.viewer).toList();
  }

  /// Check if user can manage this group
  bool canUserManageGroup(String userId) {
    final member = getMemberByUserId(userId);
    return member?.canManageGroup() ?? false;
  }

  /// Check if user can edit expenses in this group
  bool canUserEditExpenses(String userId) {
    final member = getMemberByUserId(userId);
    return member?.canEditExpenses() ?? false;
  }

  /// Check if user can invite members to this group
  bool canUserInviteMembers(String userId) {
    final member = getMemberByUserId(userId);
    return member?.canInviteMembers() ?? false;
  }

  /// Get member count
  int get memberCount => members.length;

  /// Check if this is the last administrator
  bool get hasOnlyOneAdministrator => administrators.length == 1;

  /// Get display text for member count
  String get memberCountText {
    if (memberCount == 1) return '1 member';
    return '$memberCount members';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    currency,
    creatorId,
    members,
    createdAt,
    updatedAt,
    currentUserRole,
  ];

  @override
  String toString() {
    return 'Group(id: $id, name: $name, currency: $currency, '
        'creatorId: $creatorId, memberCount: $memberCount, '
        'createdAt: $createdAt, updatedAt: $updatedAt, '
        'currentUserRole: $currentUserRole)';
  }
}
