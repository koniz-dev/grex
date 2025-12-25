import 'package:dartz/dartz.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';

/// Repository interface for expense operations
abstract class ExpenseRepository {
  /// Get all expenses for a specific group
  Future<Either<ExpenseFailure, List<Expense>>> getGroupExpenses(
    String groupId,
  );

  /// Create a new expense in a group
  Future<Either<ExpenseFailure, Expense>> createExpense(Expense expense);

  /// Update an existing expense
  Future<Either<ExpenseFailure, Expense>> updateExpense(Expense expense);

  /// Delete an expense
  Future<Either<ExpenseFailure, void>> deleteExpense(String expenseId);

  /// Get a specific expense by ID
  Future<Either<ExpenseFailure, Expense>> getExpenseById(String expenseId);

  /// Watch expenses for a group for real-time updates
  Stream<List<Expense>> watchGroupExpenses(String groupId);

  /// Watch a specific expense for real-time updates
  Stream<Expense> watchExpense(String expenseId);

  /// Search expenses by description, amount, or participant
  Future<Either<ExpenseFailure, List<Expense>>> searchExpenses(
    String groupId,
    String query,
  );

  /// Filter expenses by date range
  Future<Either<ExpenseFailure, List<Expense>>> getExpensesByDateRange(
    String groupId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Filter expenses by participant
  Future<Either<ExpenseFailure, List<Expense>>> getExpensesByParticipant(
    String groupId,
    String participantId,
  );

  /// Get expenses with pagination
  Future<Either<ExpenseFailure, List<Expense>>> getExpensesPaginated(
    String groupId, {
    int limit = 20,
    int offset = 0,
  });

  /// Check if user has permission to perform action on expense
  Future<Either<ExpenseFailure, bool>> hasPermission(
    String expenseId,
    String action,
  );

  /// Validate expense split totals
  Future<Either<ExpenseFailure, bool>> validateExpenseSplit(String expenseId);
}
