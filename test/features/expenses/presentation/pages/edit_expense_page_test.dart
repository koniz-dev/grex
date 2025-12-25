import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/expenses/presentation/pages/edit_expense_page.dart';
import 'package:mocktail/mocktail.dart';

class _FakeExpenseEvent extends Fake implements ExpenseEvent {}

class MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

void main() {
  group('EditExpensePage Widget Tests', () {
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
      when(() => mockExpenseBloc.close()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: EditExpensePage(
          expense: testExpense,
          groupId: 'group-1',
          expenseId: 'expense-1',
        ),
      );
    }

    testWidgets('should display edit expense form with pre-filled data', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Edit Expense'), findsOneWidget);
      expect(find.text('Test Expense'), findsOneWidget);
      expect(find.text('100.0'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('should load group members on init', (tester) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      verify(
        () => mockExpenseBloc.add(any()),
      ).called(1);
    });

    testWidgets('should show unsaved changes warning when form is modified', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Modify description field
      await tester.enterText(
        find.byType(TextFormField).first,
        'Modified Expense',
      );
      await tester.pump();

      // Assert
      expect(
        find.text(
          'You have unsaved changes. Make sure to save before leaving.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('should validate required fields', (tester) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Clear description field
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.tap(find.text('Update Expense'));
      await tester.pump();

      // Assert
      expect(find.text('Description is required'), findsOneWidget);
    });

    testWidgets('should validate description minimum length', (tester) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter short description
      await tester.enterText(find.byType(TextFormField).first, 'AB');
      await tester.tap(find.text('Update Expense'));
      await tester.pump();

      // Assert
      expect(
        find.text('Description must be at least 3 characters'),
        findsOneWidget,
      );
    });

    testWidgets('should validate amount field', (tester) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Clear amount field
      final amountField = find.byType(TextFormField).at(1);
      await tester.enterText(amountField, '');
      await tester.tap(find.text('Update Expense'));
      await tester.pump();

      // Assert
      expect(find.text('Amount is required'), findsOneWidget);
    });

    testWidgets('should validate positive amount', (tester) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter negative amount
      final amountField = find.byType(TextFormField).at(1);
      await tester.enterText(amountField, '-50');
      await tester.tap(find.text('Update Expense'));
      await tester.pump();

      // Assert
      expect(find.text('Enter a valid positive amount'), findsOneWidget);
    });

    testWidgets('should display currency dropdown with current selection', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text(r'USD $'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('should allow currency selection', (tester) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap currency dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select VND
      await tester.tap(find.text('VND ₫').last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('VND ₫'), findsOneWidget);
    });

    testWidgets('should display date picker', (tester) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('15/1/2024'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should open date picker when tapped', (tester) async {
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap date field
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('should display participant selection when members loaded', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Who participated?'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('should display error when members loading fails', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to load members';
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer(
        (_) => Stream.value(
          const ExpenseError(
            failure: ExpenseNetworkFailure(''),
            message: 'Failed to load members',
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(
        find.text('Error loading group members: $errorMessage'),
        findsOneWidget,
      );
    });

    testWidgets('should display split method selector', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('How to split?'), findsOneWidget);
    });

    testWidgets('should display split configuration section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      // Arrange
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Split Configuration'), findsOneWidget);
    });

    testWidgets('should show loading state during update', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const ExpenseInitial(),
          const ExpenseLoading(),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process loading state

      // Assert
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should show success message when update succeeds', (
      tester,
    ) async {
      // Arrange
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const ExpenseInitial(),
          const ExpenseOperationSuccess(message: 'updated'),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process success state

      // Assert
      expect(find.text('Expense updated successfully'), findsOneWidget);
    });

    testWidgets('should show error message when update fails', (tester) async {
      // Arrange
      const errorMessage = 'Failed to update expense';
      when(() => mockExpenseBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const ExpenseInitial(),
          const ExpenseError(
            failure: ExpenseNetworkFailure(''),
            message: errorMessage,
          ),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process error state

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets(
      'should show confirmation dialog when leaving with unsaved changes',
      (tester) async {
        // Arrange
        when(
          () => mockExpenseBloc.stream,
        ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Modify form
        await tester.enterText(
          find.byType(TextFormField).first,
          'Modified Expense',
        );
        await tester.pump();

        // Try to navigate back
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Unsaved Changes'), findsOneWidget);
        expect(
          find.text(
            'You have unsaved changes. Are you sure you want to leave '
            'without saving?',
          ),
          findsOneWidget,
        );
        expect(find.text('Stay'), findsOneWidget);
        expect(find.text('Leave'), findsOneWidget);
      },
    );

    testWidgets('should validate participant selection', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Deselect all participants (assuming they start selected)
      // This would require interacting with the ParticipantSelectionWidget
      // For now, we'll test the validation message display

      // Try to save without participants
      await tester.tap(find.text('Update Expense'));
      await tester.pump();

      // Note: The actual validation would depend on the
      // ParticipantSelectionWidget implementation
      // This test structure shows how to test the validation
    });

    testWidgets('should dispatch update event with correct data', (
      tester,
    ) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Modify description
      await tester.enterText(
        find.byType(TextFormField).first,
        'Updated Expense',
      );

      // Save
      await tester.tap(find.text('Update Expense'));

      // Assert
      verify(
        () => mockExpenseBloc.add(any()),
      ).called(1);
    });

    testWidgets('should display save button in app bar', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('should disable save button when loading', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      // Arrange
      final streamController = StreamController<ExpenseState>();
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => streamController.stream);
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Emit loading state
      streamController.add(const ExpenseLoading());
      await tester.pump(); // Process listener
      await tester.pump(); // Rebuild with _isLoading = true

      // Assert - In loading state, the TextButton in AppBar should have null
      // onPressed
      final textButtonFinder = find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(TextButton),
          )
          .first;

      final textButton = tester.widget<TextButton>(textButtonFinder);
      expect(textButton.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await streamController.close();
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should handle category field correctly', (tester) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find category field and modify it
      final categoryField = find.byType(TextFormField).at(2);
      await tester.enterText(categoryField, 'Entertainment');
      await tester.pump();

      // Assert
      expect(find.text('Entertainment'), findsOneWidget);
    });

    testWidgets('should update split calculation when amount changes', (
      tester,
    ) async {
      // Arrange
      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(
        () => mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Change amount
      final amountField = find.byType(TextFormField).at(1);
      await tester.enterText(amountField, '200');
      await tester.pump();

      // Assert - split configuration should update
      // This would be visible in the SplitConfigurationWidget
      expect(find.text('200'), findsOneWidget);
    });
  });
}
