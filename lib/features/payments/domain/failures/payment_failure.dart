import 'package:equatable/equatable.dart';

/// Base class for all payment-related failures
abstract class PaymentFailure extends Equatable implements Exception {
  /// Creates a [PaymentFailure] instance
  const PaymentFailure(this.message);

  /// Error message describing the failure
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'PaymentFailure: $message';
}

/// Failure when payment amount is invalid
class InvalidPaymentAmountFailure extends PaymentFailure {
  /// Creates an [InvalidPaymentAmountFailure] instance
  const InvalidPaymentAmountFailure([String? details])
    : super(details ?? 'Payment amount must be positive');
}

/// Failure when trying to make payment to yourself
class SelfPaymentFailure extends PaymentFailure {
  /// Creates a [SelfPaymentFailure] instance
  const SelfPaymentFailure() : super('Cannot make payment to yourself');
}

/// Failure when payment is not found
class PaymentNotFoundFailure extends PaymentFailure {
  /// Creates a [PaymentNotFoundFailure] instance
  const PaymentNotFoundFailure([String? paymentId])
    : super(
        paymentId != null
            ? 'Payment with ID $paymentId not found'
            : 'Payment not found',
      );
}

/// Failure when payment currency is invalid
class InvalidPaymentCurrencyFailure extends PaymentFailure {
  /// Creates an [InvalidPaymentCurrencyFailure] instance
  const InvalidPaymentCurrencyFailure(String currency)
    : super('Invalid currency: $currency');
}

/// Failure when payment date is invalid
class InvalidPaymentDateFailure extends PaymentFailure {
  /// Creates an [InvalidPaymentDateFailure] instance
  const InvalidPaymentDateFailure()
    : super('Payment date cannot be in the future');
}

/// Failure when payer is not found
class PayerNotFoundFailure extends PaymentFailure {
  /// Creates a [PayerNotFoundFailure] instance
  const PayerNotFoundFailure([String? payerId])
    : super(
        payerId != null
            ? 'Payer with ID $payerId not found'
            : 'Payer not found',
      );
}

/// Failure when recipient is not found
class RecipientNotFoundFailure extends PaymentFailure {
  /// Creates a [RecipientNotFoundFailure] instance
  const RecipientNotFoundFailure([String? recipientId])
    : super(
        recipientId != null
            ? 'Recipient with ID $recipientId not found'
            : 'Recipient not found',
      );
}

/// Failure when user has insufficient permissions
class InsufficientPaymentPermissionsFailure extends PaymentFailure {
  /// Creates an [InsufficientPaymentPermissionsFailure] instance
  const InsufficientPaymentPermissionsFailure([String? action])
    : super(
        action != null
            ? 'Insufficient permissions to $action payment'
            : 'Insufficient permissions for payment operation',
      );
}

/// Failure when payment amount exceeds reasonable limit
class PaymentAmountTooLargeFailure extends PaymentFailure {
  /// Creates a [PaymentAmountTooLargeFailure] instance
  PaymentAmountTooLargeFailure(double amount)
    : super(
        'Payment amount ${amount.toStringAsFixed(2)} exceeds reasonable limit',
      );
}

/// Failure when trying to delete payment that doesn't belong to user
class PaymentNotOwnedFailure extends PaymentFailure {
  /// Creates a [PaymentNotOwnedFailure] instance
  const PaymentNotOwnedFailure()
    : super('You can only delete payments you created');
}

/// Failure when payment involves users not in the group
class PaymentUsersNotInGroupFailure extends PaymentFailure {
  /// Creates a [PaymentUsersNotInGroupFailure] instance
  const PaymentUsersNotInGroupFailure()
    : super('Payment can only be made between group members');
}

/// Failure when payment description is too long
class PaymentDescriptionTooLongFailure extends PaymentFailure {
  /// Creates a [PaymentDescriptionTooLongFailure] instance
  const PaymentDescriptionTooLongFailure(int maxLength)
    : super('Payment description cannot exceed $maxLength characters');
}

/// Failure when network operation fails
class PaymentNetworkFailure extends PaymentFailure {
  /// Creates a [PaymentNetworkFailure] instance
  const PaymentNetworkFailure([String? details])
    : super(
        details != null ? 'Network error: $details' : 'Network error occurred',
      );
}

/// Failure when database operation fails
class PaymentDatabaseFailure extends PaymentFailure {
  /// Creates a [PaymentDatabaseFailure] instance
  const PaymentDatabaseFailure([String? details])
    : super(
        details != null
            ? 'Database error: $details'
            : 'Database error occurred',
      );
}

/// Failure when user is not authenticated
class PaymentAuthenticationFailure extends PaymentFailure {
  /// Creates a [PaymentAuthenticationFailure] instance
  const PaymentAuthenticationFailure()
    : super('User must be authenticated to perform this action');
}

/// Failure when operation times out
class PaymentTimeoutFailure extends PaymentFailure {
  /// Creates a [PaymentTimeoutFailure] instance
  const PaymentTimeoutFailure() : super('Operation timed out');
}

/// Failure when unknown error occurs
class UnknownPaymentFailure extends PaymentFailure {
  /// Creates an [UnknownPaymentFailure] instance
  const UnknownPaymentFailure([String? details])
    : super(
        details != null
            ? 'Unknown error: $details'
            : 'An unknown error occurred',
      );
}
