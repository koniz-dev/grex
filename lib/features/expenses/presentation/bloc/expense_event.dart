import 'package:equatable/equatable.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/entities/split_method.dart';

/// Base class for all expense events
abstract class ExpenseEvent extends Equatable {
  /// Creates an [ExpenseEvent] instance
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load expenses for a specific group
class ExpensesLoadRequested extends ExpenseEvent {
  /// Creates an [ExpensesLoadRequested] instance
  const ExpensesLoadRequested({required this.groupId});

  /// The ID of the group to load expenses for
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

/// Event to create a new expense
class ExpenseCreateRequested extends ExpenseEvent {
  /// Creates an [ExpenseCreateRequested] instance
  const ExpenseCreateRequested({
    required this.groupId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.splitMethod,
    required this.participants,
    this.category,
    this.expenseDate,
    this.notes,
  });

  /// The ID of the group to create the expense in
  final String groupId;

  /// The description of the expense
  final String description;

  /// The total amount of the expense
  final double amount;

  /// The currency code of the expense
  final String currency;

  /// The category of the expense
  final String? category;

  /// The date when the expense occurred
  final DateTime? expenseDate;

  /// The method used to split the expense
  final SplitMethod splitMethod;

  /// The list of participants in the expense
  final List<ExpenseParticipant> participants;

  /// Additional notes for the expense
  final String? notes;

  @override
  List<Object?> get props => [
    groupId,
    description,
    amount,
    currency,
    category,
    expenseDate,
    splitMethod,
    participants,
    notes,
  ];
}

/// Event to update an existing expense
class ExpenseUpdateRequested extends ExpenseEvent {
  /// Creates an [ExpenseUpdateRequested] instance
  const ExpenseUpdateRequested({
    required this.expenseId,
    this.description,
    this.amount,
    this.currency,
    this.category,
    this.expenseDate,
    this.splitMethod,
    this.participants,
    this.notes,
  });

  /// The ID of the expense to update
  final String expenseId;

  /// The updated description
  final String? description;

  /// The updated total amount
  final double? amount;

  /// The updated currency code
  final String? currency;

  /// The updated category
  final String? category;

  /// The updated date of the expense
  final DateTime? expenseDate;

  /// The updated split method
  final SplitMethod? splitMethod;

  /// The updated list of participants
  final List<ExpenseParticipant>? participants;

  /// The updated additional notes
  final String? notes;

  @override
  List<Object?> get props => [
    expenseId,
    description,
    amount,
    currency,
    category,
    expenseDate,
    splitMethod,
    participants,
    notes,
  ];
}

/// Event to delete an expense
class ExpenseDeleteRequested extends ExpenseEvent {
  /// Creates an [ExpenseDeleteRequested] instance
  const ExpenseDeleteRequested({required this.expenseId});

  /// The ID of the expense to delete
  final String expenseId;

  @override
  List<Object?> get props => [expenseId];
}

/// Event to search expenses by description
class ExpenseSearchRequested extends ExpenseEvent {
  /// Creates an [ExpenseSearchRequested] instance
  const ExpenseSearchRequested({
    required this.groupId,
    required this.query,
  });

  /// The ID of the group to search expenses in
  final String groupId;

  /// The search query
  final String query;

  @override
  List<Object?> get props => [groupId, query];
}

/// Event to filter expenses by various criteria
class ExpenseFilterRequested extends ExpenseEvent {
  /// Creates an [ExpenseFilterRequested] instance
  const ExpenseFilterRequested({
    required this.groupId,
    this.category,
    this.participantId,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  /// The ID of the group to filter expenses in
  final String groupId;

  /// The category to filter by
  final String? category;

  /// The participant ID to filter by
  final String? participantId;

  /// The start date for the date range filter
  final DateTime? startDate;

  /// The end date for the date range filter
  final DateTime? endDate;

  /// The minimum amount for the amount range filter
  final double? minAmount;

  /// The maximum amount for the amount range filter
  final double? maxAmount;

  @override
  List<Object?> get props => [
    groupId,
    category,
    participantId,
    startDate,
    endDate,
    minAmount,
    maxAmount,
  ];
}

/// Event to clear search and filters
class ExpenseFilterCleared extends ExpenseEvent {
  /// Creates an [ExpenseFilterCleared] instance
  const ExpenseFilterCleared({required this.groupId});

  /// The ID of the group to clear filters for
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

/// Event to refresh expenses (force reload)
class ExpenseRefreshRequested extends ExpenseEvent {
  /// Creates an [ExpenseRefreshRequested] instance
  const ExpenseRefreshRequested({required this.groupId});

  /// The ID of the group to refresh expenses for
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

/// Event to load a specific expense by ID
class ExpenseLoadRequested extends ExpenseEvent {
  /// Creates an [ExpenseLoadRequested] instance
  const ExpenseLoadRequested({required this.expenseId});

  /// The ID of the expense to load
  final String expenseId;

  @override
  List<Object?> get props => [expenseId];
}

/// Event to sort expenses by different criteria
class ExpenseSortRequested extends ExpenseEvent {
  /// Creates an [ExpenseSortRequested] instance
  const ExpenseSortRequested({
    required this.groupId,
    required this.sortBy,
    this.ascending = false,
  });

  /// The ID of the group to sort expenses for
  final String groupId;

  /// The criteria to sort by
  final ExpenseSortCriteria sortBy;

  /// Whether to sort in ascending order
  final bool ascending;

  @override
  List<Object?> get props => [groupId, sortBy, ascending];
}

/// Enum for expense sorting criteria
enum ExpenseSortCriteria {
  /// Sort by expense date
  date,

  /// Sort by expense amount
  amount,

  /// Sort by expense description
  description,

  /// Sort by expense category
  category,
}

/// Extension for [ExpenseSortCriteria]
extension ExpenseSortCriteriaExtension on ExpenseSortCriteria {
  /// Returns the display name for the sorting criteria
  String get displayName {
    switch (this) {
      case ExpenseSortCriteria.date:
        return 'Date';
      case ExpenseSortCriteria.amount:
        return 'Amount';
      case ExpenseSortCriteria.description:
        return 'Description';
      case ExpenseSortCriteria.category:
        return 'Category';
    }
  }
}
