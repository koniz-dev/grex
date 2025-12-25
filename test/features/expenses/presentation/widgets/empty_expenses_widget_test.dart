import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/presentation/widgets/empty_expenses_widget.dart';

void main() {
  group('EmptyExpensesWidget Tests', () {
    const testMessage =
        'No expenses match your search criteria. Try adjusting your filters.';

    testWidgets('should display empty state content correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyExpensesWidget(message: testMessage),
          ),
        ),
      );

      // Check title
      expect(find.text('No Expenses'), findsOneWidget);

      // Check message
      expect(find.text(testMessage), findsOneWidget);

      // Check icon
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('should call onAddExpense when button is tapped', (
      tester,
    ) async {
      var onAddExpenseCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyExpensesWidget(
              message: testMessage,
              onAddExpense: () => onAddExpenseCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check button text
      expect(find.text('Add First Expense'), findsOneWidget);

      // Tap the add expense button
      await tester.tap(find.text('Add First Expense'));

      expect(onAddExpenseCalled, isTrue);
    });

    testWidgets('should have proper text styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyExpensesWidget(message: testMessage),
          ),
        ),
      );

      // Check message text style
      final messageText = tester.widget<Text>(find.text(testMessage));
      expect(messageText.textAlign, equals(TextAlign.center));
    });

    testWidgets('should have proper spacing between elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyExpensesWidget(message: testMessage),
          ),
        ),
      );

      // Check padding
      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(const EdgeInsets.all(32)));
    });

    testWidgets('should display icon with correct size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyExpensesWidget(message: testMessage),
          ),
        ),
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.receipt_long_outlined),
      );
      expect(icon.size, equals(80));
    });

    testWidgets('should be responsive to different screen sizes', (
      tester,
    ) async {
      // Test with small screen
      await tester.binding.setSurfaceSize(const Size(300, 600));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyExpensesWidget(message: testMessage),
          ),
        ),
      );

      expect(find.text('No Expenses'), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should not show button when onAddExpense is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyExpensesWidget(message: testMessage),
          ),
        ),
      );

      expect(find.text('Add First Expense'), findsNothing);
    });

    testWidgets('should show button when onAddExpense is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyExpensesWidget(
              message: testMessage,
              onAddExpense: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add First Expense'), findsOneWidget);
    });
  });
}
