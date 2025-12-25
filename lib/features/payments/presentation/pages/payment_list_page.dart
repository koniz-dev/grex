import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';
import 'package:grex/features/payments/presentation/pages/create_payment_page.dart';
import 'package:grex/features/payments/presentation/widgets/empty_payments_widget.dart';
import 'package:grex/features/payments/presentation/widgets/payment_filter_sheet.dart';
import 'package:grex/features/payments/presentation/widgets/payment_list_item.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page displaying list of payments for a group with filtering and sorting
/// functionality
class PaymentListPage extends StatefulWidget {
  /// Creates a [PaymentListPage] instance
  const PaymentListPage({
    required this.groupId,
    required this.groupName,
    required this.groupCurrency,
    super.key,
  });

  /// The ID of the group to display payments for
  final String groupId;

  /// The name of the group
  final String groupName;

  /// The currency of the group
  final String groupCurrency;

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

/// State class for PaymentListPage
class _PaymentListPageState extends State<PaymentListPage> {
  late final PaymentBloc _paymentBloc;

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPayer;
  String? _selectedRecipient;
  double? _minAmount;
  double? _maxAmount;
  PaymentSortCriteria _sortBy = PaymentSortCriteria.date;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _paymentBloc = getIt<PaymentBloc>();
    _loadPayments();
  }

  @override
  void dispose() {
    unawaited(_paymentBloc.close());
    super.dispose();
  }

  void _loadPayments() {
    _paymentBloc.add(PaymentsLoadRequested(groupId: widget.groupId));
  }

  void _applyFilters() {
    _paymentBloc.add(
      PaymentFilterRequested(
        groupId: widget.groupId,
        startDate: _startDate,
        endDate: _endDate,
        payerId: _selectedPayer,
        recipientId: _selectedRecipient,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedPayer = null;
      _selectedRecipient = null;
      _minAmount = null;
      _maxAmount = null;
      _sortBy = PaymentSortCriteria.date;
      _sortAscending = false;
    });
    _paymentBloc.add(PaymentFilterCleared(groupId: widget.groupId));
  }

  void _showFilterSheet() {
    unawaited(
      showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (context) => PaymentFilterSheet(
          startDate: _startDate,
          endDate: _endDate,
          selectedPayer: _selectedPayer,
          selectedRecipient: _selectedRecipient,
          minAmount: _minAmount,
          maxAmount: _maxAmount,
          sortBy: _sortBy,
          sortAscending: _sortAscending,
          groupCurrency: widget.groupCurrency,
        ),
      ).then((filters) {
        if (filters != null) {
          setState(() {
            _startDate = filters['startDate'] as DateTime?;
            _endDate = filters['endDate'] as DateTime?;
            _selectedPayer = filters['selectedPayer'] as String?;
            _selectedRecipient = filters['selectedRecipient'] as String?;
            _minAmount = filters['minAmount'] as double?;
            _maxAmount = filters['maxAmount'] as double?;
            _sortBy =
                filters['sortBy'] as PaymentSortCriteria? ??
                PaymentSortCriteria.date;
            _sortAscending = filters['sortAscending'] as bool? ?? false;
          });
          _applyFilters();
          _applySorting();
        }
      }),
    );
  }

  void _applySorting() {
    _paymentBloc.add(
      PaymentSortRequested(
        groupId: widget.groupId,
        sortBy: _sortBy,
        ascending: _sortAscending,
      ),
    );
  }

  bool get _hasActiveFilters {
    return _startDate != null ||
        _endDate != null ||
        _selectedPayer != null ||
        _selectedRecipient != null ||
        _minAmount != null ||
        _maxAmount != null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _paymentBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.groupName} Payments'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _hasActiveFilters
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: _showFilterSheet,
              tooltip: 'Filter payments',
            ),
            if (_hasActiveFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearFilters,
                tooltip: 'Clear filters',
              ),
          ],
        ),
        body: BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              // Data is already updated in the state, no need to reload
            }

            if (state is PaymentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          child: Column(
            children: [
              // Filter summary
              BlocBuilder<PaymentBloc, PaymentState>(
                builder: (context, state) {
                  if ((state is PaymentsLoaded && state.hasActiveFilters) ||
                      (state is PaymentOperationSuccess)) {
                    final summary = state is PaymentsLoaded
                        ? _getFilterSummary(state)
                        : null; // Success state doesn't have details here yet

                    if (summary == null) return const SizedBox.shrink();

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Text(
                        summary,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Payment list
              Expanded(
                child: BlocBuilder<PaymentBloc, PaymentState>(
                  builder: (context, state) {
                    if (state is PaymentLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is PaymentError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading payments',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadPayments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is PaymentsLoaded ||
                        state is PaymentOperationSuccess) {
                      final payments = state is PaymentsLoaded
                          ? state.filteredPayments
                          : (state as PaymentOperationSuccess).filteredPayments;

                      if (payments.isEmpty) {
                        return EmptyPaymentsWidget(
                          message: state is PaymentsLoaded
                              ? _getEmptyStateMessage(state)
                              : 'No payments match your criteria.',
                          onAddPayment: _navigateToCreatePayment,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          _paymentBloc.add(
                            PaymentRefreshRequested(groupId: widget.groupId),
                          );
                        },
                        child: Column(
                          children: [
                            // Summary card
                            if (payments.isNotEmpty)
                              _buildSummaryCard(payments),

                            // Payment list
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: payments.length,
                                itemBuilder: (context, index) {
                                  final payment = payments[index];
                                  return PaymentListItem(
                                    payment: payment,
                                    onTap: () => _showPaymentDetails(payment),
                                    onDelete: _canDeletePayment(payment)
                                        ? () => _confirmDeletePayment(payment)
                                        : null,
                                    groupCurrency: widget.groupCurrency,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToCreatePayment,
          tooltip: 'Add payment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<Payment> payments) {
    final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Payments',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Text(
                      '${payments.length}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(
                        amount: totalAmount,
                        currencyCode: widget.groupCurrency,
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterSummary(PaymentsLoaded state) {
    final parts = <String>[];

    if (_startDate != null || _endDate != null) {
      if (_startDate != null && _endDate != null) {
        parts.add(
          'Date: ${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
        );
      } else if (_startDate != null) {
        parts.add('From: ${_formatDate(_startDate!)}');
      } else {
        parts.add('Until: ${_formatDate(_endDate!)}');
      }
    }

    if (_minAmount != null || _maxAmount != null) {
      if (_minAmount != null && _maxAmount != null) {
        final minFormatted = CurrencyFormatter.format(
          amount: _minAmount!,
          currencyCode: widget.groupCurrency,
        );
        final maxFormatted = CurrencyFormatter.format(
          amount: _maxAmount!,
          currencyCode: widget.groupCurrency,
        );
        parts.add('Amount: $minFormatted - $maxFormatted');
      } else if (_minAmount != null) {
        final minFormatted = CurrencyFormatter.format(
          amount: _minAmount!,
          currencyCode: widget.groupCurrency,
        );
        parts.add('Min: $minFormatted');
      } else {
        final maxFormatted = CurrencyFormatter.format(
          amount: _maxAmount!,
          currencyCode: widget.groupCurrency,
        );
        parts.add('Max: $maxFormatted');
      }
    }

    if (_selectedPayer != null) {
      parts.add('Payer filter active');
    }

    if (_selectedRecipient != null) {
      parts.add('Recipient filter active');
    }

    return 'Filters: ${parts.join(', ')} (${state.filteredCount}/${state.totalCount} payments)';
  }

  String _getEmptyStateMessage(PaymentsLoaded state) {
    if (state.hasActiveFilters) {
      return 'No payments match your search criteria. '
          'Try adjusting your filters.';
    } else {
      return 'No payments yet. Add your first payment to get started!';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _canDeletePayment(Payment payment) {
    // For now, allow deletion of all payments
    // In a real app, this would check user permissions
    return true;
  }

  void _showPaymentDetails(Payment payment) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From: ${payment.payerName}'),
              Text('To: ${payment.recipientName}'),
              Text(
                'Amount: ${CurrencyFormatter.format(
                  amount: payment.amount,
                  currencyCode: payment.currency,
                )}',
              ),
              if (payment.description != null)
                Text('Description: ${payment.description}'),
              Text('Date: ${_formatDate(payment.paymentDate)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePayment(Payment payment) {
    unawaited(
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Payment'),
          content: Text(
            'Are you sure you want to delete this payment '
            'from ${payment.payerName} to ${payment.recipientName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed ?? false) {
          _paymentBloc.add(PaymentDeleteRequested(paymentId: payment.id));
        }
      }),
    );
  }

  void _navigateToCreatePayment() {
    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (context) => CreatePaymentPage(
                groupId: widget.groupId,
                groupCurrency: widget.groupCurrency,
              ),
            ),
          )
          .then((_) {
            // Refresh payments after creating new one
            _loadPayments();
          }),
    );
  }
}
