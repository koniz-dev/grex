import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/entities/split_method.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';
import 'package:grex/features/expenses/domain/repositories/expense_repository.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockExpenseRepository extends Mock implements ExpenseRepository {
  @override
  Future<Either<ExpenseFailure, List<Expense>>> getGroupExpenses(
    String groupId,
  ) {
    return super.noSuchMethod(
          Invocation.method(#getGroupExpenses, [groupId]),
          returnValue: Future.value(
            const Right<ExpenseFailure, List<Expense>>(<Expense>[]),
          ),
          returnValueForMissingStub: Future.value(
            const Right<ExpenseFailure, List<Expense>>(<Expense>[]),
          ),
        )
        as Future<Either<ExpenseFailure, List<Expense>>>;
  }

  @override
  Stream<List<Expense>> watchGroupExpenses(String groupId) {
    return super.noSuchMethod(
          Invocation.method(#watchGroupExpenses, [groupId]),
          returnValue: const Stream<List<Expense>>.empty(),
          returnValueForMissingStub: const Stream<List<Expense>>.empty(),
        )
        as Stream<List<Expense>>;
  }

  @override
  Future<Either<ExpenseFailure, Expense>> getExpenseById(String expenseId) {
    return super.noSuchMethod(
          Invocation.method(#getExpenseById, [expenseId]),
          returnValue: Future.value(
            const Left<ExpenseFailure, Expense>(
              ExpenseNotFoundFailure('missing'),
            ),
          ),
          returnValueForMissingStub: Future.value(
            const Left<ExpenseFailure, Expense>(
              ExpenseNotFoundFailure('missing'),
            ),
          ),
        )
        as Future<Either<ExpenseFailure, Expense>>;
  }
}

void main() {
  group('ExpenseBloc Property-Based Tests', () {
    late MockExpenseRepository mockRepository;
    late ExpenseBloc expenseBloc;
    final random = Random();

    setUp(() {
      mockRepository = MockExpenseRepository();
      expenseBloc = ExpenseBloc(mockRepository);
    });

    tearDown(() async {
      await expenseBloc.close();
    });

    /// Property 10: Expense listing shows chronological order
    /// Validates: Requirements 3.1, 3.2
    group('Property 10: Expense listing chronological order', () {
      test(
        'should maintain chronological order with 200 iterations',
        () async {
          for (var iteration = 0; iteration < 200; iteration++) {
            // Generate random expenses with different dates
            final expenses = _generateRandomExpensesWithDates(
              random,
              5 + random.nextInt(15),
            );

            when(
              mockRepository.getGroupExpenses('test-group'),
            ).thenAnswer(
              (_) async => Right<ExpenseFailure, List<Expense>>(expenses),
            );
            when(
              mockRepository.watchGroupExpenses('test-group'),
            ).thenAnswer((_) => const Stream<List<Expense>>.empty());

            // Load expenses
            final loadedFuture = expenseBloc.stream.firstWhere(
              (state) => state is ExpensesLoaded,
            );
            expenseBloc.add(const ExpensesLoadRequested(groupId: 'test-group'));
            final state = await loadedFuture as ExpensesLoaded;

            // Property: Expenses should be sorted by date (newest first by
            // default)
            final sortedExpenses = state.expenses;
            for (var i = 0; i < sortedExpenses.length - 1; i++) {
              expect(
                sortedExpenses[i].expenseDate.isAfter(
                      sortedExpenses[i + 1].expenseDate,
                    ) ||
                    sortedExpenses[i].expenseDate.isAtSameMomentAs(
                      sortedExpenses[i + 1].expenseDate,
                    ),
                isTrue,
                reason:
                    'Expenses should be in chronological order (newest first) '
                    'at iteration $iteration',
              );
            }

            // Property: Filtered expenses should maintain the same order
            expect(
              state.filteredExpenses.length,
              equals(state.expenses.length),
              reason:
                  'Filtered expenses should match total expenses when no '
                  'filters applied at iteration $iteration',
            );

            // Property: All expenses should have valid dates
            for (final expense in sortedExpenses) {
              expect(
                expense.expenseDate.isBefore(
                  DateTime.now().add(const Duration(days: 1)),
                ),
                isTrue,
                reason:
                    'Expense date should not be in the future at iteration '
                    '$iteration',
              );
            }

            // Reset for next iteration
            await expenseBloc.close();
            expenseBloc = ExpenseBloc(mockRepository);
          }
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );

      test(
        'should handle sorting by different criteria with 200 iterations',
        () async {
          for (var iteration = 0; iteration < 200; iteration++) {
            final expenses = _generateRandomExpensesWithVariedData(
              random,
              3 + random.nextInt(10),
            );

            when(
              mockRepository.getGroupExpenses('test-group'),
            ).thenAnswer(
              (_) async => Right<ExpenseFailure, List<Expense>>(expenses),
            );
            when(
              mockRepository.watchGroupExpenses('test-group'),
            ).thenAnswer((_) => const Stream<List<Expense>>.empty());

            // Load expenses first
            final loadedFuture = expenseBloc.stream.firstWhere(
              (state) => state is ExpensesLoaded,
            );
            expenseBloc.add(const ExpensesLoadRequested(groupId: 'test-group'));
            final initialState = await loadedFuture as ExpensesLoaded;

            // Test different sorting criteria
            final sortCriteria = ExpenseSortCriteria
                .values[random.nextInt(ExpenseSortCriteria.values.length)];
            var ascending = random.nextBool();
            if (sortCriteria == initialState.sortBy &&
                ascending == initialState.sortAscending) {
              ascending = !ascending;
            }

            final sortedFuture = expenseBloc.stream.firstWhere(
              (state) =>
                  state is ExpensesLoaded &&
                  state.sortBy == sortCriteria &&
                  state.sortAscending == ascending,
            );
            expenseBloc.add(
              ExpenseSortRequested(
                groupId: 'test-group',
                sortBy: sortCriteria,
                ascending: ascending,
              ),
            );
            final state = await sortedFuture as ExpensesLoaded;
            final sortedExpenses = state.expenses;

            // Property: Expenses should be sorted according to criteria
            for (var i = 0; i < sortedExpenses.length - 1; i++) {
              final current = sortedExpenses[i];
              final next = sortedExpenses[i + 1];

              switch (sortCriteria) {
                case ExpenseSortCriteria.date:
                  final comparison = current.expenseDate.compareTo(
                    next.expenseDate,
                  );
                  if (ascending) {
                    expect(
                      comparison,
                      lessThanOrEqualTo(0),
                      reason:
                          'Date sorting ascending failed at iteration '
                          '$iteration',
                    );
                  } else {
                    expect(
                      comparison,
                      greaterThanOrEqualTo(0),
                      reason:
                          'Date sorting descending failed at iteration '
                          '$iteration',
                    );
                  }
                case ExpenseSortCriteria.amount:
                  final comparison = current.amount.compareTo(next.amount);
                  if (ascending) {
                    expect(
                      comparison,
                      lessThanOrEqualTo(0),
                      reason:
                          'Amount sorting ascending failed at iteration '
                          '$iteration',
                    );
                  } else {
                    expect(
                      comparison,
                      greaterThanOrEqualTo(0),
                      reason:
                          'Amount sorting descending failed at iteration '
                          '$iteration',
                    );
                  }
                case ExpenseSortCriteria.description:
                  final comparison = current.description
                      .toLowerCase()
                      .compareTo(next.description.toLowerCase());
                  if (ascending) {
                    expect(
                      comparison,
                      lessThanOrEqualTo(0),
                      reason:
                          'Description sorting ascending failed at iteration '
                          '$iteration',
                    );
                  } else {
                    expect(
                      comparison,
                      greaterThanOrEqualTo(0),
                      reason:
                          'Description sorting descending failed at iteration '
                          '$iteration',
                    );
                  }
                case ExpenseSortCriteria.category:
                  final currentCategory = current.category ?? '';
                  final nextCategory = next.category ?? '';
                  final comparison = currentCategory.toLowerCase().compareTo(
                    nextCategory.toLowerCase(),
                  );
                  if (ascending) {
                    expect(
                      comparison,
                      lessThanOrEqualTo(0),
                      reason:
                          'Category sorting ascending failed at iteration '
                          '$iteration',
                    );
                  } else {
                    expect(
                      comparison,
                      greaterThanOrEqualTo(0),
                      reason:
                          'Category sorting descending failed at iteration '
                          '$iteration',
                    );
                  }
              }
            }

            // Property: Sort criteria and direction should be preserved in
            // state
            expect(
              state.sortBy,
              equals(sortCriteria),
              reason:
                  'Sort criteria should be preserved at iteration $iteration',
            );
            expect(
              state.sortAscending,
              equals(ascending),
              reason:
                  'Sort direction should be preserved at iteration $iteration',
            );

            // Reset for next iteration
            await expenseBloc.close();
            expenseBloc = ExpenseBloc(mockRepository);
          }
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );
    });

    /// Property 11: Expense details show complete information
    /// Validates: Requirements 3.2
    group('Property 11: Expense details completeness', () {
      test(
        'should show complete expense information with 200 iterations',
        () async {
          for (var iteration = 0; iteration < 200; iteration++) {
            // Generate random expense with complete data
            final expense = _generateCompleteRandomExpense(random);

            when(
              mockRepository.getExpenseById(expense.id),
            ).thenAnswer(
              (_) async => Right<ExpenseFailure, Expense>(expense),
            );

            // Load expense details
            final loadedFuture = expenseBloc.stream.firstWhere(
              (state) => state is ExpenseDetailLoaded,
            );
            expenseBloc.add(ExpenseLoadRequested(expenseId: expense.id));
            final state = await loadedFuture as ExpenseDetailLoaded;
            final loadedExpense = state.expense;

            // Property: All required fields should be present and valid
            expect(
              loadedExpense.id,
              isNotEmpty,
              reason: 'Expense ID should not be empty at iteration $iteration',
            );
            expect(
              loadedExpense.groupId,
              isNotEmpty,
              reason: 'Group ID should not be empty at iteration $iteration',
            );
            expect(
              loadedExpense.payerId,
              isNotEmpty,
              reason: 'Payer ID should not be empty at iteration $iteration',
            );
            expect(
              loadedExpense.payerName,
              isNotEmpty,
              reason: 'Payer name should not be empty at iteration $iteration',
            );
            expect(
              loadedExpense.description,
              isNotEmpty,
              reason: 'Description should not be empty at iteration $iteration',
            );
            expect(
              loadedExpense.amount,
              greaterThan(0),
              reason: 'Amount should be positive at iteration $iteration',
            );
            expect(
              loadedExpense.currency,
              isNotEmpty,
              reason: 'Currency should not be empty at iteration $iteration',
            );

            // Property: Participants should be complete and valid
            expect(
              loadedExpense.participants,
              isNotEmpty,
              reason:
                  'Participants list should not be empty at iteration '
                  '$iteration',
            );

            double totalParticipantAmount = 0;
            for (final participant in loadedExpense.participants) {
              expect(
                participant.userId,
                isNotEmpty,
                reason:
                    'Participant user ID should not be empty at iteration '
                    '$iteration',
              );
              expect(
                participant.displayName,
                isNotEmpty,
                reason:
                    'Participant display name should not be empty at '
                    'iteration $iteration',
              );
              expect(
                participant.shareAmount,
                greaterThanOrEqualTo(0),
                reason:
                    'Participant share amount should be non-negative at '
                    'iteration $iteration',
              );

              totalParticipantAmount += participant.shareAmount;
            }

            // Property: Total participant amounts should equal expense
            // amount (within rounding tolerance)
            expect(
              totalParticipantAmount,
              closeTo(loadedExpense.amount, 0.01),
              reason:
                  'Total participant amounts should equal expense amount '
                  'at iteration $iteration',
            );
            expect(
              loadedExpense.isValidSplit,
              isTrue,
              reason: 'Expense split should be valid at iteration $iteration',
            );

            // Property: Timestamps should be valid
            expect(
              loadedExpense.expenseDate.isBefore(
                DateTime.now().add(const Duration(days: 1)),
              ),
              isTrue,
              reason:
                  'Expense date should not be in the future at iteration '
                  '$iteration',
            );
            expect(
              loadedExpense.createdAt.isBefore(
                DateTime.now().add(const Duration(minutes: 1)),
              ),
              isTrue,
              reason:
                  'Created timestamp should not be in the future at '
                  'iteration $iteration',
            );
            expect(
              loadedExpense.updatedAt.isBefore(
                DateTime.now().add(const Duration(minutes: 1)),
              ),
              isTrue,
              reason:
                  'Updated timestamp should not be in the future at '
                  'iteration $iteration',
            );

            // Property: Created timestamp should be before or equal to
            // updated timestamp
            expect(
              loadedExpense.createdAt.isBefore(loadedExpense.updatedAt) ||
                  loadedExpense.createdAt.isAtSameMomentAs(
                    loadedExpense.updatedAt,
                  ),
              isTrue,
              reason:
                  'Created timestamp should be before or equal to '
                  'updated timestamp at iteration $iteration',
            );

            // Reset for next iteration
            await expenseBloc.close();
            expenseBloc = ExpenseBloc(mockRepository);
          }
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );

      test(
        'should handle different split methods correctly with 200 iterations',
        () async {
          for (var iteration = 0; iteration < 200; iteration++) {
            final splitMethod =
                SplitMethod.values[random.nextInt(SplitMethod.values.length)];
            final expense = _generateExpenseWithSplitMethod(
              random,
              splitMethod,
            );

            when(
              mockRepository.getExpenseById(expense.id),
            ).thenAnswer(
              (_) async => Right<ExpenseFailure, Expense>(expense),
            );

            final loadedFuture = expenseBloc.stream.firstWhere(
              (state) => state is ExpenseDetailLoaded,
            );
            expenseBloc.add(ExpenseLoadRequested(expenseId: expense.id));
            final state = await loadedFuture as ExpenseDetailLoaded;
            final loadedExpense = state.expense;

            // Property: Split method specific validations
            switch (splitMethod) {
              case SplitMethod.equal:
                // For equal split, all participants should have
                // approximately equal amounts
                if (loadedExpense.participants.length > 1) {
                  final expectedAmount =
                      loadedExpense.amount / loadedExpense.participants.length;
                  for (final participant in loadedExpense.participants) {
                    expect(
                      participant.shareAmount,
                      closeTo(expectedAmount, 0.01),
                      reason:
                          'Equal split should have approximately equal '
                          'amounts at iteration $iteration',
                    );
                  }
                }

              case SplitMethod.percentage:
                // For percentage split, percentages should sum to
                // approximately 100%
                double totalPercentage = 0;
                for (final participant in loadedExpense.participants) {
                  expect(
                    participant.sharePercentage,
                    greaterThanOrEqualTo(0),
                    reason:
                        'Share percentage should be non-negative at iteration '
                        '$iteration',
                  );
                  expect(
                    participant.sharePercentage,
                    lessThanOrEqualTo(100),
                    reason:
                        'Share percentage should not exceed 100% at '
                        'iteration $iteration',
                  );
                  totalPercentage += participant.sharePercentage;
                }
                expect(
                  totalPercentage,
                  closeTo(100.0, 0.01),
                  reason:
                      'Total percentages should sum to 100% at iteration '
                      '$iteration',
                );

              case SplitMethod.exact:
                // For exact split, amounts should be explicitly set
                for (final participant in loadedExpense.participants) {
                  expect(
                    participant.shareAmount,
                    greaterThan(0),
                    reason:
                        'Exact split should have positive amounts at iteration '
                        '$iteration',
                  );
                }

              case SplitMethod.shares:
                // For shares split, amounts and percentages should still
                // be valid
                for (final participant in loadedExpense.participants) {
                  expect(
                    participant.shareAmount,
                    greaterThan(0),
                    reason:
                        'Shares split should have positive share amounts '
                        'at iteration $iteration',
                  );
                  expect(
                    participant.isValidShare,
                    isTrue,
                    reason:
                        'Shares split should have valid participant shares '
                        'at iteration $iteration',
                  );
                }
            }
            expect(
              loadedExpense.isValidSplit,
              isTrue,
              reason:
                  'Generated expense should have valid split at iteration '
                  '$iteration',
            );

            // Reset for next iteration
            await expenseBloc.close();
            expenseBloc = ExpenseBloc(mockRepository);
          }
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );
    });
  });
}

/// Generate random expenses with different dates for chronological testing
List<Expense> _generateRandomExpensesWithDates(Random random, int count) {
  final expenses = <Expense>[];
  final baseDate = DateTime.now().subtract(
    Duration(days: 30 + random.nextInt(365)),
  );

  for (var i = 0; i < count; i++) {
    final expenseDate = baseDate.add(
      Duration(
        days: random.nextInt(30),
        hours: random.nextInt(24),
        minutes: random.nextInt(60),
      ),
    );

    expenses.add(
      Expense(
        id: 'expense-$i',
        groupId: 'test-group',
        payerId: 'user-${random.nextInt(5)}',
        payerName: 'User ${random.nextInt(5)}',
        amount: 10.0 + random.nextDouble() * 1000,
        currency: 'USD',
        description: 'Test Expense $i',
        expenseDate: expenseDate,
        participants: [
          ExpenseParticipant(
            userId: 'user-${random.nextInt(5)}',
            displayName: 'User ${random.nextInt(5)}',
            shareAmount: 10.0 + random.nextDouble() * 100,
            sharePercentage: 50,
          ),
        ],
        createdAt: expenseDate.subtract(Duration(minutes: random.nextInt(60))),
        updatedAt: expenseDate,
      ),
    );
  }

  return expenses;
}

/// Generate random expenses with varied data for sorting tests
List<Expense> _generateRandomExpensesWithVariedData(Random random, int count) {
  final expenses = <Expense>[];
  final categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
  ];
  final descriptions = [
    'Dinner',
    'Lunch',
    'Movie',
    'Gas',
    'Groceries',
    'Coffee',
  ];

  for (var i = 0; i < count; i++) {
    expenses.add(
      Expense(
        id: 'expense-$i',
        groupId: 'test-group',
        payerId: 'user-${random.nextInt(3)}',
        payerName: 'User ${random.nextInt(3)}',
        amount: 5.0 + random.nextDouble() * 500,
        currency: 'USD',
        description: '${descriptions[random.nextInt(descriptions.length)]} $i',
        category: categories[random.nextInt(categories.length)],
        expenseDate: DateTime.now().subtract(
          Duration(days: random.nextInt(30)),
        ),
        participants: [
          ExpenseParticipant(
            userId: 'user-${random.nextInt(3)}',
            displayName: 'User ${random.nextInt(3)}',
            shareAmount: 10.0 + random.nextDouble() * 100,
            sharePercentage: 50,
          ),
        ],
        createdAt: DateTime.now().subtract(
          Duration(days: random.nextInt(30), hours: 1),
        ),
        updatedAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
      ),
    );
  }

  return expenses;
}

/// Generate a complete random expense for detail testing
Expense _generateCompleteRandomExpense(Random random) {
  final participantCount = 2 + random.nextInt(4);
  final amount = 20.0 + random.nextDouble() * 500;
  final participants = <ExpenseParticipant>[];

  for (var i = 0; i < participantCount; i++) {
    participants.add(
      ExpenseParticipant(
        userId: 'user-$i',
        displayName: 'User $i',
        shareAmount: amount / participantCount,
        sharePercentage: 100.0 / participantCount,
      ),
    );
  }

  final now = DateTime.now();
  final createdAt = now.subtract(Duration(days: random.nextInt(30), hours: 1));
  final updatedAtCandidate = createdAt.add(
    Duration(minutes: random.nextInt(60)),
  );
  final updatedAt = updatedAtCandidate.isAfter(now) ? now : updatedAtCandidate;

  return Expense(
    id: 'expense-${random.nextInt(10000)}',
    groupId: 'test-group-${random.nextInt(10)}',
    payerId: 'user-${random.nextInt(5)}',
    payerName: 'User ${random.nextInt(5)}',
    amount: amount,
    currency: ['USD', 'EUR', 'VND'][random.nextInt(3)],
    description: 'Complete Test Expense ${random.nextInt(1000)}',
    category: ['Food', 'Transport', 'Entertainment'][random.nextInt(3)],
    expenseDate: DateTime.now().subtract(Duration(days: random.nextInt(7))),
    participants: participants,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Generate expense with specific split method for testing
Expense _generateExpenseWithSplitMethod(
  Random random,
  SplitMethod splitMethod,
) {
  final participantCount = 2 + random.nextInt(3);
  final amount = 50.0 + random.nextDouble() * 200;
  final participants = <ExpenseParticipant>[];

  switch (splitMethod) {
    case SplitMethod.equal:
      final shareAmount = amount / participantCount;
      for (var i = 0; i < participantCount; i++) {
        participants.add(
          ExpenseParticipant(
            userId: 'user-$i',
            displayName: 'User $i',
            shareAmount: shareAmount,
            sharePercentage: 100.0 / participantCount,
          ),
        );
      }

    case SplitMethod.percentage:
      final percentages = _generatePercentages(random, participantCount);
      for (var i = 0; i < participantCount; i++) {
        participants.add(
          ExpenseParticipant(
            userId: 'user-$i',
            displayName: 'User $i',
            shareAmount: amount * percentages[i] / 100,
            sharePercentage: percentages[i],
          ),
        );
      }

    case SplitMethod.exact:
      final amounts = _generateExactAmounts(random, participantCount, amount);
      for (var i = 0; i < participantCount; i++) {
        participants.add(
          ExpenseParticipant(
            userId: 'user-$i',
            displayName: 'User $i',
            shareAmount: amounts[i],
            sharePercentage: amounts[i] / amount * 100,
          ),
        );
      }

    case SplitMethod.shares:
      final shares = _generateShares(random, participantCount);
      final totalShares = shares.fold<double>(0, (sum, share) => sum + share);
      for (var i = 0; i < participantCount; i++) {
        participants.add(
          ExpenseParticipant(
            userId: 'user-$i',
            displayName: 'User $i',
            shareAmount: amount * shares[i] / totalShares,
            sharePercentage: shares[i] / totalShares * 100,
          ),
        );
      }
  }

  final createdAt = DateTime.now().subtract(Duration(days: random.nextInt(30)));

  return Expense(
    id: 'expense-${random.nextInt(10000)}',
    groupId: 'test-group',
    payerId: 'user-0',
    payerName: 'User 0',
    amount: amount,
    currency: 'USD',
    description: 'Split Method Test Expense',
    expenseDate: DateTime.now().subtract(Duration(days: random.nextInt(7))),
    participants: participants,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

/// Generate percentages that sum to 100%
List<double> _generatePercentages(Random random, int count) {
  final percentages = <double>[];
  var remaining = 100.0;

  for (var i = 0; i < count - 1; i++) {
    final percentage =
        random.nextDouble() * remaining * 0.8; // Leave some for others
    percentages.add(percentage);
    remaining -= percentage;
  }

  percentages.add(remaining); // Last participant gets the remainder
  return percentages;
}

/// Generate exact amounts that sum to total
List<double> _generateExactAmounts(Random random, int count, double total) {
  final amounts = <double>[];
  var remaining = total;

  for (var i = 0; i < count - 1; i++) {
    final amount =
        random.nextDouble() * remaining * 0.8; // Leave some for others
    amounts.add(amount);
    remaining -= amount;
  }

  amounts.add(remaining); // Last participant gets the remainder
  return amounts;
}

/// Generate share counts
List<int> _generateShares(Random random, int count) {
  final shares = <int>[];

  for (var i = 0; i < count; i++) {
    shares.add(1 + random.nextInt(5)); // 1-5 shares each
  }

  return shares;
}
