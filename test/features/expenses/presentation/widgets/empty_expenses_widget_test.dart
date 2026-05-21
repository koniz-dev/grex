import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/presentation/widgets/empty_expenses_widget.dart';

import '../../../../helpers/localized_pumper.dart';

void main() {
  group('EmptyExpensesWidget Tests', () {
    testWidgets('shows the default empty-state copy and illustration', (
      tester,
    ) async {
      await pumpLocalized(tester, const EmptyExpensesWidget());

      // Title (VI)
      expect(find.text('Chưa có chi tiêu nào'), findsOneWidget);

      // Default description (VI, no active filters)
      expect(
        find.text(
          'Bắt đầu theo dõi chi tiêu của nhóm bằng cách thêm chi tiêu '
          'đầu tiên.',
        ),
        findsOneWidget,
      );

      // Illustration icon
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets(
      'swaps copy when there are active filters and hides the CTA',
      (tester) async {
        await pumpLocalized(
          tester,
          const EmptyExpensesWidget(hasActiveFilters: true),
        );

        expect(
          find.text(
            'Không có chi tiêu nào khớp với bộ lọc. Thử mở rộng điều kiện.',
          ),
          findsOneWidget,
        );
        expect(find.text('Thêm chi tiêu đầu tiên'), findsNothing);
      },
    );

    testWidgets('renders the add CTA when onAddExpense is provided', (
      tester,
    ) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        EmptyExpensesWidget(onAddExpense: () => tapped = true),
      );

      expect(find.text('Thêm chi tiêu đầu tiên'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      await tester.tap(find.text('Thêm chi tiêu đầu tiên'));
      expect(tapped, isTrue);
    });

    testWidgets('hides the CTA when onAddExpense is null', (tester) async {
      await pumpLocalized(tester, const EmptyExpensesWidget());
      expect(find.text('Thêm chi tiêu đầu tiên'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('stays laid out on a 300×600 surface', (tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpLocalized(tester, const EmptyExpensesWidget());
      expect(find.text('Chưa có chi tiêu nào'), findsOneWidget);
    });

    testWidgets('center-aligns the title text', (tester) async {
      await pumpLocalized(tester, const EmptyExpensesWidget());
      final title = tester.widget<Text>(find.text('Chưa có chi tiêu nào'));
      expect(title.textAlign, equals(TextAlign.center));
    });
  });
}
