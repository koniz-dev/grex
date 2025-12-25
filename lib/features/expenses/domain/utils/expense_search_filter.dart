import 'package:grex/features/expenses/domain/entities/expense.dart';

/// Utility class for searching and filtering expenses
class ExpenseSearchFilter {
  /// Search expenses by description, amount, or participant
  static List<Expense> searchExpenses({
    required List<Expense> expenses,
    required String query,
  }) {
    if (query.trim().isEmpty) {
      return expenses;
    }

    final lowercaseQuery = query.toLowerCase().trim();

    return expenses.where((expense) {
      // Search in description
      if (expense.description.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // Search in amount (convert to string and search)
      final amountString = expense.amount.toString();
      if (amountString.contains(lowercaseQuery)) {
        return true;
      }

      // Search in participant names
      final hasMatchingParticipant = expense.participants.any(
        (participant) =>
            participant.displayName.toLowerCase().contains(lowercaseQuery),
      );
      if (hasMatchingParticipant) {
        return true;
      }

      // Search in payer name (if available through participants)
      final payer = expense.participants.firstWhere(
        (p) => p.userId == expense.payerId,
        orElse: () => expense.participants.first,
      );
      if (payer.displayName.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Filter expenses by date range
  static List<Expense> filterByDateRange({
    required List<Expense> expenses,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate == null && endDate == null) {
      return expenses;
    }

    return expenses.where((expense) {
      final expenseDate = expense.expenseDate;

      // Check start date
      if (startDate != null) {
        final startOfDay = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        if (expenseDate.isBefore(startOfDay)) {
          return false;
        }
      }

      // Check end date
      if (endDate != null) {
        final endOfDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        if (expenseDate.isAfter(endOfDay)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Filter expenses by participant
  static List<Expense> filterByParticipant({
    required List<Expense> expenses,
    required String participantUserId,
  }) {
    if (participantUserId.trim().isEmpty) {
      return expenses;
    }

    return expenses.where((expense) {
      // Check if user is the payer
      if (expense.payerId == participantUserId) {
        return true;
      }

      // Check if user is a participant
      return expense.participants.any(
        (participant) => participant.userId == participantUserId,
      );
    }).toList();
  }

  /// Filter expenses by amount range
  static List<Expense> filterByAmountRange({
    required List<Expense> expenses,
    double? minAmount,
    double? maxAmount,
  }) {
    if (minAmount == null && maxAmount == null) {
      return expenses;
    }

    return expenses.where((expense) {
      final amount = expense.amount;

      // Check minimum amount
      if (minAmount != null && amount < minAmount) {
        return false;
      }

      // Check maximum amount
      if (maxAmount != null && amount > maxAmount) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Filter expenses by multiple criteria
  static List<Expense> filterExpenses({
    required List<Expense> expenses,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? participantUserId,
    double? minAmount,
    double? maxAmount,
  }) {
    var filteredExpenses = expenses;

    // Apply search filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      filteredExpenses = searchExpenses(
        expenses: filteredExpenses,
        query: searchQuery,
      );
    }

    // Apply date range filter
    filteredExpenses = filterByDateRange(
      expenses: filteredExpenses,
      startDate: startDate,
      endDate: endDate,
    );

    // Apply participant filter
    if (participantUserId != null && participantUserId.trim().isNotEmpty) {
      filteredExpenses = filterByParticipant(
        expenses: filteredExpenses,
        participantUserId: participantUserId,
      );
    }

    // Apply amount range filter
    return filterByAmountRange(
      expenses: filteredExpenses,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
  }

  /// Sort expenses by different criteria
  static List<Expense> sortExpenses({
    required List<Expense> expenses,
    required ExpenseSortCriteria sortBy,
    bool ascending = false,
  }) {
    final sortedExpenses = List<Expense>.from(expenses);

    switch (sortBy) {
      case ExpenseSortCriteria.date:
        sortedExpenses.sort(
          (a, b) => ascending
              ? a.expenseDate.compareTo(b.expenseDate)
              : b.expenseDate.compareTo(a.expenseDate),
        );

      case ExpenseSortCriteria.amount:
        sortedExpenses.sort(
          (a, b) => ascending
              ? a.amount.compareTo(b.amount)
              : b.amount.compareTo(a.amount),
        );

      case ExpenseSortCriteria.description:
        sortedExpenses.sort(
          (a, b) => ascending
              ? a.description.toLowerCase().compareTo(
                  b.description.toLowerCase(),
                )
              : b.description.toLowerCase().compareTo(
                  a.description.toLowerCase(),
                ),
        );

      case ExpenseSortCriteria.payer:
        sortedExpenses.sort((a, b) {
          final payerA = a.participants
              .firstWhere(
                (p) => p.userId == a.payerId,
                orElse: () => a.participants.first,
              )
              .displayName;
          final payerB = b.participants
              .firstWhere(
                (p) => p.userId == b.payerId,
                orElse: () => b.participants.first,
              )
              .displayName;

          return ascending
              ? payerA.toLowerCase().compareTo(payerB.toLowerCase())
              : payerB.toLowerCase().compareTo(payerA.toLowerCase());
        });
    }

    return sortedExpenses;
  }

  /// Get expense statistics for filtered results
  static ExpenseStatistics getExpenseStatistics(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return ExpenseStatistics.empty();
    }

    final totalAmount = expenses.fold(
      0,
      (sum, expense) => sum + expense.amount.toInt(),
    );
    final averageAmount = totalAmount / expenses.length;

    final sortedByAmount = List<Expense>.from(expenses)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    final minAmount = sortedByAmount.first.amount;
    final maxAmount = sortedByAmount.last.amount;

    final sortedByDate = List<Expense>.from(expenses)
      ..sort((a, b) => a.expenseDate.compareTo(b.expenseDate));

    final earliestDate = sortedByDate.first.expenseDate;
    final latestDate = sortedByDate.last.expenseDate;

    // Get unique participants
    final allParticipants = <String>{};
    for (final expense in expenses) {
      allParticipants.add(expense.payerId);
      for (final participant in expense.participants) {
        allParticipants.add(participant.userId);
      }
    }

    return ExpenseStatistics(
      totalExpenses: expenses.length,
      totalAmount: totalAmount.toDouble(),
      averageAmount: averageAmount,
      minAmount: minAmount,
      maxAmount: maxAmount,
      earliestDate: earliestDate,
      latestDate: latestDate,
      uniqueParticipants: allParticipants.length,
    );
  }

  /// Check if expenses list is empty and provide appropriate message
  static String getEmptyStateMessage({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? participantUserId,
    double? minAmount,
    double? maxAmount,
  }) {
    final hasFilters =
        (searchQuery?.isNotEmpty ?? false) ||
        startDate != null ||
        endDate != null ||
        (participantUserId?.isNotEmpty ?? false) ||
        minAmount != null ||
        maxAmount != null;

    if (hasFilters) {
      return 'No expenses match your search criteria. '
          'Try adjusting your filters.';
    } else {
      return 'No expenses yet. Add your first expense to get started!';
    }
  }

  /// Validate filter parameters
  static String? validateFilterParameters({
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) {
    // Validate date range
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      return 'Start date cannot be after end date';
    }

    // Validate amount range
    if (minAmount != null && minAmount < 0) {
      return 'Minimum amount cannot be negative';
    }

    if (maxAmount != null && maxAmount < 0) {
      return 'Maximum amount cannot be negative';
    }

    if (minAmount != null && maxAmount != null && minAmount > maxAmount) {
      return 'Minimum amount cannot be greater than maximum amount';
    }

    return null; // No validation errors
  }
}

/// Enum for expense sorting criteria
enum ExpenseSortCriteria {
  /// Sort by expense date
  date,

  /// Sort by expense amount
  amount,

  /// Sort by expense description
  description,

  /// Sort by payer name
  payer,
}

/// Extension for ExpenseSortCriteria display names
extension ExpenseSortCriteriaExtension on ExpenseSortCriteria {
  /// The human-readable name of the sorting criteria
  String get displayName {
    switch (this) {
      case ExpenseSortCriteria.date:
        return 'Date';
      case ExpenseSortCriteria.amount:
        return 'Amount';
      case ExpenseSortCriteria.description:
        return 'Description';
      case ExpenseSortCriteria.payer:
        return 'Payer';
    }
  }
}

/// Statistics for a list of expenses
class ExpenseStatistics {
  /// Creates a new [ExpenseStatistics] instance
  const ExpenseStatistics({
    required this.totalExpenses,
    required this.totalAmount,
    required this.averageAmount,
    required this.minAmount,
    required this.maxAmount,
    required this.earliestDate,
    required this.latestDate,
    required this.uniqueParticipants,
  });

  /// Creates an empty [ExpenseStatistics] instance
  factory ExpenseStatistics.empty() {
    final now = DateTime.now();
    return ExpenseStatistics(
      totalExpenses: 0,
      totalAmount: 0,
      averageAmount: 0,
      minAmount: 0,
      maxAmount: 0,
      earliestDate: now,
      latestDate: now,
      uniqueParticipants: 0,
    );
  }

  /// Total number of expenses
  final int totalExpenses;

  /// Total amount of all expenses
  final double totalAmount;

  /// Average amount per expense
  final double averageAmount;

  /// Minimum expense amount
  final double minAmount;

  /// Maximum expense amount
  final double maxAmount;

  /// Date of the earliest expense
  final DateTime earliestDate;

  /// Date of the latest expense
  final DateTime latestDate;

  /// Number of unique participants across all expenses
  final int uniqueParticipants;
}
