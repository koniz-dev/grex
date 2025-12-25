import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/presentation/widgets/balance_list_item.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

void main() {
  group('BalanceListItem Widget Tests', () {
    late Balance testBalance;

    setUp(() {
      testBalance = const Balance(
        userId: 'user-1',
        displayName: 'John Doe',
        balance: 50,
        currency: 'USD',
      );
    });

    Widget createTestWidget({
      Balance? balance,
      VoidCallback? onTap,
    }) {
      final theme = ThemeData(useMaterial3: true);
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: BalanceListItem(
            balance: balance ?? testBalance,
            onTap: onTap,
          ),
        ),
      );
    }

    testWidgets('should display user name and balance', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(
        find.text(CurrencyFormatter.format(amount: 50, currencyCode: 'USD')),
        findsOneWidget,
      );
    });

    testWidgets('should display positive balance with green color', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 50,
        currencyCode: 'USD',
      );
      expect(find.text(formattedAmount), findsOneWidget);

      final balanceText = tester.widget<Text>(find.text(formattedAmount));
      expect(balanceText.style?.color, equals(Colors.green));
    });

    testWidgets('should display negative balance with red color', (
      tester,
    ) async {
      // Arrange
      final negativeBalance = testBalance.copyWith(balance: -25);

      // Act
      await tester.pumpWidget(createTestWidget(balance: negativeBalance));

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 25,
        currencyCode: 'USD',
      );
      expect(find.text(formattedAmount), findsOneWidget);

      final balanceText = tester.widget<Text>(find.text(formattedAmount));
      expect(
        balanceText.style?.color,
        equals(ThemeData(useMaterial3: true).colorScheme.error),
      );
    });

    testWidgets('should display zero balance with neutral color', (
      tester,
    ) async {
      // Arrange
      final zeroBalance = testBalance.copyWith(balance: 0);

      // Act
      await tester.pumpWidget(createTestWidget(balance: zeroBalance));

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 0,
        currencyCode: 'USD',
      );
      expect(find.text(formattedAmount), findsOneWidget);

      final balanceText = tester.widget<Text>(find.text(formattedAmount));
      expect(
        balanceText.style?.color,
        equals(ThemeData(useMaterial3: true).colorScheme.onSurfaceVariant),
      );
    });

    testWidgets('should display formatted currency for different currencies', (
      tester,
    ) async {
      // Arrange
      final vndBalance = testBalance.copyWith(
        balance: 250000,
        currency: 'VND',
      );

      // Act
      await tester.pumpWidget(createTestWidget(balance: vndBalance));

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 250000,
        currencyCode: 'VND',
      );
      expect(find.text(formattedAmount), findsOneWidget);
    });

    testWidgets('should display user avatar with initials', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('J'), findsOneWidget); // First letter of John
    });

    testWidgets('should handle empty display name gracefully', (tester) async {
      // Arrange
      final balanceWithEmptyName = testBalance.copyWith(displayName: '');

      // Act
      await tester.pumpWidget(createTestWidget(balance: balanceWithEmptyName));

      // Assert
      expect(find.text('?'), findsOneWidget); // Avatar should show '?'
      expect(find.byType(BalanceListItem), findsOneWidget);
    });

    testWidgets('should display balance status text for positive balance', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Is owed money by group'), findsOneWidget);
    });

    testWidgets('should display balance status text for negative balance', (
      tester,
    ) async {
      // Arrange
      final negativeBalance = testBalance.copyWith(balance: -25);

      // Act
      await tester.pumpWidget(createTestWidget(balance: negativeBalance));

      // Assert
      expect(find.text('Owes money to group'), findsOneWidget);
    });

    testWidgets('should display settled status for zero balance', (
      tester,
    ) async {
      // Arrange
      final zeroBalance = testBalance.copyWith(balance: 0);

      // Act
      await tester.pumpWidget(createTestWidget(balance: zeroBalance));

      // Assert
      expect(find.text('All settled up'), findsOneWidget);
    });

    testWidgets('should call onTap when item is tapped', (tester) async {
      // Arrange
      var wasTapped = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          onTap: () {
            wasTapped = true;
          },
        ),
      );

      await tester.tap(find.byType(InkWell));

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('should handle null onTap callback gracefully', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - should not crash
      expect(find.byType(BalanceListItem), findsOneWidget);
    });

    testWidgets('should display proper visual hierarchy', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Check that balance amount is prominently displayed
      final formattedAmount = CurrencyFormatter.format(
        amount: 50,
        currencyCode: 'USD',
      );
      final balanceText = tester.widget<Text>(find.text(formattedAmount));
      expect(balanceText.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('should display chevron icon', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should handle large balance amounts', (tester) async {
      // Arrange
      final largeBalance = testBalance.copyWith(balance: 1234567.89);

      // Act
      await tester.pumpWidget(createTestWidget(balance: largeBalance));

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 1234567.89,
        currencyCode: 'USD',
      );
      expect(find.text(formattedAmount), findsOneWidget);
    });

    testWidgets('should handle very small balance amounts', (tester) async {
      // Arrange
      final smallBalance = testBalance.copyWith(balance: 0.01);

      // Act
      await tester.pumpWidget(createTestWidget(balance: smallBalance));

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 0.01,
        currencyCode: 'USD',
      );
      expect(find.text(formattedAmount), findsOneWidget);
      expect(find.text('Is owed money by group'), findsOneWidget);
    });

    testWidgets('should display proper card styling', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Card), findsOneWidget);
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, EdgeInsets.zero);
    });

    testWidgets('should handle long display names gracefully', (tester) async {
      // Arrange
      final longNameBalance = testBalance.copyWith(
        displayName: 'Very Long Display Name That Might Overflow',
      );

      // Act
      await tester.pumpWidget(createTestWidget(balance: longNameBalance));

      // Assert
      expect(find.textContaining('Very Long Display Name'), findsOneWidget);
    });

    testWidgets('should display consistent layout structure', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Check for proper content organization
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Is owed money by group'), findsOneWidget);
      expect(find.text('OWED'), findsOneWidget);
    });

    testWidgets('should use theme colors appropriately', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 50,
        currencyCode: 'USD',
      );
      final balanceText = tester.widget<Text>(find.text(formattedAmount));
      expect(balanceText.style?.color, isNotNull);
    });

    testWidgets('should work with different themes', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BalanceListItem(
              balance: testBalance,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert - should render without issues in dark theme
      expect(find.byType(BalanceListItem), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should display balance with proper precision', (tester) async {
      // Arrange
      final preciseBalance = testBalance.copyWith(balance: 123.456);

      // Act
      await tester.pumpWidget(createTestWidget(balance: preciseBalance));

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 123.456,
        currencyCode: 'USD',
      );
      expect(find.text(formattedAmount), findsOneWidget);
    });

    testWidgets('should handle different currency symbols correctly', (
      tester,
    ) async {
      // Arrange
      final eurBalance = testBalance.copyWith(
        balance: 45.50,
        currency: 'EUR',
      );

      // Act
      await tester.pumpWidget(createTestWidget(balance: eurBalance));

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 45.50,
        currencyCode: 'EUR',
      );
      expect(find.text(formattedAmount), findsOneWidget);
    });
  });
}
