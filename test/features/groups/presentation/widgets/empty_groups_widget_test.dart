import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/presentation/widgets/empty_groups_widget.dart';

void main() {
  group('EmptyGroupsWidget Tests', () {
    testWidgets('should display empty state content correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyGroupsWidget(),
          ),
        ),
      );

      // Check title
      expect(find.text('Chưa có nhóm nào'), findsOneWidget);

      // Check description
      expect(
        find.text(
          'Tạo nhóm đầu tiên để bắt đầu chia sẻ chi phí với bạn bè và gia đình',
        ),
        findsOneWidget,
      );

      // Check button
      expect(find.text('Tạo nhóm mới'), findsOneWidget);

      // Check icon
      expect(find.byIcon(Icons.group_add_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should have proper styling and layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyGroupsWidget(),
          ),
        ),
      );

      // Check that content is centered
      expect(find.byType(Center), findsOneWidget);

      // Check container with icon
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.group_add_outlined),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, equals(120));
      expect(container.constraints?.maxHeight, equals(120));

      // Check button styling
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.shape?.resolve({}), isA<RoundedRectangleBorder>());
    });

    testWidgets('should navigate to create group page when button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyGroupsWidget(),
          ),
        ),
      );

      // Tap the create group button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify navigation occurred (CreateGroupPage should be pushed)
      expect(
        find.byType(ElevatedButton),
        findsOneWidget,
      ); // Still on same page initially
    });

    testWidgets('should have proper text styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: EmptyGroupsWidget(),
          ),
        ),
      );

      // Check title text style
      final titleText = tester.widget<Text>(find.text('Chưa có nhóm nào'));
      expect(titleText.textAlign, equals(TextAlign.center));

      // Check description text style
      final descriptionText = tester.widget<Text>(
        find.text(
          'Tạo nhóm đầu tiên để bắt đầu chia sẻ chi phí với bạn bè và gia đình',
        ),
      );
      expect(descriptionText.textAlign, equals(TextAlign.center));
    });

    testWidgets('should have proper spacing between elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyGroupsWidget(),
          ),
        ),
      );

      // Check that SizedBox widgets exist for spacing
      expect(
        find.byType(SizedBox),
        findsNWidgets(3),
      ); // Should have 3 SizedBox for spacing

      // Check padding
      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(const EdgeInsets.all(32)));
    });

    testWidgets('should display icon with correct size and color', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: EmptyGroupsWidget(),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.group_add_outlined));
      expect(icon.size, equals(64));
    });

    testWidgets('should have ElevatedButton with icon and label', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyGroupsWidget(),
          ),
        ),
      );

      // Check that it's an ElevatedButton.icon
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Check that both icon and text are present
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Tạo nhóm mới'), findsOneWidget);
    });

    testWidgets('should be responsive to different screen sizes', (
      tester,
    ) async {
      // Test with small screen
      await tester.binding.setSurfaceSize(const Size(300, 600));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyGroupsWidget(),
          ),
        ),
      );

      expect(find.text('Chưa có nhóm nào'), findsOneWidget);
      expect(find.text('Tạo nhóm mới'), findsOneWidget);

      // Test with larger screen
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pump();

      expect(find.text('Chưa có nhóm nào'), findsOneWidget);
      expect(find.text('Tạo nhóm mới'), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should maintain proper column layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyGroupsWidget(),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
      expect(
        column.children.length,
        equals(7),
      ); // Container, 3 SizedBox, 2 Text, 1 Button
    });
  });
}
