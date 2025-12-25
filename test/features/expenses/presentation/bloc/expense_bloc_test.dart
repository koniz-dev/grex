import 'package:bloc_test/bloc_test.dart';
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

class TestExpenseRepository implements ExpenseRepository {
  final getGroupExpensesCalls = <String>[];
  final watchGroupExpensesCalls = <String>[];
  final getExpenseByIdCalls = <String>[];
  final createExpenseCalls = <Expense>[];
  final updateExpenseCalls = <Expense>[];
  final deleteExpenseCalls = <String>[];

  Future<Either<ExpenseFailure, List<Expense>>> Function(String groupId)?
  onGetGroupExpenses;
  Stream<List<Expense>> Function(String groupId)? onWatchGroupExpenses;
  Future<Either<ExpenseFailure, Expense>> Function(String expenseId)?
  onGetExpenseById;
  Future<Either<ExpenseFailure, Expense>> Function(Expense expense)?
  onCreateExpense;
  Future<Either<ExpenseFailure, Expense>> Function(Expense expense)?
  onUpdateExpense;
  Future<Either<ExpenseFailure, void>> Function(String expenseId)?
  onDeleteExpense;

  @override
  Future<Either<ExpenseFailure, List<Expense>>> getGroupExpenses(
    String groupId,
  ) {
    getGroupExpensesCalls.add(groupId);
    return (onGetGroupExpenses ??
        (_) async => const Right<ExpenseFailure, List<Expense>>(<Expense>[]))(
      groupId,
    );
  }

  @override
  Stream<List<Expense>> watchGroupExpenses(String groupId) {
    watchGroupExpensesCalls.add(groupId);
    return (onWatchGroupExpenses ?? (_) => const Stream<List<Expense>>.empty())(
      groupId,
    );
  }

  @override
  Future<Either<ExpenseFailure, Expense>> createExpense(Expense expense) {
    createExpenseCalls.add(expense);
    return (onCreateExpense ??
        (_) async => const Left<ExpenseFailure, Expense>(
          UnknownExpenseFailure('missing'),
        ))(
      expense,
    );
  }

  @override
  Future<Either<ExpenseFailure, Expense>> updateExpense(Expense expense) {
    updateExpenseCalls.add(expense);
    return (onUpdateExpense ??
        (_) async => const Left<ExpenseFailure, Expense>(
          UnknownExpenseFailure('missing'),
        ))(
      expense,
    );
  }

  @override
  Future<Either<ExpenseFailure, void>> deleteExpense(String expenseId) {
    deleteExpenseCalls.add(expenseId);
    return (onDeleteExpense ??
        (_) async => const Right<ExpenseFailure, void>(null))(expenseId);
  }

  @override
  Future<Either<ExpenseFailure, Expense>> getExpenseById(String expenseId) {
    getExpenseByIdCalls.add(expenseId);
    return (onGetExpenseById ??
        (_) async => const Left<ExpenseFailure, Expense>(
          ExpenseNotFoundFailure('missing'),
        ))(expenseId);
  }

  @override
  Stream<Expense> watchExpense(String expenseId) {
    return const Stream<Expense>.empty();
  }

  @override
  Future<Either<ExpenseFailure, List<Expense>>> searchExpenses(
    String groupId,
    String query,
  ) async {
    return const Right<ExpenseFailure, List<Expense>>(<Expense>[]);
  }

  @override
  Future<Either<ExpenseFailure, List<Expense>>> getExpensesByDateRange(
    String groupId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return const Right<ExpenseFailure, List<Expense>>(<Expense>[]);
  }

  @override
  Future<Either<ExpenseFailure, List<Expense>>> getExpensesByParticipant(
    String groupId,
    String participantId,
  ) async {
    return const Right<ExpenseFailure, List<Expense>>(<Expense>[]);
  }

  @override
  Future<Either<ExpenseFailure, List<Expense>>> getExpensesPaginated(
    String groupId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return const Right<ExpenseFailure, List<Expense>>(<Expense>[]);
  }

  @override
  Future<Either<ExpenseFailure, bool>> hasPermission(
    String expenseId,
    String action,
  ) async {
    return const Right<ExpenseFailure, bool>(true);
  }

  @override
  Future<Either<ExpenseFailure, bool>> validateExpenseSplit(
    String expenseId,
  ) async {
    return const Right<ExpenseFailure, bool>(true);
  }
}

void main() {
  group('ExpenseBloc', () {
    late TestExpenseRepository repository;
    late ExpenseBloc expenseBloc;

    // Test data
    const testParticipant = ExpenseParticipant(
      userId: 'user-1',
      displayName: 'Test User',
      shareAmount: 25,
      sharePercentage: 50,
    );

    final testExpense = Expense(
      id: 'expense-1',
      groupId: 'group-1',
      payerId: 'user-1',
      payerName: 'Test User',
      amount: 50,
      currency: 'USD',
      description: 'Test Expense',
      expenseDate: DateTime.now(),
      participants: const [testParticipant],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testExpenses = [testExpense];

    setUp(() {
      repository = TestExpenseRepository();
      expenseBloc = ExpenseBloc(repository);
    });

    tearDown(() async {
      await expenseBloc.close();
    });

    group('ExpensesLoadRequested', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpensesLoaded] when expenses are '
        'loaded successfully',
        build: () {
          repository
            ..onGetGroupExpenses = ((_) async => Right(testExpenses))
            ..onWatchGroupExpenses = ((_) =>
                const Stream<List<Expense>>.empty());
          return expenseBloc;
        },
        act: (bloc) =>
            bloc.add(const ExpensesLoadRequested(groupId: 'group-1')),
        expect: () => [
          const ExpenseLoading(),
          isA<ExpensesLoaded>()
              .having((state) => state.expenses.length, 'expenses length', 1)
              .having((state) => state.groupId, 'group id', 'group-1')
              .having(
                (state) => state.expenses.first.id,
                'first expense id',
                'expense-1',
              ),
        ],
        verify: (_) {
          expect(repository.getGroupExpensesCalls, equals(['group-1']));
        },
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpenseError] when loading fails',
        build: () {
          repository.onGetGroupExpenses = (_) async =>
              const Left(ExpenseNetworkFailure('Network error'));
          return expenseBloc;
        },
        act: (bloc) =>
            bloc.add(const ExpensesLoadRequested(groupId: 'group-1')),
        expect: () => [
          const ExpenseLoading(),
          isA<ExpenseError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<ExpenseNetworkFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                'Failed to load expenses',
              ),
        ],
        verify: (_) {
          expect(repository.getGroupExpensesCalls, equals(['group-1']));
        },
      );
    });

    group('ExpenseCreateRequested', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpenseOperationSuccess] when expense '
        'is created successfully',
        build: () {
          repository
            ..onCreateExpense = ((_) async => Right(testExpense))
            ..onGetGroupExpenses = ((_) async => Right(testExpenses));
          return expenseBloc;
        },
        act: (bloc) => bloc.add(
          const ExpenseCreateRequested(
            groupId: 'group-1',
            description: 'New Expense',
            amount: 100,
            currency: 'USD',
            category: 'Food',
            splitMethod: SplitMethod.equal,
            participants: [testParticipant],
            notes: 'Test notes',
          ),
        ),
        expect: () => [
          const ExpenseLoading(message: 'Creating expense...'),
          isA<ExpenseOperationSuccess>()
              .having(
                (state) => state.message,
                'message',
                contains('created successfully'),
              )
              .having((state) => state.groupId, 'group id', 'group-1'),
        ],
        verify: (_) {
          final captured = repository.createExpenseCalls.single;
          expect(captured.id, isEmpty);
          expect(captured.groupId, equals('group-1'));
          expect(captured.payerId, equals('user-1'));
          expect(captured.payerName, equals('Test User'));
          expect(captured.description, equals('New Expense'));
          expect(captured.amount, equals(100.0));
          expect(captured.currency, equals('USD'));
          expect(captured.category, equals('Food'));
          expect(captured.participants, isNotEmpty);
          expect(repository.getGroupExpensesCalls, equals(['group-1']));
        },
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpenseError] when creation fails',
        build: () {
          repository.onCreateExpense = (_) async => const Left(
            InvalidExpenseAmountFailure('Invalid amount'),
          );
          return expenseBloc;
        },
        act: (bloc) => bloc.add(
          const ExpenseCreateRequested(
            groupId: 'group-1',
            description: 'Invalid Expense',
            amount: -10,
            currency: 'USD',
            splitMethod: SplitMethod.equal,
            participants: [testParticipant],
          ),
        ),
        expect: () => [
          const ExpenseLoading(message: 'Creating expense...'),
          isA<ExpenseError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<InvalidExpenseAmountFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                'Failed to create expense',
              ),
        ],
        verify: (_) {
          expect(repository.createExpenseCalls.length, equals(1));
        },
      );
    });

    group('ExpenseUpdateRequested', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpenseOperationSuccess] when expense '
        'is updated successfully',
        build: () {
          repository
            ..onGetExpenseById = ((_) async => Right(testExpense))
            ..onUpdateExpense = ((_) async => Right(testExpense))
            ..onGetGroupExpenses = ((_) async => Right(testExpenses));
          return expenseBloc;
        },
        seed: () => ExpensesLoaded(
          expenses: testExpenses,
          filteredExpenses: testExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const ExpenseUpdateRequested(
            expenseId: 'expense-1',
            description: 'Updated Expense',
            amount: 75,
          ),
        ),
        expect: () => [
          const ExpenseLoading(message: 'Updating expense...'),
          isA<ExpenseOperationSuccess>().having(
            (state) => state.message,
            'message',
            'Expense updated successfully',
          ),
        ],
        verify: (_) {
          final captured = repository.updateExpenseCalls.single;
          expect(captured.id, equals('expense-1'));
          expect(captured.description, equals('Updated Expense'));
          expect(captured.amount, equals(75.0));
        },
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpenseError] when update fails due '
        'to permissions',
        build: () {
          repository
            ..onGetExpenseById = ((_) async => Right(testExpense))
            ..onUpdateExpense = ((_) async => const Left(
              InsufficientExpensePermissionsFailure('update'),
            ));
          return expenseBloc;
        },
        seed: () => ExpensesLoaded(
          expenses: testExpenses,
          filteredExpenses: testExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const ExpenseUpdateRequested(
            expenseId: 'expense-1',
            description: 'Updated Expense',
          ),
        ),
        expect: () => [
          const ExpenseLoading(message: 'Updating expense...'),
          isA<ExpenseError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<InsufficientExpensePermissionsFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                'Failed to update expense',
              ),
        ],
        verify: (_) {
          expect(repository.updateExpenseCalls.length, equals(1));
        },
      );
    });

    group('ExpenseDeleteRequested', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpenseOperationSuccess] when expense '
        'is deleted successfully',
        build: () {
          repository
            ..onDeleteExpense = ((_) async => const Right(null))
            ..onGetGroupExpenses = ((_) async => const Right(<Expense>[]));
          return expenseBloc;
        },
        seed: () => ExpensesLoaded(
          expenses: testExpenses,
          filteredExpenses: testExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) =>
            bloc.add(const ExpenseDeleteRequested(expenseId: 'expense-1')),
        expect: () => [
          const ExpenseLoading(message: 'Deleting expense...'),
          isA<ExpenseOperationSuccess>().having(
            (state) => state.message,
            'message',
            'Expense deleted successfully',
          ),
        ],
        verify: (_) {
          expect(repository.deleteExpenseCalls, equals(['expense-1']));
          expect(repository.getGroupExpensesCalls, equals(['group-1']));
        },
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpenseError] when deletion fails',
        build: () {
          repository.onDeleteExpense = (_) async =>
              const Left(ExpenseNotFoundFailure('expense-1'));
          return expenseBloc;
        },
        seed: () => ExpensesLoaded(
          expenses: testExpenses,
          filteredExpenses: testExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) =>
            bloc.add(const ExpenseDeleteRequested(expenseId: 'expense-1')),
        expect: () => [
          const ExpenseLoading(message: 'Deleting expense...'),
          isA<ExpenseError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<ExpenseNotFoundFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                'Failed to delete expense',
              ),
        ],
        verify: (_) {
          expect(repository.deleteExpenseCalls, equals(['expense-1']));
        },
      );
    });

    group('ExpenseSearchRequested', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'should filter expenses based on search query',
        build: () => expenseBloc,
        seed: () => ExpensesLoaded(
          expenses: [
            testExpense,
            testExpense.copyWith(id: 'expense-2', description: 'Other'),
          ],
          filteredExpenses: [
            testExpense,
            testExpense.copyWith(id: 'expense-2', description: 'Other'),
          ],
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const ExpenseSearchRequested(
            groupId: 'group-1',
            query: 'other',
          ),
        ),
        expect: () => [
          isA<ExpensesLoaded>()
              .having((state) => state.searchQuery, 'search query', 'other')
              .having(
                (state) => state.filteredExpenses.length,
                'filtered count',
                1,
              ),
        ],
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'should clear search when query is empty',
        build: () => expenseBloc,
        seed: () => ExpensesLoaded(
          expenses: testExpenses,
          filteredExpenses: testExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
          searchQuery: 'previous search',
        ),
        act: (bloc) => bloc.add(
          const ExpenseSearchRequested(
            groupId: 'group-1',
            query: '',
          ),
        ),
        expect: () => [
          isA<ExpensesLoaded>()
              .having((state) => state.searchQuery, 'search query', isNull)
              .having(
                (state) => state.filteredExpenses.length,
                'filtered count',
                1,
              ),
        ],
      );
    });

    group('ExpenseFilterRequested', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'should apply filters to expenses',
        build: () => expenseBloc,
        seed: () => ExpensesLoaded(
          expenses: testExpenses,
          filteredExpenses: testExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const ExpenseFilterRequested(
            groupId: 'group-1',
            category: 'Food',
            minAmount: 10,
            maxAmount: 100,
          ),
        ),
        expect: () => [
          isA<ExpensesLoaded>()
              .having((state) => state.activeFilter, 'active filter', isNotNull)
              .having(
                (state) => state.activeFilter?.category,
                'filter category',
                'Food',
              )
              .having(
                (state) => state.activeFilter?.minAmount,
                'filter min amount',
                10.0,
              )
              .having(
                (state) => state.activeFilter?.maxAmount,
                'filter max amount',
                100.0,
              ),
        ],
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'should clear filters when all criteria are null',
        build: () => expenseBloc,
        seed: () => ExpensesLoaded(
          expenses: testExpenses,
          filteredExpenses: testExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
          activeFilter: const ExpenseFilter(category: 'Food'),
        ),
        act: (bloc) => bloc.add(
          const ExpenseFilterRequested(
            groupId: 'group-1',
          ),
        ),
        expect: () => [
          isA<ExpensesLoaded>().having(
            (state) => state.activeFilter,
            'active filter',
            isNull,
          ),
        ],
      );
    });

    group('ExpenseFilterCleared', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'should reset filtered list back to full expenses',
        build: () => expenseBloc,
        seed: () => ExpensesLoaded(
          expenses: testExpenses,
          filteredExpenses: const [],
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
          searchQuery: 'test search',
          activeFilter: const ExpenseFilter(category: 'Food'),
        ),
        act: (bloc) => bloc.add(const ExpenseFilterCleared(groupId: 'group-1')),
        expect: () => [
          isA<ExpensesLoaded>().having(
            (state) => state.filteredExpenses.length,
            'filtered count',
            1,
          ),
        ],
      );
    });

    group('ExpenseLoadRequested', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpenseDetailLoaded] when expense is '
        'loaded successfully',
        build: () {
          repository.onGetExpenseById = (_) async => Right(testExpense);
          return expenseBloc;
        },
        act: (bloc) =>
            bloc.add(const ExpenseLoadRequested(expenseId: 'expense-1')),
        expect: () => [
          const ExpenseLoading(message: 'Loading expense details...'),
          isA<ExpenseDetailLoaded>()
              .having((state) => state.expense.id, 'expense id', 'expense-1')
              .having(
                (state) => state.expense.description,
                'description',
                'Test Expense',
              ),
        ],
        verify: (_) {
          expect(repository.getExpenseByIdCalls, equals(['expense-1']));
        },
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'should emit [ExpenseLoading, ExpenseError] when loading fails',
        build: () {
          repository.onGetExpenseById = (_) async =>
              const Left(ExpenseNotFoundFailure('expense-1'));
          return expenseBloc;
        },
        act: (bloc) =>
            bloc.add(const ExpenseLoadRequested(expenseId: 'expense-1')),
        expect: () => [
          const ExpenseLoading(message: 'Loading expense details...'),
          isA<ExpenseError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<ExpenseNotFoundFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                'Failed to load expense details',
              ),
        ],
        verify: (_) {
          expect(repository.getExpenseByIdCalls, equals(['expense-1']));
        },
      );
    });

    group('ExpenseSortRequested', () {
      final expense1 = testExpense.copyWith(
        id: 'expense-1',
        description: 'A First Expense',
        amount: 100,
        expenseDate: DateTime(2023),
      );
      final expense2 = testExpense.copyWith(
        id: 'expense-2',
        description: 'B Second Expense',
        amount: 50,
        expenseDate: DateTime(2023, 1, 2),
      );
      final unsortedExpenses = [expense2, expense1];

      blocTest<ExpenseBloc, ExpenseState>(
        'should sort expenses by date ascending',
        build: () => expenseBloc,
        seed: () => ExpensesLoaded(
          expenses: unsortedExpenses,
          filteredExpenses: unsortedExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const ExpenseSortRequested(
            groupId: 'group-1',
            sortBy: ExpenseSortCriteria.date,
            ascending: true,
          ),
        ),
        expect: () => [
          isA<ExpensesLoaded>()
              .having(
                (state) => state.expenses.first.id,
                'first expense',
                'expense-1',
              )
              .having(
                (state) => state.sortBy,
                'sort criteria',
                ExpenseSortCriteria.date,
              )
              .having((state) => state.sortAscending, 'sort ascending', true),
        ],
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'should sort expenses by amount descending',
        build: () => expenseBloc,
        seed: () => ExpensesLoaded(
          expenses: unsortedExpenses,
          filteredExpenses: unsortedExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const ExpenseSortRequested(
            groupId: 'group-1',
            sortBy: ExpenseSortCriteria.amount,
          ),
        ),
        expect: () => [
          isA<ExpensesLoaded>()
              .having(
                (state) => state.expenses.first.id,
                'first expense',
                'expense-1',
              )
              .having(
                (state) => state.sortBy,
                'sort criteria',
                ExpenseSortCriteria.amount,
              )
              .having((state) => state.sortAscending, 'sort ascending', false),
        ],
      );

      blocTest<ExpenseBloc, ExpenseState>(
        'should sort expenses by description ascending',
        build: () => expenseBloc,
        seed: () => ExpensesLoaded(
          expenses: unsortedExpenses,
          filteredExpenses: unsortedExpenses,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const ExpenseSortRequested(
            groupId: 'group-1',
            sortBy: ExpenseSortCriteria.description,
            ascending: true,
          ),
        ),
        expect: () => [
          isA<ExpensesLoaded>()
              .having(
                (state) => state.expenses.first.id,
                'first expense',
                'expense-1',
              )
              .having(
                (state) => state.sortBy,
                'sort criteria',
                ExpenseSortCriteria.description,
              )
              .having((state) => state.sortAscending, 'sort ascending', true),
        ],
      );
    });

    group('ExpenseRefreshRequested', () {
      blocTest<ExpenseBloc, ExpenseState>(
        'should trigger ExpensesLoadRequested when refresh is requested',
        build: () {
          repository
            ..onGetGroupExpenses = ((_) async => Right(testExpenses))
            ..onWatchGroupExpenses = ((_) =>
                const Stream<List<Expense>>.empty());
          return expenseBloc;
        },
        act: (bloc) =>
            bloc.add(const ExpenseRefreshRequested(groupId: 'group-1')),
        expect: () => [
          const ExpenseLoading(),
          isA<ExpensesLoaded>().having(
            (state) => state.expenses.length,
            'expenses length',
            1,
          ),
        ],
        verify: (_) {
          expect(repository.getGroupExpensesCalls, equals(['group-1']));
        },
      );
    });
  });
}
