import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/utils/expense_search_filter.dart';

void main() {
  group('Search and Filtering Properties', () {
    final random = Random();
    const testIterations = 1000;

    // Helper function to generate random expenses
    List<Expense> generateRandomExpenses(int count) {
      final descriptions = [
        'Dinner at restaurant',
        'Movie tickets',
        'Grocery shopping',
        'Gas station',
        'Coffee shop',
        'Taxi ride',
        'Hotel booking',
        'Concert tickets',
        'Lunch meeting',
        'Office supplies',
      ];

      final userNames = [
        'Alice Johnson',
        'Bob Smith',
        'Charlie Brown',
        'Diana Prince',
        'Eve Wilson',
        'Frank Miller',
        'Grace Lee',
        'Henry Davis',
      ];

      return List.generate(count, (index) {
        final participantCount = random.nextInt(4) + 2; // 2-5 participants
        final selectedUsers = (userNames..shuffle())
            .take(participantCount)
            .toList();

        final participants = selectedUsers
            .map(
              (name) => ExpenseParticipant(
                userId: 'user-${name.toLowerCase().replaceAll(' ', '-')}',
                displayName: name,
                shareAmount: random.nextDouble() * 100,
                sharePercentage: 100.0 / participantCount,
              ),
            )
            .toList();

        return Expense(
          id: 'expense-$index',
          groupId: 'group-1',
          payerId: participants[random.nextInt(participants.length)].userId,
          payerName:
              participants[random.nextInt(participants.length)].displayName,
          amount: random.nextDouble() * 1000 + 10, // 10-1010
          currency: 'USD',
          description: descriptions[random.nextInt(descriptions.length)],
          expenseDate: DateTime.now().subtract(
            Duration(days: random.nextInt(365)),
          ),
          participants: participants,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });
    }

    test('Property 31: Search and filtering work across all criteria', () {
      // Property: Search and filtering operations should be consistent,
      // preserve data integrity, and handle edge cases correctly

      for (var i = 0; i < testIterations; i++) {
        // Generate random test data
        final expenseCount = random.nextInt(50) + 10; // 10-59 expenses
        final expenses = generateRandomExpenses(expenseCount);

        // Test search functionality
        if (expenses.isNotEmpty) {
          // Property: Searching with empty query returns all expenses
          final emptySearchResult = ExpenseSearchFilter.searchExpenses(
            expenses: expenses,
            query: '',
          );
          expect(
            emptySearchResult.length,
            equals(expenses.length),
            reason: 'Empty search should return all expenses',
          );

          // Property: Search results are subset of original expenses
          final randomExpense = expenses[random.nextInt(expenses.length)];
          final searchQuery = randomExpense.description.substring(0, 3);
          final searchResults = ExpenseSearchFilter.searchExpenses(
            expenses: expenses,
            query: searchQuery,
          );

          expect(
            searchResults.length,
            lessThanOrEqualTo(expenses.length),
            reason: 'Search results should be subset of original expenses',
          );

          // Property: All search results should contain the query
          for (final result in searchResults) {
            final matchesDescription = result.description
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
            final matchesAmount = result.amount.toString().contains(
              searchQuery,
            );
            final matchesParticipant = result.participants.any(
              (p) => p.displayName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
            );

            expect(
              matchesDescription || matchesAmount || matchesParticipant,
              isTrue,
              reason: 'Search result should match query in some field',
            );
          }
        }

        // Test date range filtering
        if (expenses.isNotEmpty) {
          final sortedByDate = List<Expense>.from(expenses)
            ..sort((a, b) => a.expenseDate.compareTo(b.expenseDate));

          final startDate = sortedByDate.first.expenseDate;
          final endDate = sortedByDate.last.expenseDate;
          final midDate = DateTime.fromMillisecondsSinceEpoch(
            (startDate.millisecondsSinceEpoch +
                    endDate.millisecondsSinceEpoch) ~/
                2,
          );

          // Property: Date filtering returns expenses within range
          final dateFiltered = ExpenseSearchFilter.filterByDateRange(
            expenses: expenses,
            startDate: startDate,
            endDate: midDate,
          );

          for (final expense in dateFiltered) {
            expect(
              expense.expenseDate.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ),
              isTrue,
              reason: 'Filtered expense should be after start date',
            );
            expect(
              expense.expenseDate.isBefore(
                midDate.add(const Duration(days: 1)),
              ),
              isTrue,
              reason: 'Filtered expense should be before end date',
            );
          }

          // Property: No date filter returns all expenses
          final noDateFilter = ExpenseSearchFilter.filterByDateRange(
            expenses: expenses,
          );
          expect(
            noDateFilter.length,
            equals(expenses.length),
            reason: 'No date filter should return all expenses',
          );
        }

        // Test participant filtering
        if (expenses.isNotEmpty) {
          final randomExpense = expenses[random.nextInt(expenses.length)];
          final participantId = randomExpense.participants.first.userId;

          // Property: Participant filtering returns expenses with that
          // participant
          final participantFiltered = ExpenseSearchFilter.filterByParticipant(
            expenses: expenses,
            participantUserId: participantId,
          );

          for (final expense in participantFiltered) {
            final isParticipant = expense.participants.any(
              (p) => p.userId == participantId,
            );
            final isPayer = expense.payerId == participantId;

            expect(
              isParticipant || isPayer,
              isTrue,
              reason:
                  'Filtered expense should include the specified participant',
            );
          }
        }

        // Test amount range filtering
        if (expenses.isNotEmpty) {
          final amounts = expenses.map((e) => e.amount).toList()..sort();
          final minAmount = amounts.first;
          final maxAmount = amounts.last;
          final midAmount = (minAmount + maxAmount) / 2;

          // Property: Amount filtering returns expenses within range
          final amountFiltered = ExpenseSearchFilter.filterByAmountRange(
            expenses: expenses,
            minAmount: minAmount,
            maxAmount: midAmount,
          );

          for (final expense in amountFiltered) {
            expect(
              expense.amount,
              greaterThanOrEqualTo(minAmount),
              reason: 'Filtered expense amount should be >= min amount',
            );
            expect(
              expense.amount,
              lessThanOrEqualTo(midAmount),
              reason: 'Filtered expense amount should be <= max amount',
            );
          }

          // Property: No amount filter returns all expenses
          final noAmountFilter = ExpenseSearchFilter.filterByAmountRange(
            expenses: expenses,
          );
          expect(
            noAmountFilter.length,
            equals(expenses.length),
            reason: 'No amount filter should return all expenses',
          );
        }

        // Test combined filtering
        if (expenses.isNotEmpty) {
          final randomExpense = expenses[random.nextInt(expenses.length)];

          // Property: Multiple filters should work together
          final multiFiltered = ExpenseSearchFilter.filterExpenses(
            expenses: expenses,
            searchQuery: randomExpense.description.substring(0, 3),
            participantUserId: randomExpense.participants.first.userId,
          );

          expect(
            multiFiltered.length,
            lessThanOrEqualTo(expenses.length),
            reason: 'Multi-filtered results should be subset of original',
          );

          // Property: Each result should match all applied filters
          for (final result in multiFiltered) {
            final matchesSearch = result.description.toLowerCase().contains(
              randomExpense.description.substring(0, 3).toLowerCase(),
            );
            final matchesParticipant =
                result.participants.any(
                  (p) => p.userId == randomExpense.participants.first.userId,
                ) ||
                result.payerId == randomExpense.participants.first.userId;

            expect(
              matchesSearch ||
                  result.amount.toString().contains(
                    randomExpense.description.substring(0, 3),
                  ),
              isTrue,
              reason: 'Result should match search criteria',
            );
            expect(
              matchesParticipant,
              isTrue,
              reason: 'Result should match participant criteria',
            );
          }
        }

        // Test sorting
        if (expenses.length > 1) {
          // Property: Sorting by date should order expenses chronologically
          final sortedByDate = ExpenseSearchFilter.sortExpenses(
            expenses: expenses,
            sortBy: ExpenseSortCriteria.date,
            ascending: true,
          );

          for (var j = 0; j < sortedByDate.length - 1; j++) {
            expect(
              sortedByDate[j].expenseDate.isBefore(
                    sortedByDate[j + 1].expenseDate,
                  ) ||
                  sortedByDate[j].expenseDate.isAtSameMomentAs(
                    sortedByDate[j + 1].expenseDate,
                  ),
              isTrue,
              reason: 'Expenses should be sorted by date in ascending order',
            );
          }

          // Property: Sorting by amount should order expenses by value
          final sortedByAmount = ExpenseSearchFilter.sortExpenses(
            expenses: expenses,
            sortBy: ExpenseSortCriteria.amount,
            ascending: true,
          );

          for (var j = 0; j < sortedByAmount.length - 1; j++) {
            expect(
              sortedByAmount[j].amount,
              lessThanOrEqualTo(sortedByAmount[j + 1].amount),
              reason: 'Expenses should be sorted by amount in ascending order',
            );
          }

          // Property: Descending sort should reverse the order
          final sortedDescending = ExpenseSearchFilter.sortExpenses(
            expenses: expenses,
            sortBy: ExpenseSortCriteria.amount,
          );

          for (var j = 0; j < sortedDescending.length - 1; j++) {
            expect(
              sortedDescending[j].amount,
              greaterThanOrEqualTo(sortedDescending[j + 1].amount),
              reason: 'Expenses should be sorted by amount in descending order',
            );
          }
        }

        // Test statistics calculation
        if (expenses.isNotEmpty) {
          final stats = ExpenseSearchFilter.getExpenseStatistics(expenses);

          // Property: Statistics should accurately reflect the data
          expect(
            stats.totalExpenses,
            equals(expenses.length),
            reason: 'Total expenses count should match input',
          );

          final expectedTotal = expenses.fold<double>(
            0,
            (sum, e) => sum + e.amount,
          );
          expect(
            stats.totalAmount,
            closeTo(expectedTotal, 0.01),
            reason: 'Total amount should match sum of all expenses',
          );

          expect(
            stats.averageAmount,
            closeTo(expectedTotal / expenses.length, 0.01),
            reason: 'Average amount should be total divided by count',
          );

          final amounts = expenses.map((e) => e.amount).toList()..sort();
          expect(
            stats.minAmount,
            equals(amounts.first),
            reason: 'Min amount should match smallest expense',
          );
          expect(
            stats.maxAmount,
            equals(amounts.last),
            reason: 'Max amount should match largest expense',
          );

          expect(
            stats.uniqueParticipants,
            greaterThan(0),
            reason: 'Should have at least one unique participant',
          );
        }

        // Test validation
        // Property: Invalid filter parameters should be caught
        final invalidDateValidation =
            ExpenseSearchFilter.validateFilterParameters(
              startDate: DateTime.now(),
              endDate: DateTime.now().subtract(const Duration(days: 1)),
            );
        expect(
          invalidDateValidation,
          isNotNull,
          reason: 'Should detect invalid date range',
        );

        final invalidAmountValidation =
            ExpenseSearchFilter.validateFilterParameters(
              minAmount: 100,
              maxAmount: 50,
            );
        expect(
          invalidAmountValidation,
          isNotNull,
          reason: 'Should detect invalid amount range',
        );

        final validValidation = ExpenseSearchFilter.validateFilterParameters(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now(),
          minAmount: 10,
          maxAmount: 100,
        );
        expect(
          validValidation,
          isNull,
          reason: 'Should accept valid parameters',
        );
      }
    });
  });
}
