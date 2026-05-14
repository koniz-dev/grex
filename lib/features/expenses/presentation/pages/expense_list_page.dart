import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/expenses/domain/utils/expense_search_filter.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart'
    hide ExpenseSortCriteria;
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/expenses/presentation/pages/create_expense_page.dart';
import 'package:grex/features/expenses/presentation/pages/expense_details_page.dart';
import 'package:grex/features/expenses/presentation/widgets/empty_expenses_widget.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_filter_sheet.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_list_error_widget.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_list_item.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_list_skeleton.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_search_bar.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Expense list page for a single group, with search, filter, sort, and
/// pull-to-refresh.
class ExpenseListPage extends StatefulWidget {
  /// Creates an [ExpenseListPage].
  const ExpenseListPage({
    required this.groupId,
    required this.groupName,
    required this.groupCurrency,
    super.key,
  });

  /// The ID of the group whose expenses are being displayed.
  final String groupId;

  /// The display name of the group (rendered in the app bar).
  final String groupName;

  /// The functional currency of the group (used for amount conversion hints).
  final String groupCurrency;

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  late final ExpenseBloc _expenseBloc;
  final TextEditingController _searchController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedParticipant;
  double? _minAmount;
  double? _maxAmount;
  ExpenseSortCriteria _sortBy = ExpenseSortCriteria.date;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _expenseBloc = getIt<ExpenseBloc>();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    unawaited(_expenseBloc.close());
    super.dispose();
  }

  void _loadExpenses() {
    _expenseBloc.add(ExpensesLoadRequested(groupId: widget.groupId));
  }

  void _onSearchChanged(String query) {
    _expenseBloc.add(
      ExpenseSearchRequested(groupId: widget.groupId, query: query),
    );
  }

  bool get _hasActiveFilters {
    return _searchController.text.isNotEmpty ||
        _startDate != null ||
        _endDate != null ||
        _selectedParticipant != null ||
        _minAmount != null ||
        _maxAmount != null;
  }

  Future<void> _showFilterSheet() async {
    HapticFeedback.lightImpact();
    final filters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseFilterSheet(
        startDate: _startDate,
        endDate: _endDate,
        selectedParticipant: _selectedParticipant,
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
      _selectedParticipant = filters['selectedParticipant'] as String?;
      _minAmount = filters['minAmount'] as double?;
      _maxAmount = filters['maxAmount'] as double?;
      _sortBy =
          filters['sortBy'] as ExpenseSortCriteria? ?? ExpenseSortCriteria.date;
      _sortAscending = filters['sortAscending'] as bool? ?? false;
    });
    _onSearchChanged(_searchController.text);
  }

  void _clearFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedParticipant = null;
      _minAmount = null;
      _maxAmount = null;
      _sortBy = ExpenseSortCriteria.date;
      _sortAscending = false;
    });
    _searchController.clear();
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _expenseBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.expensesPageTitle(widget.groupName)),
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
              tooltip: l10n.filterExpenses,
            ),
            if (_hasActiveFilters)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearFilters,
                tooltip: l10n.clearFilters,
              ),
          ],
        ),
        body: Column(
          children: [
            ExpenseSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hintText: l10n.expensesSearchHint,
            ),
            if (_hasActiveFilters) _FilterSummaryBanner(summary: _filterSummary),
            Expanded(
              child: BlocBuilder<ExpenseBloc, ExpenseState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      _loadExpenses();
                    },
                    child: _ExpenseListBody(
                      state: state,
                      groupCurrency: widget.groupCurrency,
                      hasActiveFilters: _hasActiveFilters,
                      sortBy: _sortBy,
                      sortAscending: _sortAscending,
                      onRetry: _loadExpenses,
                      onAddExpense: _navigateToCreateExpense,
                      onTapExpense: _navigateToExpenseDetails,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToCreateExpense,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.addExpense),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        ),
      ),
    );
  }

  // ---------------- Filter summary ----------------

  String get _filterSummary {
    final filters = <String>[];
    if (_searchController.text.isNotEmpty) {
      filters.add('"${_searchController.text}"');
    }
    if (_startDate != null && _endDate != null) {
      filters.add(
        '${_formatDateTime(_startDate!)} – ${_formatDateTime(_endDate!)}',
      );
    } else if (_startDate != null) {
      filters.add('≥ ${_formatDateTime(_startDate!)}');
    } else if (_endDate != null) {
      filters.add('≤ ${_formatDateTime(_endDate!)}');
    }
    if (_minAmount != null || _maxAmount != null) {
      final min = _minAmount;
      final max = _maxAmount;
      if (min != null && max != null) {
        filters.add(
          '${CurrencyFormatter.format(amount: min, currencyCode: widget.groupCurrency)} – '
          '${CurrencyFormatter.format(amount: max, currencyCode: widget.groupCurrency)}',
        );
      } else if (min != null) {
        filters.add(
          '≥ ${CurrencyFormatter.format(amount: min, currencyCode: widget.groupCurrency)}',
        );
      } else if (max != null) {
        filters.add(
          '≤ ${CurrencyFormatter.format(amount: max, currencyCode: widget.groupCurrency)}',
        );
      }
    }
    if (_selectedParticipant != null) filters.add('@');
    return filters.join(' · ');
  }

  String _formatDateTime(DateTime dateTime) {
    final dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final timeStr =
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr $timeStr';
  }

  // ---------------- Navigation ----------------

  void _navigateToCreateExpense() {
    HapticFeedback.lightImpact();
    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => CreateExpensePage(
                groupId: widget.groupId,
                groupCurrency: widget.groupCurrency,
              ),
            ),
          )
          .then((_) => _loadExpenses()),
    );
  }

  void _navigateToExpenseDetails(String expenseId) {
    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ExpenseDetailsPage(
                expenseId: expenseId,
                groupId: widget.groupId,
              ),
            ),
          )
          .then((_) => _loadExpenses()),
    );
  }
}

class _ExpenseListBody extends StatelessWidget {
  const _ExpenseListBody({
    required this.state,
    required this.groupCurrency,
    required this.hasActiveFilters,
    required this.sortBy,
    required this.sortAscending,
    required this.onRetry,
    required this.onAddExpense,
    required this.onTapExpense,
  });

  final ExpenseState state;
  final String groupCurrency;
  final bool hasActiveFilters;
  final ExpenseSortCriteria sortBy;
  final bool sortAscending;
  final VoidCallback onRetry;
  final VoidCallback onAddExpense;
  final void Function(String expenseId) onTapExpense;

  @override
  Widget build(BuildContext context) {
    if (state is ExpenseLoading) {
      return const ExpenseListSkeleton();
    }
    if (state is ExpenseError) {
      return ExpenseListErrorWidget(onRetry: onRetry);
    }
    if (state is ExpensesLoaded) {
      final loaded = state as ExpensesLoaded;
      final expenses = ExpenseSearchFilter.sortExpenses(
        expenses: loaded.filteredExpenses,
        sortBy: sortBy,
        ascending: sortAscending,
      );

      if (expenses.isEmpty) {
        return EmptyExpensesWidget(
          hasActiveFilters: hasActiveFilters,
          onAddExpense: hasActiveFilters ? null : onAddExpense,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.huge + AppSpacing.lg,
        ),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ExpenseListItem(
              expense: expense,
              onTap: () => onTapExpense(expense.id),
              groupCurrency: groupCurrency,
            ),
          );
        },
      );
    }
    return const ExpenseListSkeleton();
  }
}

class _FilterSummaryBanner extends StatelessWidget {
  const _FilterSummaryBanner({required this.summary});

  final String summary;

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
              summary,
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
