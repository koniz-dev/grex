import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grex/core/services/export_service.dart';
import 'package:grex/features/export/presentation/widgets/export_format_selector.dart';

void main() {
  group('ExportFormatSelector', () {
    testWidgets('should display all export formats', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportFormatSelector(
              selectedFormat: ExportFormat.csv,
              onFormatChanged: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(
        find.text('Spreadsheet format, perfect for Excel or Google Sheets'),
        findsOneWidget,
      );
      expect(
        find.text('Formatted report, easy to read and share'),
        findsOneWidget,
      );
    });

    testWidgets('should show CSV as selected initially', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportFormatSelector(
              selectedFormat: ExportFormat.csv,
              onFormatChanged: (format) {},
            ),
          ),
        ),
      );

      // Assert
      final csvRadio = find.byType(Radio<ExportFormat>).first;
      final csvRadioWidget = tester.widget<Radio<ExportFormat>>(csvRadio);
      expect(csvRadioWidget.value, equals(ExportFormat.csv));
      // Accessing deprecated member for testing purposes
      // ignore: deprecated_member_use
      expect(csvRadioWidget.groupValue, equals(ExportFormat.csv));
    });

    testWidgets('should call onFormatChanged when format is selected', (
      tester,
    ) async {
      // Arrange
      ExportFormat? selectedFormat;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportFormatSelector(
              selectedFormat: ExportFormat.csv,
              onFormatChanged: (format) {
                selectedFormat = format;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedFormat, equals(ExportFormat.pdf));
    });

    testWidgets('should call onFormatChanged when radio button is tapped', (
      tester,
    ) async {
      // Arrange
      ExportFormat? selectedFormat;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportFormatSelector(
              selectedFormat: ExportFormat.csv,
              onFormatChanged: (format) {
                selectedFormat = format;
              },
            ),
          ),
        ),
      );

      // Act
      final pdfRadio = find.byType(Radio<ExportFormat>).last;
      await tester.tap(pdfRadio);
      await tester.pumpAndSettle();

      // Assert
      expect(selectedFormat, equals(ExportFormat.pdf));
    });

    testWidgets('should highlight selected format', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportFormatSelector(
              selectedFormat: ExportFormat.pdf,
              onFormatChanged: (format) {},
            ),
          ),
        ),
      );

      // Assert
      final pdfRadio = find.byType(Radio<ExportFormat>).last;
      final pdfRadioWidget = tester.widget<Radio<ExportFormat>>(pdfRadio);
      // Accessing deprecated member for testing purposes
      // ignore: deprecated_member_use
      expect(pdfRadioWidget.groupValue, equals(ExportFormat.pdf));
    });

    testWidgets('should display correct icons for each format', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportFormatSelector(
              selectedFormat: ExportFormat.csv,
              onFormatChanged: (format) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportFormatSelector(
              selectedFormat: ExportFormat.csv,
              onFormatChanged: (format) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(InkWell), findsNWidgets(2));
      expect(find.byType(Radio<ExportFormat>), findsNWidgets(2));
    });
  });
}
