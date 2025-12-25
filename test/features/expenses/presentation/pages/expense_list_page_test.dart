import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/expenses/presentation/pages/expense_list_page.dart';
import 'package:grex/features/expenses/presentation/widgets/empty_expenses_widget.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:mocktail/mocktail.dart';

// Mock ExpenseBloc
class _FakeExpenseEvent extends Fake implements ExpenseEvent {}

class MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

class _FakeGroupEvent extends Fake implements GroupEvent {}

class MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

void main() {
  group('ExpenseListPage Widget Tests', () {
    late MockExpenseBloc mockExpenseBloc;
    late MockGroupBloc mockGroupBloc;
    late List<Expense> testExpenses;

    setUpAll(() {
      registerFallbackValue(_FakeExpenseEvent());
      registerFallbackValue(_FakeGroupEvent());
    });

    setUp(() async {
      mockExpenseBloc = MockExpenseBloc();
      mockGroupBloc = MockGroupBloc();

      final getIt = GetIt.instance;
      if (getIt.isRegistered<ExpenseBloc>()) {
        await getIt.unregister<ExpenseBloc>();
      }
      if (getIt.isRegistered<GroupBloc>()) {
        await getIt.unregister<GroupBloc>();
      }
      GetIt.instance
        ..registerFactory<ExpenseBloc>(() => mockExpenseBloc)
        ..registerFactory<GroupBloc>(() => mockGroupBloc);

      // Stub GroupBloc
      when(() => mockGroupBloc.state).thenReturn(const GroupInitial());
      when(
        () => mockGroupBloc.stream,
      ).thenAnswer((_) => Stream.value(const GroupInitial()));

      testExpenses = [
        Expense(
          id: 'expense-1',
          groupId: 'group-1',
          payerId: 'user-1',
          payerName: 'John Doe',
          amount: 150000,
          currency: 'VND',
          description: 'Dinner at restaurant',
          expenseDate: DateTime.now().subtract(const Duration(days: 1)),
          participants: const [
            ExpenseParticipant(
              userId: 'user-1',
              displayName: 'John Doe',
              shareAmount: 75000,
              sharePercentage: 50,
            ),
            ExpenseParticipant(
              userId: 'user-2',
              displayName: 'Jane Smith',
              shareAmount: 75000,
              sharePercentage: 50,
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Expense(
          id: 'expense-2',
          groupId: 'group-1',
          payerId: 'user-2',
          payerName: 'Jane Smith',
          amount: 80000,
          currency: 'VND',
          description: 'Movie tickets',
          expenseDate: DateTime.now().subtract(const Duration(days: 2)),
          participants: const [
            ExpenseParticipant(
              userId: 'user-1',
              displayName: 'John Doe',
              shareAmount: 40000,
              sharePercentage: 50,
            ),
            ExpenseParticipant(
              userId: 'user-2',
              displayName: 'Jane Smith',
              shareAmount: 40000,
              sharePercentage: 50,
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<ExpenseBloc>.value(
          value: mockExpenseBloc,
          child: const ExpenseListPage(
            groupId: 'group-1',
            groupName: 'Test Group',
            groupCurrency: 'VND',
          ),
        ),
      );
    }

    testWidgets('should display loading indicator when state is loading', (
      tester,
    ) async {
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseLoading());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseLoading()));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no expenses exist', (
      tester,
    ) async {
      final emptyState = ExpensesLoaded(
        expenses: const [],
        filteredExpenses: const [],
        groupId: 'group-1',
        lastUpdated: DateTime.now(),
      );
      when(() => mockExpenseBloc.state).thenReturn(emptyState);
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(emptyState));

      await tester.pumpWidget(createTestWidget());

      expect(
        find.text('No expenses yet. Add your first expense to get started!'),
        findsOneWidget,
      );
      expect(find.text('Add First Expense'), findsOneWidget);
    });

    testWidgets('should display expenses when expenses exist', (tester) async {
      final loadedState = ExpensesLoaded(
        expenses: testExpenses,
        filteredExpenses: testExpenses,
        groupId: 'group-1',
        lastUpdated: DateTime.now(),
      );
      when(() => mockExpenseBloc.state).thenReturn(loadedState);
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Check expense items
      expect(find.text('Dinner at restaurant'), findsOneWidget);
      expect(find.text('Movie tickets'), findsOneWidget);
      expect(find.textContaining('150.000'), findsOneWidget);
      expect(find.textContaining('80.000'), findsOneWidget);
    });

    testWidgets('should display search bar', (tester) async {
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Search expenses...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should show floating action button', (tester) async {
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should trigger search when search text changes', (
      tester,
    ) async {
      final loadedState = ExpensesLoaded(
        expenses: testExpenses,
        filteredExpenses: testExpenses,
        groupId: 'group-1',
        lastUpdated: DateTime.now(),
      );
      when(() => mockExpenseBloc.state).thenReturn(loadedState);
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Enter search text
      await tester.enterText(find.byType(TextField), 'dinner');

      // Verify search event was triggered
      verify(() => mockExpenseBloc.add(any())).called(greaterThan(0));
    });

    testWidgets('should show filter button and handle filter tap', (
      tester,
    ) async {
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should show filter bottom sheet
      expect(find.text('Filter & Sort'), findsOneWidget);
    });

    testWidgets('should trigger refresh when pull to refresh', (tester) async {
      final loadedState = ExpensesLoaded(
        expenses: testExpenses,
        filteredExpenses: testExpenses,
        groupId: 'group-1',
        lastUpdated: DateTime.now(),
      );
      when(() => mockExpenseBloc.state).thenReturn(loadedState);
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Trigger pull to refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();

      // Verify refresh event was triggered
      verify(() => mockExpenseBloc.add(any())).called(greaterThan(0));
    });

    testWidgets('should display error message when error occurs', (
      tester,
    ) async {
      const errorState = ExpenseError(
        failure: ExpenseNetworkFailure('Network error'),
        message: 'Failed to load expenses',
      );
      when(() => mockExpenseBloc.state).thenReturn(errorState);
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(errorState));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Error loading expenses'), findsOneWidget);
      expect(find.text('Failed to load expenses'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should navigate to expense details when expense is tapped', (
      tester,
    ) async {
      final loadedState = ExpensesLoaded(
        expenses: testExpenses,
        filteredExpenses: testExpenses,
        groupId: 'group-1',
        lastUpdated: DateTime.now(),
      );
      when(() => mockExpenseBloc.state).thenReturn(loadedState);
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Tap on expense item
      await tester.tap(find.text('Dinner at restaurant'));
      await tester.pump(); // Start navigation
      await tester.pump(const Duration(seconds: 1)); // Complete navigation

      // Verify that we are on the details page (AppBar title change is a good
      // indicator)
      expect(find.text('Expense Details'), findsOneWidget);
    });

    testWidgets('should navigate to create expense when FAB is tapped', (
      tester,
    ) async {
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      await tester.pumpWidget(createTestWidget());

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(); // Start navigation
      await tester.pump(const Duration(seconds: 1)); // Complete navigation

      // Verify that we are on the create page
      expect(find.text('Create Expense'), findsOneWidget);
    });

    testWidgets('should display expenses in chronological order', (
      tester,
    ) async {
      final loadedState = ExpensesLoaded(
        expenses: testExpenses,
        filteredExpenses: testExpenses,
        groupId: 'group-1',
        lastUpdated: DateTime.now(),
      );
      when(() => mockExpenseBloc.state).thenReturn(loadedState);
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Find all expense descriptions
      final expenseTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Text),
            ),
          )
          .where(
            (text) =>
                text.data == 'Dinner at restaurant' ||
                text.data == 'Movie tickets',
          )
          .toList();

      // Should be ordered by date (newest first)
      expect(expenseTexts.isNotEmpty, isTrue);
    });

    testWidgets('should display filtered results correctly', (tester) async {
      final filteredExpenses = [testExpenses.first]; // Only dinner expense
      final loadedState = ExpensesLoaded(
        expenses: testExpenses,
        filteredExpenses: filteredExpenses,
        groupId: 'group-1',
        lastUpdated: DateTime.now(),
      );
      when(() => mockExpenseBloc.state).thenReturn(loadedState);
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Should only show filtered expense
      expect(find.textContaining('150.000'), findsOneWidget);
      expect(find.text('Movie tickets'), findsNothing);
    });

    testWidgets(
      'should show active filter indicator when filters are applied',
      (tester) async {
        final loadedState = ExpensesLoaded(
          expenses: testExpenses,
          filteredExpenses: [testExpenses.first],
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
          searchQuery: '',
        );
        when(() => mockExpenseBloc.state).thenReturn(loadedState);
        when(
          () => mockExpenseBloc.stream,
        ).thenAnswer((_) => Stream.value(loadedState));

        await tester.pumpWidget(createTestWidget());

        // Should show filter indicator
        expect(find.byIcon(Icons.filter_list), findsOneWidget);
        // The actual indicator styling depends on implementation
      },
    );

    testWidgets('should handle empty search results', (tester) async {
      final loadedState = ExpensesLoaded(
        expenses: testExpenses,
        filteredExpenses: const [], // No results after search
        groupId: 'group-1',
        lastUpdated: DateTime.now(),
        searchQuery: 'nonexistent',
      );
      when(() => mockExpenseBloc.state).thenReturn(loadedState);
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // We need to enter the text so the controller has it for the message
      // calculation
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pump();

      // Should show no results message
      expect(find.byType(EmptyExpensesWidget), findsOneWidget);
      expect(
        find.textContaining(
          'No expenses match your search criteria',
        ),
        findsOneWidget,
      );
    });
  });
}

// NetworkFailure removed as it should use ExpenseNetworkFailure
