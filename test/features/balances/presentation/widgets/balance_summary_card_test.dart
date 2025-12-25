import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/presentation/widgets/balance_summary_card.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

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

    Widget createTestWidget({
      List<Balance>? balances,
      String currency = 'USD',
      VoidCallback? onGenerateSettlement,
    }) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: BalanceSummaryCard(
            balances: balances ?? testBalances,
            currency: currency,
            onGenerateSettlement: onGenerateSettlement,
          ),
        ),
      );
    }

    testWidgets('should display summary card title', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Balance Summary'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('should display total owed amount', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Total Owed'), findsOneWidget);
      expect(
        find.text(CurrencyFormatter.format(amount: 50, currencyCode: 'USD')),
        findsOneWidget,
      );
    });

    testWidgets('should display total owes amount', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Total Owes'), findsOneWidget);
      expect(
        find.text(CurrencyFormatter.format(amount: 25, currencyCode: 'USD')),
        findsOneWidget,
      );
    });

    testWidgets('should display settled and unsettled counts', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Settled'), findsOneWidget);
      expect(find.text('Unsettled'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should display statistics icons', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.pending), findsOneWidget);
    });

    testWidgets('should handle empty balances list', (tester) async {
      await tester.pumpWidget(createTestWidget(balances: []));

      expect(find.text('Balance Summary'), findsOneWidget);
      expect(
        find.text(CurrencyFormatter.format(amount: 0, currencyCode: 'USD')),
        findsNWidgets(2),
      );
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('All members are settled up!'), findsOneWidget);
      expect(find.text('Generate Settlement Plan'), findsNothing);
    });

    testWidgets('should handle all zero balances', (tester) async {
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

      await tester.pumpWidget(createTestWidget(balances: zeroBalances));

      expect(
        find.text(CurrencyFormatter.format(amount: 0, currencyCode: 'USD')),
        findsNWidgets(2),
      );
      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('All members are settled up!'), findsOneWidget);
      expect(find.text('Generate Settlement Plan'), findsNothing);
    });

    testWidgets('should handle all positive balances', (tester) async {
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

      await tester.pumpWidget(createTestWidget(balances: positiveBalances));

      expect(
        find.text(CurrencyFormatter.format(amount: 50, currencyCode: 'USD')),
        findsOneWidget,
      );
      expect(
        find.text(CurrencyFormatter.format(amount: 0, currencyCode: 'USD')),
        findsOneWidget,
      );
      expect(find.text('Generate Settlement Plan'), findsOneWidget);
      expect(find.text('All members are settled up!'), findsNothing);
    });

    testWidgets('should handle all negative balances', (tester) async {
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

      await tester.pumpWidget(createTestWidget(balances: negativeBalances));

      expect(
        find.text(CurrencyFormatter.format(amount: 0, currencyCode: 'USD')),
        findsOneWidget,
      );
      expect(
        find.text(CurrencyFormatter.format(amount: 50, currencyCode: 'USD')),
        findsOneWidget,
      );
      expect(find.text('Generate Settlement Plan'), findsOneWidget);
    });

    testWidgets('should display VND currency correctly', (tester) async {
      final vndBalances = testBalances
          .map(
            (balance) => balance.copyWith(
              balance: balance.balance * 25000, // Convert to VND
              currency: 'VND',
            ),
          )
          .toList();

      await tester.pumpWidget(
        createTestWidget(
          balances: vndBalances,
          currency: 'VND',
        ),
      );

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

    testWidgets('should display proper visual hierarchy', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Card), findsOneWidget);
      final titleText = tester.widget<Text>(find.text('Balance Summary'));
      expect(titleText.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('should render settlement button and call callback', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Generate Settlement Plan'), findsOneWidget);
      expect(find.byIcon(Icons.calculate), findsOneWidget);

      await tester.pumpWidget(
        createTestWidget(
          onGenerateSettlement: () {
            tapped = true;
          },
        ),
      );
      await tester.tap(
        find.byWidgetPredicate((widget) => widget is ElevatedButton),
      );
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('should handle large amounts correctly', (tester) async {
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

      await tester.pumpWidget(createTestWidget(balances: largeBalances));

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

    testWidgets('should display proper card styling', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Card), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Padding && widget.padding == const EdgeInsets.all(20),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should handle decimal precision correctly', (tester) async {
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

      await tester.pumpWidget(createTestWidget(balances: preciseBalances));

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

    testWidgets('should show all settled message when all settled', (
      tester,
    ) async {
      final balancedBalances = [
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

      await tester.pumpWidget(createTestWidget(balances: balancedBalances));

      expect(find.text('All members are settled up!'), findsOneWidget);
      expect(find.text('Generate Settlement Plan'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('should work with different themes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BalanceSummaryCard(
              balances: testBalances,
              currency: 'USD',
            ),
          ),
        ),
      );

      expect(find.byType(BalanceSummaryCard), findsOneWidget);
      expect(find.text('Balance Summary'), findsOneWidget);
    });
  });
}
