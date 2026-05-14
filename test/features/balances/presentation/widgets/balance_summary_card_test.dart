import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/presentation/widgets/balance_summary_card.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

import '../../../../helpers/localized_pumper.dart';

void main() {
  group('BalanceSummaryCard Widget Tests', () {
    late List<Balance> testBalances;

    setUp(() {
      testBalances = [
        const Balance(
          userId: 'user-1',
          displayName: 'John Doe',
          balance: 50,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'Jane Smith',
          balance: -25,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-3',
          displayName: 'Bob Johnson',
          balance: 0,
          currency: 'USD',
        ),
      ];
    });

    Future<void> pump(
      WidgetTester tester, {
      List<Balance>? balances,
      String currency = 'USD',
      VoidCallback? onGenerateSettlement,
    }) {
      return pumpLocalized(
        tester,
        BalanceSummaryCard(
          balances: balances ?? testBalances,
          currency: currency,
          onGenerateSettlement: onGenerateSettlement,
        ),
      );
    }

    testWidgets('renders the summary card title (VI)', (tester) async {
      await pump(tester);

      expect(find.text('Tổng quan số dư'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    });

    testWidgets('renders the total-owed amount with its label', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Tổng được nợ'), findsOneWidget);
      expect(
        find.text(CurrencyFormatter.format(amount: 50, currencyCode: 'USD')),
        findsOneWidget,
      );
    });

    testWidgets('renders the total-owes amount with its label', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Tổng đang nợ'), findsOneWidget);
      expect(
        find.text(CurrencyFormatter.format(amount: 25, currencyCode: 'USD')),
        findsOneWidget,
      );
    });

    testWidgets('renders settled and unsettled counts', (tester) async {
      await pump(tester);

      expect(find.text('Cân bằng'), findsOneWidget);
      expect(find.text('Chưa cân bằng'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('renders the four stat icons (rounded variants)', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pending_outlined), findsOneWidget);
    });

    testWidgets('handles an empty balance list as fully settled', (
      tester,
    ) async {
      await pump(tester, balances: []);

      expect(find.text('Tổng quan số dư'), findsOneWidget);
      expect(
        find.text(CurrencyFormatter.format(amount: 0, currencyCode: 'USD')),
        findsNWidgets(2),
      );
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('Mọi thành viên đã cân bằng!'), findsOneWidget);
      expect(find.text('Tạo kế hoạch thanh toán'), findsNothing);
    });

    testWidgets('handles all-zero balances as fully settled', (tester) async {
      final zeroBalances = [
        const Balance(
          userId: 'user-1',
          displayName: 'John Doe',
          balance: 0,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'Jane Smith',
          balance: 0,
          currency: 'USD',
        ),
      ];

      await pump(tester, balances: zeroBalances);

      expect(
        find.text(CurrencyFormatter.format(amount: 0, currencyCode: 'USD')),
        findsNWidgets(2),
      );
      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Mọi thành viên đã cân bằng!'), findsOneWidget);
      expect(find.text('Tạo kế hoạch thanh toán'), findsNothing);
    });

    testWidgets('renders the settle CTA when balances are unsettled', (
      tester,
    ) async {
      final positiveBalances = [
        const Balance(
          userId: 'user-1',
          displayName: 'John Doe',
          balance: 30,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'Jane Smith',
          balance: 20,
          currency: 'USD',
        ),
      ];

      await pump(tester, balances: positiveBalances);

      expect(
        find.text(CurrencyFormatter.format(amount: 50, currencyCode: 'USD')),
        findsOneWidget,
      );
      expect(
        find.text(CurrencyFormatter.format(amount: 0, currencyCode: 'USD')),
        findsOneWidget,
      );
      expect(find.text('Tạo kế hoạch thanh toán'), findsOneWidget);
      expect(find.text('Mọi thành viên đã cân bằng!'), findsNothing);
    });

    testWidgets('still renders the CTA for all-negative balances', (
      tester,
    ) async {
      final negativeBalances = [
        const Balance(
          userId: 'user-1',
          displayName: 'John Doe',
          balance: -30,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'Jane Smith',
          balance: -20,
          currency: 'USD',
        ),
      ];

      await pump(tester, balances: negativeBalances);

      expect(
        find.text(CurrencyFormatter.format(amount: 0, currencyCode: 'USD')),
        findsOneWidget,
      );
      expect(
        find.text(CurrencyFormatter.format(amount: 50, currencyCode: 'USD')),
        findsOneWidget,
      );
      expect(find.text('Tạo kế hoạch thanh toán'), findsOneWidget);
    });

    testWidgets('renders VND amounts correctly', (tester) async {
      final vndBalances = testBalances
          .map(
            (balance) => balance.copyWith(
              balance: balance.balance * 25000,
              currency: 'VND',
            ),
          )
          .toList();

      await pump(tester, balances: vndBalances, currency: 'VND');

      expect(
        find.text(
          CurrencyFormatter.format(amount: 1250000, currencyCode: 'VND'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          CurrencyFormatter.format(amount: 625000, currencyCode: 'VND'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the title in a semibold weight', (tester) async {
      await pump(tester);
      expect(find.byType(Card), findsOneWidget);
      final titleText = tester.widget<Text>(find.text('Tổng quan số dư'));
      expect(titleText.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('invokes the onGenerateSettlement callback when tapped', (
      tester,
    ) async {
      var tapped = false;
      await pump(tester, onGenerateSettlement: () => tapped = true);

      expect(find.text('Tạo kế hoạch thanh toán'), findsOneWidget);
      expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate((widget) => widget is ElevatedButton),
      );
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders large amounts without overflow', (tester) async {
      final largeBalances = [
        const Balance(
          userId: 'user-1',
          displayName: 'John Doe',
          balance: 1234567.89,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'Jane Smith',
          balance: -987654.32,
          currency: 'USD',
        ),
      ];

      await pump(tester, balances: largeBalances);

      expect(
        find.text(
          CurrencyFormatter.format(amount: 1234567.89, currencyCode: 'USD'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          CurrencyFormatter.format(amount: 987654.32, currencyCode: 'USD'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders decimal precision correctly', (tester) async {
      final preciseBalances = [
        const Balance(
          userId: 'user-1',
          displayName: 'John Doe',
          balance: 123.456,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'Jane Smith',
          balance: -67.891,
          currency: 'USD',
        ),
      ];

      await pump(tester, balances: preciseBalances);

      expect(
        find.text(
          CurrencyFormatter.format(amount: 123.456, currencyCode: 'USD'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          CurrencyFormatter.format(amount: 67.891, currencyCode: 'USD'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the all-settled banner when nobody owes', (
      tester,
    ) async {
      final balanced = [
        const Balance(
          userId: 'user-1',
          displayName: 'John Doe',
          balance: 0,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'Jane Smith',
          balance: 0,
          currency: 'USD',
        ),
      ];

      await pump(tester, balances: balanced);

      expect(find.text('Mọi thành viên đã cân bằng!'), findsOneWidget);
      expect(find.text('Tạo kế hoạch thanh toán'), findsNothing);
      // Banner icon (filled) + stat icon (outlined)
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('renders in a dark theme', (tester) async {
      await pumpLocalized(
        tester,
        BalanceSummaryCard(balances: testBalances, currency: 'USD'),
        theme: ThemeData.dark(),
      );

      expect(find.byType(BalanceSummaryCard), findsOneWidget);
      expect(find.text('Tổng quan số dư'), findsOneWidget);
    });
  });
}
