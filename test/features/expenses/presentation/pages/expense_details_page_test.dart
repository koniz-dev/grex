import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart'; // Keep this import
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/expenses/presentation/pages/expense_details_page.dart';
import 'package:grex/shared/utils/currency_formatter.dart';
import 'package:mocktail/mocktail.dart';

class _FakeExpenseEvent extends Fake implements ExpenseEvent {}

class MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

void main() {
  group('ExpenseDetailsPage Widget Tests', () {
    late MockExpenseBloc mockExpenseBloc;
    late Expense testExpense;

    setUpAll(() async {
      registerFallbackValue(_FakeExpenseEvent());
      final getIt = GetIt.instance;
      if (getIt.isRegistered<ExpenseBloc>()) {
        await getIt.unregister<ExpenseBloc>();
      }
    });

    setUp(() {
      mockExpenseBloc = MockExpenseBloc();
      GetIt.instance.registerFactory<ExpenseBloc>(() => mockExpenseBloc);

      // Create test expense
      testExpense = Expense(
        id: 'expense-1',
        groupId: 'group-1',
        payerId: 'user-1',
        payerName: 'John Doe',
        amount: 100,
        currency: 'USD',
        description: 'Test Expense',
        expenseDate: DateTime(2024, 1, 15),
        participants: const [
          ExpenseParticipant(
            userId: 'user-1',
            displayName: 'John Doe',
            shareAmount: 50,
            sharePercentage: 50,
          ),
          ExpenseParticipant(
            userId: 'user-2',
            displayName: 'Jane Smith',
            shareAmount: 50,
            sharePercentage: 50,
          ),
        ],
        createdAt: DateTime(2024, 1, 15, 10),
        updatedAt: DateTime(2024, 1, 15, 10),
        category: 'Food',
      );

      // Setup default mock behavior
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    Widget createTestWidget() {
      return const MaterialApp(
        home: ExpenseDetailsPage(
          expenseId: 'expense-1',
          groupId: 'group-1',
        ),
      );
    }

    testWidgets('should display loading indicator when loading', (
      tester,
    ) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseLoading());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseLoading()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Expense Details'), findsOneWidget);
    });

    testWidgets('should display error state with retry button', (tester) async {
      // Arrange
      const errorMessage = 'Failed to load expense';
      when(() => mockExpenseBloc.state).thenReturn(
        const ExpenseError(
          failure: ExpenseNetworkFailure(''),
          message: errorMessage,
        ),
      );
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer(
        (_) => Stream.value(
          const ExpenseError(
            failure: ExpenseNetworkFailure(''),
            message: errorMessage,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading expense'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should retry loading when retry button is tapped', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to load expense';
      when(() => mockExpenseBloc.state).thenReturn(
        const ExpenseError(
          failure: ExpenseNetworkFailure(''),
          message: errorMessage,
        ),
      );
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer(
        (_) => Stream.value(
          const ExpenseError(
            failure: ExpenseNetworkFailure(''),
            message: errorMessage,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Retry'));

      // Assert
      verify(() => mockExpenseBloc.add(any())).called(greaterThan(0));
    });

    testWidgets('should display expense details when loaded', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Test Expense'), findsOneWidget);
      expect(find.text(r'$100.00'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Paid by John Doe'), findsOneWidget);
      expect(find.text('Participants (2)'), findsOneWidget);
    });

    testWidgets('should display formatted currency amount', (tester) async {
      // Arrange
      final expenseWithVND = testExpense.copyWith(
        amount: 250000,
        currency: 'VND',
      );
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(
          expense: expenseWithVND,
          lastUpdated: DateTime.now(),
        ),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: expenseWithVND,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 250000,
        currencyCode: 'VND',
      );
      expect(find.text(formattedAmount), findsOneWidget);
    });

    testWidgets('should display valid split indicator for valid splits', (
      tester,
    ) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Valid Split'), findsOneWidget);
    });

    testWidgets('should display invalid split warning for invalid splits', (
      tester,
    ) async {
      // Arrange
      final invalidExpense = testExpense.copyWith(
        participants: [
          const ExpenseParticipant(
            userId: 'user-1',
            displayName: 'John Doe',
            shareAmount: 60, // Total doesn't match expense amount
            sharePercentage: 60,
          ),
          const ExpenseParticipant(
            userId: 'user-2',
            displayName: 'Jane Smith',
            shareAmount: 30,
            sharePercentage: 30,
          ),
        ],
      );
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(
          expense: invalidExpense,
          lastUpdated: DateTime.now(),
        ),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: invalidExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('Invalid Split'), findsOneWidget);
    });

    testWidgets('should display all participants with their share amounts', (
      tester,
    ) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Participants (2)'), findsOneWidget);
    });

    testWidgets('should display category when available', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('should not display category section when not available', (
      tester,
    ) async {
      // Arrange
      final expenseWithoutCategory = testExpense.copyWith();
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(
          expense: expenseWithoutCategory,
          lastUpdated: DateTime.now(),
        ),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: expenseWithoutCategory,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Category'), findsNothing);
    });

    testWidgets('should display formatted dates correctly', (tester) async {
      // Arrange
      final today = DateTime.now();
      final todayExpense = testExpense.copyWith(expenseDate: today);
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: todayExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: todayExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('should display yesterday for yesterday expenses', (
      tester,
    ) async {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayExpense = testExpense.copyWith(expenseDate: yesterday);
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(
          expense: yesterdayExpense,
          lastUpdated: DateTime.now(),
        ),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: yesterdayExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('should display menu button with edit and delete options', (
      tester,
    ) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap menu button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit Expense'), findsOneWidget);
      expect(find.text('Delete Expense'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Open menu and tap delete
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Expense'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Delete Expense'), findsWidgets);
      expect(
        find.text(
          'Are you sure you want to delete "Test Expense"? '
          'This action cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('should dispatch delete event when confirmed', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Open menu, tap delete, and confirm
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Expense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);

      // Assert
      verify(
        () => mockExpenseBloc.add(any(that: isA<ExpenseDeleteRequested>())),
      ).called(1);
    });

    testWidgets('should show success message and navigate back when deleted', (
      tester,
    ) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
          const ExpenseOperationSuccess(message: 'deleted'),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process the ExpenseDeleted state

      // Assert
      expect(find.text('Expense deleted successfully'), findsOneWidget);
    });

    testWidgets('should show error message when deletion fails', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to delete expense';
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
          const ExpenseError(
            failure: ExpenseNetworkFailure(''),
            message: errorMessage,
          ),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process the ExpenseError state

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should refresh expense details on pull to refresh', (
      tester,
    ) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Perform pull to refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();

      // Assert
      verify(() => mockExpenseBloc.add(any())).called(greaterThan(0));
    });

    testWidgets('should display metadata information', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(expense: testExpense, lastUpdated: DateTime.now()),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: testExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('Last Updated'), findsOneWidget);
      expect(find.text('Expense ID'), findsOneWidget);
      expect(find.text('expense-1'), findsOneWidget);
    });

    testWidgets('should display split total for invalid splits', (
      tester,
    ) async {
      // Arrange
      final invalidExpense = testExpense.copyWith(
        participants: [
          const ExpenseParticipant(
            userId: 'user-1',
            displayName: 'John Doe',
            shareAmount: 60,
            sharePercentage: 60,
          ),
          const ExpenseParticipant(
            userId: 'user-2',
            displayName: 'Jane Smith',
            shareAmount: 30,
            sharePercentage: 30,
          ),
        ],
      );
      when(() => mockExpenseBloc.state).thenReturn(
        ExpenseDetailLoaded(
          expense: invalidExpense,
          lastUpdated: DateTime.now(),
        ),
      );
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.value(
          ExpenseDetailLoaded(
            expense: invalidExpense,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Split Total'), findsOneWidget);
      expect(find.text(r'$90.00'), findsOneWidget); // 60 + 30
    });

    testWidgets('should load expense details on init', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      verify(
        () => mockExpenseBloc.add(any(that: isA<ExpenseLoadRequested>())),
      ).called(1);
    });
  });
}
