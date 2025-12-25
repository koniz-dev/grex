import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/core/services/export_service.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/presentation/bloc/balance_bloc.dart';
import 'package:grex/features/balances/presentation/bloc/balance_state.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/export/presentation/widgets/export_format_selector.dart';
import 'package:grex/features/export/presentation/widgets/export_progress_dialog.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';

/// Page for exporting group data to various formats
class ExportPage extends StatefulWidget {
  /// Creates an [ExportPage] instance
  const ExportPage({
    required this.groupId,
    required this.groupName,
    super.key,
  });

  /// The unique identifier of the group for which data will be exported
  final String groupId;

  /// The display name of the group for which data will be exported
  final String groupName;

  @override
  State<ExportPage> createState() => _ExportPageState();
}

/// State class for ExportPage
class _ExportPageState extends State<ExportPage> {
  /// The service used to handle data export operations
  late final ExportService _exportService;
  late final GroupBloc _groupBloc;
  late final ExpenseBloc _expenseBloc;
  late final PaymentBloc _paymentBloc;
  late final BalanceBloc _balanceBloc;

  ExportFormat _selectedFormat = ExportFormat.csv;
  bool _isExporting = false;
  double _exportProgress = 0;

  @override
  void initState() {
    super.initState();
    _exportService = getIt<ExportService>();
    _groupBloc = getIt<GroupBloc>();
    _expenseBloc = getIt<ExpenseBloc>();
    _paymentBloc = getIt<PaymentBloc>();
    _balanceBloc = getIt<BalanceBloc>();
  }

  @override
  void dispose() {
    unawaited(_groupBloc.close());
    unawaited(_expenseBloc.close());
    unawaited(_paymentBloc.close());
    unawaited(_balanceBloc.close());
    super.dispose();
  }

  Future<void> _startExport() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    try {
      // Show progress dialog
      if (mounted) {
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => ExportProgressDialog(
              format: _selectedFormat,
              progress: _exportProgress,
              onCancel: _cancelExport,
            ),
          ),
        );
      }

      // Gather all data
      final group = await _getGroupData();
      final expenses = await _getExpenseData();
      final payments = await _getPaymentData();
      final balances = await _getBalanceData();

      if (group == null) {
        throw Exception('Failed to load group data');
      }

      // Perform export
      final ExportResult result;
      switch (_selectedFormat) {
        case ExportFormat.csv:
          result = await _exportService.exportToCSV(
            group: group,
            expenses: expenses,
            payments: payments,
            balances: balances,
            onProgress: (progress) {
              setState(() {
                _exportProgress = progress;
              });
            },
          );
        case ExportFormat.pdf:
          result = await _exportService.exportToPDF(
            group: group,
            expenses: expenses,
            payments: payments,
            balances: balances,
            onProgress: (progress) {
              setState(() {
                _exportProgress = progress;
              });
            },
          );
      }

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.isSuccess) {
        await _showExportSuccess(result);
      } else {
        await _showExportError(result.errorMessage ?? 'Export failed');
      }
    } on Exception catch (e) {
      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      await _showExportError(e.toString());
    } finally {
      setState(() {
        _isExporting = false;
        _exportProgress = 0.0;
      });
    }
  }

  void _cancelExport() {
    setState(() {
      _isExporting = false;
      _exportProgress = 0.0;
    });
    Navigator.of(context).pop(); // Close progress dialog
  }

  Future<Group?> _getGroupData() async {
    final groupState = _groupBloc.state;
    if (groupState is GroupsLoaded) {
      return groupState.getGroupById(widget.groupId);
    }
    return null;
  }

  Future<List<Expense>> _getExpenseData() async {
    final expenseState = _expenseBloc.state;
    if (expenseState is ExpensesLoaded) {
      return expenseState.filteredExpenses;
    }
    return [];
  }

  Future<List<Payment>> _getPaymentData() async {
    final paymentState = _paymentBloc.state;
    if (paymentState is PaymentsLoaded) {
      return paymentState.filteredPayments;
    }
    return [];
  }

  Future<List<Balance>> _getBalanceData() async {
    final balanceState = _balanceBloc.state;
    if (balanceState is BalancesLoaded) {
      return balanceState.balances;
    }
    return [];
  }

  Future<void> _showExportSuccess(ExportResult result) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            SizedBox(width: 12),
            Text('Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your ${result.format!.displayName} export is ready!'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File: ${result.fileName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Format: ${result.format!.displayName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportService.shareFile(
                result.filePath!,
                result.fileName!,
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportError(String error) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Export Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Failed to export group data.'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(_startExport()); // Retry
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _groupBloc),
        BlocProvider.value(value: _expenseBloc),
        BlocProvider.value(value: _paymentBloc),
        BlocProvider.value(value: _balanceBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text('Export ${widget.groupName}'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.download,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Export Group Data',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Export all group information including members, '
                        'expenses, payments, and balances.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Format selection
              Text(
                'Export Format',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ExportFormatSelector(
                selectedFormat: _selectedFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _selectedFormat = format;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Data preview
              Text(
                'What will be exported',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildDataPreview(),

              const Spacer(),

              // Export button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _startExport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Exported files can be shared via email, messaging '
                        'apps, or saved to your device.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPreviewItem(
              icon: Icons.group,
              title: 'Group Information',
              description: 'Name, currency, members, and roles',
            ),
            const Divider(),
            _buildPreviewItem(
              icon: Icons.receipt_long,
              title: 'Expenses',
              description: 'All expenses with details and participants',
            ),
            const Divider(),
            _buildPreviewItem(
              icon: Icons.payment,
              title: 'Payments',
              description: 'Payment history between members',
            ),
            const Divider(),
            _buildPreviewItem(
              icon: Icons.account_balance_wallet,
              title: 'Balances',
              description: 'Current balance status for each member',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        ),
      ],
    );
  }
}
