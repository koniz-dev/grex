import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/expenses/presentation/pages/create_expense_page.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:mocktail/mocktail.dart';

class _FakeExpenseEvent extends Fake implements ExpenseEvent {}

class _FakeGroupEvent extends Fake implements GroupEvent {}

class MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

class MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

void main() {
  group('CreateExpensePage Widget Tests', () {
    late MockExpenseBloc mockExpenseBloc;
    late MockGroupBloc mockGroupBloc;
    late List<GroupMember> testMembers;
    late GroupsLoaded groupsLoadedState;

    setUpAll(() async {
      registerFallbackValue(_FakeExpenseEvent());
      registerFallbackValue(_FakeGroupEvent());
      if (getIt.isRegistered<ExpenseBloc>()) {
        await getIt.unregister<ExpenseBloc>();
      }
      if (getIt.isRegistered<GroupBloc>()) {
        await getIt.unregister<GroupBloc>();
      }
    });

    setUp(() async {
      mockExpenseBloc = MockExpenseBloc();
      mockGroupBloc = MockGroupBloc();
      testMembers = [
        GroupMember(
          id: 'member-1',
          userId: 'user-1',
          displayName: 'John Doe',
          role: MemberRole.administrator,
          joinedAt: DateTime.now(),
        ),
        GroupMember(
          id: 'member-2',
          userId: 'user-2',
          displayName: 'Jane Smith',
          role: MemberRole.editor,
          joinedAt: DateTime.now(),
        ),
        GroupMember(
          id: 'member-3',
          userId: 'user-3',
          displayName: 'Bob Wilson',
          role: MemberRole.viewer,
          joinedAt: DateTime.now(),
        ),
      ];

      final testGroup = Group(
        id: 'group-1',
        name: 'Test Group',
        currency: 'USD',
        creatorId: 'user-1',
        members: testMembers,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      groupsLoadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );

      if (getIt.isRegistered<ExpenseBloc>()) {
        await getIt.unregister<ExpenseBloc>();
      }
      if (getIt.isRegistered<GroupBloc>()) {
        await getIt.unregister<GroupBloc>();
      }

      getIt
        ..registerFactory<ExpenseBloc>(() => mockExpenseBloc)
        ..registerFactory<GroupBloc>(() => mockGroupBloc);

      when(() => mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(() => mockExpenseBloc.close()).thenAnswer((_) async {});
      whenListen(
        mockExpenseBloc,
        const Stream<ExpenseState>.empty(),
        initialState: const ExpenseInitial(),
      );

      when(() => mockGroupBloc.state).thenReturn(groupsLoadedState);
      when(() => mockGroupBloc.close()).thenAnswer((_) async {});
      whenListen(
        mockGroupBloc,
        const Stream<GroupState>.empty(),
        initialState: groupsLoadedState,
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<GroupBloc>.value(
          value: mockGroupBloc,
          child: const CreateExpensePage(
            groupId: 'group-1',
            groupCurrency: 'USD',
          ),
        ),
      );
    }

    Future<void> tapParticipant(WidgetTester tester, int index) async {
      final tile = find.byType(CheckboxListTile).at(index);
      await tester.ensureVisible(tile);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> pumpPage(WidgetTester tester) async {
      addTearDown(() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        try {
          tester.testTextInput.hide();
        } on Exception catch (_) {}
        await tester.pump();
      });
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
    }

    testWidgets('should display form fields correctly', (tester) async {
      await pumpPage(tester);

      // Check app bar
      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Check form fields
      expect(find.text('Description *'), findsOneWidget);
      expect(find.text('Amount *'), findsOneWidget);
      expect(find.text('Category (Optional)'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Who participated?'), findsOneWidget);
      expect(find.text('How to split?'), findsOneWidget);

      // Check create button
      expect(find.text('Create Expense'), findsOneWidget);
    });

    testWidgets('should show validation error for empty description', (
      tester,
    ) async {
      await pumpPage(tester);

      // Try to submit without entering description
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Description is required'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid amount', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Test expense',
      );

      // Enter invalid amount
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '0',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Enter a valid positive amount'), findsOneWidget);
    });

    testWidgets('should display group members when loaded', (tester) async {
      await pumpPage(tester);
      await tester.pump();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(testMembers.length));
    });

    testWidgets('should display split method selector', (tester) async {
      await pumpPage(tester);

      // Check split method options
      expect(find.text('Equal Split'), findsOneWidget);
      expect(find.text('Percentage Split'), findsOneWidget);
      expect(find.text('Exact Amount'), findsOneWidget);
      expect(find.text('Share-based Split'), findsOneWidget);
    });

    testWidgets(
      'should show participant selection when split method is selected',
      (tester) async {
        await pumpPage(tester);
        await tester.pump();

        // Select equal split method (should be default)
        // Should show member checkboxes
        expect(
          find.byType(CheckboxListTile),
          findsNWidgets(testMembers.length),
        );
      },
    );

    testWidgets('should show custom split inputs for exact split method', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(1), '100');
      await tapParticipant(tester, 0);
      await tapParticipant(tester, 1);
      await tester.pump();

      // Select exact split method
      await tester.tap(find.text('Exact Amount'));
      await tester.pump();

      // Should show amount input fields for selected participants
      expect(
        find.text('Enter exact amount for each participant'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('should validate split amounts for exact method', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.pump();

      // Fill required fields
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test expense',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '100',
      );

      // Select participants
      await tapParticipant(tester, 0);
      await tapParticipant(tester, 1);
      await tester.pump();

      // Select exact split method
      await tester.ensureVisible(find.text('Exact Amount'));
      await tester.tap(find.text('Exact Amount'));
      await tester.pump();

      // Enter split amounts that don't match total
      final splitFields = find.byType(TextField);
      await tester.enterText(splitFields.first, '30');
      await tester.enterText(splitFields.at(1), '30');
      await tester.pump();

      // Should show validation error
      expect(
        find.textContaining('Exact amounts must sum to total amount'),
        findsOneWidget,
      );
    });

    testWidgets('should show percentage inputs for percentage split method', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.pump();

      // Select percentage split method
      await tester.enterText(find.byType(TextFormField).at(1), '100');
      await tapParticipant(tester, 0);
      await tapParticipant(tester, 1);
      await tester.pump();

      await tester.ensureVisible(find.text('Percentage Split'));
      await tester.tap(find.text('Percentage Split'));
      await tester.pump();

      // Should show percentage input fields
      expect(
        find.text('Enter percentage for each participant (must total 100%)'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('should validate percentage totals', (tester) async {
      await pumpPage(tester);
      await tester.pump();

      // Fill required fields
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test expense',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '100',
      );

      // Select participants
      await tapParticipant(tester, 0);
      await tapParticipant(tester, 1);
      await tester.pump();

      // Select percentage split method
      await tester.ensureVisible(find.text('Percentage Split'));
      await tester.tap(find.text('Percentage Split'));
      await tester.pump();

      // Enter percentages that don't total 100%
      final percentageFields = find.byType(TextField);
      await tester.enterText(percentageFields.first, '30');
      await tester.enterText(percentageFields.at(1), '30');
      await tester.pump();

      // Should show validation error
      expect(
        find.textContaining('Percentages must sum to 100%'),
        findsOneWidget,
      );
    });

    testWidgets('should show date picker when date field is tapped', (
      tester,
    ) async {
      await pumpPage(tester);

      // Tap date field
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Should show date picker
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('should submit form with valid data', (tester) async {
      await pumpPage(tester);
      await tester.pump();

      // Fill form with valid data
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test expense',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '100',
      );

      // Select participants (equal split is default)
      await tapParticipant(tester, 0);
      await tapParticipant(tester, 1);
      await tester.pump();

      // Submit form
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Verify CreateExpense event was added
      verify(() => mockExpenseBloc.add(any())).called(1);
    });

    testWidgets('should show loading state when creating expense', (
      tester,
    ) async {
      whenListen(
        mockExpenseBloc,
        Stream.fromIterable(const [ExpenseLoading()]),
        initialState: const ExpenseInitial(),
      );

      await pumpPage(tester);
      await tester.pump();
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Save button should be disabled
      final saveButton = tester.widget<TextButton>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(TextButton),
        ),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('should show error message when creation fails', (
      tester,
    ) async {
      const errorState = ExpenseError(
        failure: ExpenseNetworkFailure('Network error'),
        message: 'Failed to create expense',
      );
      whenListen(
        mockExpenseBloc,
        Stream.value(errorState),
        initialState: const ExpenseInitial(),
      );

      await pumpPage(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should show error message
      expect(find.text('Failed to create expense'), findsOneWidget);
    });

    testWidgets('should require at least one participant', (tester) async {
      await pumpPage(tester);
      await tester.pump();

      // Fill form but don't select any participants
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test expense',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '100',
      );

      // Try to submit without selecting participants
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should show validation error
      expect(
        find.text('Please select at least one participant'),
        findsOneWidget,
      );
    });

    testWidgets('should have proper form styling', (tester) async {
      await pumpPage(tester);

      // Check form exists
      expect(find.byType(Form), findsOneWidget);

      // Check text fields exist
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Description *'), findsOneWidget);
    });
  });
}
