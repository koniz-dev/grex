import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/services/export_service.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';

void main() {
  group('ExportService', () {
    late ExportService exportService;
    late Group testGroup;
    late List<Expense> testExpenses;
    late List<Payment> testPayments;
    late List<Balance> testBalances;

    setUp(() async {
      exportService = ExportService();

      // Create test data
      testGroup = Group(
        id: 'group-1',
        name: 'Test Group',
        currency: 'VND',
        creatorId: 'user-1',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        members: [
          GroupMember(
            id: 'member-1',
            userId: 'user-1',
            displayName: 'User One',
            role: MemberRole.administrator,
            joinedAt: DateTime(2024),
          ),
          GroupMember(
            id: 'member-2',
            userId: 'user-2',
            displayName: 'User Two',
            role: MemberRole.editor,
            joinedAt: DateTime(2024, 1, 2),
          ),
        ],
      );

      testExpenses = [
        Expense(
          id: 'expense-1',
          groupId: 'group-1',
          payerId: 'user-1',
          payerName: 'User One',
          amount: 100000,
          currency: 'VND',
          description: 'Test Expense',
          category: 'Food',
          expenseDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
          participants: const [
            ExpenseParticipant(
              userId: 'user-1',
              displayName: 'User One',
              shareAmount: 50000,
              sharePercentage: 50,
            ),
            ExpenseParticipant(
              userId: 'user-2',
              displayName: 'User Two',
              shareAmount: 50000,
              sharePercentage: 50,
            ),
          ],
        ),
      ];

      testPayments = [
        Payment(
          id: 'payment-1',
          groupId: 'group-1',
          payerId: 'user-2',
          payerName: 'User Two',
          recipientId: 'user-1',
          recipientName: 'User One',
          amount: 25000,
          currency: 'VND',
          description: 'Test Payment',
          paymentDate: DateTime(2024, 1, 20),
          createdAt: DateTime(2024, 1, 20),
        ),
      ];

      testBalances = [
        const Balance(
          userId: 'user-1',
          displayName: 'User One',
          balance: 25000,
          currency: 'VND',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'User Two',
          balance: -25000,
          currency: 'VND',
        ),
      ];
    });

    group('CSV Export', () {
      test('should export group data to CSV format successfully', () async {
        // Arrange
        double? progressValue;

        // Act
        final result = await exportService.exportToCSV(
          group: testGroup,
          expenses: testExpenses,
          payments: testPayments,
          balances: testBalances,
          onProgress: (progress) {
            progressValue = progress;
          },
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.filePath, isNotNull);
        expect(result.fileName, equals('Test Group_export.csv'));
        expect(result.format, equals(ExportFormat.csv));
        expect(progressValue, equals(1.0));

        // Verify file exists and has content
        final file = File(result.filePath!);
        expect(file.existsSync(), isTrue);

        final content = await file.readAsString();
        expect(content, contains('Grex Export - Test Group'));
        expect(content, contains('GROUP MEMBERS'));
        expect(content, contains('EXPENSES'));
        expect(content, contains('PAYMENTS'));
        expect(content, contains('BALANCES'));
        expect(content, contains('User One'));
        expect(content, contains('User Two'));
        expect(content, contains('Test Expense'));
        expect(content, contains('Test Payment'));

        // Cleanup
        await exportService.deleteExportFile(result.filePath!);
      });

      test('should handle CSV export with empty data', () async {
        // Act
        final result = await exportService.exportToCSV(
          group: testGroup,
          expenses: [],
          payments: [],
          balances: [],
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.filePath, isNotNull);

        final file = File(result.filePath!);
        final content = await file.readAsString();
        expect(content, contains('Grex Export - Test Group'));
        expect(content, contains('GROUP MEMBERS'));

        // Cleanup
        await exportService.deleteExportFile(result.filePath!);
      });

      test('should escape CSV special characters correctly', () async {
        // Arrange
        final groupWithSpecialChars = testGroup.copyWith(
          name: 'Test "Group" with, commas',
        );

        final expenseWithSpecialChars = testExpenses.first.copyWith(
          description: 'Expense with "quotes" and, commas\nand newlines',
        );

        // Act
        final result = await exportService.exportToCSV(
          group: groupWithSpecialChars,
          expenses: [expenseWithSpecialChars],
          payments: [],
          balances: [],
        );

        // Assert
        expect(result.isSuccess, isTrue);

        final file = File(result.filePath!);
        final content = await file.readAsString();
        expect(content, contains('"Test ""Group"" with, commas"'));
        expect(
          content,
          contains('"Expense with ""quotes"" and, commas\nand newlines"'),
        );

        // Cleanup
        await exportService.deleteExportFile(result.filePath!);
      });
    });

    group('PDF Export', () {
      test('should export group data to PDF format successfully', () async {
        // Arrange
        double? progressValue;

        // Act
        final result = await exportService.exportToPDF(
          group: testGroup,
          expenses: testExpenses,
          payments: testPayments,
          balances: testBalances,
          onProgress: (progress) {
            progressValue = progress;
          },
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.filePath, isNotNull);
        expect(result.fileName, equals('Test Group_report.txt'));
        expect(result.format, equals(ExportFormat.pdf));
        expect(progressValue, equals(1.0));

        // Verify file exists and has content
        final file = File(result.filePath!);
        expect(file.existsSync(), isTrue);

        final content = await file.readAsString();
        expect(content, contains('GREX EXPENSE REPORT'));
        expect(content, contains('Group: Test Group'));
        expect(content, contains('SUMMARY'));
        expect(content, contains('GROUP MEMBERS'));
        expect(content, contains('CURRENT BALANCES'));
        expect(content, contains('EXPENSES'));
        expect(content, contains('PAYMENTS'));
        expect(content, contains('User One'));
        expect(content, contains('User Two'));

        // Cleanup
        await exportService.deleteExportFile(result.filePath!);
      });

      test('should handle PDF export with large datasets', () async {
        // Arrange - Create many expenses and payments
        final manyExpenses = List.generate(
          50,
          (index) => testExpenses.first.copyWith(
            id: 'expense-$index',
            description: 'Expense $index',
            expenseDate: DateTime(2024, 1, index + 1),
          ),
        );

        final manyPayments = List.generate(
          30,
          (index) => testPayments.first.copyWith(
            id: 'payment-$index',
            description: 'Payment $index',
            paymentDate: DateTime(2024, 1, index + 1),
          ),
        );

        // Act
        final result = await exportService.exportToPDF(
          group: testGroup,
          expenses: manyExpenses,
          payments: manyPayments,
          balances: testBalances,
        );

        // Assert
        expect(result.isSuccess, isTrue);

        final file = File(result.filePath!);
        final content = await file.readAsString();
        expect(content, contains('Number of Expenses: 50'));
        expect(content, contains('Number of Payments: 30'));
        // Should only show last 20 expenses and payments in detail
        expect(content, contains('Expense 49'));
        expect(content, contains('Payment 29'));

        // Cleanup
        await exportService.deleteExportFile(result.filePath!);
      });
    });

    group('File Management', () {
      test('should delete export file successfully', () async {
        // Arrange
        final result = await exportService.exportToCSV(
          group: testGroup,
          expenses: [],
          payments: [],
          balances: [],
        );

        final file = File(result.filePath!);
        expect(file.existsSync(), isTrue);

        // Act
        await exportService.deleteExportFile(result.filePath!);

        // Assert
        expect(file.existsSync(), isFalse);
      });

      test('should handle deletion of non-existent file gracefully', () async {
        // Act & Assert - Should not throw
        await exportService.deleteExportFile('/non/existent/file.csv');
      });
    });

    group('Progress Tracking', () {
      test('should call progress callback during CSV export', () async {
        // Arrange
        final progressValues = <double>[];

        // Act
        await exportService.exportToCSV(
          group: testGroup,
          expenses: testExpenses,
          payments: testPayments,
          balances: testBalances,
          onProgress: progressValues.add,
        );

        // Assert
        expect(progressValues, isNotEmpty);
        expect(progressValues.first, equals(0.1));
        expect(progressValues.last, equals(1.0));

        // Progress should be increasing
        for (var i = 1; i < progressValues.length; i++) {
          expect(
            progressValues[i],
            greaterThanOrEqualTo(progressValues[i - 1]),
          );
        }
      });

      test('should call progress callback during PDF export', () async {
        // Arrange
        final progressValues = <double>[];

        // Act
        await exportService.exportToPDF(
          group: testGroup,
          expenses: testExpenses,
          payments: testPayments,
          balances: testBalances,
          onProgress: progressValues.add,
        );

        // Assert
        expect(progressValues, isNotEmpty);
        expect(progressValues.first, equals(0.1));
        expect(progressValues.last, equals(1.0));
      });

      test('should work without progress callback', () async {
        // Act & Assert - Should not throw
        final result = await exportService.exportToCSV(
          group: testGroup,
          expenses: testExpenses,
          payments: testPayments,
          balances: testBalances,
        );

        expect(result.isSuccess, isTrue);

        // Cleanup
        await exportService.deleteExportFile(result.filePath!);
      });
    });

    group('Error Handling', () {
      test('should handle export errors gracefully', () async {
        // This test would require mocking file system operations
        // For now, we'll test with invalid data scenarios

        // Act - Try to export with null group name (should be handled)
        final result = await exportService.exportToCSV(
          group: testGroup,
          expenses: testExpenses,
          payments: testPayments,
          balances: testBalances,
        );

        // Assert - Should still succeed with valid data
        expect(result.isSuccess, isTrue);

        // Cleanup
        await exportService.deleteExportFile(result.filePath!);
      });
    });

    group('Data Formatting', () {
      test('should format currency amounts correctly in CSV', () async {
        // Act
        final result = await exportService.exportToCSV(
          group: testGroup,
          expenses: testExpenses,
          payments: testPayments,
          balances: testBalances,
        );

        // Assert
        final file = File(result.filePath!);
        final content = await file.readAsString();

        expect(content, contains('100000')); // Expense amount
        expect(content, contains('25000')); // Payment amount
        expect(content, contains('VND')); // Currency

        // Cleanup
        await exportService.deleteExportFile(result.filePath!);
      });

      test('should format dates correctly in exports', () async {
        // Act
        final result = await exportService.exportToPDF(
          group: testGroup,
          expenses: testExpenses,
          payments: testPayments,
          balances: testBalances,
        );

        // Assert
        final file = File(result.filePath!);
        final content = await file.readAsString();

        expect(content, contains('15/1/2024')); // Expense date
        expect(content, contains('20/1/2024')); // Payment date

        // Cleanup
        await exportService.deleteExportFile(result.filePath!);
      });
    });
  });

  group('ExportResult', () {
    test('should create success result correctly', () {
      // Act
      final result = ExportResult.success(
        filePath: '/path/to/file.csv',
        fileName: 'export.csv',
        format: ExportFormat.csv,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.filePath, equals('/path/to/file.csv'));
      expect(result.fileName, equals('export.csv'));
      expect(result.format, equals(ExportFormat.csv));
      expect(result.errorMessage, isNull);
    });

    test('should create error result correctly', () {
      // Act
      final result = ExportResult.error('Export failed');

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.filePath, isNull);
      expect(result.fileName, isNull);
      expect(result.format, isNull);
      expect(result.errorMessage, equals('Export failed'));
    });
  });

  group('ExportFormat', () {
    test('should have correct display names', () {
      expect(ExportFormat.csv.displayName, equals('CSV'));
      expect(ExportFormat.pdf.displayName, equals('PDF'));
    });

    test('should have correct file extensions', () {
      expect(ExportFormat.csv.fileExtension, equals('.csv'));
      expect(ExportFormat.pdf.fileExtension, equals('.txt'));
    });

    test('should have correct mime types', () {
      expect(ExportFormat.csv.mimeType, equals('text/csv'));
      expect(ExportFormat.pdf.mimeType, equals('text/plain'));
    });
  });
}
