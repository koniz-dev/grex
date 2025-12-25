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
  group('ExportService Property Tests', () {
    late ExportService exportService;

    setUp(() {
      exportService = ExportService();
    });

    group('Property 32: Data export includes complete information', () {
      test('CSV export contains all group data', () async {
        // **Feature: main-app-features, Property 32: Data export **
        // **includes complete information**

        for (var i = 0; i < 100; i++) {
          // Generate random test data
          final group = _generateRandomGroup();
          final expenses = _generateRandomExpenses(group);
          final payments = _generateRandomPayments(group);
          final balances = _generateRandomBalances(group);

          // Export to CSV
          final result = await exportService.exportToCSV(
            group: group,
            expenses: expenses,
            payments: payments,
            balances: balances,
          );

          // Property: Export should succeed
          expect(
            result.isSuccess,
            isTrue,
            reason: 'Export should always succeed with valid data',
          );

          if (result.isSuccess) {
            // Property: File should exist
            final file = File(result.filePath!);
            expect(
              file.existsSync(),
              isTrue,
              reason: 'Exported file should exist',
            );

            // Property: File should contain group information
            final content = await file.readAsString();
            expect(
              content.contains(group.name),
              isTrue,
              reason: 'Export should contain group name',
            );
            expect(
              content.contains(group.currency),
              isTrue,
              reason: 'Export should contain group currency',
            );

            // Property: File should contain all members
            for (final member in group.members) {
              expect(
                content.contains(member.displayName),
                isTrue,
                reason: 'Export should contain all member names',
              );
            }

            // Property: File should contain all expenses
            for (final expense in expenses) {
              expect(
                content.contains(expense.description),
                isTrue,
                reason: 'Export should contain all expense descriptions',
              );
              expect(
                content.contains(expense.amount.toString()),
                isTrue,
                reason: 'Export should contain all expense amounts',
              );
            }

            // Property: File should contain all payments
            for (final payment in payments) {
              expect(
                content.contains(payment.payerName),
                isTrue,
                reason: 'Export should contain all payment payer names',
              );
              expect(
                content.contains(payment.recipientName),
                isTrue,
                reason: 'Export should contain all payment recipient names',
              );
            }

            // Property: File should contain all balances
            for (final balance in balances) {
              expect(
                content.contains(balance.displayName),
                isTrue,
                reason: 'Export should contain all balance member names',
              );
            }

            // Clean up
            await exportService.deleteExportFile(result.filePath!);
          }
        }
      });

      test('PDF export contains all group data', () async {
        // **Feature: main-app-features, Property 32: Data export **
        // **includes complete information**

        for (var i = 0; i < 100; i++) {
          // Generate random test data
          final group = _generateRandomGroup();
          final expenses = _generateRandomExpenses(group);
          final payments = _generateRandomPayments(group);
          final balances = _generateRandomBalances(group);

          // Export to PDF
          final result = await exportService.exportToPDF(
            group: group,
            expenses: expenses,
            payments: payments,
            balances: balances,
          );

          // Property: Export should succeed
          expect(
            result.isSuccess,
            isTrue,
            reason: 'PDF export should always succeed with valid data',
          );

          if (result.isSuccess) {
            // Property: File should exist
            final file = File(result.filePath!);
            expect(
              file.existsSync(),
              isTrue,
              reason: 'Exported PDF file should exist',
            );

            // Property: File should contain comprehensive report
            final content = await file.readAsString();
            expect(
              content.contains('GREX EXPENSE REPORT'),
              isTrue,
              reason: 'PDF should contain report header',
            );
            expect(
              content.contains(group.name),
              isTrue,
              reason: 'PDF should contain group name',
            );
            expect(
              content.contains('SUMMARY'),
              isTrue,
              reason: 'PDF should contain summary section',
            );
            expect(
              content.contains('GROUP MEMBERS'),
              isTrue,
              reason: 'PDF should contain members section',
            );
            expect(
              content.contains('CURRENT BALANCES'),
              isTrue,
              reason: 'PDF should contain balances section',
            );

            // Clean up
            await exportService.deleteExportFile(result.filePath!);
          }
        }
      });
    });

    group('Property 33: Export sharing options are available', () {
      test('Export results provide sharing capabilities', () async {
        // **Feature: main-app-features, Property 33: Export sharing **
        // **options are available**

        for (var i = 0; i < 100; i++) {
          // Generate random test data
          final group = _generateRandomGroup();
          final expenses = _generateRandomExpenses(group);
          final payments = _generateRandomPayments(group);
          final balances = _generateRandomBalances(group);

          // Test both CSV and PDF exports
          final formats = [
            () => exportService.exportToCSV(
              group: group,
              expenses: expenses,
              payments: payments,
              balances: balances,
            ),
            () => exportService.exportToPDF(
              group: group,
              expenses: expenses,
              payments: payments,
              balances: balances,
            ),
          ];

          for (final exportFunction in formats) {
            final result = await exportFunction();

            // Property: Export should provide file path for sharing
            expect(
              result.isSuccess,
              isTrue,
              reason: 'Export should succeed to enable sharing',
            );

            if (result.isSuccess) {
              // Property: File path should be valid
              expect(
                result.filePath,
                isNotNull,
                reason: 'Export should provide file path for sharing',
              );
              expect(
                result.filePath!.isNotEmpty,
                isTrue,
                reason: 'File path should not be empty',
              );

              // Property: File name should be provided
              expect(
                result.fileName,
                isNotNull,
                reason: 'Export should provide file name for sharing',
              );
              expect(
                result.fileName!.isNotEmpty,
                isTrue,
                reason: 'File name should not be empty',
              );

              // Property: Format should be specified
              expect(
                result.format,
                isNotNull,
                reason: 'Export should specify format for sharing',
              );

              // Property: File should be accessible for sharing
              final file = File(result.filePath!);
              expect(
                file.existsSync(),
                isTrue,
                reason: 'File should exist and be accessible for sharing',
              );

              // Property: File should have content
              final stat = file.statSync();
              expect(
                stat.size,
                greaterThan(0),
                reason: 'File should have content for meaningful sharing',
              );

              // Clean up
              await exportService.deleteExportFile(result.filePath!);
            }
          }
        }
      });

      test('Export file cleanup works correctly', () async {
        // **Feature: main-app-features, Property 33: Export sharing **
        // **options are available**

        for (var i = 0; i < 50; i++) {
          // Generate test data
          final group = _generateRandomGroup();
          final expenses = _generateRandomExpenses(group);
          final payments = _generateRandomPayments(group);
          final balances = _generateRandomBalances(group);

          // Export file
          final result = await exportService.exportToCSV(
            group: group,
            expenses: expenses,
            payments: payments,
            balances: balances,
          );

          expect(result.isSuccess, isTrue);

          if (result.isSuccess) {
            final filePath = result.filePath!;

            // Property: File should exist before cleanup
            expect(
              File(filePath).existsSync(),
              isTrue,
              reason: 'File should exist before cleanup',
            );

            // Property: Cleanup should work without errors
            await expectLater(
              exportService.deleteExportFile(filePath),
              completes,
              reason: 'File cleanup should complete without errors',
            );

            // Property: File should not exist after cleanup
            expect(
              File(filePath).existsSync(),
              isFalse,
              reason: 'File should not exist after cleanup',
            );
          }
        }
      });
    });

    group('Export Progress Tracking', () {
      test('Progress callback is called with valid values', () async {
        for (var i = 0; i < 20; i++) {
          final group = _generateRandomGroup();
          final expenses = _generateRandomExpenses(group);
          final payments = _generateRandomPayments(group);
          final balances = _generateRandomBalances(group);

          final progressValues = <double>[];

          // Export with progress tracking
          final result = await exportService.exportToCSV(
            group: group,
            expenses: expenses,
            payments: payments,
            balances: balances,
            onProgress: progressValues.add,
          );

          expect(result.isSuccess, isTrue);

          // Property: Progress should be reported
          expect(
            progressValues.isNotEmpty,
            isTrue,
            reason: 'Progress should be reported during export',
          );

          // Property: Progress values should be between 0 and 1
          for (final progress in progressValues) {
            expect(
              progress,
              greaterThanOrEqualTo(0.0),
              reason: 'Progress should not be negative',
            );
            expect(
              progress,
              lessThanOrEqualTo(1.0),
              reason: 'Progress should not exceed 1.0',
            );
          }

          // Property: Progress should generally increase
          if (progressValues.length > 1) {
            final lastProgress = progressValues.last;
            expect(
              lastProgress,
              greaterThanOrEqualTo(0.8),
              reason: 'Final progress should be near completion',
            );
          }

          if (result.isSuccess) {
            await exportService.deleteExportFile(result.filePath!);
          }
        }
      });
    });
  });
}

// Helper functions to generate random test data
Group _generateRandomGroup() {
  final random = DateTime.now().millisecondsSinceEpoch % 1000;
  final currencies = ['VND', 'USD', 'EUR'];
  final currency = currencies[random % currencies.length];

  final members = List.generate(2 + (random % 5), (index) {
    return GroupMember(
      id: 'member-$index',
      userId: 'user-$index',
      displayName: 'Member $index',
      role: MemberRole.values[index % MemberRole.values.length],
      joinedAt: DateTime.now().subtract(Duration(days: random % 30)),
    );
  });

  return Group(
    id: 'group-$random',
    name: 'Test Group $random',
    currency: currency,
    creatorId: 'user-0',
    members: members,
    createdAt: DateTime.now().subtract(Duration(days: random % 100)),
    updatedAt: DateTime.now(),
  );
}

List<Expense> _generateRandomExpenses(Group group) {
  final random = DateTime.now().millisecondsSinceEpoch % 1000;
  final count = random % 10;

  return List.generate(count, (index) {
    final amount = 10000 + (random * index % 500000);
    final payer = group.members[index % group.members.length];

    final expenseDate = DateTime.now().subtract(Duration(days: index));
    return Expense(
      id: 'expense-$index',
      groupId: group.id,
      payerId: payer.userId,
      payerName: payer.displayName,
      amount: amount.toDouble(),
      currency: group.currency,
      description: 'Test Expense $index',
      category: index.isEven ? 'Food' : 'Transport',
      expenseDate: expenseDate,
      createdAt: expenseDate,
      updatedAt: expenseDate,
      participants: group.members
          .map(
            (member) => ExpenseParticipant(
              userId: member.userId,
              displayName: member.displayName,
              shareAmount: amount / group.members.length,
              sharePercentage: 100.0 / group.members.length,
            ),
          )
          .toList(),
    );
  });
}

List<Payment> _generateRandomPayments(Group group) {
  final random = DateTime.now().millisecondsSinceEpoch % 1000;
  final count = random % 8;

  return List.generate(count, (index) {
    final payer = group.members[index % group.members.length];
    final recipient = group.members[(index + 1) % group.members.length];
    final amount = 50000 + (random * index % 200000);

    return Payment(
      id: 'payment-$index',
      groupId: group.id,
      payerId: payer.userId,
      payerName: payer.displayName,
      recipientId: recipient.userId,
      recipientName: recipient.displayName,
      amount: amount.toDouble(),
      currency: group.currency,
      description: index.isEven ? 'Settlement payment' : null,
      paymentDate: DateTime.now().subtract(Duration(days: index)),
      createdAt: DateTime.now().subtract(Duration(days: index)),
    );
  });
}

List<Balance> _generateRandomBalances(Group group) {
  final random = DateTime.now().millisecondsSinceEpoch % 1000;

  return group.members.map((member) {
    final balance = (random % 1000000) - 500000; // Can be positive or negative

    return Balance(
      userId: member.userId,
      displayName: member.displayName,
      balance: balance.toDouble(),
      currency: group.currency,
    );
  }).toList();
}
