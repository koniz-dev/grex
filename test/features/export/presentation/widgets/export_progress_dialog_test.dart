import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grex/core/services/export_service.dart';
import 'package:grex/features/export/presentation/widgets/export_progress_dialog.dart';

void main() {
  group('ExportProgressDialog', () {
    testWidgets('should display export progress correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportProgressDialog(
            format: ExportFormat.csv,
            progress: 0.5,
          ),
        ),
      );

      // Assert
      expect(find.text('Exporting Data'), findsOneWidget);
      expect(find.text('Generating CSV export...'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display PDF format correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportProgressDialog(
            format: ExportFormat.pdf,
            progress: 0.3,
          ),
        ),
      );

      // Assert
      expect(find.text('Generating PDF export...'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('should show correct progress text at different stages', (
      tester,
    ) async {
      // Test different progress stages
      final progressStages = [
        (0.1, 'Preparing data...'),
        (0.3, 'Processing members...'),
        (0.5, 'Processing expenses...'),
        (0.7, 'Processing payments...'),
        (0.9, 'Finalizing export...'),
        (1.0, 'Complete!'),
      ];

      for (final (progress, expectedText) in progressStages) {
        await tester.pumpWidget(
          MaterialApp(
            home: ExportProgressDialog(
              format: ExportFormat.csv,
              progress: progress,
            ),
          ),
        );

        expect(find.text(expectedText), findsOneWidget);
      }
    });

    testWidgets('should show correct status messages at different stages', (
      tester,
    ) async {
      // Test different status messages
      final statusStages = [
        (0.1, 'Gathering group information and member data'),
        (0.3, 'Collecting member details and roles'),
        (0.5, 'Compiling expense records and calculations'),
        (0.7, 'Processing payment history and balances'),
        (0.9, 'Creating CSV file and preparing for sharing'),
        (1.0, 'Export completed successfully!'),
      ];

      for (final (progress, expectedMessage) in statusStages) {
        await tester.pumpWidget(
          MaterialApp(
            home: ExportProgressDialog(
              format: ExportFormat.csv,
              progress: progress,
            ),
          ),
        );

        expect(find.textContaining(expectedMessage), findsOneWidget);
      }
    });

    testWidgets('should show cancel button when onCancel is provided', (
      tester,
    ) async {
      // Arrange
      var cancelCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ExportProgressDialog(
            format: ExportFormat.csv,
            progress: 0.5,
            onCancel: () {
              cancelCalled = true;
            },
          ),
        ),
      );

      // Assert
      expect(find.text('Cancel'), findsOneWidget);

      // Act - tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert
      expect(cancelCalled, isTrue);
    });

    testWidgets('should not show cancel button when onCancel is null', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportProgressDialog(
            format: ExportFormat.csv,
            progress: 0.5,
          ),
        ),
      );

      // Assert
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('should update progress indicator value', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportProgressDialog(
            format: ExportFormat.csv,
            progress: 0.75,
          ),
        ),
      );

      // Assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, equals(0.75));
    });

    testWidgets('should display correct percentage text', (tester) async {
      // Test various progress values
      final progressValues = [0.0, 0.25, 0.5, 0.75, 1.0];
      final expectedTexts = ['0%', '25%', '50%', '75%', '100%'];

      for (var i = 0; i < progressValues.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: ExportProgressDialog(
              format: ExportFormat.csv,
              progress: progressValues[i],
            ),
          ),
        );

        expect(find.text(expectedTexts[i]), findsOneWidget);
      }
    });

    testWidgets('should show download icon in title', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportProgressDialog(
            format: ExportFormat.csv,
            progress: 0.5,
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ExportProgressDialog(
            format: ExportFormat.csv,
            progress: 0.5,
            onCancel: () {},
          ),
        ),
      );

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
