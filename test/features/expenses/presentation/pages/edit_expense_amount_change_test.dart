import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/expenses/presentation/pages/edit_expense_page.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:mocktail/mocktail.dart';

/// Editing only the amount must not silently redistribute an uneven split.
///
/// `EditExpensePage` rebuilds its split data from
/// `ExpenseCalculator.getDefaultParticipantData` on every amount keystroke,
/// and those defaults are one share each / 0.00 exact / an even percentage.
/// So a 3:1 split survived only until someone corrected a typo in the amount.
/// See issue #29.
class _MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _FakeExpenseEvent extends Fake implements ExpenseEvent {}

class _FakeGroupEvent extends Fake implements GroupEvent {}

/// A 100.00 expense split 3:1 between two people.
Expense _unevenExpense() => Expense(
  id: 'expense-1',
  groupId: 'group-1',
  payerId: 'user-a',
  payerName: 'A',
  amount: 100,
  currency: 'USD',
  description: 'Dinner',
  expenseDate: DateTime(2026, 8, 10),
  participants: const [
    ExpenseParticipant(
      userId: 'user-a',
      displayName: 'A',
      shareAmount: 75,
      sharePercentage: 75,
    ),
    ExpenseParticipant(
      userId: 'user-b',
      displayName: 'B',
      shareAmount: 25,
      sharePercentage: 25,
    ),
  ],
  createdAt: DateTime(2026, 8, 10),
  updatedAt: DateTime(2026, 8, 10),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeExpenseEvent());
    registerFallbackValue(_FakeGroupEvent());
  });

  late _MockExpenseBloc expenseBloc;
  late _MockGroupBloc groupBloc;

  setUp(() {
    expenseBloc = _MockExpenseBloc();
    groupBloc = _MockGroupBloc();
    whenListen(
      expenseBloc,
      const Stream<ExpenseState>.empty(),
      initialState: const ExpenseInitial(),
    );
    whenListen(
      groupBloc,
      const Stream<GroupState>.empty(),
      initialState: const GroupInitial(),
    );

    final getIt = GetIt.instance
      ..registerFactory<ExpenseBloc>(() => expenseBloc)
      ..registerFactory<GroupBloc>(() => groupBloc);
    addTearDown(getIt.reset);
  });

  Widget wrap(Widget child) => MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<ExpenseBloc>.value(value: expenseBloc),
        BlocProvider<GroupBloc>.value(value: groupBloc),
      ],
      child: child,
    ),
  );

  /// The participants the page asked the bloc to save.
  List<ExpenseParticipant> savedParticipants() {
    final events = verify(
      () => expenseBloc.add(captureAny()),
    ).captured.whereType<ExpenseUpdateRequested>().toList();
    expect(
      events,
      isNotEmpty,
      reason: 'the page never asked to save, so there is nothing to assert on',
    );
    return events.last.participants!;
  }

  testWidgets('changing only the amount keeps the 3:1 split 3:1', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        EditExpensePage(
          expenseId: 'expense-1',
          groupId: 'group-1',
          expense: _unevenExpense(),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(1), '200');
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Save').first);
    await tester.pump(const Duration(milliseconds: 300));

    final saved = savedParticipants();
    final byId = {for (final p in saved) p.userId: p.shareAmount};

    expect(
      byId['user-a'],
      equals(150.0),
      reason: 'A held 75% of 100.00 and must hold 75% of 200.00',
    );
    expect(byId['user-b'], equals(50.0));

    final totalCents = saved.fold<int>(
      0,
      (sum, p) => sum + (p.shareAmount * 100).round(),
    );
    expect(totalCents, equals(20000));
  });

  testWidgets('the split still conserves an amount that does not divide', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        EditExpensePage(
          expenseId: 'expense-1',
          groupId: 'group-1',
          expense: _unevenExpense(),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(1), '100.01');
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Save').first);
    await tester.pump(const Duration(milliseconds: 300));

    final saved = savedParticipants();
    final totalCents = saved.fold<int>(
      0,
      (sum, p) => sum + (p.shareAmount * 100).round(),
    );
    expect(
      totalCents,
      equals(10001),
      reason: 'the shares must still sum to the amount exactly',
    );
  });

  testWidgets('editing the amount leaves no split validation error', (
    tester,
  ) async {
    // The regression: every exact amount was reset to 0.00, so the form
    // rejected itself with "Exact amounts must sum to total amount
    // (0.00 != 200.00)" and the expense could not be saved at all.
    await tester.pumpWidget(
      wrap(
        EditExpensePage(
          expenseId: 'expense-1',
          groupId: 'group-1',
          expense: _unevenExpense(),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(1), '200');
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Split configuration error'),
      findsNothing,
      reason: 'changing only the amount must not invalidate the split',
    );
  });
}
