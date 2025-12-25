import 'dart:io';

import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/shared/utils/currency_formatter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for exporting group data to various formats
class ExportService {
  /// Export group data to CSV format
  Future<ExportResult> exportToCSV({
    required Group group,
    required List<Expense> expenses,
    required List<Payment> payments,
    required List<Balance> balances,
    void Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);

      final csvContent = _generateCSVContent(
        group: group,
        expenses: expenses,
        payments: payments,
        balances: balances,
        onProgress: onProgress,
      );

      onProgress?.call(0.8);

      final file = await _saveToFile(
        content: csvContent,
        fileName: '${group.name}_export.csv',
        mimeType: 'text/csv',
      );

      onProgress?.call(1);

      return ExportResult.success(
        filePath: file.path,
        fileName: '${group.name}_export.csv',
        format: ExportFormat.csv,
      );
    } on Exception catch (e) {
      return ExportResult.error('Failed to export CSV: $e');
    }
  }

  /// Export group data to PDF format (simplified text-based PDF)
  Future<ExportResult> exportToPDF({
    required Group group,
    required List<Expense> expenses,
    required List<Payment> payments,
    required List<Balance> balances,
    void Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);

      // For simplicity, we'll create a text-based report
      // In a real app, you'd use a PDF library like pdf package
      final pdfContent = _generatePDFContent(
        group: group,
        expenses: expenses,
        payments: payments,
        balances: balances,
        onProgress: onProgress,
      );

      onProgress?.call(0.8);

      final file = await _saveToFile(
        content: pdfContent,
        fileName: '${group.name}_report.txt',
        mimeType: 'text/plain',
      );

      onProgress?.call(1);

      return ExportResult.success(
        filePath: file.path,
        fileName: '${group.name}_report.txt',
        format: ExportFormat.pdf,
      );
    } on Exception catch (e) {
      return ExportResult.error('Failed to export PDF: $e');
    }
  }

  /// Share exported file
  Future<void> shareFile(String filePath, String fileName) async {
    final xFile = XFile(filePath);
    await Share.shareXFiles(
      [xFile],
      text: 'Grex Export: $fileName',
      subject: 'Group Expense Report',
    );
  }

  /// Delete temporary export file
  Future<void> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } on Exception catch (_) {
      // Ignore deletion errors
    }
  }

  String _generateCSVContent({
    required Group group,
    required List<Expense> expenses,
    required List<Payment> payments,
    required List<Balance> balances,
    void Function(double)? onProgress,
  }) {
    final buffer = StringBuffer()
      ..writeln('Grex Export - ${group.name}')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Currency: ${group.currency}')
      ..writeln();

    onProgress?.call(0.2);

    // Group Members
    buffer
      ..writeln('GROUP MEMBERS')
      ..writeln('Name,Role,Joined Date');
    for (final member in group.members) {
      buffer.writeln(
        '${_escapeCsv(member.displayName)},'
        '${member.role.displayName},'
        '${member.joinedAt.toIso8601String()}',
      );
    }
    buffer.writeln();

    onProgress?.call(0.4);

    // Expenses
    buffer
      ..writeln('EXPENSES')
      ..writeln(
        'Date,Description,Amount,Currency,Payer,Category,Participants',
      );
    for (final expense in expenses) {
      final participantNames = expense.participants
          .map((p) => p.displayName)
          .join(';');
      buffer.writeln(
        '${expense.expenseDate.toIso8601String()},'
        '${_escapeCsv(expense.description)},${expense.amount},'
        '${expense.currency},${_escapeCsv(expense.payerName)},'
        '${_escapeCsv(expense.category ?? '')},'
        '${_escapeCsv(participantNames)}',
      );
    }
    buffer.writeln();

    onProgress?.call(0.6);

    // Payments
    buffer
      ..writeln('PAYMENTS')
      ..writeln('Date,Payer,Recipient,Amount,Currency,Description');
    for (final payment in payments) {
      buffer.writeln(
        '${payment.paymentDate.toIso8601String()},'
        '${_escapeCsv(payment.payerName)},'
        '${_escapeCsv(payment.recipientName)},${payment.amount},'
        '${payment.currency},'
        '${_escapeCsv(payment.description ?? '')}',
      );
    }
    buffer.writeln();

    onProgress?.call(0.7);

    // Balances
    buffer
      ..writeln('BALANCES')
      ..writeln('Member,Balance,Currency,Status');
    for (final balance in balances) {
      buffer.writeln(
        '${_escapeCsv(balance.displayName)},${balance.balance},'
        '${balance.currency},${balance.balanceStatusText}',
      );
    }

    return buffer.toString();
  }

  String _generatePDFContent({
    required Group group,
    required List<Expense> expenses,
    required List<Payment> payments,
    required List<Balance> balances,
    void Function(double)? onProgress,
  }) {
    final buffer = StringBuffer()
      ..writeln('=' * 60)
      ..writeln('GREX EXPENSE REPORT')
      ..writeln('=' * 60)
      ..writeln()
      ..writeln('Group: ${group.name}')
      ..writeln('Currency: ${group.currency}')
      ..writeln('Generated: ${_formatDateTime(DateTime.now())}')
      ..writeln('Members: ${group.members.length}')
      ..writeln();

    onProgress?.call(0.2);

    // Summary
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalPayments = payments.fold<double>(0, (sum, p) => sum + p.amount);

    buffer
      ..writeln('-' * 40)
      ..writeln('SUMMARY')
      ..writeln('-' * 40)
      ..writeln(
        'Total Expenses: ${CurrencyFormatter.format(
          amount: totalExpenses,
          currencyCode: group.currency,
        )}',
      )
      ..writeln(
        'Total Payments: ${CurrencyFormatter.format(
          amount: totalPayments,
          currencyCode: group.currency,
        )}',
      )
      ..writeln('Number of Expenses: ${expenses.length}')
      ..writeln('Number of Payments: ${payments.length}')
      ..writeln();

    onProgress?.call(0.3);

    // Group Members
    buffer
      ..writeln('-' * 40)
      ..writeln('GROUP MEMBERS')
      ..writeln('-' * 40);
    for (final member in group.members) {
      buffer
        ..writeln('• ${member.displayName} (${member.role.displayName})')
        ..writeln('  Joined: ${_formatDateTime(member.joinedAt)}');
    }
    buffer.writeln();

    onProgress?.call(0.5);

    // Balances
    buffer
      ..writeln('-' * 40)
      ..writeln('CURRENT BALANCES')
      ..writeln('-' * 40);
    for (final balance in balances) {
      final status = balance.isSettled
          ? 'SETTLED'
          : balance.owesMoneyToGroup
          ? 'OWES'
          : 'OWED';
      buffer.writeln(
        '• ${balance.displayName}: ${CurrencyFormatter.format(
          amount: balance.absoluteBalance,
          currencyCode: balance.currency,
        )} ($status)',
      );
    }
    buffer.writeln();

    onProgress?.call(0.6);

    // Recent Expenses
    buffer
      ..writeln('-' * 40)
      ..writeln('EXPENSES (${expenses.length} total)')
      ..writeln('-' * 40);
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    for (final expense in sortedExpenses.take(20)) {
      // Show last 20 expenses
      buffer
        ..writeln(_formatDateTime(expense.expenseDate))
        ..writeln('  ${expense.description}')
        ..writeln(
          '  Amount: ${CurrencyFormatter.format(
            amount: expense.amount,
            currencyCode: expense.currency,
          )}',
        )
        ..writeln('  Paid by: ${expense.payerName}');
      if (expense.category?.isNotEmpty ?? false) {
        buffer.writeln('  Category: ${expense.category}');
      }
      buffer
        ..writeln(
          '  Participants: '
          '${expense.participants.map((p) => p.displayName).join(', ')}',
        )
        ..writeln();
    }

    onProgress?.call(0.8);

    // Recent Payments
    buffer
      ..writeln('-' * 40)
      ..writeln('PAYMENTS (${payments.length} total)')
      ..writeln('-' * 40);
    final sortedPayments = List<Payment>.from(payments)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    for (final payment in sortedPayments.take(20)) {
      // Show last 20 payments
      buffer
        ..writeln(_formatDateTime(payment.paymentDate))
        ..writeln('  ${payment.payerName} → ${payment.recipientName}')
        ..writeln(
          '  Amount: ${CurrencyFormatter.format(
            amount: payment.amount,
            currencyCode: payment.currency,
          )}',
        );
      if (payment.description?.isNotEmpty ?? false) {
        buffer.writeln('  Note: ${payment.description}');
      }
      buffer.writeln();
    }

    // Footer
    buffer
      ..writeln('=' * 60)
      ..writeln('End of Report')
      ..writeln('Generated by Grex - Expense Sharing App')
      ..writeln('=' * 60);

    return buffer.toString();
  }

  Future<File> _saveToFile({
    required String content,
    required String fileName,
    required String mimeType,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Result of an export operation
class ExportResult {
  const ExportResult._({
    required this.isSuccess,
    this.filePath,
    this.fileName,
    this.format,
    this.errorMessage,
  });

  /// Creates a successful export result
  factory ExportResult.success({
    required String filePath,
    required String fileName,
    required ExportFormat format,
  }) {
    return ExportResult._(
      isSuccess: true,
      filePath: filePath,
      fileName: fileName,
      format: format,
    );
  }

  /// Creates an error export result
  factory ExportResult.error(String message) {
    return ExportResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  /// Whether the operation was successful
  final bool isSuccess;

  /// Path to the exported file
  final String? filePath;

  /// Name of the exported file
  final String? fileName;

  /// Format of the exported file
  final ExportFormat? format;

  /// Error message if the operation failed
  final String? errorMessage;
}

/// Supported export formats
enum ExportFormat {
  /// Comma-separated values format
  csv,

  /// Portable Document Format (simplified text)
  pdf;

  /// Display name for the format
  String get displayName {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.pdf:
        return 'PDF';
    }
  }

  /// File extension for the format
  String get fileExtension {
    switch (this) {
      case ExportFormat.csv:
        return '.csv';
      case ExportFormat.pdf:
        return '.txt'; // Simplified for now
    }
  }

  /// MIME type for the format
  String get mimeType {
    switch (this) {
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.pdf:
        return 'text/plain'; // Simplified for now
    }
  }
}
