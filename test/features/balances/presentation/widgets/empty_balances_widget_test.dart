import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grex/features/balances/presentation/widgets/empty_balances_widget.dart';

void main() {
  group('EmptyBalancesWidget Widget Tests', () {
    Widget createTestWidget() {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: EmptyBalancesWidget(),
        ),
      );
    }

    testWidgets('should display empty state message', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('No Balances Yet'), findsOneWidget);
    });

    testWidgets('should display descriptive subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(
        find.text(
          'Balances will appear here once expenses\n'
          'and payments are added to the group.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display empty state icon', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(
        find.byIcon(Icons.account_balance_wallet_outlined),
        findsOneWidget,
      );
    });

    testWidgets('should display action buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(
        find.byWidgetPredicate((widget) => widget is ElevatedButton),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((widget) => widget is OutlinedButton),
        findsOneWidget,
      );

      expect(find.text('Add Expenses'), findsOneWidget);
      expect(find.text('Record Payments'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.payment), findsOneWidget);
    });

    testWidgets('should display proper visual hierarchy', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Column), findsNWidgets(2));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Center && widget.child is Padding,
        ),
        findsOneWidget,
      );

      final titleText = tester.widget<Text>(find.text('No Balances Yet'));
      expect(titleText.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('should have proper spacing between elements', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should display icon with proper size and color', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.account_balance_wallet_outlined),
      );
      expect(icon.size, equals(64));
      expect(icon.color, isNotNull);
    });

    testWidgets('should maintain consistent layout', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(
        find.byIcon(Icons.account_balance_wallet_outlined),
        findsOneWidget,
      );
      expect(find.text('No Balances Yet'), findsOneWidget);
      expect(find.text('Add Expenses'), findsOneWidget);
      expect(find.text('Record Payments'), findsOneWidget);
    });

    testWidgets('should handle different screen sizes', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(tester.takeException(), isNull);
    });

    testWidgets('should have proper padding and margins', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('should work with different themes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: EmptyBalancesWidget(),
          ),
        ),
      );

      expect(find.byType(EmptyBalancesWidget), findsOneWidget);
      expect(find.text('No Balances Yet'), findsOneWidget);
    });

    testWidgets('should display help text', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(
        find.text(
          'Balances are calculated automatically based on '
          'expenses and payments in your group.',
        ),
        findsOneWidget,
      );
    });
  });
}
