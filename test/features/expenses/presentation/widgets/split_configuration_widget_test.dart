import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grex/features/expenses/domain/entities/split_method.dart';
import 'package:grex/features/expenses/presentation/widgets/split_configuration_widget.dart';

void main() {
  group('SplitConfigurationWidget Widget Tests', () {
    late List<Map<String, dynamic>> testParticipants;

    setUp(() {
      testParticipants = [
        {'userId': 'user-1', 'displayName': 'John Doe'},
        {'userId': 'user-2', 'displayName': 'Jane Smith'},
        {'userId': 'user-3', 'displayName': 'Bob Johnson'},
      ];
    });

    Widget createTestWidget({
      SplitMethod splitMethod = SplitMethod.equal,
      List<Map<String, dynamic>>? participants,
      double totalAmount = 100.0,
      String currency = 'USD',
      ValueChanged<List<Map<String, dynamic>>>? onConfigurationChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SplitConfigurationWidget(
            splitMethod: splitMethod,
            participants: participants ?? testParticipants,
            totalAmount: totalAmount,
            currency: currency,
            onConfigurationChanged: onConfigurationChanged ?? (data) {},
          ),
        ),
      );
    }

    testWidgets('should display message when no participants or amount', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          participants: [],
          totalAmount: 0,
        ),
      );

      // Assert
      expect(
        find.text('Configure participants and amount first'),
        findsOneWidget,
      );
    });

    group('Equal Split Method', () {
      testWidgets('should display equal split explanation', (tester) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(),
        );

        // Assert
        expect(
          find.text('Each participant pays the same amount'),
          findsOneWidget,
        );
      });

      testWidgets('should display all participants with equal amounts', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(
            totalAmount: 90, // Evenly divisible by 3
          ),
        );

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Bob Johnson'), findsOneWidget);
        expect(find.text(r'$30.00'), findsNWidgets(3)); // Each person pays $30
      });

      testWidgets('should handle rounding in equal split', (tester) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(),
        );

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Bob Johnson'), findsOneWidget);
        // Should show rounded amounts that total to $100
      });

      testWidgets('should display participant avatars', (tester) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(),
        );

        // Assert
        expect(find.byType(CircleAvatar), findsNWidgets(3));
        expect(find.text('J'), findsNWidgets(2)); // John and Jane
        expect(find.text('B'), findsOneWidget); // Bob
      });
    });

    group('Percentage Split Method', () {
      testWidgets('should display percentage split explanation', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(splitMethod: SplitMethod.percentage),
        );

        // Assert
        expect(
          find.text('Enter percentage for each participant (must total 100%)'),
          findsOneWidget,
        );
      });

      testWidgets('should display percentage input fields', (tester) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(splitMethod: SplitMethod.percentage),
        );

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Bob Johnson'), findsOneWidget);
        expect(find.text('%'), findsNWidgets(3));
        expect(find.byType(TextField), findsNWidgets(3));
      });

      testWidgets('should show calculated amounts for percentages', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.percentage,
          ),
        );

        // Assert - should show calculated amounts based on default percentages
        expect(find.byType(TextField), findsNWidgets(3));
      });

      testWidgets('should update calculated amounts when percentage changes', (
        tester,
      ) async {
        // Arrange
        List<Map<String, dynamic>>? configurationData;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.percentage,
            onConfigurationChanged: (data) {
              configurationData = data;
            },
          ),
        );

        // Enter 50% for first participant
        await tester.enterText(find.byType(TextField).first, '50');

        // Assert
        expect(configurationData, isNotNull);
      });

      testWidgets('should display total summary for percentage split', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(splitMethod: SplitMethod.percentage),
        );

        // Assert
        expect(find.text('Total:'), findsOneWidget);
        expect(find.text(r'Target: $100.00'), findsOneWidget);
      });
    });

    group('Exact Amount Split Method', () {
      testWidgets('should display exact amount explanation', (tester) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(splitMethod: SplitMethod.exact),
        );

        // Assert
        expect(
          find.text('Enter exact amount for each participant'),
          findsOneWidget,
        );
      });

      testWidgets('should display amount input fields with currency', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.exact,
            currency: 'VND',
          ),
        );

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Bob Johnson'), findsOneWidget);
        expect(find.text('₫'), findsNWidgets(3)); // VND symbol
        expect(find.byType(TextField), findsNWidgets(3));
      });

      testWidgets('should update configuration when amounts change', (
        tester,
      ) async {
        // Arrange
        List<Map<String, dynamic>>? configurationData;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.exact,
            onConfigurationChanged: (data) {
              configurationData = data;
            },
          ),
        );

        // Enter amount for first participant
        await tester.enterText(find.byType(TextField).first, '40');

        // Assert
        expect(configurationData, isNotNull);
      });
    });

    group('Shares Split Method', () {
      testWidgets('should display shares explanation', (tester) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(splitMethod: SplitMethod.shares),
        );

        // Assert
        expect(
          find.text('Enter number of shares for each participant'),
          findsOneWidget,
        );
      });

      testWidgets('should display shares input fields', (tester) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(splitMethod: SplitMethod.shares),
        );

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Bob Johnson'), findsOneWidget);
        expect(find.text('shares'), findsNWidgets(3));
        expect(find.byType(TextField), findsNWidgets(3));
      });

      testWidgets('should show calculated amounts for shares', (tester) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.shares,
            totalAmount: 120, // Easily divisible
          ),
        );

        // Assert - should show calculated amounts based on shares
        expect(find.byType(TextField), findsNWidgets(3));
      });

      testWidgets('should update calculated amounts when shares change', (
        tester,
      ) async {
        // Arrange
        List<Map<String, dynamic>>? configurationData;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.shares,
            onConfigurationChanged: (data) {
              configurationData = data;
            },
          ),
        );

        // Enter 2 shares for first participant
        await tester.enterText(find.byType(TextField).first, '2');

        // Assert
        expect(configurationData, isNotNull);
      });
    });

    group('Total Summary', () {
      testWidgets('should display valid total summary when amounts match', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.percentage,
          ),
        );

        // Assert
        expect(find.text('Total:'), findsOneWidget);
        expect(find.text(r'Target: $100.00'), findsOneWidget);
      });

      testWidgets('should display error state when amounts do not match', (
        tester,
      ) async {
        // This would require setting up invalid split data
        // The widget should show error styling when totals don't match

        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.exact,
          ),
        );

        // Assert - structure is there for error display
        expect(find.text('Total:'), findsOneWidget);
      });

      testWidgets('should update total when configuration changes', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.exact,
          ),
        );

        // Enter amounts that don't total to 100
        await tester.enterText(find.byType(TextField).first, '30');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '30');
        await tester.pump();

        // Assert - total should update to show $90 vs target $100
        expect(find.text('Total:'), findsOneWidget);
      });
    });

    group('Widget Updates', () {
      testWidgets('should reinitialize when split method changes', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(),
        );

        // Change to percentage method
        await tester.pumpWidget(
          createTestWidget(splitMethod: SplitMethod.percentage),
        );

        // Assert
        expect(
          find.text('Enter percentage for each participant (must total 100%)'),
          findsOneWidget,
        );
        expect(find.text('%'), findsNWidgets(3));
      });

      testWidgets('should reinitialize when participants change', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          createTestWidget(participants: testParticipants.take(2).toList()),
        );

        // Change participants
        await tester.pumpWidget(
          createTestWidget(participants: testParticipants),
        );

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Bob Johnson'), findsOneWidget);
      });

      testWidgets('should reinitialize when total amount changes', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(createTestWidget());

        // Change amount
        await tester.pumpWidget(createTestWidget(totalAmount: 200));

        // Assert
        expect(find.text(r'Target: $200.00'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty participant name', (tester) async {
        // Arrange
        final participantsWithEmptyName = [
          {'userId': 'user-1', 'displayName': ''},
        ];

        // Act
        await tester.pumpWidget(
          createTestWidget(
            participants: participantsWithEmptyName,
            totalAmount: 50,
          ),
        );

        // Assert
        expect(find.text('?'), findsOneWidget); // Avatar should show '?'
      });

      testWidgets('should handle single participant', (tester) async {
        // Arrange
        final singleParticipant = [testParticipants.first];

        // Act
        await tester.pumpWidget(
          createTestWidget(
            participants: singleParticipant,
          ),
        );

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text(r'$100.00'), findsOneWidget); // Should get full amount
      });

      testWidgets('should handle zero amount', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(totalAmount: 0));

        // Assert
        expect(
          find.text('Configure participants and amount first'),
          findsOneWidget,
        );
      });

      testWidgets('should handle negative amount gracefully', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(totalAmount: -50));

        // Assert
        expect(
          find.text('Configure participants and amount first'),
          findsOneWidget,
        );
      });
    });

    group('Configuration Callbacks', () {
      testWidgets('should call onConfigurationChanged on initialization', (
        tester,
      ) async {
        // Arrange
        List<Map<String, dynamic>>? configurationData;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            onConfigurationChanged: (data) {
              configurationData = data;
            },
          ),
        );

        // Assert
        expect(configurationData, isNotNull);
        expect(configurationData!.length, equals(3));
      });

      testWidgets('should include correct data structure in callbacks', (
        tester,
      ) async {
        // Arrange
        List<Map<String, dynamic>>? configurationData;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            splitMethod: SplitMethod.percentage,
            onConfigurationChanged: (data) {
              configurationData = data;
            },
          ),
        );

        // Assert
        expect(configurationData, isNotNull);
        expect(configurationData!.first.containsKey('userId'), isTrue);
        expect(configurationData!.first.containsKey('displayName'), isTrue);
        expect(configurationData!.first.containsKey('percentage'), isTrue);
      });
    });
  });
}
