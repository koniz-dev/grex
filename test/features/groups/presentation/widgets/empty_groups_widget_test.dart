import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/presentation/widgets/empty_groups_widget.dart';

import '../../../../helpers/localized_pumper.dart';

void main() {
  group('EmptyGroupsWidget Tests', () {
    testWidgets('should display empty state content correctly', (tester) async {
      await pumpLocalized(tester, const EmptyGroupsWidget());

      // Title (VI)
      expect(find.text('Chưa có nhóm nào'), findsOneWidget);

      // Description (VI)
      expect(
        find.text(
          'Tạo nhóm đầu tiên để bắt đầu chia sẻ chi phí với bạn bè và '
          'gia đình.',
        ),
        findsOneWidget,
      );

      // CTA label
      expect(find.text('Tạo nhóm mới'), findsOneWidget);

      // Icons
      expect(find.byIcon(Icons.group_add_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('should render an illustration container with fixed size', (
      tester,
    ) async {
      await pumpLocalized(tester, const EmptyGroupsWidget());

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.group_add_outlined),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, equals(120));
      expect(container.constraints?.maxHeight, equals(120));
    });

    testWidgets('should center-align all text', (tester) async {
      await pumpLocalized(tester, const EmptyGroupsWidget());

      final titleText = tester.widget<Text>(find.text('Chưa có nhóm nào'));
      expect(titleText.textAlign, equals(TextAlign.center));
    });

    testWidgets('should remain laid out on small screens', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpLocalized(tester, const EmptyGroupsWidget());

      expect(find.text('Chưa có nhóm nào'), findsOneWidget);
      expect(find.text('Tạo nhóm mới'), findsOneWidget);
    });

    testWidgets('should render an ElevatedButton.icon CTA', (tester) async {
      await pumpLocalized(tester, const EmptyGroupsWidget());

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.text('Tạo nhóm mới'), findsOneWidget);
    });
  });
}
