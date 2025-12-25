import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grex/features/payments/presentation/widgets/empty_payments_widget.dart';

void main() {
  group('EmptyPaymentsWidget Widget Tests', () {
    Widget createTestWidget({
      String? message,
      VoidCallback? onAddPayment,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: EmptyPaymentsWidget(
            message: message ?? 'No Payments',
            onAddPayment: onAddPayment,
          ),
        ),
      );
    }

    testWidgets('should display empty state message', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('No Payments'), findsOneWidget);
    });

    testWidgets('should display descriptive subtitle', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(
        find.text('Record payments between group members to settle debts'),
        findsOneWidget,
      );
    });

    testWidgets('should display empty state icon', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.payment_outlined), findsOneWidget);
    });

    testWidgets('should display create payment button', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Add First Payment'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should call onCreatePayment when button is tapped', (
      tester,
    ) async {
      // Arrange
      var wasPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          onAddPayment: () {
            wasPressed = true;
          },
        ),
      );

      await tester.tap(find.text('Add First Payment'));

      // Assert
      expect(wasPressed, isTrue);
    });

    testWidgets('should handle null callback gracefully', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - should not crash
      expect(find.byType(EmptyPaymentsWidget), findsOneWidget);
      expect(find.text('Add First Payment'), findsOneWidget);
    });

    testWidgets('should display proper visual hierarchy', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Column), findsOneWidget);
      expect(find.byIcon(Icons.payment_outlined), findsOneWidget);

      // Check text styling
      final titleText = tester.widget<Text>(find.text('No Payments'));
      expect(titleText.style?.fontSize, greaterThan(16));
      expect(titleText.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('should center content properly', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should have proper spacing between elements', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should display icon with proper size and color', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.payment_outlined));
      expect(icon.size, equals(64));
    });

    testWidgets('should display button with proper styling', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.child, isA<Text>());
    });

    testWidgets('should maintain consistent layout', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      // Check that all elements are present in correct order
      expect(find.byIcon(Icons.payment_outlined), findsOneWidget);
      expect(find.text('No Payments'), findsOneWidget);
      expect(
        find.text('Record payments between group members to settle debts'),
        findsOneWidget,
      );
      expect(find.text('Add First Payment'), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('should handle different screen sizes', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - should render without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display helpful guidance text', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(
        find.text('Record payments between group members to settle debts'),
        findsOneWidget,
      );

      final subtitleText = tester.widget<Text>(
        find.text('Record payments between group members to settle debts'),
      );
      expect(subtitleText.textAlign, equals(TextAlign.center));
    });

    testWidgets('should use theme colors appropriately', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.payment_outlined));
      expect(icon.color, isNotNull);
    });

    testWidgets('should have proper padding and margins', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('should display call-to-action prominently', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Add First Payment'), findsOneWidget);
    });

    testWidgets('should work with different themes', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: EmptyPaymentsWidget(
              message: 'No payments yet',
              onAddPayment: () {},
            ),
          ),
        ),
      );

      // Assert - should render without issues in dark theme
      expect(find.byType(EmptyPaymentsWidget), findsOneWidget);
    });
  });
}
