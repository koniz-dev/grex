import 'package:equatable/equatable.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';

const _copyWithUnset = Object();

/// Base class for all expense states
abstract class ExpenseState extends Equatable {
  /// Creates an [ExpenseState] instance
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

/// Initial state when ExpenseBloc is first created
class ExpenseInitial extends ExpenseState {
  /// Creates an [ExpenseInitial] instance
  const ExpenseInitial();
}

/// State when expenses are being loaded
class ExpenseLoading extends ExpenseState {
  /// Creates an [ExpenseLoading] instance
  const ExpenseLoading({this.message = 'Loading expenses...'});

  /// Message to show during loading
  final String message;

  @override
  List<Object?> get props => [message];
}

/// State when expenses have been loaded successfully
class ExpensesLoaded extends ExpenseState {
  /// Creates an [ExpensesLoaded] instance
  const ExpensesLoaded({
    required this.expenses,
    required this.filteredExpenses,
    required this.groupId,
    required this.lastUpdated,
    this.searchQuery,
    this.activeFilter,
    this.sortBy = ExpenseSortCriteria.date,
    this.sortAscending = false,
  });

  /// The complete list of expenses for the group
  final List<Expense> expenses;

  /// The list of expenses after applying search and filters
  final List<Expense> filteredExpenses;

  /// The ID of the group the expenses belong to
  final String groupId;

  /// The timestamp of the last update
  final DateTime lastUpdated;

  /// The current search query, if any
  final String? searchQuery;

  /// The current active filters, if any
  final ExpenseFilter? activeFilter;

  /// The current sorting criteria
  final ExpenseSortCriteria sortBy;

  /// Whether sorting is in ascending order
  final bool sortAscending;

  @override
  List<Object?> get props => [
    expenses,
    filteredExpenses,
    groupId,
    lastUpdated,
    searchQuery,
    activeFilter,
    sortBy,
    sortAscending,
  ];

  /// Get expense by ID from the loaded expenses
  Expense? getExpenseById(String expenseId) {
    for (final expense in expenses) {
      if (expense.id == expenseId) {
        return expense;
      }
    }
    return null;
  }

  /// Check if there are any active filters or search
  bool get hasActiveFilters =>
      (searchQuery?.isNotEmpty ?? false) || activeFilter != null;

  /// Get the count of filtered expenses
  int get filteredCount => filteredExpenses.length;

  /// Get the total count of all expenses
  int get totalCount => expenses.length;

  /// Check if the list is empty after filtering
  bool get isFilteredEmpty => filteredExpenses.isEmpty;

  /// Check if the original list is empty
  bool get isEmpty => expenses.isEmpty;

  /// Copy with new values
  ExpensesLoaded copyWith({
    List<Expense>? expenses,
    List<Expense>? filteredExpenses,
    String? groupId,
    DateTime? lastUpdated,
    Object? searchQuery = _copyWithUnset,
    Object? activeFilter = _copyWithUnset,
    ExpenseSortCriteria? sortBy,
    bool? sortAscending,
  }) {
    return ExpensesLoaded(
      expenses: expenses ?? this.expenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      groupId: groupId ?? this.groupId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      searchQuery: identical(searchQuery, _copyWithUnset)
          ? this.searchQuery
          : searchQuery as String?,
      activeFilter: identical(activeFilter, _copyWithUnset)
          ? this.activeFilter
          : activeFilter as ExpenseFilter?,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

/// State when a single expense has been loaded
class ExpenseDetailLoaded extends ExpenseState {
  /// Creates an [ExpenseDetailLoaded] instance
  const ExpenseDetailLoaded({
    required this.expense,
    required this.lastUpdated,
  });

  /// The loaded expense details
  final Expense expense;

  /// The timestamp of the last update
  final DateTime lastUpdated;

  @override
  List<Object?> get props => [expense, lastUpdated];
}

/// State when an expense operation was successful
class ExpenseOperationSuccess extends ExpenseState {
  /// Creates an [ExpenseOperationSuccess] instance
  const ExpenseOperationSuccess({
    required this.message,
    this.expenses,
    this.groupId,
  });

  /// Success message to display to the user
  final String message;

  /// The updated list of expenses, if available
  final List<Expense>? expenses;

  /// The group ID, if available
  final String? groupId;

  @override
  List<Object?> get props => [message, expenses, groupId];
}

/// State when an error occurs
class ExpenseError extends ExpenseState {
  /// Creates an [ExpenseError] instance
  const ExpenseError({
    required this.failure,
    required this.message,
    this.expenses,
    this.groupId,
  });

  /// The failure that occurred
  final ExpenseFailure failure;

  /// Error message to display to the user
  final String message;

  /// The last known list of expenses, if available
  final List<Expense>? expenses;

  /// The group ID, if available
  final String? groupId;

  @override
  List<Object?> get props => [failure, message, expenses, groupId];
}

/// State for real-time updates
class ExpenseRealTimeUpdate extends ExpenseState {
  /// Creates an [ExpenseRealTimeUpdate] instance
  const ExpenseRealTimeUpdate({
    required this.expenses,
    required this.groupId,
    required this.updateType,
    this.affectedExpenseId,
  });

  /// The updated list of expenses
  final List<Expense> expenses;

  /// The group ID
  final String groupId;

  /// Type of update ('created', 'updated', or 'deleted')
  final String updateType;

  /// The ID of the affected expense, if any
  final String? affectedExpenseId;

  @override
  List<Object?> get props => [expenses, groupId, updateType, affectedExpenseId];
}

/// Filter criteria for expenses
class ExpenseFilter extends Equatable {
  /// Creates an [ExpenseFilter] instance
  const ExpenseFilter({
    this.category,
    this.participantId,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  /// Create a filter from event parameters
  factory ExpenseFilter.fromEvent({
    String? category,
    String? participantId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) {
    return ExpenseFilter(
      category: category,
      participantId: participantId,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
  }

  /// Category to filter by
  final String? category;

  /// Participant ID to filter by
  final String? participantId;

  /// Start date for the date range filter
  final DateTime? startDate;

  /// End date for the date range filter
  final DateTime? endDate;

  /// Minimum amount for the amount range filter
  final double? minAmount;

  /// Maximum amount for the amount range filter
  final double? maxAmount;

  @override
  List<Object?> get props => [
    category,
    participantId,
    startDate,
    endDate,
    minAmount,
    maxAmount,
  ];

  /// Check if the filter is empty (no criteria set)
  bool get isEmpty =>
      category == null &&
      participantId == null &&
      startDate == null &&
      endDate == null &&
      minAmount == null &&
      maxAmount == null;

  /// Check if an expense matches this filter
  bool matches(Expense expense) {
    // Category filter
    if (category != null && expense.category != category) {
      return false;
    }

    // Participant filter
    if (participantId != null) {
      final hasParticipant = expense.participants.any(
        (participant) => participant.userId == participantId,
      );
      if (!hasParticipant) return false;
    }

    // Date range filter
    if (startDate != null && expense.expenseDate.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && expense.expenseDate.isAfter(endDate!)) {
      return false;
    }

    // Amount range filter
    if (minAmount != null && expense.amount < minAmount!) {
      return false;
    }
    if (maxAmount != null && expense.amount > maxAmount!) {
      return false;
    }

    return true;
  }

  /// Copy with new values
  ExpenseFilter copyWith({
    String? category,
    String? participantId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) {
    return ExpenseFilter(
      category: category ?? this.category,
      participantId: participantId ?? this.participantId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }
}
