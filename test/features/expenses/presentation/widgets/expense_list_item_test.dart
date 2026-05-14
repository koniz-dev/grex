import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_list_item.dart';

import '../../../../helpers/localized_pumper.dart';

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

    testWidgets('renders description, amount, payer and participants', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: testExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );

      expect(find.text('Dinner at restaurant'), findsOneWidget);
      expect(find.textContaining('150.000'), findsOneWidget);
      expect(find.textContaining('₫'), findsOneWidget);

      // Localized "Paid by John Doe" (VI)
      expect(find.text('Trả bởi John Doe'), findsOneWidget);

      // Localized pluralized participant count (VI)
      expect(find.text('2 người tham gia'), findsOneWidget);
    });

    testWidgets('renders "Yesterday" relative date (VI)', (tester) async {
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: testExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );

      expect(find.text('Hôm qua'), findsOneWidget);
    });

    testWidgets('renders "Today" relative date (VI)', (tester) async {
      final todayExpense = testExpense.copyWith(expenseDate: DateTime.now());
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: todayExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );
      expect(find.text('Hôm nay'), findsOneWidget);
    });

    testWidgets('renders USD currency symbol when groupCurrency differs', (
      tester,
    ) async {
      final usdExpense = testExpense.copyWith(amount: 50, currency: 'USD');
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: usdExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );

      expect(find.textContaining('50.00'), findsOneWidget);
      expect(find.textContaining(r'$'), findsOneWidget);
      // Group currency hint (VI)
      expect(find.text('Nhóm: VND'), findsOneWidget);
    });

    testWidgets('calls onTap when the card is tapped', (tester) async {
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: testExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(onTapCalled, isTrue);
    });

    testWidgets('shows the valid-split badge (VI)', (tester) async {
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: testExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );

      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.text('Hợp lệ'), findsOneWidget);
    });

    testWidgets('shows the invalid-split badge (VI)', (tester) async {
      final invalidExpense = testExpense.copyWith(amount: 200000);
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: invalidExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Chia không hợp lệ'), findsOneWidget);
    });

    testWidgets('truncates long descriptions to two lines', (tester) async {
      const longDescription =
          'This is a very long expense description that should be truncated '
          'when displayed in the list item';
      final longExpense = testExpense.copyWith(description: longDescription);

      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: longExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );

      final text = tester.widget<Text>(find.text(longDescription));
      expect(text.maxLines, equals(2));
      expect(text.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('renders the singular participant label (VI)', (tester) async {
      final singleParticipant = testExpense.copyWith(
        participants: [testExpense.participants.first],
      );
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: singleParticipant,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );
      expect(find.text('1 người tham gia'), findsOneWidget);
    });

    testWidgets('renders the multi-participant label (VI)', (tester) async {
      final manyParticipants = testExpense.copyWith(
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
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: manyParticipants,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );
      expect(find.text('3 người tham gia'), findsOneWidget);
    });

    testWidgets('renders a card with a rounded shape', (tester) async {
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: testExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('shows the category badge when category is present', (
      tester,
    ) async {
      final categoryExpense = testExpense.copyWith(category: 'Food');
      await pumpLocalized(
        tester,
        ExpenseListItem(
          expense: categoryExpense,
          onTap: () => onTapCalled = true,
          groupCurrency: 'VND',
        ),
      );
      expect(find.text('Food'), findsOneWidget);
    });
  });
}
