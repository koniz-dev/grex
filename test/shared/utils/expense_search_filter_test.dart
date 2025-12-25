import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/utils/expense_search_filter.dart';

void main() {
  group('ExpenseSearchFilter', () {
    late List<Expense> testExpenses;

    setUp(() {
      testExpenses = [
        Expense(
          id: '1',
          groupId: 'group1',
          payerId: 'user1',
          payerName: 'Alice Johnson',
          amount: 100,
          currency: 'USD',
          description: 'Dinner at restaurant',
          expenseDate: DateTime(2024, 1, 15),
          participants: const [
            ExpenseParticipant(
              userId: 'user1',
              displayName: 'Alice Johnson',
              shareAmount: 50,
              sharePercentage: 50,
            ),
            ExpenseParticipant(
              userId: 'user2',
              displayName: 'Bob Smith',
              shareAmount: 50,
              sharePercentage: 50,
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Expense(
          id: '2',
          groupId: 'group1',
          payerId: 'user2',
          payerName: 'Bob Smith',
          amount: 50,
          currency: 'USD',
          description: 'Coffee shop',
          expenseDate: DateTime(2024, 1, 20),
          participants: const [
            ExpenseParticipant(
              userId: 'user1',
              displayName: 'Alice Johnson',
              shareAmount: 25,
              sharePercentage: 50,
            ),
            ExpenseParticipant(
              userId: 'user2',
              displayName: 'Bob Smith',
              shareAmount: 25,
              sharePercentage: 50,
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Expense(
          id: '3',
          groupId: 'group1',
          payerId: 'user3',
          payerName: 'Charlie Brown',
          amount: 200,
          currency: 'USD',
          description: 'Movie tickets',
          expenseDate: DateTime(2024, 1, 10),
          participants: const [
            ExpenseParticipant(
              userId: 'user2',
              displayName: 'Bob Smith',
              shareAmount: 100,
              sharePercentage: 50,
            ),
            ExpenseParticipant(
              userId: 'user3',
              displayName: 'Charlie Brown',
              shareAmount: 100,
              sharePercentage: 50,
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    group('searchExpenses', () {
      test('should return all expenses for empty query', () {
        final result = ExpenseSearchFilter.searchExpenses(
          expenses: testExpenses,
          query: '',
        );

        expect(result.length, equals(testExpenses.length));
      });

      test('should search by description', () {
        final result = ExpenseSearchFilter.searchExpenses(
          expenses: testExpenses,
          query: 'dinner',
        );

        expect(result.length, equals(1));
        expect(result.first.description, contains('Dinner'));
      });

      test('should search by amount', () {
        final result = ExpenseSearchFilter.searchExpenses(
          expenses: testExpenses,
          query: '50',
        );

        expect(result.length, equals(1));
        expect(result.first.amount, equals(50.0));
      });

      test('should search by participant name', () {
        final result = ExpenseSearchFilter.searchExpenses(
          expenses: testExpenses,
          query: 'alice',
        );

        expect(result.length, equals(2));
        expect(
          result.every(
            (e) => e.participants.any(
              (p) => p.displayName.toLowerCase().contains('alice'),
            ),
          ),
          isTrue,
        );
      });

      test('should be case insensitive', () {
        final result = ExpenseSearchFilter.searchExpenses(
          expenses: testExpenses,
          query: 'COFFEE',
        );

        expect(result.length, equals(1));
        expect(result.first.description, equals('Coffee shop'));
      });
    });

    group('filterByDateRange', () {
      test('should return all expenses when no dates provided', () {
        final result = ExpenseSearchFilter.filterByDateRange(
          expenses: testExpenses,
        );

        expect(result.length, equals(testExpenses.length));
      });

      test('should filter by start date only', () {
        final result = ExpenseSearchFilter.filterByDateRange(
          expenses: testExpenses,
          startDate: DateTime(2024, 1, 15),
        );

        expect(result.length, equals(2));
        expect(
          result.every((e) => e.expenseDate.isAfter(DateTime(2024, 1, 14))),
          isTrue,
        );
      });

      test('should filter by end date only', () {
        final result = ExpenseSearchFilter.filterByDateRange(
          expenses: testExpenses,
          endDate: DateTime(2024, 1, 15),
        );

        expect(result.length, equals(2));
        expect(
          result.every((e) => e.expenseDate.isBefore(DateTime(2024, 1, 16))),
          isTrue,
        );
      });

      test('should filter by date range', () {
        final result = ExpenseSearchFilter.filterByDateRange(
          expenses: testExpenses,
          startDate: DateTime(2024, 1, 12),
          endDate: DateTime(2024, 1, 18),
        );

        expect(result.length, equals(1));
        expect(result.first.expenseDate, equals(DateTime(2024, 1, 15)));
      });
    });

    group('filterByParticipant', () {
      test('should return all expenses for empty participant ID', () {
        final result = ExpenseSearchFilter.filterByParticipant(
          expenses: testExpenses,
          participantUserId: '',
        );

        expect(result.length, equals(testExpenses.length));
      });

      test('should filter by participant', () {
        final result = ExpenseSearchFilter.filterByParticipant(
          expenses: testExpenses,
          participantUserId: 'user1',
        );

        expect(result.length, equals(2));
        expect(
          result.every(
            (e) =>
                e.payerId == 'user1' ||
                e.participants.any((p) => p.userId == 'user1'),
          ),
          isTrue,
        );
      });

      test('should include expenses where user is payer', () {
        final result = ExpenseSearchFilter.filterByParticipant(
          expenses: testExpenses,
          participantUserId: 'user3',
        );

        expect(result.length, equals(1));
        expect(result.first.payerId, equals('user3'));
      });
    });

    group('filterByAmountRange', () {
      test('should return all expenses when no amounts provided', () {
        final result = ExpenseSearchFilter.filterByAmountRange(
          expenses: testExpenses,
        );

        expect(result.length, equals(testExpenses.length));
      });

      test('should filter by minimum amount', () {
        final result = ExpenseSearchFilter.filterByAmountRange(
          expenses: testExpenses,
          minAmount: 75,
        );

        expect(result.length, equals(2));
        expect(result.every((e) => e.amount >= 75.0), isTrue);
      });

      test('should filter by maximum amount', () {
        final result = ExpenseSearchFilter.filterByAmountRange(
          expenses: testExpenses,
          maxAmount: 150,
        );

        expect(result.length, equals(2));
        expect(result.every((e) => e.amount <= 150.0), isTrue);
      });

      test('should filter by amount range', () {
        final result = ExpenseSearchFilter.filterByAmountRange(
          expenses: testExpenses,
          minAmount: 75,
          maxAmount: 150,
        );

        expect(result.length, equals(1));
        expect(result.first.amount, equals(100.0));
      });
    });

    group('filterExpenses', () {
      test('should apply multiple filters', () {
        final result = ExpenseSearchFilter.filterExpenses(
          expenses: testExpenses,
          searchQuery: 'coffee',
          participantUserId: 'user1',
          minAmount: 40,
          maxAmount: 60,
        );

        expect(result.length, equals(1));
        expect(result.first.description, equals('Coffee shop'));
      });

      test('should return empty list when no matches', () {
        final result = ExpenseSearchFilter.filterExpenses(
          expenses: testExpenses,
          searchQuery: 'nonexistent',
        );

        expect(result.isEmpty, isTrue);
      });
    });

    group('sortExpenses', () {
      test('should sort by date ascending', () {
        final result = ExpenseSearchFilter.sortExpenses(
          expenses: testExpenses,
          sortBy: ExpenseSortCriteria.date,
          ascending: true,
        );

        expect(result.first.expenseDate, equals(DateTime(2024, 1, 10)));
        expect(result.last.expenseDate, equals(DateTime(2024, 1, 20)));
      });

      test('should sort by date descending', () {
        final result = ExpenseSearchFilter.sortExpenses(
          expenses: testExpenses,
          sortBy: ExpenseSortCriteria.date,
        );

        expect(result.first.expenseDate, equals(DateTime(2024, 1, 20)));
        expect(result.last.expenseDate, equals(DateTime(2024, 1, 10)));
      });

      test('should sort by amount ascending', () {
        final result = ExpenseSearchFilter.sortExpenses(
          expenses: testExpenses,
          sortBy: ExpenseSortCriteria.amount,
          ascending: true,
        );

        expect(result.first.amount, equals(50.0));
        expect(result.last.amount, equals(200.0));
      });

      test('should sort by description', () {
        final result = ExpenseSearchFilter.sortExpenses(
          expenses: testExpenses,
          sortBy: ExpenseSortCriteria.description,
          ascending: true,
        );

        expect(result.first.description, equals('Coffee shop'));
        expect(result.last.description, equals('Movie tickets'));
      });
    });

    group('getExpenseStatistics', () {
      test('should calculate correct statistics', () {
        final stats = ExpenseSearchFilter.getExpenseStatistics(testExpenses);

        expect(stats.totalExpenses, equals(3));
        expect(stats.totalAmount, equals(350.0));
        expect(stats.averageAmount, closeTo(116.67, 0.01));
        expect(stats.minAmount, equals(50.0));
        expect(stats.maxAmount, equals(200.0));
        expect(stats.earliestDate, equals(DateTime(2024, 1, 10)));
        expect(stats.latestDate, equals(DateTime(2024, 1, 20)));
        expect(stats.uniqueParticipants, equals(3));
      });

      test('should handle empty list', () {
        final stats = ExpenseSearchFilter.getExpenseStatistics([]);

        expect(stats.totalExpenses, equals(0));
        expect(stats.totalAmount, equals(0.0));
        expect(stats.averageAmount, equals(0.0));
        expect(stats.uniqueParticipants, equals(0));
      });
    });

    group('getEmptyStateMessage', () {
      test('should return filtered message when filters applied', () {
        final message = ExpenseSearchFilter.getEmptyStateMessage(
          searchQuery: 'test',
        );

        expect(message, contains('No expenses match'));
        expect(message, contains('filters'));
      });

      test('should return default message when no filters', () {
        final message = ExpenseSearchFilter.getEmptyStateMessage();

        expect(message, contains('No expenses yet'));
        expect(message, contains('Add your first'));
      });
    });

    group('validateFilterParameters', () {
      test('should accept valid parameters', () {
        final error = ExpenseSearchFilter.validateFilterParameters(
          startDate: DateTime(2024),
          endDate: DateTime(2024, 1, 31),
          minAmount: 10,
          maxAmount: 100,
        );

        expect(error, isNull);
      });

      test('should reject invalid date range', () {
        final error = ExpenseSearchFilter.validateFilterParameters(
          startDate: DateTime(2024, 1, 31),
          endDate: DateTime(2024),
        );

        expect(error, isNotNull);
        expect(error, contains('Start date'));
      });

      test('should reject negative amounts', () {
        final error = ExpenseSearchFilter.validateFilterParameters(
          minAmount: -10,
        );

        expect(error, isNotNull);
        expect(error, contains('negative'));
      });

      test('should reject invalid amount range', () {
        final error = ExpenseSearchFilter.validateFilterParameters(
          minAmount: 100,
          maxAmount: 50,
        );

        expect(error, isNotNull);
        expect(error, contains('Minimum amount'));
      });
    });
  });

  group('ExpenseSortCriteria', () {
    test('should have correct display names', () {
      expect(ExpenseSortCriteria.date.displayName, equals('Date'));
      expect(ExpenseSortCriteria.amount.displayName, equals('Amount'));
      expect(
        ExpenseSortCriteria.description.displayName,
        equals('Description'),
      );
      expect(ExpenseSortCriteria.payer.displayName, equals('Payer'));
    });
  });
}
