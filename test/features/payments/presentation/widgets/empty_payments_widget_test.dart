import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/payments/presentation/widgets/empty_payments_widget.dart';
import 'package:grex/shared/theme/app_icon_sizes.dart';

import '../../../../helpers/localized_pumper.dart';

void main() {
  group('EmptyPaymentsWidget Tests', () {
    testWidgets('shows the default empty-state copy and illustration', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const EmptyPaymentsWidget(),
      );

      // Title (VI)
      expect(find.text('Không có thanh toán'), findsOneWidget);

      // Default description (VI, no active filters)
      expect(
        find.text(
          'Chưa có thanh toán nào. Thêm thanh toán đầu tiên để bắt đầu!',
        ),
        findsOneWidget,
      );

      // Illustration icon
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    });

    testWidgets(
      'swaps copy when there are active filters',
      (tester) async {
        await pumpLocalized(
          tester,
          const EmptyPaymentsWidget(hasActiveFilters: true),
        );

        expect(
          find.text(
            'Không có thanh toán nào phù hợp với tiêu chí tìm kiếm. '
            'Hãy thử điều chỉnh bộ lọc.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('hides the CTA when onAddPayment is null', (tester) async {
      await pumpLocalized(
        tester,
        const EmptyPaymentsWidget(),
      );

      expect(find.text('Thêm thanh toán đầu tiên'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders the add CTA when onAddPayment is provided', (
      tester,
    ) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        EmptyPaymentsWidget(
          onAddPayment: () => tapped = true,
        ),
      );

      expect(find.text('Thêm thanh toán đầu tiên'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      await tester.tap(find.text('Thêm thanh toán đầu tiên'));
      expect(tapped, isTrue);
    });

    testWidgets('renders the illustration at the standard size', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const EmptyPaymentsWidget(),
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.payments_outlined),
      );
      expect(icon.size, equals(AppIconSizes.illustration));
    });

    testWidgets('center-aligns the title text', (tester) async {
      await pumpLocalized(
        tester,
        const EmptyPaymentsWidget(),
      );
      final title = tester.widget<Text>(find.text('Không có thanh toán'));
      expect(title.textAlign, equals(TextAlign.center));
    });

    testWidgets('works under a dark theme', (tester) async {
      await pumpLocalized(
        tester,
        EmptyPaymentsWidget(
          onAddPayment: () {},
        ),
        theme: ThemeData.dark(),
      );

      expect(find.byType(EmptyPaymentsWidget), findsOneWidget);
    });
  });
}
