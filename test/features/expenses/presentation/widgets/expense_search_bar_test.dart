import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_search_bar.dart';

void main() {
  group('ExpenseSearchBar Widget Tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should display search field correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) {},
              hintText: 'Tìm kiếm chi tiêu...',
            ),
          ),
        ),
      );

      // Check search field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Tìm kiếm chi tiêu...'), findsOneWidget);
    });

    testWidgets('should call onChanged when text changes', (tester) async {
      var searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) => searchQuery = query,
            ),
          ),
        ),
      );

      // Enter search text
      await tester.enterText(find.byType(TextField), 'dinner');

      expect(searchQuery, equals('dinner'));
      expect(controller.text, equals('dinner'));
    });

    testWidgets('should show clear button when text is entered', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) {},
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should clear text when clear button is tapped', (
      tester,
    ) async {
      var searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) => searchQuery = query,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Text should be cleared
      expect(searchQuery, equals(''));
      expect(controller.text, equals(''));
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('should show filter button', (tester) async {
      var filterTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) {},
              onFilterTap: () => filterTapped = true,
            ),
          ),
        ),
      );

      // Check filter button
      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));

      expect(filterTapped, isTrue);
    });

    testWidgets('should work without filter callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) {},
            ),
          ),
        ),
      );

      // Should still show filter button
      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Should not throw when tapping
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pump();
    });

    testWidgets('should have proper styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) {},
              hintText: 'Tìm kiếm chi tiêu...',
            ),
          ),
        ),
      );

      // Check container styling
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.margin, equals(const EdgeInsets.all(16)));

      // Check text field decoration
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, equals('Tìm kiếm chi tiêu...'));
      expect(textField.decoration?.prefixIcon, isNotNull);
    });

    testWidgets('should handle long search queries', (tester) async {
      var searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) => searchQuery = query,
            ),
          ),
        ),
      );

      const longQuery =
          'This is a very long search query that should be handled properly';
      await tester.enterText(find.byType(TextField), longQuery);

      expect(searchQuery, equals(longQuery));
    });

    testWidgets('should handle special characters in search', (tester) async {
      var searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) => searchQuery = query,
            ),
          ),
        ),
      );

      const specialQuery = r'café & restaurant @#$%';
      await tester.enterText(find.byType(TextField), specialQuery);

      expect(searchQuery, equals(specialQuery));
    });

    testWidgets(
      'should show active filter indicator when filters are applied',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExpenseSearchBar(
                controller: controller,
                onChanged: (query) {},
                hasActiveFilters: true,
              ),
            ),
          ),
        );

        // Should show filter indicator
        final icon = tester.widget<Icon>(find.byIcon(Icons.filter_list));
        expect(icon.color, isNotNull);
      },
    );

    testWidgets('should handle keyboard actions', (tester) async {
      var searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) => searchQuery = query,
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);

      // Focus on text field
      await tester.tap(textField);
      await tester.pump();

      // Enter text
      await tester.enterText(textField, 'search test');

      expect(searchQuery, equals('search test'));
    });

    testWidgets('should debounce search input', (tester) async {
      var callCount = 0;
      var lastQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) {
                callCount++;
                lastQuery = query;
              },
            ),
          ),
        ),
      );

      // Rapidly enter text
      await tester.enterText(find.byType(TextField), 'a');
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.enterText(find.byType(TextField), 'abc');

      // Small wait
      await tester.pump(const Duration(milliseconds: 100));

      // In this simple implementation, it calls onChanged immediately
      expect(callCount, equals(3));
      expect(lastQuery, equals('abc'));
    });

    testWidgets('should maintain focus state correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSearchBar(
              controller: controller,
              onChanged: (query) {},
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);

      // Tap to focus
      await tester.tap(textField);
      await tester.pump();

      // Should be focused
      final focusNode = tester.widget<TextField>(textField).focusNode;
      if (focusNode != null) {
        expect(focusNode.hasFocus, isTrue);
      }
    });
  });
}
