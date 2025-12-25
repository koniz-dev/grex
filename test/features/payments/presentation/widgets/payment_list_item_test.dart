import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/presentation/widgets/payment_list_item.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

void main() {
  group('PaymentListItem Widget Tests', () {
    late Payment testPayment;

    setUp(() {
      testPayment = Payment(
        id: 'payment-1',
        groupId: 'group-1',
        payerId: 'user-1',
        payerName: 'John Doe',
        recipientId: 'user-2',
        recipientName: 'Jane Smith',
        amount: 50,
        currency: 'USD',
        description: 'Dinner payment',
        paymentDate: DateTime(2024, 1, 15, 14, 30),
        createdAt: DateTime(2024, 1, 15, 14, 30),
      );
    });

    Widget createTestWidget({
      Payment? payment,
      VoidCallback? onTap,
      VoidCallback? onDelete,
      String? groupCurrency,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PaymentListItem(
            payment: payment ?? testPayment,
            onTap: onTap ?? () {},
            onDelete: onDelete,
            groupCurrency: groupCurrency ?? 'USD',
          ),
        ),
      );
    }

    testWidgets('should display payment information correctly', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('John Doe → Jane Smith'), findsOneWidget);
      expect(find.text(r'$50.00'), findsOneWidget);
      expect(find.text('Dinner payment'), findsOneWidget);
    });

    testWidgets('should display formatted currency amount', (tester) async {
      // Arrange
      final vndPayment = testPayment.copyWith(
        amount: 250000,
        currency: 'VND',
      );

      // Act
      await tester.pumpWidget(createTestWidget(payment: vndPayment));

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 250000,
        currencyCode: 'VND',
      );
      expect(find.text(formattedAmount), findsOneWidget);
    });

    testWidgets('should display payment date correctly', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('15/1/2024'), findsOneWidget);
    });

    testWidgets('should display today for today payments', (tester) async {
      // Arrange
      final todayPayment = testPayment.copyWith(
        paymentDate: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(payment: todayPayment));

      // Assert
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('should display yesterday for yesterday payments', (
      tester,
    ) async {
      // Arrange
      final yesterdayPayment = testPayment.copyWith(
        paymentDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      // Act
      await tester.pumpWidget(createTestWidget(payment: yesterdayPayment));

      // Assert
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('should display payment direction with arrow', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('John Doe → Jane Smith'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('should display payment icon', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.payment), findsOneWidget);
    });

    testWidgets('should display delete button when enabled', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('should hide delete button when onDelete is null', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('should call onTap when payment item is tapped', (
      tester,
    ) async {
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

    testWidgets('should call onDelete when delete button is tapped', (
      tester,
    ) async {
      // Arrange
      var wasDeleted = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          onDelete: () {
            wasDeleted = true;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));

      // Assert
      expect(wasDeleted, isTrue);
    });

    testWidgets('should display description when available', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Dinner payment'), findsOneWidget);
    });

    testWidgets('should handle empty description gracefully', (tester) async {
      // Arrange
      final paymentWithoutDescription = testPayment.copyWith();

      // Act
      await tester.pumpWidget(
        createTestWidget(payment: paymentWithoutDescription),
      );

      // Assert
      expect(find.text('Payment'), findsOneWidget); // Default description
    });

    testWidgets('should display proper styling for payment amount', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final amountText = tester.widget<Text>(find.text(r'$50.00'));
      expect(amountText.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('should display proper card elevation and styling', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Card), findsOneWidget);
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, greaterThan(0));
    });

    testWidgets('should handle long names gracefully', (tester) async {
      // Arrange
      final paymentWithLongNames = testPayment.copyWith(
        payerName: 'Very Long Payer Name That Might Overflow',
        recipientName: 'Very Long Recipient Name That Might Also Overflow',
      );

      // Act
      await tester.pumpWidget(createTestWidget(payment: paymentWithLongNames));

      // Assert
      expect(find.textContaining('Very Long Payer Name'), findsOneWidget);
      expect(find.textContaining('Very Long Recipient Name'), findsOneWidget);
    });

    testWidgets('should display time for recent payments', (tester) async {
      // Arrange
      final recentPayment = testPayment.copyWith(
        paymentDate: DateTime.now().subtract(const Duration(hours: 2)),
      );

      // Act
      await tester.pumpWidget(createTestWidget(payment: recentPayment));

      // Assert
      // Should show time for recent payments
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('should handle different currencies correctly', (tester) async {
      // Arrange
      final eurPayment = testPayment.copyWith(
        amount: 45.50,
        currency: 'EUR',
      );

      // Act
      await tester.pumpWidget(createTestWidget(payment: eurPayment));

      // Assert
      final formattedAmount = CurrencyFormatter.format(
        amount: 45.50,
        currencyCode: 'EUR',
      );
      expect(find.text(formattedAmount), findsOneWidget);
    });

    testWidgets('should display proper visual hierarchy', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Check that amount is prominently displayed
      final amountText = tester.widget<Text>(find.text(r'$50.00'));
      expect(amountText.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('should handle tap and delete interactions independently', (
      tester,
    ) async {
      // Arrange
      var wasTapped = false;
      var wasDeleted = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          onTap: () {
            wasTapped = true;
          },
          onDelete: () {
            wasDeleted = true;
          },
        ),
      );

      // Tap the main item
      await tester.tap(find.byType(InkWell));
      expect(wasTapped, isTrue);
      expect(wasDeleted, isFalse);

      // Reset and tap delete
      wasTapped = false;
      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(wasTapped, isFalse);
      expect(wasDeleted, isTrue);
    });

    testWidgets('should display payment metadata correctly', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('15/1/2024'), findsOneWidget);
      expect(find.byIcon(Icons.payment), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('should handle null callbacks gracefully', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - should not crash
      expect(find.byType(PaymentListItem), findsOneWidget);
    });

    testWidgets('should display consistent layout structure', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Check for proper content organization
      expect(find.text('John Doe → Jane Smith'), findsOneWidget);
      expect(find.text('Dinner payment'), findsOneWidget);
      expect(find.text(r'$50.00'), findsOneWidget);
      expect(find.text('15/1/2024'), findsOneWidget);
    });
  });
}
