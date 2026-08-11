import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/data/repositories/supabase_expense_repository.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';
import 'package:grex/features/payments/data/repositories/supabase_payment_repository.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/postgrest_fakes.dart';

/// The balance side of issue #18.
///
/// `calculate_group_balances` filters every CTE on `e.currency =
/// group_currency`, and filters payments the same way. Anything recorded in
/// another currency is therefore invisible to every balance while still showing
/// up in the expense list and in exports — the group under-counts what it owes
/// with no error and no warning.
///
/// The fix closes the hole from the other end: such a row cannot be created.
/// These tests pin that invariant from the balances' point of view, which is
/// the half that matters — *no path leaves a row recorded but ignored*.
///
/// What these tests cannot do: execute `calculate_group_balances` itself.
/// `flutter test` mocks `SupabaseClient` and never runs a migration, so the SQL
/// filter is asserted here only by construction, from reading the migration.
/// A database-level guard against rows inserted outside the app is criterion 7
/// of #18 and needs a real Supabase project.
class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class _MockFilterBuilder<T> extends Mock implements PostgrestFilterBuilder<T> {}

/// The currency `calculate_group_balances` will match on.
const _groupCurrency = 'USD';

/// A currency the balance engine would silently discard.
const _foreignCurrency = 'EUR';

Expense _expenseIn(String currency) => Expense(
  id: 'expense-1',
  groupId: 'group-1',
  payerId: 'user-1',
  payerName: 'User One',
  amount: 100,
  currency: currency,
  description: 'Dinner in Paris',
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

Payment _paymentIn(String currency) => Payment(
  id: 'payment-1',
  groupId: 'group-1',
  payerId: 'user-1',
  payerName: 'User One',
  recipientId: 'user-2',
  recipientName: 'User Two',
  amount: 50,
  currency: currency,
  paymentDate: DateTime(2026, 8, 10),
  createdAt: DateTime(2026, 8, 10),
);

void main() {
  late _MockSupabaseClient client;

  setUp(() {
    client = _MockSupabaseClient();

    final auth = _MockGoTrueClient();
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);
    when(() => client.auth).thenReturn(auth);

    final membersTable = _MockQueryBuilder();
    final membersFilter = _MockFilterBuilder<List<Map<String, dynamic>>>();
    when(() => client.from('group_members')).thenAnswer((_) => membersTable);
    when(() => membersTable.select(any())).thenAnswer((_) => membersFilter);
    when(
      () => membersFilter.eq(any(), any()),
    ).thenAnswer((_) => membersFilter);
    when(membersFilter.maybeSingle).thenAnswer(
      (_) => FakePostgrestTransformBuilder<PostgrestMap?>(
        const {'id': 'member-1'},
      ),
    );

    final groupsTable = _MockQueryBuilder();
    final groupsFilter = _MockFilterBuilder<List<Map<String, dynamic>>>();
    when(() => client.from('groups')).thenAnswer((_) => groupsTable);
    when(() => groupsTable.select(any())).thenAnswer((_) => groupsFilter);
    when(() => groupsFilter.eq(any(), any())).thenAnswer((_) => groupsFilter);
    when(groupsFilter.maybeSingle).thenAnswer(
      (_) => FakePostgrestTransformBuilder<PostgrestMap?>(
        const {'currency': _groupCurrency},
      ),
    );

    // The insert is stubbed to throw, so a request that gets *past* the
    // currency guard fails with something else. That is what lets the
    // group-currency case prove the guard let it through.
    final expensesTable = _MockQueryBuilder();
    when(() => client.from('expenses')).thenAnswer((_) => expensesTable);
    when(() => expensesTable.insert(any())).thenThrow(
      const PostgrestException(message: 'insert not stubbed in this test'),
    );
  });

  group('an expense the balance engine would ignore', () {
    test(
      'cannot be created, so it can never be recorded-but-ignored',
      () async {
        final repository = SupabaseExpenseRepository(supabaseClient: client);

        final result = await repository.createExpense(
          _expenseIn(_foreignCurrency),
        );

        expect(
          result.isLeft(),
          isTrue,
          reason:
              'a $_foreignCurrency expense in a $_groupCurrency group would be '
              'filtered out of every balance, so it must not be creatable',
        );
        expect(
          result.fold((f) => f, (_) => null),
          isA<ExpenseCurrencyMismatchFailure>(),
        );
        verifyNever(() => client.from('expenses'));
      },
    );

    test(
      'an expense in the group currency is not blocked by the guard',
      () async {
        // The guard must reject only the mismatch. This one gets past it and
        // fails later on the insert, which is unstubbed — proving the currency
        // check is not what stopped it.
        final repository = SupabaseExpenseRepository(supabaseClient: client);

        final result = await repository.createExpense(
          _expenseIn(_groupCurrency),
        );

        expect(
          result.fold((f) => f, (_) => null),
          isNot(isA<ExpenseCurrencyMismatchFailure>()),
          reason: 'the group currency itself must never be rejected',
        );
      },
    );
  });

  group('a payment the balance engine would ignore', () {
    test('cannot be created, so no settlement is silently lost', () async {
      final repository = SupabasePaymentRepository(supabaseClient: client);

      final result = await repository.createPayment(
        _paymentIn(_foreignCurrency),
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((f) => f, (_) => null),
        isA<PaymentCurrencyMismatchFailure>(),
      );
      verifyNever(() => client.from('payments'));
    });
  });
}
