import 'package:dartz/dartz.dart';
import 'package:grex/features/groups/data/models/group_member_model.dart';
import 'package:grex/features/groups/data/models/group_model.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/domain/failures/group_failure.dart';
import 'package:grex/features/groups/domain/repositories/group_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of GroupRepository
class SupabaseGroupRepository implements GroupRepository {
  /// Creates a [SupabaseGroupRepository] instance
  const SupabaseGroupRepository(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  /// Get current user ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  @override
  Future<Either<GroupFailure, List<Group>>> getUserGroups() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      // Query groups where user is a member with RLS-compliant query
      final response = await _supabaseClient
          .from('groups')
          .select('''
            *,
            group_members!inner(
              id,
              user_id,
              display_name,
              role,
              joined_at
            )
          ''')
          .eq('group_members.user_id', userId)
          .order('created_at', ascending: false);

      final groups = (response as List<dynamic>)
          .map((json) => GroupModel.fromJson(json as Map<String, dynamic>))
          .cast<Group>()
          .toList();

      return Right(groups);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  @override
  Future<Either<GroupFailure, Group>> createGroup({
    required String name,
    required String currency,
    String? description,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      // Validate group data
      if (name.trim().isEmpty) {
        return const Left(
          InvalidGroupDataFailure('Group name cannot be empty'),
        );
      }

      // Create group
      final groupData = {
        'name': name.trim(),
        'currency': currency.toUpperCase(),
        'creator_id': userId,
        'description': description?.trim(),
      };

      final groupResponse = await _supabaseClient
          .from('groups')
          .insert(groupData)
          .select()
          .single();

      final createdGroupId = groupResponse['id'] as String;

      // Add creator as administrator
      final memberData = {
        'group_id': createdGroupId,
        'user_id': userId,
        'display_name': 'Administrator', // This should come from user profile
        'role': MemberRole.administrator.name,
      };

      await _supabaseClient.from('group_members').insert(memberData);

      // Fetch the complete group with members
      return getGroupById(createdGroupId);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  @override
  Future<Either<GroupFailure, Group>> updateGroup({
    required String groupId,
    String? name,
    String? currency,
    String? description,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      // Check permissions
      final hasPermissionResult = await hasPermission(groupId, 'update');
      if (hasPermissionResult.isLeft()) {
        return hasPermissionResult.fold(
          Left.new,
          (_) => const Left(InsufficientPermissionsFailure('update group')),
        );
      }

      final userHasPermission = hasPermissionResult.getOrElse(() => false);
      if (!userHasPermission) {
        return const Left(InsufficientPermissionsFailure('update group'));
      }

      // Build update data
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name.trim();
      if (currency != null) updateData['currency'] = currency.toUpperCase();
      if (description != null) updateData['description'] = description.trim();

      if (updateData.isEmpty) {
        return getGroupById(groupId); // No changes to make
      }

      // Update group
      await _supabaseClient.from('groups').update(updateData).eq('id', groupId);

      // Fetch updated group
      return getGroupById(groupId);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  @override
  Future<Either<GroupFailure, GroupMember>> inviteMember({
    required String groupId,
    required String email,
    required String displayName,
    MemberRole role = MemberRole.editor,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      // Check permissions
      final hasPermissionResult = await hasPermission(groupId, 'invite');
      if (hasPermissionResult.isLeft()) {
        return hasPermissionResult.fold(
          Left.new,
          (_) => const Left(InsufficientPermissionsFailure('invite members')),
        );
      }

      // Validate email
      if (!_isValidEmail(email)) {
        return const Left(InvalidGroupDataFailure('Invalid email format'));
      }

      // Find user by email
      final userResponse = await _supabaseClient
          .from('users')
          .select('id, display_name')
          .eq('email', email)
          .maybeSingle();

      if (userResponse == null) {
        return Left(GroupNotFoundFailure('User with email $email not found'));
      }

      final invitedUserId = userResponse['id'] as String;
      final userDisplayName =
          userResponse['display_name'] as String? ?? displayName;

      // Check if user is already a member
      final existingMember = await _supabaseClient
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', invitedUserId)
          .maybeSingle();

      if (existingMember != null) {
        return const Left(
          InvalidGroupDataFailure('User is already a member of this group'),
        );
      }

      // Add member
      final memberData = {
        'group_id': groupId,
        'user_id': invitedUserId,
        'display_name': userDisplayName,
        'role': role.name,
      };

      final memberResponse = await _supabaseClient
          .from('group_members')
          .insert(memberData)
          .select()
          .single();

      final member = GroupMemberModel.fromJson(memberResponse).toEntity();
      return Right(member);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  @override
  Future<Either<GroupFailure, GroupMember>> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole newRole,
  }) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      // Check permissions
      final hasPermissionResult = await hasPermission(
        groupId,
        'manage_members',
      );
      if (hasPermissionResult.isLeft()) {
        return hasPermissionResult.fold(
          Left.new,
          (_) => const Left(InsufficientPermissionsFailure('manage members')),
        );
      }

      // Update member role
      final memberResponse = await _supabaseClient
          .from('group_members')
          .update({'role': newRole.name})
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .select()
          .single();

      final member = GroupMemberModel.fromJson(memberResponse).toEntity();
      return Right(member);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  @override
  Future<Either<GroupFailure, void>> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      // Check permissions
      final hasPermissionResult = await hasPermission(
        groupId,
        'manage_members',
      );
      if (hasPermissionResult.isLeft()) {
        return hasPermissionResult.fold(
          Left.new,
          (_) => const Left(InsufficientPermissionsFailure('manage members')),
        );
      }

      // Remove member
      await _supabaseClient
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  @override
  Future<Either<GroupFailure, Group>> getGroupById(String groupId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('groups')
          .select('''
            *,
            group_members(
              id,
              user_id,
              display_name,
              role,
              joined_at
            )
          ''')
          .eq('id', groupId)
          .single();

      final group = GroupModel.fromJson(response).toEntity();
      return Right(group);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  @override
  Stream<List<Group>> watchUserGroups() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.error(const GroupAuthenticationFailure());
    }

    return _supabaseClient
        .from('groups')
        .stream(primaryKey: ['id'])
        .eq('group_members.user_id', userId)
        .map(
          (data) =>
              data.map((json) => GroupModel.fromJson(json).toEntity()).toList(),
        );
  }

  @override
  Stream<Group> watchGroup(String groupId) {
    return _supabaseClient
        .from('groups')
        .stream(primaryKey: ['id'])
        .eq('id', groupId)
        .map(
          (data) => data.isNotEmpty
              ? GroupModel.fromJson(data.first).toEntity()
              : throw const GroupNotFoundFailure('Group not found'),
        );
  }

  @override
  Future<Either<GroupFailure, bool>> hasPermission(
    String groupId,
    String action,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      final memberResponse = await _supabaseClient
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResponse == null) {
        return const Right(false);
      }

      final role = MemberRole.fromJson(memberResponse['role'] as String);
      final hasPermission = _checkPermission(role, action);
      return Right(hasPermission);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  @override
  Future<Either<GroupFailure, void>> leaveGroup(String groupId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      // Remove user from group
      await _supabaseClient
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  @override
  Future<Either<GroupFailure, void>> deleteGroup(String groupId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(GroupAuthenticationFailure());
      }

      // Check if user is administrator
      final hasPermissionResult = await hasPermission(groupId, 'delete');
      if (hasPermissionResult.isLeft()) {
        return hasPermissionResult.fold(
          Left.new,
          (_) => const Left(InsufficientPermissionsFailure('delete group')),
        );
      }

      final userHasPermission = hasPermissionResult.getOrElse(() => false);
      if (!userHasPermission) {
        return const Left(InsufficientPermissionsFailure('delete group'));
      }

      // Delete group (cascade will handle members)
      await _supabaseClient.from('groups').delete().eq('id', groupId);

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownGroupFailure(e.toString()));
    }
  }

  /// Map PostgrestException to GroupFailure
  GroupFailure _mapPostgrestException(PostgrestException e) {
    switch (e.code) {
      case '23505': // Unique violation
        return InvalidGroupDataFailure('Duplicate data: ${e.message}');
      case '23503': // Foreign key violation
        return const GroupNotFoundFailure('Referenced data not found');
      case '42501': // Insufficient privilege (RLS)
        return const InsufficientPermissionsFailure('Access denied');
      default:
        return UnknownGroupFailure('Database error: ${e.message}');
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if user role has permission for action
  bool _checkPermission(MemberRole role, String action) {
    switch (action) {
      case 'update':
      case 'invite':
      case 'manage_members':
      case 'delete':
        return role == MemberRole.administrator;
      case 'view':
        return true; // All members can view
      default:
        return false;
    }
  }
}
