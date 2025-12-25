import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_list_item.dart';

void main() {
  group('ExpenseListItem Widget Tests', () {
    late Expense testExpense;
    late bool onTapCalled;

    setUp(() {
      onTapCalled = false;
      testExpense = Expense(
        id: 'expense-1',
        groupId: 'group-1',
        payerId: 'user-1',
        payerName: 'John Doe',
        amount: 150000,
        currency: 'VND',
        description: 'Dinner at restaurant',
        expenseDate: DateTime.now().subtract(const Duration(days: 1)),
        participants: const [
          ExpenseParticipant(
            userId: 'user-1',
            displayName: 'John Doe',
            shareAmount: 75000,
            sharePercentage: 50,
          ),
          ExpenseParticipant(
            userId: 'user-2',
            displayName: 'Jane Smith',
            shareAmount: 75000,
            sharePercentage: 50,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
    });

    testWidgets('should display expense information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: testExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      // Check expense description
      expect(find.text('Dinner at restaurant'), findsOneWidget);

      // Check amount - use textContaining to handle potential spaces between
      // number and symbol
      expect(find.textContaining('150.000'), findsOneWidget);
      expect(find.textContaining('₫'), findsOneWidget);

      // Check payer name
      expect(find.text('Paid by John Doe'), findsOneWidget);

      // Check participant count
      expect(find.text('2 participants'), findsOneWidget);
    });

    testWidgets('should display expense date correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: testExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      // Should show relative date like "Yesterday" (since the test setup uses
      // -1 day)
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('should display different currencies correctly', (
      tester,
    ) async {
      final usdExpense = testExpense.copyWith(
        amount: 50,
        currency: 'USD',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: usdExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'USD',
            ),
          ),
        ),
      );

      expect(find.textContaining('50.00'), findsOneWidget);
      expect(find.textContaining(r'$'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: testExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(onTapCalled, isTrue);
    });

    testWidgets('should display split validity indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: testExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      // Should show valid split icon since totalParticipantShares matches
      // amount
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Valid'), findsOneWidget);
    });

    testWidgets('should display invalid split indicator', (tester) async {
      final invalidExpense = testExpense.copyWith(
        amount: 200000, // Shares only sum to 150000
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: invalidExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      // Should show invalid split icon
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('Invalid split'), findsOneWidget);
    });

    testWidgets('should truncate long descriptions', (tester) async {
      const longDescription =
          'This is a very long expense description that should be truncated '
          'when displayed in the list item';
      final longDescriptionExpense = testExpense.copyWith(
        description: longDescription,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: longDescriptionExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      // The description should be present
      expect(find.text(longDescription), findsOneWidget);

      final text = tester.widget<Text>(find.text(longDescription));
      expect(text.maxLines, equals(2));
      expect(text.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('should display expense with single participant', (
      tester,
    ) async {
      final singleParticipantExpense = testExpense.copyWith(
        participants: [testExpense.participants.first],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: singleParticipantExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      expect(find.text('1 participant'), findsOneWidget);
    });

    testWidgets('should display expense with many participants', (
      tester,
    ) async {
      final manyParticipantsExpense = testExpense.copyWith(
        participants: [
          ...testExpense.participants,
          const ExpenseParticipant(
            userId: 'user-3',
            displayName: 'Bob Wilson',
            shareAmount: 50000,
            sharePercentage: 33.33,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: manyParticipantsExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      expect(find.text('3 participants'), findsOneWidget);
    });

    testWidgets('should have proper card styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: testExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, isNotNull);
    });

    testWidgets('should display expense category if available', (
      tester,
    ) async {
      final categoryExpense = testExpense.copyWith(category: 'Food');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: categoryExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      // Should show category text
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('should handle zero amount expense', (tester) async {
      final zeroAmountExpense = testExpense.copyWith(amount: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: zeroAmountExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      expect(find.textContaining('0'), findsOneWidget);
      expect(find.textContaining('₫'), findsOneWidget);
    });

    testWidgets('should display today date correctly', (tester) async {
      final todayExpense = testExpense.copyWith(
        expenseDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: todayExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('should display yesterday date correctly', (tester) async {
      // Use exactly 24 hours ago
      final yesterdayExpense = testExpense.copyWith(
        expenseDate: DateTime.now().subtract(const Duration(hours: 25)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListItem(
              expense: yesterdayExpense,
              onTap: () => onTapCalled = true,
              groupCurrency: 'VND',
            ),
          ),
        ),
      );

      expect(find.text('Yesterday'), findsOneWidget);
    });
  });
}
