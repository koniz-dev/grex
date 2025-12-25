import 'package:equatable/equatable.dart';

/// Base class for all group-related failures
abstract class GroupFailure extends Equatable implements Exception {
  /// Creates a [GroupFailure] instance
  const GroupFailure(this.message);

  /// Error message describing the failure
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'GroupFailure: $message';
}

/// Failure when a group is not found
class GroupNotFoundFailure extends GroupFailure {
  /// Creates a [GroupNotFoundFailure] instance
  const GroupNotFoundFailure([String? groupId])
    : super(
        groupId != null
            ? 'Group with ID $groupId not found'
            : 'Group not found',
      );
}

/// Failure when user has insufficient permissions
class InsufficientPermissionsFailure extends GroupFailure {
  /// Creates an [InsufficientPermissionsFailure] instance
  const InsufficientPermissionsFailure([String? action])
    : super(
        action != null
            ? 'Insufficient permissions to $action'
            : 'Insufficient permissions',
      );
}

/// Failure when group data is invalid
class InvalidGroupDataFailure extends GroupFailure {
  /// Creates an [InvalidGroupDataFailure] instance
  const InvalidGroupDataFailure(super.message);
}

/// Failure when group name is invalid
class InvalidGroupNameFailure extends GroupFailure {
  /// Creates an [InvalidGroupNameFailure] instance
  const InvalidGroupNameFailure()
    : super('Group name must be between 1 and 100 characters');
}

/// Failure when group currency is invalid
class InvalidGroupCurrencyFailure extends GroupFailure {
  /// Creates an [InvalidGroupCurrencyFailure] instance
  const InvalidGroupCurrencyFailure(String currency)
    : super('Invalid currency: $currency');
}

/// Failure when trying to perform action on group with no members
class EmptyGroupFailure extends GroupFailure {
  /// Creates an [EmptyGroupFailure] instance
  const EmptyGroupFailure() : super('Cannot perform action on empty group');
}

/// Failure when trying to remove the last administrator
class LastAdministratorFailure extends GroupFailure {
  /// Creates a [LastAdministratorFailure] instance
  const LastAdministratorFailure()
    : super('Cannot remove the last administrator from the group');
}

/// Failure when member is not found in group
class MemberNotFoundFailure extends GroupFailure {
  /// Creates a [MemberNotFoundFailure] instance
  const MemberNotFoundFailure([String? userId])
    : super(
        userId != null
            ? 'Member with ID $userId not found in group'
            : 'Member not found in group',
      );
}

/// Failure when trying to invite a user who is already a member
class MemberAlreadyExistsFailure extends GroupFailure {
  /// Creates a [MemberAlreadyExistsFailure] instance
  const MemberAlreadyExistsFailure(String email)
    : super('User $email is already a member of this group');
}

/// Failure when trying to invite an invalid email
class InvalidEmailFailure extends GroupFailure {
  /// Creates an [InvalidEmailFailure] instance
  const InvalidEmailFailure(String email)
    : super('Invalid email address: $email');
}

/// Failure when network operation fails
class GroupNetworkFailure extends GroupFailure {
  /// Creates a [GroupNetworkFailure] instance
  const GroupNetworkFailure([String? details])
    : super(
        details != null ? 'Network error: $details' : 'Network error occurred',
      );
}

/// Failure when database operation fails
class GroupDatabaseFailure extends GroupFailure {
  /// Creates a [GroupDatabaseFailure] instance
  const GroupDatabaseFailure([String? details])
    : super(
        details != null
            ? 'Database error: $details'
            : 'Database error occurred',
      );
}

/// Failure when user is not authenticated
class GroupAuthenticationFailure extends GroupFailure {
  /// Creates a [GroupAuthenticationFailure] instance
  const GroupAuthenticationFailure()
    : super('User must be authenticated to perform this action');
}

/// Failure when operation times out
class GroupTimeoutFailure extends GroupFailure {
  /// Creates a [GroupTimeoutFailure] instance
  const GroupTimeoutFailure() : super('Operation timed out');
}

/// Failure when unknown error occurs
class UnknownGroupFailure extends GroupFailure {
  /// Creates an [UnknownGroupFailure] instance
  const UnknownGroupFailure([String? details])
    : super(
        details != null
            ? 'Unknown error: $details'
            : 'An unknown error occurred',
      );
}
