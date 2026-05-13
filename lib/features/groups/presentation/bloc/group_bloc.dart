import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/domain/failures/group_failure.dart';
import 'package:grex/features/groups/domain/repositories/group_repository.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';

/// Bloc for managing group-related operations and state
class GroupBloc extends Bloc<GroupEvent, GroupState> {
  /// Creates a [GroupBloc] instance
  GroupBloc(this._groupRepository) : super(const GroupInitial()) {
    on<GroupsLoadRequested>(_onGroupsLoadRequested);
    on<GroupCreateRequested>(_onGroupCreateRequested);
    on<GroupUpdateRequested>(_onGroupUpdateRequested);
    on<GroupMemberInvited>(_onGroupMemberInvited);
    on<GroupMemberRoleChanged>(_onGroupMemberRoleChanged);
    on<GroupMemberRemoved>(_onGroupMemberRemoved);
    on<GroupLeaveRequested>(_onGroupLeaveRequested);
    on<GroupDeleteRequested>(_onGroupDeleteRequested);
    on<GroupRefreshRequested>(_onGroupRefreshRequested);
    on<GroupsStreamReceived>(_onGroupsStreamReceived);
    on<GroupsStreamErrored>(_onGroupsStreamErrored);
  }
  final GroupRepository _groupRepository;
  StreamSubscription<List<Group>>? _groupsSubscription;

  @override
  Future<void> close() async {
    await _groupsSubscription?.cancel();
    return super.close();
  }

  /// Handle loading groups with real-time updates
  Future<void> _onGroupsLoadRequested(
    GroupsLoadRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading(message: 'Loading groups...'));

    try {
      // Cancel existing subscription
      await _groupsSubscription?.cancel();

      // Get initial groups
      final result = await _groupRepository.getUserGroups();

      result.fold(
        (failure) => emit(
          GroupError(
            failure: failure,
            message: 'Failed to load groups',
          ),
        ),
        (groups) {
          emit(
            GroupsLoaded(
              groups: groups,
              lastUpdated: DateTime.now(),
            ),
          );

          // Set up real-time subscription
          _setupRealTimeSubscription();
        },
      );
    } on Exception catch (e) {
      emit(
        GroupError(
          failure: const GroupNetworkFailure('Unexpected error occurred'),
          message: 'Failed to load groups: $e',
        ),
      );
    }
  }

  // Pushes stream updates through the bloc event loop so emits happen
  // inside a handler's lifecycle (avoids the emit-after-complete assertion).
  void _setupRealTimeSubscription() {
    _groupsSubscription = _groupRepository.watchUserGroups().listen(
      (groups) {
        if (!isClosed) add(GroupsStreamReceived(groups));
      },
      onError: (Object error) {
        if (!isClosed) add(GroupsStreamErrored(error));
      },
    );
  }

  void _onGroupsStreamReceived(
    GroupsStreamReceived event,
    Emitter<GroupState> emit,
  ) {
    emit(
      GroupsLoaded(
        groups: event.groups,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void _onGroupsStreamErrored(
    GroupsStreamErrored event,
    Emitter<GroupState> emit,
  ) {
    emit(
      GroupError(
        failure: const GroupNetworkFailure('Real-time connection error'),
        message: 'Connection error: ${event.error}',
        groups: state is GroupsLoaded ? (state as GroupsLoaded).groups : null,
      ),
    );
  }

  /// Handle group creation
  Future<void> _onGroupCreateRequested(
    GroupCreateRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading(message: 'Creating group...'));

    try {
      final result = await _groupRepository.createGroup(
        name: event.name,
        currency: event.currency,
        description: event.description,
      );

      final successMessage = result.fold<String?>(
        (failure) {
          emit(
            GroupError(
              failure: failure,
              message: 'Failed to create group',
              groups: state is GroupsLoaded
                  ? (state as GroupsLoaded).groups
                  : null,
            ),
          );
          return null;
        },
        (group) => 'Group "${group.name}" created successfully',
      );

      if (successMessage != null) {
        await _refreshGroups(emit, successMessage);
      }
    } on Exception catch (e) {
      emit(
        GroupError(
          failure: const GroupNetworkFailure('Unexpected error occurred'),
          message: 'Failed to create group: $e',
          groups: state is GroupsLoaded ? (state as GroupsLoaded).groups : null,
        ),
      );
    }
  }

  /// Handle group updates
  Future<void> _onGroupUpdateRequested(
    GroupUpdateRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading(message: 'Updating group...'));

    try {
      final result = await _groupRepository.updateGroup(
        groupId: event.groupId,
        name: event.name,
        currency: event.currency,
        description: event.description,
      );

      final successMessage = result.fold<String?>(
        (failure) {
          emit(
            GroupError(
              failure: failure,
              message: 'Failed to update group',
              groups: state is GroupsLoaded
                  ? (state as GroupsLoaded).groups
                  : null,
            ),
          );
          return null;
        },
        (group) => 'Group updated successfully',
      );

      if (successMessage != null) {
        await _refreshGroups(emit, successMessage);
      }
    } on Exception catch (e) {
      emit(
        GroupError(
          failure: const GroupNetworkFailure('Unexpected error occurred'),
          message: 'Failed to update group: $e',
          groups: state is GroupsLoaded ? (state as GroupsLoaded).groups : null,
        ),
      );
    }
  }

  /// Handle member invitation
  Future<void> _onGroupMemberInvited(
    GroupMemberInvited event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading(message: 'Inviting member...'));

    try {
      final result = await _groupRepository.inviteMember(
        groupId: event.groupId,
        email: event.email,
        displayName: event.displayName,
        role: event.role,
      );

      final successMessage = result.fold<String?>(
        (failure) {
          emit(
            GroupError(
              failure: failure,
              message: 'Failed to invite member',
              groups: state is GroupsLoaded
                  ? (state as GroupsLoaded).groups
                  : null,
            ),
          );
          return null;
        },
        (member) => 'Member "${member.displayName}" invited successfully',
      );

      if (successMessage != null) {
        await _refreshGroups(emit, successMessage);
      }
    } on Exception catch (e) {
      emit(
        GroupError(
          failure: const GroupNetworkFailure('Unexpected error occurred'),
          message: 'Failed to invite member: $e',
          groups: state is GroupsLoaded ? (state as GroupsLoaded).groups : null,
        ),
      );
    }
  }

  /// Handle member role changes
  Future<void> _onGroupMemberRoleChanged(
    GroupMemberRoleChanged event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading(message: 'Updating member role...'));

    try {
      final result = await _groupRepository.updateMemberRole(
        groupId: event.groupId,
        userId: event.userId,
        newRole: event.newRole,
      );

      final successMessage = result.fold<String?>(
        (failure) {
          emit(
            GroupError(
              failure: failure,
              message: 'Failed to update member role',
              groups: state is GroupsLoaded
                  ? (state as GroupsLoaded).groups
                  : null,
            ),
          );
          return null;
        },
        (member) => 'Member role updated to ${event.newRole.displayName}',
      );

      if (successMessage != null) {
        await _refreshGroups(emit, successMessage);
      }
    } on Exception catch (e) {
      emit(
        GroupError(
          failure: const GroupNetworkFailure('Unexpected error occurred'),
          message: 'Failed to update member role: $e',
          groups: state is GroupsLoaded ? (state as GroupsLoaded).groups : null,
        ),
      );
    }
  }

  /// Handle member removal
  Future<void> _onGroupMemberRemoved(
    GroupMemberRemoved event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading(message: 'Removing member...'));

    try {
      final result = await _groupRepository.removeMember(
        groupId: event.groupId,
        userId: event.userId,
      );

      final successMessage = result.fold<String?>(
        (failure) {
          emit(
            GroupError(
              failure: failure,
              message: 'Failed to remove member',
              groups: state is GroupsLoaded
                  ? (state as GroupsLoaded).groups
                  : null,
            ),
          );
          return null;
        },
        (_) => 'Member removed successfully',
      );

      if (successMessage != null) {
        await _refreshGroups(emit, successMessage);
      }
    } on Exception catch (e) {
      emit(
        GroupError(
          failure: const GroupNetworkFailure('Unexpected error occurred'),
          message: 'Failed to remove member: $e',
          groups: state is GroupsLoaded ? (state as GroupsLoaded).groups : null,
        ),
      );
    }
  }

  /// Handle leaving a group
  Future<void> _onGroupLeaveRequested(
    GroupLeaveRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading(message: 'Leaving group...'));

    try {
      final result = await _groupRepository.leaveGroup(event.groupId);

      final successMessage = result.fold<String?>(
        (failure) {
          emit(
            GroupError(
              failure: failure,
              message: 'Failed to leave group',
              groups: state is GroupsLoaded
                  ? (state as GroupsLoaded).groups
                  : null,
            ),
          );
          return null;
        },
        (_) => 'Left group successfully',
      );

      if (successMessage != null) {
        await _refreshGroups(emit, successMessage);
      }
    } on Exception catch (e) {
      emit(
        GroupError(
          failure: const GroupNetworkFailure('Unexpected error occurred'),
          message: 'Failed to leave group: $e',
          groups: state is GroupsLoaded ? (state as GroupsLoaded).groups : null,
        ),
      );
    }
  }

  /// Handle group deletion
  Future<void> _onGroupDeleteRequested(
    GroupDeleteRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading(message: 'Deleting group...'));

    try {
      final result = await _groupRepository.deleteGroup(event.groupId);

      final successMessage = result.fold<String?>(
        (failure) {
          emit(
            GroupError(
              failure: failure,
              message: 'Failed to delete group',
              groups: state is GroupsLoaded
                  ? (state as GroupsLoaded).groups
                  : null,
            ),
          );
          return null;
        },
        (_) => 'Group deleted successfully',
      );

      if (successMessage != null) {
        await _refreshGroups(emit, successMessage);
      }
    } on Exception catch (e) {
      emit(
        GroupError(
          failure: const GroupNetworkFailure('Unexpected error occurred'),
          message: 'Failed to delete group: $e',
          groups: state is GroupsLoaded ? (state as GroupsLoaded).groups : null,
        ),
      );
    }
  }

  /// Handle refresh requests
  Future<void> _onGroupRefreshRequested(
    GroupRefreshRequested event,
    Emitter<GroupState> emit,
  ) async {
    // If specific group ID provided, we could refresh just that group
    // For now, refresh all groups
    add(const GroupsLoadRequested());
  }

  /// Helper method to refresh groups and emit success state
  Future<void> _refreshGroups(Emitter<GroupState> emit, String message) async {
    try {
      final result = await _groupRepository.getUserGroups();

      result.fold(
        (failure) => emit(
          GroupError(
            failure: failure,
            message: 'Failed to refresh groups',
            groups: state is GroupsLoaded
                ? (state as GroupsLoaded).groups
                : null,
          ),
        ),
        (groups) => emit(
          GroupOperationSuccess(
            message: message,
            groups: groups,
          ),
        ),
      );
    } on Exception catch (e) {
      emit(
        GroupError(
          failure: const GroupNetworkFailure('Unexpected error occurred'),
          message: 'Failed to refresh groups: $e',
          groups: state is GroupsLoaded ? (state as GroupsLoaded).groups : null,
        ),
      );
    }
  }

  /// Check if current user can perform administrative actions on a group
  bool canAdministrateGroup(String groupId) {
    if (state is! GroupsLoaded) return false;

    final group = (state as GroupsLoaded).getGroupById(groupId);
    return group?.currentUserRole == MemberRole.administrator;
  }

  /// Check if current user can edit a group
  bool canEditGroup(String groupId) {
    if (state is! GroupsLoaded) return false;

    final group = (state as GroupsLoaded).getGroupById(groupId);
    return group?.currentUserRole == MemberRole.administrator ||
        group?.currentUserRole == MemberRole.editor;
  }

  /// Get current user's role in a specific group
  MemberRole? getUserRoleInGroup(String groupId) {
    if (state is! GroupsLoaded) return null;

    final group = (state as GroupsLoaded).getGroupById(groupId);
    return group?.currentUserRole;
  }
}
