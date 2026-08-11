import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/payments/data/repositories/supabase_payment_repository.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/postgrest_fakes.dart';

/// `calculate_group_balances` filters payments on the group currency exactly as
/// it filters expenses, so a payment in another currency settles nothing while
/// appearing in the payment list as though it had. See issue #18.
class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class _MockFilterBuilder<T> extends Mock implements PostgrestFilterBuilder<T> {}

const _groupCurrency = 'USD';

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
  late SupabasePaymentRepository repository;

  setUp(() {
    client = _MockSupabaseClient();

    final auth = _MockGoTrueClient();
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);
    when(() => client.auth).thenReturn(auth);

    // Membership check passes, so the currency guard is what decides.
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

    // The group is denominated in USD.
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

    repository = SupabasePaymentRepository(supabaseClient: client);
  });

  group('createPayment currency guard', () {
    test('rejects a payment in a currency the group does not use', () async {
      final result = await repository.createPayment(_paymentIn('EUR'));

      expect(result.isLeft(), isTrue);
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<PaymentCurrencyMismatchFailure>());
      expect(failure!.message, contains('EUR'));
      expect(failure.message, contains(_groupCurrency));
    });

    test('never writes the rejected payment', () async {
      await repository.createPayment(_paymentIn('EUR'));

      verifyNever(() => client.from('payments'));
    });

    test('rejects every non-group currency, not just EUR', () async {
      for (final currency in const ['EUR', 'GBP', 'JPY', 'VND']) {
        final result = await repository.createPayment(_paymentIn(currency));

        expect(
          result.isLeft(),
          isTrue,
          reason: '$currency must not be recordable in a $_groupCurrency group',
        );
      }
    });
  });
}
