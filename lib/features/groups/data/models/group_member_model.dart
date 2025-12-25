import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';

/// Data model for GroupMember that extends the domain entity
/// Provides additional functionality for data layer operations
class GroupMemberModel extends GroupMember {
  /// Creates a [GroupMemberModel] instance
  const GroupMemberModel({
    required super.id,
    required super.userId,
    required super.displayName,
    required super.role,
    required super.joinedAt,
  });

  /// Create from JSON with enhanced error handling
  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    try {
      return GroupMemberModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        role: MemberRole.fromJson(json['role'] as String),
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );
    } catch (e) {
      throw FormatException('Failed to parse GroupMemberModel from JSON: $e');
    }
  }

  /// Create from domain entity
  factory GroupMemberModel.fromEntity(GroupMember entity) {
    return GroupMemberModel(
      id: entity.id,
      userId: entity.userId,
      displayName: entity.displayName,
      role: entity.role,
      joinedAt: entity.joinedAt,
    );
  }

  /// Convert to domain entity
  GroupMember toEntity() {
    return GroupMember(
      id: id,
      userId: userId,
      displayName: displayName,
      role: role,
      joinedAt: joinedAt,
    );
  }

  /// Convert to JSON for database operations
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'role': role.toJson(),
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// Create JSON for database insertion (without id for auto-generation)
  Map<String, dynamic> toInsertJson({
    required String groupId,
  }) {
    return {
      'group_id': groupId,
      'user_id': userId,
      'display_name': displayName,
      'role': role.toJson(),
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// Create JSON for database update (only updatable fields)
  Map<String, dynamic> toUpdateJson() {
    return {
      'display_name': displayName,
      'role': role.toJson(),
    };
  }

  /// Create a copy with updated fields
  @override
  GroupMemberModel copyWith({
    String? id,
    String? userId,
    String? displayName,
    MemberRole? role,
    DateTime? joinedAt,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
