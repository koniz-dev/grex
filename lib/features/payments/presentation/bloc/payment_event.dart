import 'package:equatable/equatable.dart';

/// Base class for all payment events
abstract class PaymentEvent extends Equatable {
  /// Creates a [PaymentEvent] instance
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load payments for a specific group
class PaymentsLoadRequested extends PaymentEvent {
  /// Creates a [PaymentsLoadRequested] instance
  const PaymentsLoadRequested({required this.groupId});

  /// The ID of the group to load payments for
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

/// Event to create a new payment
class PaymentCreateRequested extends PaymentEvent {
  /// Creates a [PaymentCreateRequested] instance
  const PaymentCreateRequested({
    required this.groupId,
    required this.payerId,
    required this.recipientId,
    required this.amount,
    required this.currency,
    this.description,
    this.paymentDate,
  });

  /// The ID of the group this payment belongs to
  final String groupId;

  /// The ID of the member who paid
  final String payerId;

  /// The ID of the member who received the payment
  final String recipientId;

  /// The payment amount
  final double amount;

  /// The currency of the payment
  final String currency;

  /// Optional description for the payment
  final String? description;

  /// Optional date when the payment occurred
  final DateTime? paymentDate;

  @override
  List<Object?> get props => [
    groupId,
    payerId,
    recipientId,
    amount,
    currency,
    description,
    paymentDate,
  ];
}

/// Event to delete a payment
class PaymentDeleteRequested extends PaymentEvent {
  /// Creates a [PaymentDeleteRequested] instance
  const PaymentDeleteRequested({required this.paymentId});

  /// The ID of the payment to delete
  final String paymentId;

  @override
  List<Object?> get props => [paymentId];
}

/// Event to refresh payments (force reload)
class PaymentRefreshRequested extends PaymentEvent {
  /// Creates a [PaymentRefreshRequested] instance
  const PaymentRefreshRequested({required this.groupId});

  /// The ID of the group to refresh payments for
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

/// Event to load a specific payment by ID
class PaymentLoadRequested extends PaymentEvent {
  /// Creates a [PaymentLoadRequested] instance
  const PaymentLoadRequested({required this.paymentId});

  /// The ID of the payment to load
  final String paymentId;

  @override
  List<Object?> get props => [paymentId];
}

/// Event to filter payments with various criteria
class PaymentFilterRequested extends PaymentEvent {
  /// Creates a [PaymentFilterRequested] instance
  const PaymentFilterRequested({
    required this.groupId,
    this.startDate,
    this.endDate,
    this.payerId,
    this.recipientId,
    this.minAmount,
    this.maxAmount,
  });

  /// The ID of the group to filter payments in
  final String groupId;

  /// Optional start date for the filter range
  final DateTime? startDate;

  /// Optional end date for the filter range
  final DateTime? endDate;

  /// Optional payer ID to filter by
  final String? payerId;

  /// Optional recipient ID to filter by
  final String? recipientId;

  /// Optional minimum amount to filter by
  final double? minAmount;

  /// Optional maximum amount to filter by
  final double? maxAmount;

  @override
  List<Object?> get props => [
    groupId,
    startDate,
    endDate,
    payerId,
    recipientId,
    minAmount,
    maxAmount,
  ];
}

/// Event to clear payment filters
class PaymentFilterCleared extends PaymentEvent {
  /// Creates a [PaymentFilterCleared] instance
  const PaymentFilterCleared({required this.groupId});

  /// The ID of the group to clear filters for
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

/// Event to sort payments by different criteria
class PaymentSortRequested extends PaymentEvent {
  /// Creates a [PaymentSortRequested] instance
  const PaymentSortRequested({
    required this.groupId,
    required this.sortBy,
    this.ascending = false,
  });

  /// The ID of the group whose payments are being sorted
  final String groupId;

  /// The criteria to sort by
  final PaymentSortCriteria sortBy;

  /// Whether to sort in ascending order
  final bool ascending;

  @override
  List<Object?> get props => [groupId, sortBy, ascending];
}

/// Enum for payment sorting criteria
enum PaymentSortCriteria {
  /// Sort by payment date
  date,

  /// Sort by payment amount
  amount,

  /// Sort by payer name
  payer,

  /// Sort by recipient name
  recipient,
}

/// Extension on [PaymentSortCriteria] to provide display names
extension PaymentSortCriteriaExtension on PaymentSortCriteria {
  /// Returns a user-friendly display name for the sorting criteria
  String get displayName {
    switch (this) {
      case PaymentSortCriteria.date:
        return 'Date';
      case PaymentSortCriteria.amount:
        return 'Amount';
      case PaymentSortCriteria.payer:
        return 'Payer';
      case PaymentSortCriteria.recipient:
        return 'Recipient';
    }
  }
}
