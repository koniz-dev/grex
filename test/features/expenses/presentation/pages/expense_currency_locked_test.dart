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
import 'package:grex/features/expenses/presentation/pages/create_expense_page.dart';
import 'package:grex/features/expenses/presentation/pages/edit_expense_page.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/shared/utils/currency_formatter.dart';
import 'package:grex/shared/widgets/group_currency_field.dart';
import 'package:mocktail/mocktail.dart';

/// An expense recorded in any currency other than the group's is filtered out
/// by `calculate_group_balances`, so it is stored and listed while affecting no
/// balance at all. These tests pin the UI half of the fix: the forms must not
/// offer a currency the balance engine would then discard. See issue #18.
class _MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _FakeExpenseEvent extends Fake implements ExpenseEvent {}

class _FakeGroupEvent extends Fake implements GroupEvent {}

const _groupCurrency = 'USD';
final _groupCurrencyLabel =
    '$_groupCurrency ${CurrencyFormatter.getCurrencySymbol(_groupCurrency)}';

Expense _expenseIn(String currency) => Expense(
  id: 'expense-1',
  groupId: 'group-1',
  payerId: 'user-1',
  payerName: 'User One',
  amount: 100,
  currency: currency,
  description: 'Dinner',
  expenseDate: DateTime(2026, 8, 10),
  participants: const [
    ExpenseParticipant(
      userId: 'user-1',
      displayName: 'User One',
      shareAmount: 100,
      sharePercentage: 100,
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

  /// The pages read GroupBloc from the widget tree as well as from GetIt.
  Widget wrap(Widget child) => MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<ExpenseBloc>.value(value: expenseBloc),
        BlocProvider<GroupBloc>.value(value: groupBloc),
      ],
      child: child,
    ),
  );

  /// Every currency the app knows about apart from the group's.
  Iterable<String> otherCurrencies() =>
      CurrencyFormatter.getSupportedCurrencies().where(
        (currency) => currency != _groupCurrency,
      );

  void expectNoAlternativeCurrencyOffered(WidgetTester tester) {
    expect(
      find.byType(GroupCurrencyField),
      findsOneWidget,
      reason: 'the currency control must be the fixed group-currency field',
    );
    expect(
      find.text(_groupCurrencyLabel),
      findsOneWidget,
      reason: "the group's own currency must still be shown",
    );

    // The old control was a DropdownButtonFormField over all ten supported
    // currencies. Nothing in the tree may offer any of the other nine.
    for (final currency in otherCurrencies()) {
      final symbol = CurrencyFormatter.getCurrencySymbol(currency);
      expect(
        find.text('$currency $symbol'),
        findsNothing,
        reason:
            '$currency is offered by the form but would be silently dropped '
            'from every balance by calculate_group_balances',
      );
    }
  }

  group('CreateExpensePage currency', () {
    testWidgets('offers no currency other than the group currency', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const CreateExpensePage(
            groupId: 'group-1',
            groupCurrency: _groupCurrency,
          ),
        ),
      );
      await tester.pump();

      expectNoAlternativeCurrencyOffered(tester);
    });

    testWidgets('the currency field cannot be interacted with', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CreateExpensePage(
            groupId: 'group-1',
            groupCurrency: _groupCurrency,
          ),
        ),
      );
      await tester.pump();

      // Tapping it must not open a menu of alternatives.
      await tester.tap(find.byType(GroupCurrencyField));
      // Bounded pumps, not pumpAndSettle: the page shows an indeterminate
      // progress indicator that never settles.
      await tester.pump(const Duration(milliseconds: 300));

      expectNoAlternativeCurrencyOffered(tester);
    });
  });

  group('EditExpensePage currency', () {
    testWidgets('offers no currency other than the group currency', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          EditExpensePage(
            expenseId: 'expense-1',
            groupId: 'group-1',
            expense: _expenseIn(_groupCurrency),
          ),
        ),
      );
      await tester.pump();

      expectNoAlternativeCurrencyOffered(tester);
    });

    testWidgets('cannot change the currency away from the group currency', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          EditExpensePage(
            expenseId: 'expense-1',
            groupId: 'group-1',
            expense: _expenseIn(_groupCurrency),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(GroupCurrencyField));
      // Bounded pumps, not pumpAndSettle: the page shows an indeterminate
      // progress indicator that never settles.
      await tester.pump(const Duration(milliseconds: 300));

      expectNoAlternativeCurrencyOffered(tester);
    });
  });
}
