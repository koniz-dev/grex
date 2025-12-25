import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:grex/features/expenses/presentation/widgets/expense_list_item.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_search_bar.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page displaying list of expenses for a group with search and filter
/// functionality
class ExpenseListPage extends StatefulWidget {
  /// Creates an [ExpenseListPage] instance
  const ExpenseListPage({
    required this.groupId,
    required this.groupName,
    required this.groupCurrency,
    super.key,
  });

  /// The ID of the group whose expenses are being displayed
  final String groupId;

  /// The name of the group
  final String groupName;

  /// The functional currency of the group
  final String groupCurrency;

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

/// State class for ExpenseListPage
class _ExpenseListPageState extends State<ExpenseListPage> {
  late final ExpenseBloc _expenseBloc;
  final TextEditingController _searchController = TextEditingController();

  // Filter state
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
      ExpenseSearchRequested(
        groupId: widget.groupId,
        query: query,
      ),
    );
  }

  void _showFilterSheet() {
    unawaited(
      showModalBottomSheet<Map<String, dynamic>>(
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
      ).then((filters) {
        if (filters != null) {
          setState(() {
            _startDate = filters['startDate'] as DateTime?;
            _endDate = filters['endDate'] as DateTime?;
            _selectedParticipant = filters['selectedParticipant'] as String?;
            _minAmount = filters['minAmount'] as double?;
            _maxAmount = filters['maxAmount'] as double?;
            _sortBy =
                filters['sortBy'] as ExpenseSortCriteria? ??
                ExpenseSortCriteria.date;
            _sortAscending = filters['sortAscending'] as bool? ?? false;
          });
          _onSearchChanged(_searchController.text);
        }
      }),
    );
  }

  void _clearFilters() {
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

  bool get _hasActiveFilters {
    return _searchController.text.isNotEmpty ||
        _startDate != null ||
        _endDate != null ||
        _selectedParticipant != null ||
        _minAmount != null ||
        _maxAmount != null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _expenseBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.groupName} Expenses'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _hasActiveFilters
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: _showFilterSheet,
              tooltip: 'Filter expenses',
            ),
            if (_hasActiveFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearFilters,
                tooltip: 'Clear filters',
              ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            ExpenseSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hintText: 'Search expenses...',
            ),

            // Filter summary
            if (_hasActiveFilters)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  _getFilterSummary(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

            // Expense list
            Expanded(
              child: BlocBuilder<ExpenseBloc, ExpenseState>(
                builder: (context, state) {
                  if (state is ExpenseLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is ExpenseError) {
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
                            'Error loading expenses',
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
                            onPressed: _loadExpenses,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ExpensesLoaded) {
                    final expenses = ExpenseSearchFilter.sortExpenses(
                      expenses: state.filteredExpenses,
                      sortBy: _sortBy,
                      ascending: _sortAscending,
                    );

                    if (expenses.isEmpty) {
                      return EmptyExpensesWidget(
                        message: ExpenseSearchFilter.getEmptyStateMessage(
                          searchQuery: state.searchQuery,
                          startDate: _startDate,
                          endDate: _endDate,
                          participantUserId: _selectedParticipant,
                          minAmount: _minAmount,
                          maxAmount: _maxAmount,
                        ),
                        onAddExpense: _navigateToCreateExpense,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _loadExpenses();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return ExpenseListItem(
                            expense: expense,
                            onTap: () => _navigateToExpenseDetails(expense.id),
                            groupCurrency: widget.groupCurrency,
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToCreateExpense,
          tooltip: 'Add expense',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  String _getFilterSummary() {
    final filters = <String>[];

    if (_searchController.text.isNotEmpty) {
      filters.add('Search: "${_searchController.text}"');
    }

    if (_startDate != null || _endDate != null) {
      if (_startDate != null && _endDate != null) {
        filters.add(
          'Date: ${_formatDateTime(_startDate!)} - '
          '${_formatDateTime(_endDate!)}',
        );
      } else if (_startDate != null) {
        filters.add('From: ${_formatDateTime(_startDate!)}');
      } else {
        filters.add('Until: ${_formatDateTime(_endDate!)}');
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
        filters.add('Amount: $minFormatted - $maxFormatted');
      } else if (_minAmount != null) {
        final minFormatted = CurrencyFormatter.format(
          amount: _minAmount!,
          currencyCode: widget.groupCurrency,
        );
        filters.add('Min: $minFormatted');
      } else {
        final maxFormatted = CurrencyFormatter.format(
          amount: _maxAmount!,
          currencyCode: widget.groupCurrency,
        );
        filters.add('Max: $maxFormatted');
      }
    }

    if (_selectedParticipant != null) {
      filters.add('Participant filter active');
    }

    return 'Filters: ${filters.join(', ')}';
  }

  /// Formats a [DateTime] object into a string with date and time.
  /// Example: "1/1/2023 at 14:30"
  String _formatDateTime(DateTime dateTime) {
    final dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final timeStr =
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  void _navigateToCreateExpense() {
    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (context) => CreateExpensePage(
                groupId: widget.groupId,
                groupCurrency: widget.groupCurrency,
              ),
            ),
          )
          .then((_) {
            // Refresh expenses after creating new one
            _loadExpenses();
          }),
    );
  }

  void _navigateToExpenseDetails(String expenseId) {
    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (context) => ExpenseDetailsPage(
                expenseId: expenseId,
                groupId: widget.groupId,
              ),
            ),
          )
          .then((_) {
            // Refresh expenses in case of updates
            _loadExpenses();
          }),
    );
  }
}
