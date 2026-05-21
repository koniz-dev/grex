import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';
import 'package:grex/features/payments/presentation/pages/create_payment_page.dart';
import 'package:grex/features/payments/presentation/widgets/empty_payments_widget.dart';
import 'package:grex/features/payments/presentation/widgets/payment_filter_sheet.dart';
import 'package:grex/features/payments/presentation/widgets/payment_list_error_widget.dart';
import 'package:grex/features/payments/presentation/widgets/payment_list_item.dart';
import 'package:grex/features/payments/presentation/widgets/payment_list_skeleton.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

/// Page displaying the list of payments for a group, with filter / sort and
/// pull-to-refresh.
class PaymentListPage extends StatefulWidget {
  /// Creates a [PaymentListPage].
  const PaymentListPage({
    required this.groupId,
    required this.groupName,
    required this.groupCurrency,
    super.key,
  });

  /// The ID of the group whose payments are being displayed.
  final String groupId;

  /// The display name of the group (rendered in the app bar).
  final String groupName;

  /// The currency of the group, used for amount conversion hints.
  final String groupCurrency;

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  late final PaymentBloc _paymentBloc;

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

  void _applySorting() {
    _paymentBloc.add(
      PaymentSortRequested(
        groupId: widget.groupId,
        sortBy: _sortBy,
        ascending: _sortAscending,
      ),
    );
  }

  void _clearFilters() {
    unawaited(HapticFeedback.lightImpact());
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

  Future<void> _showFilterSheet() async {
    unawaited(HapticFeedback.lightImpact());
    final filters = await showModalBottomSheet<Map<String, dynamic>>(
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
    );
    if (filters == null || !mounted) return;
    setState(() {
      _startDate = filters['startDate'] as DateTime?;
      _endDate = filters['endDate'] as DateTime?;
      _selectedPayer = filters['selectedPayer'] as String?;
      _selectedRecipient = filters['selectedRecipient'] as String?;
      _minAmount = filters['minAmount'] as double?;
      _maxAmount = filters['maxAmount'] as double?;
      _sortBy =
          filters['sortBy'] as PaymentSortCriteria? ?? PaymentSortCriteria.date;
      _sortAscending = filters['sortAscending'] as bool? ?? false;
    });
    _applyFilters();
    _applySorting();
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
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _paymentBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.groupPayments(widget.groupName)),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          actions: [
            IconButton(
              icon: Icon(
                Icons.filter_list_rounded,
                color: _hasActiveFilters ? theme.colorScheme.primary : null,
              ),
              onPressed: _showFilterSheet,
              tooltip: l10n.filterPayments,
            ),
            if (_hasActiveFilters)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearFilters,
                tooltip: l10n.clearFilters,
              ),
          ],
        ),
        body: BlocListener<PaymentBloc, PaymentState>(
          listener: _handleStateNotifications,
          child: Column(
            children: [
              BlocBuilder<PaymentBloc, PaymentState>(
                builder: (context, state) {
                  final hasFilters =
                      (state is PaymentsLoaded && state.hasActiveFilters) ||
                      _hasActiveFilters;
                  if (!hasFilters) return const SizedBox.shrink();
                  return const _FilterBadge();
                },
              ),
              Expanded(
                child: BlocBuilder<PaymentBloc, PaymentState>(
                  builder: (context, state) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        unawaited(HapticFeedback.lightImpact());
                        _paymentBloc.add(
                          PaymentRefreshRequested(groupId: widget.groupId),
                        );
                      },
                      child: _PaymentListBody(
                        state: state,
                        groupCurrency: widget.groupCurrency,
                        hasActiveFilters: _hasActiveFilters,
                        onRetry: _loadPayments,
                        onAddPayment: _navigateToCreatePayment,
                        onTapPayment: _showPaymentDetails,
                        canDelete: _canDeletePayment,
                        onDelete: _confirmDeletePayment,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToCreatePayment,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.addPayment),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        ),
      ),
    );
  }

  void _handleStateNotifications(BuildContext context, PaymentState state) {
    if (state is PaymentOperationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
      );
    }
    if (state is PaymentError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
      );
    }
  }

  // ---------------- Navigation / actions ----------------

  bool _canDeletePayment(Payment payment) {
    // For now, allow deletion of all payments. In a real app this would
    // check user permissions / payment ownership.
    return true;
  }

  void _showPaymentDetails(Payment payment) {
    final l10n = context.l10n;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.paymentDetails),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.from(payment.payerName)),
              Text(l10n.to(payment.recipientName)),
              Text(
                l10n.amount(
                  CurrencyFormatter.format(
                    amount: payment.amount,
                    currencyCode: payment.currency,
                  ),
                ),
              ),
              if (payment.description != null)
                Text(l10n.description(payment.description!)),
              Text(l10n.date(_formatDate(context, payment.paymentDate))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePayment(Payment payment) {
    final l10n = context.l10n;
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deletePayment),
          content: Text(
            l10n.confirmDeletePaymentFrom(
              payment.payerName,
              payment.recipientName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.delete),
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
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => CreatePaymentPage(
                groupId: widget.groupId,
                groupCurrency: widget.groupCurrency,
              ),
            ),
          )
          .then((_) => _loadPayments()),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMd(locale).format(date);
  }
}

class _FilterBadge extends StatelessWidget {
  const _FilterBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_outlined,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.l10n.filterPayments,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentListBody extends StatelessWidget {
  const _PaymentListBody({
    required this.state,
    required this.groupCurrency,
    required this.hasActiveFilters,
    required this.onRetry,
    required this.onAddPayment,
    required this.onTapPayment,
    required this.canDelete,
    required this.onDelete,
  });

  final PaymentState state;
  final String groupCurrency;
  final bool hasActiveFilters;
  final VoidCallback onRetry;
  final VoidCallback onAddPayment;
  final void Function(Payment payment) onTapPayment;
  final bool Function(Payment payment) canDelete;
  final void Function(Payment payment) onDelete;

  @override
  Widget build(BuildContext context) {
    if (state is PaymentLoading) {
      return const PaymentListSkeleton();
    }
    if (state is PaymentError) {
      return PaymentListErrorWidget(onRetry: onRetry);
    }
    if (state is PaymentsLoaded || state is PaymentOperationSuccess) {
      final payments = state is PaymentsLoaded
          ? (state as PaymentsLoaded).filteredPayments
          : (state as PaymentOperationSuccess).filteredPayments;

      if (payments.isEmpty) {
        return EmptyPaymentsWidget(
          hasActiveFilters: hasActiveFilters,
          onAddPayment: hasActiveFilters ? null : onAddPayment,
        );
      }

      return Column(
        children: [
          _SummaryCard(
            payments: payments,
            currency: groupCurrency,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.huge + AppSpacing.lg,
              ),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PaymentListItem(
                    payment: payment,
                    groupCurrency: groupCurrency,
                    onTap: () => onTapPayment(payment),
                    onDelete: canDelete(payment)
                        ? () => onDelete(payment)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    return const PaymentListSkeleton();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.payments, required this.currency});

  final List<Payment> payments;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Card(
        elevation: AppElevation.card,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.paymentSummary,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.totalPayments,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        '${payments.length}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.totalAmount,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(
                          amount: totalAmount,
                          currencyCode: currency,
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
