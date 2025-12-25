import 'package:equatable/equatable.dart';

/// Base class for all expense-related failures
abstract class ExpenseFailure extends Equatable implements Exception {
  /// Creates an [ExpenseFailure] instance
  const ExpenseFailure(this.message);

  /// Error message describing the failure
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ExpenseFailure: $message';
}

/// Failure when expense split amounts do not match total
class InvalidSplitFailure extends ExpenseFailure {
  /// Creates an [InvalidSplitFailure] instance
  const InvalidSplitFailure([String? details])
    : super(details ?? 'Split amounts do not match total expense amount');
}

/// Failure when expense participants are invalid
class InvalidParticipantsFailure extends ExpenseFailure {
  /// Creates an [InvalidParticipantsFailure] instance
  const InvalidParticipantsFailure([String? details])
    : super(details ?? 'Invalid participants selected for expense');
}

/// Failure when expense is not found
class ExpenseNotFoundFailure extends ExpenseFailure {
  /// Creates an [ExpenseNotFoundFailure] instance
  const ExpenseNotFoundFailure([String? expenseId])
    : super(
        expenseId != null
            ? 'Expense with ID $expenseId not found'
            : 'Expense not found',
      );
}

/// Failure when expense amount is invalid
class InvalidExpenseAmountFailure extends ExpenseFailure {
  /// Creates an [InvalidExpenseAmountFailure] instance
  const InvalidExpenseAmountFailure([String? details])
    : super(details ?? 'Expense amount must be positive');
}

/// Failure when expense description is invalid
class InvalidExpenseDescriptionFailure extends ExpenseFailure {
  /// Creates an [InvalidExpenseDescriptionFailure] instance
  const InvalidExpenseDescriptionFailure()
    : super('Expense description cannot be empty');
}

/// Failure when expense currency is invalid
class InvalidExpenseCurrencyFailure extends ExpenseFailure {
  /// Creates an [InvalidExpenseCurrencyFailure] instance
  const InvalidExpenseCurrencyFailure(String currency)
    : super('Invalid currency: $currency');
}

/// Failure when expense date is invalid
class InvalidExpenseDateFailure extends ExpenseFailure {
  /// Creates an [InvalidExpenseDateFailure] instance
  const InvalidExpenseDateFailure()
    : super('Expense date cannot be in the future');
}

/// Failure when no participants are selected
class NoParticipantsFailure extends ExpenseFailure {
  /// Creates a [NoParticipantsFailure] instance
  const NoParticipantsFailure()
    : super('At least one participant must be selected');
}

/// Failure when payer is not a participant
class PayerNotParticipantFailure extends ExpenseFailure {
  /// Creates a [PayerNotParticipantFailure] instance
  const PayerNotParticipantFailure()
    : super('Expense payer must be included as a participant');
}

/// Failure when percentage split doesn't total 100%
class InvalidPercentageSplitFailure extends ExpenseFailure {
  /// Creates an [InvalidPercentageSplitFailure] instance
  InvalidPercentageSplitFailure(double total)
    : super(
        'Percentage split must total 100%, got ${total.toStringAsFixed(1)}%',
      );
}

/// Failure when exact split amounts don't match total
class InvalidExactSplitFailure extends ExpenseFailure {
  /// Creates an [InvalidExactSplitFailure] instance
  InvalidExactSplitFailure(double splitTotal, double expenseTotal)
    : super(
        'Split amounts total ${splitTotal.toStringAsFixed(2)} '
        'but expense total is ${expenseTotal.toStringAsFixed(2)}',
      );
}

/// Failure when share split has invalid shares
class InvalidShareSplitFailure extends ExpenseFailure {
  /// Creates an [InvalidShareSplitFailure] instance
  const InvalidShareSplitFailure()
    : super('All participants must have at least 1 share');
}

/// Failure when user has insufficient permissions
class InsufficientExpensePermissionsFailure extends ExpenseFailure {
  /// Creates an [InsufficientExpensePermissionsFailure] instance
  const InsufficientExpensePermissionsFailure([String? action])
    : super(
        action != null
            ? 'Insufficient permissions to $action expense'
            : 'Insufficient permissions for expense operation',
      );
}

/// Failure when expense amount exceeds reasonable limit
class ExpenseAmountTooLargeFailure extends ExpenseFailure {
  /// Creates an [ExpenseAmountTooLargeFailure] instance
  ExpenseAmountTooLargeFailure(double amount)
    : super(
        'Expense amount ${amount.toStringAsFixed(2)} exceeds reasonable limit',
      );
}

/// Failure when network operation fails
class ExpenseNetworkFailure extends ExpenseFailure {
  /// Creates an [ExpenseNetworkFailure] instance
  const ExpenseNetworkFailure([String? details])
    : super(
        details != null ? 'Network error: $details' : 'Network error occurred',
      );
}

/// Failure when database operation fails
class ExpenseDatabaseFailure extends ExpenseFailure {
  /// Creates an [ExpenseDatabaseFailure] instance
  const ExpenseDatabaseFailure([String? details])
    : super(
        details != null
            ? 'Database error: $details'
            : 'Database error occurred',
      );
}

/// Failure when user is not authenticated
class ExpenseAuthenticationFailure extends ExpenseFailure {
  /// Creates an [ExpenseAuthenticationFailure] instance
  const ExpenseAuthenticationFailure()
    : super('User must be authenticated to perform this action');
}

/// Failure when operation times out
class ExpenseTimeoutFailure extends ExpenseFailure {
  /// Creates an [ExpenseTimeoutFailure] instance
  const ExpenseTimeoutFailure() : super('Operation timed out');
}

/// Failure when unknown error occurs
class UnknownExpenseFailure extends ExpenseFailure {
  /// Creates an [UnknownExpenseFailure] instance
  const UnknownExpenseFailure([String? details])
    : super(
        details != null
            ? 'Unknown error: $details'
            : 'An unknown error occurred',
      );
}
