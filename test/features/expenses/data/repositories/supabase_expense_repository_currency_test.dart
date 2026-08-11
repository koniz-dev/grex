import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/data/repositories/supabase_expense_repository.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/postgrest_fakes.dart';

/// The forms no longer offer a non-group currency, but the form is not the only
/// way a row reaches the table. `calculate_group_balances` filters every CTE on
/// `e.currency = group_currency`, so an expense in another currency is stored,
/// listed and exported while contributing to no balance at all. The repository
/// is the layer that has to refuse it. See issue #18.
class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class _MockFilterBuilder<T> extends Mock implements PostgrestFilterBuilder<T> {}

const _groupCurrency = 'USD';

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
  late _MockSupabaseClient client;
  late SupabaseExpenseRepository repository;
  late _MockQueryBuilder membersTable;
  late _MockQueryBuilder groupsTable;

  setUp(() {
    client = _MockSupabaseClient();
    membersTable = _MockQueryBuilder();
    groupsTable = _MockQueryBuilder();

    // Authenticated user
    final auth = _MockGoTrueClient();
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);
    when(() => client.auth).thenReturn(auth);

    // Membership check passes, so the currency guard is what decides.
    final membersFilter = _MockFilterBuilder<List<Map<String, dynamic>>>();
    when(() => client.from('group_members')).thenAnswer((_) => membersTable);
    when(() => membersTable.select(any())).thenAnswer((_) => membersFilter);
    when(() => membersFilter.eq(any(), any())).thenAnswer((_) => membersFilter);
    when(membersFilter.maybeSingle).thenAnswer(
      (_) => FakePostgrestTransformBuilder<PostgrestMap?>(
        const {'id': 'member-1'},
      ),
    );

    // The group is denominated in USD.
    final groupsFilter = _MockFilterBuilder<List<Map<String, dynamic>>>();
    when(() => client.from('groups')).thenAnswer((_) => groupsTable);
    when(() => groupsTable.select(any())).thenAnswer((_) => groupsFilter);
    when(() => groupsFilter.eq(any(), any())).thenAnswer((_) => groupsFilter);
    when(groupsFilter.maybeSingle).thenAnswer(
      (_) => FakePostgrestTransformBuilder<PostgrestMap?>(
        const {'currency': _groupCurrency},
      ),
    );

    // updateExpense checks permission first; the user is the payer, which
    // short-circuits to allowed, so the currency guard is again what decides.
    final expensesTable = _MockQueryBuilder();
    final expensesFilter = _MockFilterBuilder<List<Map<String, dynamic>>>();
    when(() => client.from('expenses')).thenAnswer((_) => expensesTable);
    when(() => expensesTable.select(any())).thenAnswer((_) => expensesFilter);
    when(
      () => expensesFilter.eq(any(), any()),
    ).thenAnswer((_) => expensesFilter);
    when(expensesFilter.maybeSingle).thenAnswer(
      (_) => FakePostgrestTransformBuilder<PostgrestMap?>(
        const {'payer_id': 'user-1', 'group_id': 'group-1'},
      ),
    );

    repository = SupabaseExpenseRepository(supabaseClient: client);
  });

  group('createExpense currency guard', () {
    test('rejects an expense in a currency the group does not use', () async {
      final result = await repository.createExpense(_expenseIn('EUR'));

      expect(result.isLeft(), isTrue);
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ExpenseCurrencyMismatchFailure>());
      expect(failure!.message, contains('EUR'));
      expect(failure.message, contains(_groupCurrency));
    });

    test('never writes the rejected expense', () async {
      await repository.createExpense(_expenseIn('EUR'));

      // createExpense does not consult the expenses table at all before
      // writing, so no interaction with it means no row was written.
      verifyNever(() => client.from('expenses'));
      verifyNever(() => client.from('expense_participants'));
    });

    test('rejects every non-group currency, not just EUR', () async {
      for (final currency in const ['EUR', 'GBP', 'JPY', 'VND']) {
        final result = await repository.createExpense(_expenseIn(currency));

        expect(
          result.isLeft(),
          isTrue,
          reason: '$currency must not be recordable in a $_groupCurrency group',
        );
      }
    });
  });

  group('updateExpense currency guard', () {
    test('rejects a change to a currency the group does not use', () async {
      final result = await repository.updateExpense(_expenseIn('EUR'));

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((f) => f, (_) => null),
        isA<ExpenseCurrencyMismatchFailure>(),
      );
    });
  });
}
