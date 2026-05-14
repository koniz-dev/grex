import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/balances/presentation/widgets/empty_balances_widget.dart';

import '../../../../helpers/localized_pumper.dart';

void main() {
  group('EmptyBalancesWidget Widget Tests', () {
    testWidgets('renders the empty-state title (VI)', (tester) async {
      await pumpLocalized(tester, const EmptyBalancesWidget());

      expect(find.text('Chưa có số dư nào'), findsOneWidget);
    });

    testWidgets('renders the empty-state description (VI)', (tester) async {
      await pumpLocalized(tester, const EmptyBalancesWidget());

      expect(
        find.text(
          'Số dư sẽ xuất hiện khi chi tiêu và thanh toán được thêm vào nhóm.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the wallet illustration icon', (tester) async {
      await pumpLocalized(tester, const EmptyBalancesWidget());

      expect(
        find.byIcon(Icons.account_balance_wallet_outlined),
        findsOneWidget,
      );
    });

    testWidgets('renders both CTAs with their localised labels (VI)', (
      tester,
    ) async {
      await pumpLocalized(tester, const EmptyBalancesWidget());

      expect(
        find.byWidgetPredicate((widget) => widget is ElevatedButton),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((widget) => widget is OutlinedButton),
        findsOneWidget,
      );

      expect(find.text('Thêm chi tiêu'), findsOneWidget);
      expect(find.text('Ghi nhận thanh toán'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
      expect(find.byIcon(Icons.payment_rounded), findsOneWidget);
    });

    testWidgets('renders the title with a semibold weight', (tester) async {
      await pumpLocalized(tester, const EmptyBalancesWidget());

      final titleText = tester.widget<Text>(find.text('Chưa có số dư nào'));
      expect(titleText.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('renders the auto-explainer help row', (tester) async {
      await pumpLocalized(tester, const EmptyBalancesWidget());

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(
        find.text(
          'Số dư được tính tự động dựa trên chi tiêu và thanh toán của nhóm.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('throws nothing across screen sizes', (tester) async {
      await pumpLocalized(tester, const EmptyBalancesWidget());
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in a dark theme', (tester) async {
      await pumpLocalized(
        tester,
        const EmptyBalancesWidget(),
        theme: ThemeData.dark(),
      );

      expect(find.byType(EmptyBalancesWidget), findsOneWidget);
      expect(find.text('Chưa có số dư nào'), findsOneWidget);
    });
  });
}
