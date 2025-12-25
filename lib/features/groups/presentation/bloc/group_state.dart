import 'package:equatable/equatable.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/domain/failures/group_failure.dart';

/// Base class for all group states
abstract class GroupState extends Equatable {
  /// Creates a [GroupState] instance
  const GroupState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the BLoC is first created
class GroupInitial extends GroupState {
  /// Creates a [GroupInitial] instance
  const GroupInitial();
}

/// State when groups are being loaded or an operation is in progress
class GroupLoading extends GroupState {
  /// Creates a [GroupLoading] instance
  const GroupLoading({this.message});

  /// Optional message describing the current operation
  final String? message;

  @override
  List<Object?> get props => [message];
}

/// State when groups have been successfully loaded
class GroupsLoaded extends GroupState {
  /// Creates a [GroupsLoaded] instance
  const GroupsLoaded({
    required this.groups,
    required this.lastUpdated,
  });

  /// The list of loaded groups
  final List<Group> groups;

  /// The timestamp of the last successful update
  final DateTime lastUpdated;

  @override
  List<Object?> get props => [groups, lastUpdated];

  /// Get a specific group by ID
  Group? getGroupById(String groupId) {
    for (final group in groups) {
      if (group.id == groupId) return group;
    }
    return null;
  }

  /// Check if user is administrator of any group
  bool get hasAdministratorRole {
    return groups.any(
      (group) => group.currentUserRole == MemberRole.administrator,
    );
  }

  /// Get groups where user is administrator
  List<Group> get administratorGroups {
    return groups
        .where((group) => group.currentUserRole == MemberRole.administrator)
        .toList();
  }

  /// Get groups where user is editor or administrator
  List<Group> get editableGroups {
    return groups
        .where(
          (group) =>
              group.currentUserRole == MemberRole.administrator ||
              group.currentUserRole == MemberRole.editor,
        )
        .toList();
  }

  /// Create a copy with updated groups
  GroupsLoaded copyWith({
    List<Group>? groups,
    DateTime? lastUpdated,
  }) {
    return GroupsLoaded(
      groups: groups ?? this.groups,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// State when a group operation was successful
class GroupOperationSuccess extends GroupState {
  // 'create', 'update', 'invite', 'remove', etc.

  /// Creates a [GroupOperationSuccess] instance
  const GroupOperationSuccess({
    required this.message,
    required this.groups,
    this.operationType,
  });

  /// The success message to display
  final String message;

  /// The updated list of groups
  final List<Group> groups;

  /// The type of operation that succeeded
  final String? operationType;

  @override
  List<Object?> get props => [message, groups, operationType];
}

/// State when an error occurs
class GroupError extends GroupState {
  // Preserve existing groups if available

  /// Creates a [GroupError] instance
  const GroupError({
    required this.failure,
    required this.message,
    this.groups,
  });

  /// The failure that occurred
  final GroupFailure failure;

  /// The error message
  final String message;

  /// Optional list of groups that were previously loaded
  final List<Group>? groups;

  @override
  List<Object?> get props => [failure, message, groups];

  /// Check if this is a network error
  bool get isNetworkError {
    return failure is GroupNetworkFailure;
  }

  /// Check if this is a permission error
  bool get isPermissionError {
    return failure is InsufficientPermissionsFailure;
  }

  /// Check if this is a validation error
  bool get isValidationError {
    return failure is InvalidGroupDataFailure;
  }

  /// Get user-friendly error message
  String get userFriendlyMessage {
    if (failure is GroupNotFoundFailure) {
      return 'Group not found. It may have been deleted.';
    } else if (failure is InsufficientPermissionsFailure) {
      return "You don't have permission to perform this action.";
    } else if (failure is InvalidGroupDataFailure) {
      return 'Invalid group data. Please check your input.';
    } else if (failure is GroupNetworkFailure) {
      return 'Network error. Please check your connection and try again.';
    } else if (failure is InvalidGroupDataFailure) {
      return 'A group with this name already exists.';
    } else if (failure is MemberAlreadyExistsFailure) {
      return 'This member is already in the group.';
    } else if (failure is LastAdministratorFailure) {
      return 'Cannot remove the last administrator. '
          'Promote another member first.';
    } else {
      return message;
    }
  }
}

/// State when real-time updates are being processed
class GroupRealTimeUpdate extends GroupState {
  /// Creates a [GroupRealTimeUpdate] instance
  const GroupRealTimeUpdate({
    required this.groups,
    required this.updateType,
    this.affectedGroupId,
  });

  /// The updated list of groups
  final List<Group> groups;

  /// The type of real-time update
  final String updateType;

  /// The identifier of the group that was affected
  final String? affectedGroupId;

  @override
  List<Object?> get props => [groups, updateType, affectedGroupId];
}
