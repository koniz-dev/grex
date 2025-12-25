import 'package:equatable/equatable.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';

/// Base class for all payment states
abstract class PaymentState extends Equatable {
  /// Creates a [PaymentState] instance
  const PaymentState();

  @override
  List<Object?> get props => [];
}

/// Initial state when PaymentBloc is first created
class PaymentInitial extends PaymentState {
  /// Creates a [PaymentInitial] instance
  const PaymentInitial();
}

/// State when payments are being loaded
class PaymentLoading extends PaymentState {
  /// Creates a [PaymentLoading] instance
  const PaymentLoading({this.message = 'Loading payments...'});

  /// Optional message to display during loading
  final String message;

  @override
  List<Object?> get props => [message];
}

/// State when payments have been loaded successfully
class PaymentsLoaded extends PaymentState {
  /// Creates a [PaymentsLoaded] instance
  const PaymentsLoaded({
    required this.payments,
    required this.filteredPayments,
    required this.groupId,
    required this.lastUpdated,
    this.activeFilter,
    this.sortBy = PaymentSortCriteria.date,
    this.sortAscending = false,
  });

  /// All payments in the group
  final List<Payment> payments;

  /// Payments that match the active filters
  final List<Payment> filteredPayments;

  /// The ID of the group these payments belong to
  final String groupId;

  /// Timestamp of the last update
  final DateTime lastUpdated;

  /// The currently active filter, if any
  final PaymentFilter? activeFilter;

  /// The current sorting criteria
  final PaymentSortCriteria sortBy;

  /// Whether sorting is in ascending order
  final bool sortAscending;

  @override
  List<Object?> get props => [
    payments,
    filteredPayments,
    groupId,
    lastUpdated,
    activeFilter,
    sortBy,
    sortAscending,
  ];

  /// Get payment by ID from the loaded payments
  Payment? getPaymentById(String paymentId) {
    for (final payment in payments) {
      if (payment.id == paymentId) return payment;
    }
    return null;
  }

  /// Check if there are any active filters
  bool get hasActiveFilters => activeFilter != null;

  /// Get the count of filtered payments
  int get filteredCount => filteredPayments.length;

  /// Get the total count of all payments
  int get totalCount => payments.length;

  /// Check if the list is empty after filtering
  bool get isFilteredEmpty => filteredPayments.isEmpty;

  /// Check if the original list is empty
  bool get isEmpty => payments.isEmpty;

  /// Get total amount of all payments
  double get totalAmount =>
      payments.fold(0, (sum, payment) => sum + payment.amount);

  /// Get total amount of filtered payments
  double get filteredTotalAmount =>
      filteredPayments.fold(0, (sum, payment) => sum + payment.amount);

  /// Copy with new values
  PaymentsLoaded copyWith({
    List<Payment>? payments,
    List<Payment>? filteredPayments,
    String? groupId,
    DateTime? lastUpdated,
    PaymentFilter? activeFilter,
    PaymentSortCriteria? sortBy,
    bool? sortAscending,
  }) {
    return PaymentsLoaded(
      payments: payments ?? this.payments,
      filteredPayments: filteredPayments ?? this.filteredPayments,
      groupId: groupId ?? this.groupId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      activeFilter: activeFilter ?? this.activeFilter,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

/// State when a single payment has been loaded
class PaymentDetailLoaded extends PaymentState {
  /// Creates a [PaymentDetailLoaded] instance
  const PaymentDetailLoaded({
    required this.payment,
    required this.lastUpdated,
  });

  /// The payment details
  final Payment payment;

  /// Timestamp of the last update
  final DateTime lastUpdated;

  @override
  List<Object?> get props => [payment, lastUpdated];
}

/// State when a payment operation was successful
class PaymentOperationSuccess extends PaymentState {
  /// Creates a [PaymentOperationSuccess] instance
  const PaymentOperationSuccess({
    required this.message,
    required this.payments,
    required this.filteredPayments,
    required this.groupId,
  });

  /// Success message to display to the user
  final String message;

  /// Updated list of all payments
  final List<Payment> payments;

  /// Updated list of filtered payments
  final List<Payment> filteredPayments;

  /// The ID of the group the operation was performed on
  final String groupId;

  @override
  List<Object?> get props => [message, payments, filteredPayments, groupId];
}

/// State when an error occurs
class PaymentError extends PaymentState {
  /// Creates a [PaymentError] instance
  const PaymentError({
    required this.failure,
    required this.message,
    this.payments,
    this.groupId,
  });

  /// The failure that occurred
  final PaymentFailure failure;

  /// User-friendly error message
  final String message;

  /// Current list of payments, if available
  final List<Payment>? payments;

  /// The ID of the group the error occurred in, if available
  final String? groupId;

  @override
  List<Object?> get props => [failure, message, payments, groupId];
}

/// State for real-time updates
class PaymentRealTimeUpdate extends PaymentState {
  /// Creates a [PaymentRealTimeUpdate] instance
  const PaymentRealTimeUpdate({
    required this.payments,
    required this.groupId,
    required this.updateType,
    this.affectedPaymentId,
  });

  /// Updated list of payments
  final List<Payment> payments;

  /// The ID of the group the update occurred in
  final String groupId;

  /// The type of update ('created', 'deleted', etc.)
  final String updateType; // 'created', 'deleted'

  /// The ID of the payment affected by the update
  final String? affectedPaymentId;

  @override
  List<Object?> get props => [payments, groupId, updateType, affectedPaymentId];
}

/// Filter criteria for payments
class PaymentFilter extends Equatable {
  /// Creates a [PaymentFilter] instance
  const PaymentFilter({
    this.startDate,
    this.endDate,
    this.payerId,
    this.recipientId,
    this.minAmount,
    this.maxAmount,
  });

  /// Create a filter from event parameters
  factory PaymentFilter.fromEvent({
    DateTime? startDate,
    DateTime? endDate,
    String? payerId,
    String? recipientId,
    double? minAmount,
    double? maxAmount,
  }) {
    return PaymentFilter(
      startDate: startDate,
      endDate: endDate,
      payerId: payerId,
      recipientId: recipientId,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
  }

  /// The start date for the filter range
  final DateTime? startDate;

  /// The end date for the filter range
  final DateTime? endDate;

  /// The ID of the payer to filter by
  final String? payerId;

  /// The ID of the recipient to filter by
  final String? recipientId;

  /// The minimum amount to filter by
  final double? minAmount;

  /// The maximum amount to filter by
  final double? maxAmount;

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    payerId,
    recipientId,
    minAmount,
    maxAmount,
  ];

  /// Check if the filter is empty (no criteria set)
  bool get isEmpty =>
      startDate == null &&
      endDate == null &&
      payerId == null &&
      recipientId == null &&
      minAmount == null &&
      maxAmount == null;

  /// Check if a payment matches this filter
  bool matches(Payment payment) {
    // Date range filter
    if (startDate != null && payment.paymentDate.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && payment.paymentDate.isAfter(endDate!)) {
      return false;
    }

    // Payer filter
    if (payerId != null && payment.payerId != payerId) {
      return false;
    }

    // Recipient filter
    if (recipientId != null && payment.recipientId != recipientId) {
      return false;
    }

    // Amount range filter
    if (minAmount != null && payment.amount < minAmount!) {
      return false;
    }
    if (maxAmount != null && payment.amount > maxAmount!) {
      return false;
    }

    return true;
  }

  /// Copy with new values
  PaymentFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? payerId,
    String? recipientId,
    double? minAmount,
    double? maxAmount,
  }) {
    return PaymentFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      payerId: payerId ?? this.payerId,
      recipientId: recipientId ?? this.recipientId,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }

  /// Get a human-readable description of the filter
  String get description {
    final parts = <String>[];

    if (startDate != null || endDate != null) {
      if (startDate != null && endDate != null) {
        parts.add(
          'Date: ${_formatDate(startDate!)} - ${_formatDate(endDate!)}',
        );
      } else if (startDate != null) {
        parts.add('From: ${_formatDate(startDate!)}');
      } else if (endDate != null) {
        parts.add('Until: ${_formatDate(endDate!)}');
      }
    }

    if (payerId != null) {
      parts.add('Payer: $payerId');
    }

    if (recipientId != null) {
      parts.add('Recipient: $recipientId');
    }

    if (minAmount != null || maxAmount != null) {
      if (minAmount != null && maxAmount != null) {
        parts.add(
          'Amount: \$${minAmount!.toStringAsFixed(2)} - '
          '\$${maxAmount!.toStringAsFixed(2)}',
        );
      } else if (minAmount != null) {
        parts.add('Min amount: \$${minAmount!.toStringAsFixed(2)}');
      } else if (maxAmount != null) {
        parts.add('Max amount: \$${maxAmount!.toStringAsFixed(2)}');
      }
    }

    return parts.join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
