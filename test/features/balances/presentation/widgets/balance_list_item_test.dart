import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/presentation/widgets/balance_list_item.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

import '../../../../helpers/localized_pumper.dart';

void main() {
  group('BalanceListItem Widget Tests', () {
    late Balance testBalance;

    setUp(() {
      testBalance = const Balance(
        userId: 'user-1',
        displayName: 'John Doe',
        balance: 50,
        currency: 'USD',
      );
    });

    Future<void> pump(
      WidgetTester tester, {
      Balance? balance,
      VoidCallback? onTap,
    }) {
      return pumpLocalized(
        tester,
        BalanceListItem(balance: balance ?? testBalance, onTap: onTap),
      );
    }

    testWidgets('renders the member name and amount', (tester) async {
      await pump(tester);

      expect(find.text('John Doe'), findsOneWidget);
      expect(
        find.text(CurrencyFormatter.format(amount: 50, currencyCode: 'USD')),
        findsOneWidget,
      );
    });

    testWidgets('renders positive balances with the green accent', (
      tester,
    ) async {
      await pump(tester);

      final formattedAmount = CurrencyFormatter.format(
        amount: 50,
        currencyCode: 'USD',
      );
      final balanceText = tester.widget<Text>(find.text(formattedAmount));
      expect(balanceText.style?.color, equals(Colors.green));
    });

    testWidgets('renders negative balances with the error accent', (
      tester,
    ) async {
      final negative = testBalance.copyWith(balance: -25);
      await pump(tester, balance: negative);

      final formattedAmount = CurrencyFormatter.format(
        amount: 25,
        currencyCode: 'USD',
      );
      final balanceText = tester.widget<Text>(find.text(formattedAmount));
      expect(
        balanceText.style?.color,
        equals(ThemeData(useMaterial3: true).colorScheme.error),
      );
    });

    testWidgets('renders zero balances with the neutral accent', (
      tester,
    ) async {
      final zero = testBalance.copyWith(balance: 0);
      await pump(tester, balance: zero);

      final formattedAmount = CurrencyFormatter.format(
        amount: 0,
        currencyCode: 'USD',
      );
      final balanceText = tester.widget<Text>(find.text(formattedAmount));
      expect(
        balanceText.style?.color,
        equals(ThemeData(useMaterial3: true).colorScheme.onSurfaceVariant),
      );
    });

    testWidgets('renders a different currency correctly', (tester) async {
      final vnd = testBalance.copyWith(balance: 250000, currency: 'VND');
      await pump(tester, balance: vnd);

      expect(
        find.text(
          CurrencyFormatter.format(amount: 250000, currencyCode: 'VND'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the avatar with the user initial', (tester) async {
      await pump(tester);

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('falls back to ? when the display name is empty', (
      tester,
    ) async {
      final empty = testBalance.copyWith(displayName: '');
      await pump(tester, balance: empty);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('renders the "is owed money" subtitle (VI)', (tester) async {
      await pump(tester);
      expect(find.text('Được nhóm nợ'), findsOneWidget);
    });

    testWidgets('renders the "owes money" subtitle (VI)', (tester) async {
      final negative = testBalance.copyWith(balance: -25);
      await pump(tester, balance: negative);
      expect(find.text('Đang nợ nhóm'), findsOneWidget);
    });

    testWidgets('renders the "settled" subtitle (VI)', (tester) async {
      final zero = testBalance.copyWith(balance: 0);
      await pump(tester, balance: zero);
      expect(find.text('Đã cân bằng'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await pump(tester, onTap: () => tapped = true);
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('does not crash when onTap is null', (tester) async {
      await pump(tester);
      expect(find.byType(BalanceListItem), findsOneWidget);
    });

    testWidgets('renders the rounded chevron', (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('renders the OWED badge (VI)', (tester) async {
      await pump(tester);
      expect(find.text('ĐƯỢC NỢ'), findsOneWidget);
    });

    testWidgets('renders the OWES badge for negative balances (VI)', (
      tester,
    ) async {
      final negative = testBalance.copyWith(balance: -25);
      await pump(tester, balance: negative);
      expect(find.text('NỢ'), findsOneWidget);
    });

    testWidgets('renders the SETTLED badge for zero balances (VI)', (
      tester,
    ) async {
      final zero = testBalance.copyWith(balance: 0);
      await pump(tester, balance: zero);
      expect(find.text('CÂN BẰNG'), findsOneWidget);
    });

    testWidgets('renders a card with zero margin', (tester) async {
      await pump(tester);
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, equals(EdgeInsets.zero));
    });

    testWidgets('handles large amounts and decimals without crashing', (
      tester,
    ) async {
      final large = testBalance.copyWith(balance: 1234567.89);
      await pump(tester, balance: large);

      expect(
        find.text(
          CurrencyFormatter.format(amount: 1234567.89, currencyCode: 'USD'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders in a dark theme', (tester) async {
      await pumpLocalized(
        tester,
        BalanceListItem(balance: testBalance, onTap: () {}),
        theme: ThemeData.dark(),
      );
      expect(find.text('John Doe'), findsOneWidget);
    });
  });
}
