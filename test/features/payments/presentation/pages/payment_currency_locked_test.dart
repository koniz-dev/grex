import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';
import 'package:grex/features/payments/presentation/pages/create_payment_page.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/utils/currency_formatter.dart';
import 'package:grex/shared/widgets/group_currency_field.dart';
import 'package:mocktail/mocktail.dart';

/// `calculate_group_balances` filters payments on the group currency exactly as
/// it filters expenses, so a payment in another currency settles nothing while
/// appearing in the payment list as though it had. The form must not offer the
/// choice. See issue #18.
class _MockPaymentBloc extends MockBloc<PaymentEvent, PaymentState>
    implements PaymentBloc {}

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _FakePaymentEvent extends Fake implements PaymentEvent {}

class _FakeGroupEvent extends Fake implements GroupEvent {}

const _groupCurrency = 'USD';
final _groupCurrencyLabel =
    '$_groupCurrency ${CurrencyFormatter.getCurrencySymbol(_groupCurrency)}';

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePaymentEvent());
    registerFallbackValue(_FakeGroupEvent());
  });

  late _MockPaymentBloc paymentBloc;
  late _MockGroupBloc groupBloc;

  setUp(() {
    paymentBloc = _MockPaymentBloc();
    groupBloc = _MockGroupBloc();
    whenListen(
      paymentBloc,
      const Stream<PaymentState>.empty(),
      initialState: const PaymentInitial(),
    );
    whenListen(
      groupBloc,
      const Stream<GroupState>.empty(),
      initialState: const GroupInitial(),
    );

    final getIt = GetIt.instance
      ..registerFactory<PaymentBloc>(() => paymentBloc)
      ..registerFactory<GroupBloc>(() => groupBloc);
    addTearDown(getIt.reset);
  });

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<PaymentBloc>.value(value: paymentBloc),
        BlocProvider<GroupBloc>.value(value: groupBloc),
      ],
      child: child,
    ),
  );

  void expectNoAlternativeCurrencyOffered() {
    expect(
      find.byType(GroupCurrencyField),
      findsOneWidget,
      reason: 'the currency control must be the fixed group-currency field',
    );
    expect(
      find.text(_groupCurrencyLabel),
      findsOneWidget,
    );

    for (final currency in CurrencyFormatter.getSupportedCurrencies().where(
      (currency) => currency != _groupCurrency,
    )) {
      expect(
        find.text('$currency ${CurrencyFormatter.getCurrencySymbol(currency)}'),
        findsNothing,
        reason:
            '$currency is offered by the form but would settle nothing, '
            'because calculate_group_balances filters it out',
      );
    }
  }

  group('CreatePaymentPage currency', () {
    testWidgets('offers no currency other than the group currency', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const CreatePaymentPage(
            groupId: 'group-1',
            groupCurrency: _groupCurrency,
            groupMembers: [],
          ),
        ),
      );
      await tester.pump();

      expectNoAlternativeCurrencyOffered();
    });

    testWidgets('tapping the currency field opens no list of alternatives', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const CreatePaymentPage(
            groupId: 'group-1',
            groupCurrency: _groupCurrency,
            groupMembers: [],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(GroupCurrencyField));
      // Bounded pumps, not pumpAndSettle: the page shows an indeterminate
      // progress indicator that never settles.
      await tester.pump(const Duration(milliseconds: 300));

      expectNoAlternativeCurrencyOffered();
    });
  });
}
