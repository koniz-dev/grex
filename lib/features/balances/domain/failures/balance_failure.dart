import 'package:equatable/equatable.dart';

/// Base class for all balance-related failures
abstract class BalanceFailure extends Equatable implements Exception {
  /// Creates a [BalanceFailure] instance
  const BalanceFailure(this.message);

  /// Error message describing the failure
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'BalanceFailure: $message';
}

/// Failure when balance calculation fails
class BalanceCalculationFailure extends BalanceFailure {
  /// Creates a [BalanceCalculationFailure] instance
  const BalanceCalculationFailure([String? details])
    : super(details ?? 'Failed to calculate group balances');
}

/// Failure when settlement plan generation fails
class SettlementPlanFailure extends BalanceFailure {
  /// Creates a [SettlementPlanFailure] instance
  const SettlementPlanFailure([String? details])
    : super(details ?? 'Failed to generate settlement plan');
}

/// Failure when balance data is not found
class BalanceNotFoundFailure extends BalanceFailure {
  /// Creates a [BalanceNotFoundFailure] instance
  const BalanceNotFoundFailure([String? groupId])
    : super(
        groupId != null
            ? 'Balance data not found for group $groupId'
            : 'Balance data not found',
      );
}

/// Failure when group has no transactions
class NoTransactionsFailure extends BalanceFailure {
  /// Creates a [NoTransactionsFailure] instance
  const NoTransactionsFailure()
    : super('Group has no expenses or payments to calculate balances');
}

/// Failure when currency mismatch occurs
class CurrencyMismatchFailure extends BalanceFailure {
  /// Creates a [CurrencyMismatchFailure] instance
  const CurrencyMismatchFailure([String? details])
    : super(details ?? 'Currency mismatch in balance calculation');
}

/// Failure when balance data is inconsistent
class InconsistentBalanceDataFailure extends BalanceFailure {
  /// Creates an [InconsistentBalanceDataFailure] instance
  const InconsistentBalanceDataFailure([String? details])
    : super(details ?? 'Balance data is inconsistent');
}

/// Failure when settlement optimization fails
class SettlementOptimizationFailure extends BalanceFailure {
  /// Creates a [SettlementOptimizationFailure] instance
  const SettlementOptimizationFailure()
    : super('Failed to optimize settlement plan');
}

/// Failure when all balances are already settled
class AlreadySettledFailure extends BalanceFailure {
  /// Creates an [AlreadySettledFailure] instance
  const AlreadySettledFailure()
    : super('All group members are already settled');
}

/// Failure when balance amount is invalid
class InvalidBalanceAmountFailure extends BalanceFailure {
  /// Creates an [InvalidBalanceAmountFailure] instance
  const InvalidBalanceAmountFailure(this.amount)
    : super('Invalid balance amount');

  /// The invalid amount that was encountered
  final double amount;

  @override
  String get message => 'Invalid balance amount: ${amount.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [amount];
}

/// Failure when balance data is invalid
class InvalidBalanceDataFailure extends BalanceFailure {
  /// Creates an [InvalidBalanceDataFailure] instance
  const InvalidBalanceDataFailure([String? details])
    : super(details ?? 'Invalid balance data');
}

/// Failure when user has insufficient permissions
class InsufficientPermissionsFailure extends BalanceFailure {
  /// Creates an [InsufficientPermissionsFailure] instance
  const InsufficientPermissionsFailure([String? action])
    : super(
        action != null
            ? 'Insufficient permissions to $action'
            : 'Insufficient permissions',
      );
}

/// Failure when user has insufficient permissions
class InsufficientBalancePermissionsFailure extends BalanceFailure {
  /// Creates an [InsufficientBalancePermissionsFailure] instance
  const InsufficientBalancePermissionsFailure([String? action])
    : super(
        action != null
            ? 'Insufficient permissions to $action balances'
            : 'Insufficient permissions for balance operation',
      );
}

/// Failure when network operation fails
class BalanceNetworkFailure extends BalanceFailure {
  /// Creates a [BalanceNetworkFailure] instance
  const BalanceNetworkFailure([String? details])
    : super(
        details != null ? 'Network error: $details' : 'Network error occurred',
      );
}

/// Failure when database operation fails
class BalanceDatabaseFailure extends BalanceFailure {
  /// Creates a [BalanceDatabaseFailure] instance
  const BalanceDatabaseFailure([String? details])
    : super(
        details != null
            ? 'Database error: $details'
            : 'Database error occurred',
      );
}

/// Failure when user is not authenticated
class BalanceAuthenticationFailure extends BalanceFailure {
  /// Creates a [BalanceAuthenticationFailure] instance
  const BalanceAuthenticationFailure()
    : super('User must be authenticated to perform this action');
}

/// Failure when operation times out
class BalanceTimeoutFailure extends BalanceFailure {
  /// Creates a [BalanceTimeoutFailure] instance
  const BalanceTimeoutFailure() : super('Operation timed out');
}

/// Failure when unknown error occurs
class UnknownBalanceFailure extends BalanceFailure {
  /// Creates an [UnknownBalanceFailure] instance
  const UnknownBalanceFailure([String? details])
    : super(
        details != null
            ? 'Unknown error: $details'
            : 'An unknown error occurred',
      );
}
