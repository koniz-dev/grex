import 'package:dartz/dartz.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/domain/failures/group_failure.dart';

/// Repository interface for group operations
abstract class GroupRepository {
  /// Get all groups where the current user is a member
  Future<Either<GroupFailure, List<Group>>> getUserGroups();

  /// Create a new group with the current user as administrator
  Future<Either<GroupFailure, Group>> createGroup({
    required String name,
    required String currency,
    String? description,
  });

  /// Update an existing group (name, currency)
  Future<Either<GroupFailure, Group>> updateGroup({
    required String groupId,
    String? name,
    String? currency,
    String? description,
  });

  /// Invite a member to the group by email
  Future<Either<GroupFailure, GroupMember>> inviteMember({
    required String groupId,
    required String email,
    required String displayName,
    MemberRole role = MemberRole.editor,
  });

  /// Update a member's role in the group
  Future<Either<GroupFailure, GroupMember>> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole newRole,
  });

  /// Remove a member from the group
  Future<Either<GroupFailure, void>> removeMember({
    required String groupId,
    required String userId,
  });

  /// Get a specific group by ID
  Future<Either<GroupFailure, Group>> getGroupById(String groupId);

  /// Watch user's groups for real-time updates
  Stream<List<Group>> watchUserGroups();

  /// Watch a specific group for real-time updates
  Stream<Group> watchGroup(String groupId);

  /// Check if user has permission to perform action on group
  Future<Either<GroupFailure, bool>> hasPermission(
    String groupId,
    String action,
  );

  /// Leave a group (remove self from group)
  Future<Either<GroupFailure, void>> leaveGroup(String groupId);

  /// Delete a group (only for administrators)
  Future<Either<GroupFailure, void>> deleteGroup(String groupId);
}
