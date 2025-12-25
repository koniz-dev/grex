import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';
import 'package:grex/features/expenses/domain/repositories/expense_repository.dart';
import 'package:grex/features/expenses/domain/utils/expense_search_filter.dart'
    hide ExpenseSortCriteria, ExpenseSortCriteriaExtension;
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';

class _ExpensesStreamEmitted extends ExpenseEvent {
  const _ExpensesStreamEmitted({
    required this.groupId,
    required this.expenses,
  });

  final String groupId;
  final List<Expense> expenses;

  @override
  List<Object?> get props => [groupId, expenses];
}

class _ExpensesStreamErrored extends ExpenseEvent {
  const _ExpensesStreamErrored({
    required this.groupId,
    required this.error,
  });

  final String groupId;
  final Object error;

  @override
  List<Object?> get props => [groupId, error];
}

/// BLoC managing group expenses and their lifecycle
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  /// Creates an [ExpenseBloc] instance
  ExpenseBloc(
    this._expenseRepository,
  ) : super(const ExpenseInitial()) {
    on<ExpensesLoadRequested>(_onExpensesLoadRequested);
    on<_ExpensesStreamEmitted>(_onExpensesStreamEmitted);
    on<_ExpensesStreamErrored>(_onExpensesStreamErrored);
    on<ExpenseCreateRequested>(_onExpenseCreateRequested);
    on<ExpenseUpdateRequested>(_onExpenseUpdateRequested);
    on<ExpenseDeleteRequested>(_onExpenseDeleteRequested);
    on<ExpenseSearchRequested>(_onExpenseSearchRequested);
    on<ExpenseFilterRequested>(_onExpenseFilterRequested);
    on<ExpenseFilterCleared>(_onExpenseFilterCleared);
    on<ExpenseRefreshRequested>(_onExpenseRefreshRequested);
    on<ExpenseLoadRequested>(_onExpenseLoadRequested);
    on<ExpenseSortRequested>(_onExpenseSortRequested);
  }
  final ExpenseRepository _expenseRepository;
  StreamSubscription<List<Expense>>? _expensesSubscription;

  @override
  Future<void> close() async {
    await _expensesSubscription?.cancel();
    return super.close();
  }

  /// Handle loading expenses for a group with real-time updates
  Future<void> _onExpensesLoadRequested(
    ExpensesLoadRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());

    try {
      // Cancel existing subscription
      await _expensesSubscription?.cancel();

      // Get initial expenses
      final result = await _expenseRepository.getGroupExpenses(event.groupId);

      result.fold(
        (failure) => emit(
          ExpenseError(
            failure: failure,
            message: 'Failed to load expenses',
          ),
        ),
        (expenses) {
          final sortedExpenses = _sortExpenses(
            expenses,
            ExpenseSortCriteria.date,
            false,
          );
          emit(
            ExpensesLoaded(
              expenses: sortedExpenses,
              filteredExpenses: sortedExpenses,
              groupId: event.groupId,
              lastUpdated: DateTime.now(),
            ),
          );

          // Set up real-time subscription
          _setupRealTimeSubscription(event.groupId);
        },
      );
    } on Exception catch (e) {
      emit(
        ExpenseError(
          failure: const UnknownExpenseFailure(),
          message: 'Failed to load expenses: $e',
        ),
      );
    }
  }

  /// Set up real-time subscription for expense updates
  void _setupRealTimeSubscription(String groupId) {
    _expensesSubscription = _expenseRepository
        .watchGroupExpenses(groupId)
        .listen(
          (expenses) {
            if (!isClosed) {
              add(_ExpensesStreamEmitted(groupId: groupId, expenses: expenses));
            }
          },
          onError: (Object error) {
            if (!isClosed) {
              add(
                _ExpensesStreamErrored(
                  groupId: groupId,
                  error: error,
                ),
              );
            }
          },
        );
  }

  Future<void> _onExpensesStreamEmitted(
    _ExpensesStreamEmitted event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is! ExpensesLoaded) return;

    final currentState = state as ExpensesLoaded;
    if (currentState.groupId != event.groupId) return;

    final sortedExpenses = _sortExpenses(
      event.expenses,
      currentState.sortBy,
      currentState.sortAscending,
    );

    final filteredExpenses = _applyFiltersAndSearch(
      sortedExpenses,
      currentState.searchQuery,
      currentState.activeFilter,
    );

    emit(
      currentState.copyWith(
        expenses: sortedExpenses,
        filteredExpenses: filteredExpenses,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  Future<void> _onExpensesStreamErrored(
    _ExpensesStreamErrored event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(
      ExpenseError(
        failure: const ExpenseNetworkFailure('Real-time connection error'),
        message: 'Connection error: ${event.error}',
        expenses: state is ExpensesLoaded
            ? (state as ExpensesLoaded).expenses
            : null,
        groupId: event.groupId,
      ),
    );
  }

  /// Handle expense creation
  Future<void> _onExpenseCreateRequested(
    ExpenseCreateRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading(message: 'Creating expense...'));

    try {
      // Determine payer from participants
      // (first participant is typically the payer)
      if (event.participants.isEmpty) {
        emit(
          ExpenseError(
            failure: const NoParticipantsFailure(),
            message: 'At least one participant is required',
            expenses: state is ExpensesLoaded
                ? (state as ExpensesLoaded).expenses
                : null,
            groupId: event.groupId,
          ),
        );
        return;
      }

      final payer = event.participants.first;
      final now = DateTime.now();

      final expense = Expense(
        id: '', // Will be generated by database
        groupId: event.groupId,
        payerId: payer.userId,
        payerName: payer.displayName,
        amount: event.amount,
        currency: event.currency,
        description: event.description,
        category: event.category,
        expenseDate: event.expenseDate ?? now,
        participants: event.participants,
        createdAt: now,
        updatedAt: now,
      );

      final result = await _expenseRepository.createExpense(expense);

      await result.fold<Future<void>>(
        (failure) async {
          emit(
            ExpenseError(
              failure: failure,
              message: 'Failed to create expense',
              expenses: state is ExpensesLoaded
                  ? (state as ExpensesLoaded).expenses
                  : null,
              groupId: event.groupId,
            ),
          );
        },
        (expense) async {
          await _refreshExpenses(
            emit,
            event.groupId,
            'Expense "${expense.description}" created successfully',
          );
        },
      );
    } on Exception catch (e) {
      emit(
        ExpenseError(
          failure: const UnknownExpenseFailure(),
          message: 'Failed to create expense: $e',
          expenses: state is ExpensesLoaded
              ? (state as ExpensesLoaded).expenses
              : null,
          groupId: event.groupId,
        ),
      );
    }
  }

  /// Handle expense updates
  Future<void> _onExpenseUpdateRequested(
    ExpenseUpdateRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading(message: 'Updating expense...'));

    try {
      // First, get the existing expense to preserve payer information
      final existingExpenseResult = await _expenseRepository.getExpenseById(
        event.expenseId,
      );

      final existingExpense = existingExpenseResult.fold(
        (failure) => null,
        (expense) => expense,
      );

      if (existingExpense == null) {
        emit(
          ExpenseError(
            failure: const ExpenseNotFoundFailure(),
            message: 'Expense not found',
            expenses: state is ExpensesLoaded
                ? (state as ExpensesLoaded).expenses
                : null,
            groupId: state is ExpensesLoaded
                ? (state as ExpensesLoaded).groupId
                : null,
          ),
        );
        return;
      }

      // Create updated expense with new values
      final updatedExpense = existingExpense.copyWith(
        description: event.description,
        amount: event.amount,
        currency: event.currency,
        category: event.category,
        expenseDate: event.expenseDate,
        participants: event.participants,
        updatedAt: DateTime.now(),
      );

      final result = await _expenseRepository.updateExpense(updatedExpense);

      await result.fold<Future<void>>(
        (failure) async {
          emit(
            ExpenseError(
              failure: failure,
              message: 'Failed to update expense',
              expenses: state is ExpensesLoaded
                  ? (state as ExpensesLoaded).expenses
                  : null,
              groupId: state is ExpensesLoaded
                  ? (state as ExpensesLoaded).groupId
                  : null,
            ),
          );
        },
        (expense) async {
          final groupId = state is ExpensesLoaded
              ? (state as ExpensesLoaded).groupId
              : expense.groupId;
          await _refreshExpenses(emit, groupId, 'Expense updated successfully');
        },
      );
    } on Exception catch (e) {
      emit(
        ExpenseError(
          failure: const UnknownExpenseFailure(),
          message: 'Failed to update expense: $e',
          expenses: state is ExpensesLoaded
              ? (state as ExpensesLoaded).expenses
              : null,
          groupId: state is ExpensesLoaded
              ? (state as ExpensesLoaded).groupId
              : null,
        ),
      );
    }
  }

  /// Handle expense deletion
  Future<void> _onExpenseDeleteRequested(
    ExpenseDeleteRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final previousState = state;
    final previousGroupId = previousState is ExpensesLoaded
        ? previousState.groupId
        : null;
    final previousExpenses = previousState is ExpensesLoaded
        ? previousState.expenses
        : null;

    emit(const ExpenseLoading(message: 'Deleting expense...'));

    try {
      final result = await _expenseRepository.deleteExpense(event.expenseId);

      await result.fold<Future<void>>(
        (failure) async {
          emit(
            ExpenseError(
              failure: failure,
              message: 'Failed to delete expense',
              expenses: previousExpenses,
              groupId: previousGroupId,
            ),
          );
        },
        (_) async {
          if (previousGroupId != null) {
            await _refreshExpenses(
              emit,
              previousGroupId,
              'Expense deleted successfully',
            );
          }
        },
      );
    } on Exception catch (e) {
      emit(
        ExpenseError(
          failure: const UnknownExpenseFailure(),
          message: 'Failed to delete expense: $e',
          expenses: previousExpenses,
          groupId: previousGroupId,
        ),
      );
    }
  }

  /// Handle expense search
  Future<void> _onExpenseSearchRequested(
    ExpenseSearchRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is! ExpensesLoaded) return;

    final currentState = state as ExpensesLoaded;

    final filteredExpenses = _applyFiltersAndSearch(
      currentState.expenses,
      event.query.trim().isEmpty ? null : event.query.trim(),
      currentState.activeFilter,
    );

    emit(
      currentState.copyWith(
        filteredExpenses: filteredExpenses,
        searchQuery: event.query.trim().isEmpty ? null : event.query.trim(),
      ),
    );
  }

  /// Handle expense filtering
  Future<void> _onExpenseFilterRequested(
    ExpenseFilterRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is! ExpensesLoaded) return;

    final currentState = state as ExpensesLoaded;

    final filter = ExpenseFilter.fromEvent(
      category: event.category,
      participantId: event.participantId,
      startDate: event.startDate,
      endDate: event.endDate,
      minAmount: event.minAmount,
      maxAmount: event.maxAmount,
    );

    final filteredExpenses = _applyFiltersAndSearch(
      currentState.expenses,
      currentState.searchQuery,
      filter.isEmpty ? null : filter,
    );

    emit(
      currentState.copyWith(
        filteredExpenses: filteredExpenses,
        activeFilter: filter.isEmpty ? null : filter,
      ),
    );
  }

  /// Handle clearing filters and search
  Future<void> _onExpenseFilterCleared(
    ExpenseFilterCleared event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is! ExpensesLoaded) return;

    final currentState = state as ExpensesLoaded;

    emit(
      currentState.copyWith(
        filteredExpenses: currentState.expenses,
      ),
    );
  }

  /// Handle refresh requests
  Future<void> _onExpenseRefreshRequested(
    ExpenseRefreshRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    add(ExpensesLoadRequested(groupId: event.groupId));
  }

  /// Handle loading a specific expense
  Future<void> _onExpenseLoadRequested(
    ExpenseLoadRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading(message: 'Loading expense details...'));

    try {
      final result = await _expenseRepository.getExpenseById(event.expenseId);

      result.fold(
        (failure) => emit(
          ExpenseError(
            failure: failure,
            message: 'Failed to load expense details',
          ),
        ),
        (expense) => emit(
          ExpenseDetailLoaded(
            expense: expense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );
    } on Exception catch (e) {
      emit(
        ExpenseError(
          failure: const UnknownExpenseFailure(),
          message: 'Failed to load expense details: $e',
        ),
      );
    }
  }

  /// Handle expense sorting
  Future<void> _onExpenseSortRequested(
    ExpenseSortRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is! ExpensesLoaded) return;

    final currentState = state as ExpensesLoaded;

    final sortedExpenses = _sortExpenses(
      currentState.expenses,
      event.sortBy,
      event.ascending,
    );

    final filteredExpenses = _applyFiltersAndSearch(
      sortedExpenses,
      currentState.searchQuery,
      currentState.activeFilter,
    );

    emit(
      currentState.copyWith(
        expenses: sortedExpenses,
        filteredExpenses: filteredExpenses,
        sortBy: event.sortBy,
        sortAscending: event.ascending,
      ),
    );
  }

  /// Helper method to refresh expenses and emit success state
  Future<void> _refreshExpenses(
    Emitter<ExpenseState> emit,
    String groupId,
    String message,
  ) async {
    try {
      final result = await _expenseRepository.getGroupExpenses(groupId);

      result.fold(
        (failure) => emit(
          ExpenseError(
            failure: failure,
            message: 'Failed to refresh expenses',
            expenses: state is ExpensesLoaded
                ? (state as ExpensesLoaded).expenses
                : null,
            groupId: groupId,
          ),
        ),
        (expenses) {
          final currentState = state is ExpensesLoaded
              ? state as ExpensesLoaded
              : null;
          final sortedExpenses = _sortExpenses(
            expenses,
            currentState?.sortBy ?? ExpenseSortCriteria.date,
            currentState?.sortAscending ?? false,
          );

          emit(
            ExpenseOperationSuccess(
              message: message,
              expenses: sortedExpenses,
              groupId: groupId,
            ),
          );
        },
      );
    } on Exception catch (e) {
      emit(
        ExpenseError(
          failure: const UnknownExpenseFailure(),
          message: 'Failed to refresh expenses: $e',
          expenses: state is ExpensesLoaded
              ? (state as ExpensesLoaded).expenses
              : null,
          groupId: groupId,
        ),
      );
    }
  }

  /// Apply search and filters to expense list
  List<Expense> _applyFiltersAndSearch(
    List<Expense> expenses,
    String? searchQuery,
    ExpenseFilter? filter,
  ) {
    var filtered = expenses;

    // Apply search
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = ExpenseSearchFilter.searchExpenses(
        expenses: filtered,
        query: searchQuery,
      );
    }

    // Apply filters
    if (filter != null && !filter.isEmpty) {
      filtered = filtered.where((expense) => filter.matches(expense)).toList();
    }

    return filtered;
  }

  /// Sort expenses by criteria
  List<Expense> _sortExpenses(
    List<Expense> expenses,
    ExpenseSortCriteria sortBy,
    bool ascending,
  ) {
    final sorted = List<Expense>.from(expenses);

    switch (sortBy) {
      case ExpenseSortCriteria.date:
        sorted.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
      case ExpenseSortCriteria.amount:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
      case ExpenseSortCriteria.description:
        sorted.sort(
          (a, b) => a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          ),
        );
      case ExpenseSortCriteria.category:
        sorted.sort(
          (a, b) => (a.category ?? '').toLowerCase().compareTo(
            (b.category ?? '').toLowerCase(),
          ),
        );
    }

    return ascending ? sorted : sorted.reversed.toList();
  }

  /// Check if current user can edit an expense
  bool canEditExpense(String expenseId) {
    if (state is! ExpensesLoaded) return false;

    final expense = (state as ExpensesLoaded).getExpenseById(expenseId);
    // This would need to check user permissions based on group role and
    // expense ownership. For now, return true - actual permission checking
    // would be implemented based on business rules.
    return expense != null;
  }

  /// Check if current user can delete an expense
  bool canDeleteExpense(String expenseId) {
    if (state is! ExpensesLoaded) return false;

    final expense = (state as ExpensesLoaded).getExpenseById(expenseId);
    // This would need to check user permissions based on group role and
    // expense ownership. For now, return true - actual permission checking
    // would be implemented based on business rules.
    return expense != null;
  }

  /// Get current filter summary for UI display
  String? getFilterSummary() {
    if (state is! ExpensesLoaded) return null;

    final currentState = state as ExpensesLoaded;
    final parts = <String>[];

    if (currentState.searchQuery?.isNotEmpty ?? false) {
      parts.add('Search: "${currentState.searchQuery}"');
    }

    if (currentState.activeFilter != null) {
      final filter = currentState.activeFilter!;
      if (filter.category != null) parts.add('Category: ${filter.category}');
      if (filter.startDate != null || filter.endDate != null) {
        parts.add('Date range');
      }
      if (filter.minAmount != null || filter.maxAmount != null) {
        parts.add('Amount range');
      }
    }

    return parts.isEmpty ? null : parts.join(', ');
  }
}
