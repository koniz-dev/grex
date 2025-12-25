import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';
import 'package:grex/features/payments/domain/repositories/payment_repository.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';

/// BLoC for managing payments
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  /// Creates a [PaymentBloc] instance
  PaymentBloc(this._paymentRepository) : super(const PaymentInitial()) {
    on<PaymentsLoadRequested>(_onPaymentsLoadRequested);
    on<PaymentCreateRequested>(_onPaymentCreateRequested);
    on<PaymentDeleteRequested>(_onPaymentDeleteRequested);
    on<PaymentRefreshRequested>(_onPaymentRefreshRequested);
    on<PaymentLoadRequested>(_onPaymentLoadRequested);
    on<PaymentFilterRequested>(_onPaymentFilterRequested);
    on<PaymentFilterCleared>(_onPaymentFilterCleared);
    on<PaymentSortRequested>(_onPaymentSortRequested);
  }
  final PaymentRepository _paymentRepository;
  StreamSubscription<List<Payment>>? _paymentsSubscription;

  @override
  Future<void> close() async {
    await _paymentsSubscription?.cancel();
    return super.close();
  }

  /// Handle loading payments for a group with real-time updates
  Future<void> _onPaymentsLoadRequested(
    PaymentsLoadRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());

    try {
      // Cancel existing subscription
      await _paymentsSubscription?.cancel();

      // Get initial payments
      final result = await _paymentRepository.getGroupPayments(event.groupId);

      result.fold(
        (failure) => emit(
          PaymentError(
            failure: failure,
            message: 'Failed to load payments',
          ),
        ),
        (payments) {
          final sortedPayments = _sortPayments(
            payments,
            PaymentSortCriteria.date,
            false,
          );
          emit(
            PaymentsLoaded(
              payments: sortedPayments,
              filteredPayments: sortedPayments,
              groupId: event.groupId,
              lastUpdated: DateTime.now(),
            ),
          );

          // Set up real-time subscription
          _setupRealTimeSubscription(event.groupId, emit);
        },
      );
    } on Exception catch (e) {
      emit(
        PaymentError(
          failure: const PaymentNetworkFailure('Unexpected error occurred'),
          message: 'Failed to load payments: $e',
        ),
      );
    }
  }

  /// Set up real-time subscription for payment updates
  void _setupRealTimeSubscription(String groupId, Emitter<PaymentState> emit) {
    _paymentsSubscription = _paymentRepository
        .watchGroupPayments(groupId)
        .listen(
          (payments) {
            if (!isClosed && state is PaymentsLoaded) {
              final currentState = state as PaymentsLoaded;
              final sortedPayments = _sortPayments(
                payments,
                currentState.sortBy,
                currentState.sortAscending,
              );

              final filteredPayments = _applyFilters(
                sortedPayments,
                currentState.activeFilter,
              );

              emit(
                currentState.copyWith(
                  payments: sortedPayments,
                  filteredPayments: filteredPayments,
                  lastUpdated: DateTime.now(),
                ),
              );
            }
          },
          onError: (Object error) {
            if (!isClosed) {
              emit(
                PaymentError(
                  failure: const PaymentNetworkFailure(
                    'Real-time connection error',
                  ),
                  message: 'Connection error: $error',
                  payments: state is PaymentsLoaded
                      ? (state as PaymentsLoaded).payments
                      : null,
                  groupId: groupId,
                ),
              );
            }
          },
        );
  }

  /// Handle payment creation
  Future<void> _onPaymentCreateRequested(
    PaymentCreateRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Creating payment...'));

    try {
      // Construct Payment object from event data
      final payment = Payment(
        id: '', // Empty ID for new payment
        groupId: event.groupId,
        payerId: event.payerId,
        payerName: '', // Will be populated by repository
        recipientId: event.recipientId,
        recipientName: '', // Will be populated by repository
        amount: event.amount,
        currency: event.currency,
        description: event.description,
        paymentDate: event.paymentDate ?? DateTime.now(),
        createdAt: DateTime.now(),
      );

      final result = await _paymentRepository.createPayment(payment);

      result.fold(
        (failure) => emit(
          PaymentError(
            failure: failure,
            message: 'Failed to create payment',
            payments: state is PaymentsLoaded
                ? (state as PaymentsLoaded).payments
                : null,
            groupId: event.groupId,
          ),
        ),
        (payment) {
          unawaited(
            _refreshPayments(
              emit,
              event.groupId,
              'Payment created successfully',
            ),
          );
        },
      );
    } on Exception catch (e) {
      emit(
        PaymentError(
          failure: const PaymentNetworkFailure('Unexpected error occurred'),
          message: 'Failed to create payment: $e',
          payments: state is PaymentsLoaded
              ? (state as PaymentsLoaded).payments
              : null,
          groupId: event.groupId,
        ),
      );
    }
  }

  /// Handle payment deletion
  Future<void> _onPaymentDeleteRequested(
    PaymentDeleteRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Deleting payment...'));

    try {
      final result = await _paymentRepository.deletePayment(event.paymentId);

      result.fold(
        (failure) => emit(
          PaymentError(
            failure: failure,
            message: 'Failed to delete payment',
            payments: state is PaymentsLoaded
                ? (state as PaymentsLoaded).payments
                : null,
            groupId: state is PaymentsLoaded
                ? (state as PaymentsLoaded).groupId
                : null,
          ),
        ),
        (_) {
          final groupId = state is PaymentsLoaded
              ? (state as PaymentsLoaded).groupId
              : null;
          if (groupId != null) {
            unawaited(
              _refreshPayments(emit, groupId, 'Payment deleted successfully'),
            );
          }
        },
      );
    } on Exception catch (e) {
      emit(
        PaymentError(
          failure: const PaymentNetworkFailure('Unexpected error occurred'),
          message: 'Failed to delete payment: $e',
          payments: state is PaymentsLoaded
              ? (state as PaymentsLoaded).payments
              : null,
          groupId: state is PaymentsLoaded
              ? (state as PaymentsLoaded).groupId
              : null,
        ),
      );
    }
  }

  /// Handle refresh requests
  Future<void> _onPaymentRefreshRequested(
    PaymentRefreshRequested event,
    Emitter<PaymentState> emit,
  ) async {
    add(PaymentsLoadRequested(groupId: event.groupId));
  }

  /// Handle loading a specific payment
  Future<void> _onPaymentLoadRequested(
    PaymentLoadRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Loading payment details...'));

    try {
      final result = await _paymentRepository.getPaymentById(event.paymentId);

      result.fold(
        (failure) => emit(
          PaymentError(
            failure: failure,
            message: 'Failed to load payment details',
          ),
        ),
        (payment) => emit(
          PaymentDetailLoaded(
            payment: payment,
            lastUpdated: DateTime.now(),
          ),
        ),
      );
    } on Exception catch (e) {
      emit(
        PaymentError(
          failure: const PaymentNetworkFailure('Unexpected error occurred'),
          message: 'Failed to load payment details: $e',
        ),
      );
    }
  }

  /// Handle payment filtering
  Future<void> _onPaymentFilterRequested(
    PaymentFilterRequested event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentsLoaded) return;

    final currentState = state as PaymentsLoaded;

    final filter = PaymentFilter.fromEvent(
      startDate: event.startDate,
      endDate: event.endDate,
      payerId: event.payerId,
      recipientId: event.recipientId,
      minAmount: event.minAmount,
      maxAmount: event.maxAmount,
    );

    final filteredPayments = _applyFilters(
      currentState.payments,
      filter.isEmpty ? null : filter,
    );

    emit(
      currentState.copyWith(
        filteredPayments: filteredPayments,
        activeFilter: filter.isEmpty ? null : filter,
      ),
    );
  }

  /// Handle clearing filters
  Future<void> _onPaymentFilterCleared(
    PaymentFilterCleared event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentsLoaded) return;

    final currentState = state as PaymentsLoaded;

    emit(
      currentState.copyWith(
        filteredPayments: currentState.payments,
      ),
    );
  }

  /// Handle payment sorting
  Future<void> _onPaymentSortRequested(
    PaymentSortRequested event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentsLoaded) return;

    final currentState = state as PaymentsLoaded;

    final sortedPayments = _sortPayments(
      currentState.payments,
      event.sortBy,
      event.ascending,
    );

    final filteredPayments = _applyFilters(
      sortedPayments,
      currentState.activeFilter,
    );

    emit(
      currentState.copyWith(
        payments: sortedPayments,
        filteredPayments: filteredPayments,
        sortBy: event.sortBy,
        sortAscending: event.ascending,
      ),
    );
  }

  /// Helper method to refresh payments and emit success state
  Future<void> _refreshPayments(
    Emitter<PaymentState> emit,
    String groupId,
    String message,
  ) async {
    try {
      final result = await _paymentRepository.getGroupPayments(groupId);

      result.fold(
        (failure) => emit(
          PaymentError(
            failure: failure,
            message: 'Failed to refresh payments',
            payments: state is PaymentsLoaded
                ? (state as PaymentsLoaded).payments
                : null,
            groupId: groupId,
          ),
        ),
        (payments) {
          final currentState = state is PaymentsLoaded
              ? state as PaymentsLoaded
              : null;
          final sortedPayments = _sortPayments(
            payments,
            currentState?.sortBy ?? PaymentSortCriteria.date,
            currentState?.sortAscending ?? false,
          );

          final filteredPayments = _applyFilters(
            sortedPayments,
            currentState?.activeFilter,
          );

          emit(
            PaymentOperationSuccess(
              message: message,
              payments: sortedPayments,
              filteredPayments: filteredPayments,
              groupId: groupId,
            ),
          );
        },
      );
    } on Exception catch (e) {
      emit(
        PaymentError(
          failure: const PaymentNetworkFailure('Unexpected error occurred'),
          message: 'Failed to refresh payments: $e',
          payments: state is PaymentsLoaded
              ? (state as PaymentsLoaded).payments
              : null,
          groupId: groupId,
        ),
      );
    }
  }

  /// Apply filters to payment list
  List<Payment> _applyFilters(
    List<Payment> payments,
    PaymentFilter? filter,
  ) {
    if (filter == null || filter.isEmpty) {
      return payments;
    }

    return payments.where((payment) => filter.matches(payment)).toList();
  }

  /// Sort payments by criteria
  List<Payment> _sortPayments(
    List<Payment> payments,
    PaymentSortCriteria sortBy,
    bool ascending,
  ) {
    final sorted = List<Payment>.from(payments);

    switch (sortBy) {
      case PaymentSortCriteria.date:
        sorted.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
      case PaymentSortCriteria.amount:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
      case PaymentSortCriteria.payer:
        sorted.sort(
          (a, b) =>
              a.payerName.toLowerCase().compareTo(b.payerName.toLowerCase()),
        );
      case PaymentSortCriteria.recipient:
        sorted.sort(
          (a, b) => a.recipientName.toLowerCase().compareTo(
            b.recipientName.toLowerCase(),
          ),
        );
    }

    return ascending ? sorted : sorted.reversed.toList();
  }

  /// Check if current user can delete a payment
  bool canDeletePayment(String paymentId) {
    if (state is! PaymentsLoaded) return false;

    final payment = (state as PaymentsLoaded).getPaymentById(paymentId);
    // This would need to check user permissions based on group role and
    // payment ownership. For now, return true - actual permission checking
    // would be implemented based on business rules.
    return payment != null;
  }

  /// Get current filter summary for UI display
  String? getFilterSummary() {
    if (state is! PaymentsLoaded) return null;

    final currentState = state as PaymentsLoaded;
    return currentState.activeFilter?.description;
  }

  /// Get payments by user (as payer or recipient)
  List<Payment> getPaymentsByUser(String userId) {
    if (state is! PaymentsLoaded) return [];

    final currentState = state as PaymentsLoaded;
    return currentState.filteredPayments
        .where(
          (payment) =>
              payment.payerId == userId || payment.recipientId == userId,
        )
        .toList();
  }

  /// Get total amount paid by a user
  double getTotalPaidByUser(String userId) {
    if (state is! PaymentsLoaded) return 0;

    final currentState = state as PaymentsLoaded;
    return currentState.filteredPayments
        .where((payment) => payment.payerId == userId)
        .fold(0, (sum, payment) => sum + payment.amount);
  }

  /// Get total amount received by a user
  double getTotalReceivedByUser(String userId) {
    if (state is! PaymentsLoaded) return 0;

    final currentState = state as PaymentsLoaded;
    return currentState.filteredPayments
        .where((payment) => payment.recipientId == userId)
        .fold(0, (sum, payment) => sum + payment.amount);
  }

  /// Get net payment amount for a user (received - paid)
  double getNetPaymentForUser(String userId) {
    return getTotalReceivedByUser(userId) - getTotalPaidByUser(userId);
  }
}
