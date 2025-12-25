import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/expenses/presentation/pages/edit_expense_page.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_actions_widget.dart';
import 'package:grex/features/expenses/presentation/widgets/expense_participant_list.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page displaying detailed information about a specific expense
class ExpenseDetailsPage extends StatefulWidget {
  /// Creates an [ExpenseDetailsPage] instance
  const ExpenseDetailsPage({
    required this.expenseId,
    required this.groupId,
    super.key,
  });

  /// The ID of the expense to display
  final String expenseId;

  /// The ID of the group the expense belongs to
  final String groupId;

  @override
  State<ExpenseDetailsPage> createState() => _ExpenseDetailsPageState();
}

/// State class for ExpenseDetailsPage
class _ExpenseDetailsPageState extends State<ExpenseDetailsPage> {
  late final ExpenseBloc _expenseBloc;

  @override
  void initState() {
    super.initState();
    _expenseBloc = getIt<ExpenseBloc>();
    _loadExpenseDetails();
  }

  @override
  void dispose() {
    unawaited(_expenseBloc.close());
    super.dispose();
  }

  void _loadExpenseDetails() {
    _expenseBloc.add(ExpenseLoadRequested(expenseId: widget.expenseId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _expenseBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expense Details'),
          actions: [
            BlocBuilder<ExpenseBloc, ExpenseState>(
              builder: (context, state) {
                if (state is ExpenseDetailLoaded) {
                  return PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(value, state.expense),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit Expense'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Delete Expense',
                            style: TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocListener<ExpenseBloc, ExpenseState>(
          listener: (context, state) {
            if (state is ExpenseOperationSuccess &&
                state.message.contains('deleted')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            }

            if (state is ExpenseError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          child: BlocBuilder<ExpenseBloc, ExpenseState>(
            builder: (context, state) {
              if (state is ExpenseLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is ExpenseError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading expense',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadExpenseDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is ExpenseDetailLoaded) {
                return RefreshIndicator(
                  onRefresh: () async {
                    _loadExpenseDetails();
                  },
                  child: _buildExpenseDetails(state.expense),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseDetails(Expense expense) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main expense info card
        _buildMainInfoCard(expense),

        const SizedBox(height: 16),

        // Participants card
        _buildParticipantsCard(expense),

        const SizedBox(height: 16),

        // Actions card
        _buildActionsCard(expense),

        const SizedBox(height: 16),

        // Metadata card
        _buildMetadataCard(expense),
      ],
    );
  }

  Widget _buildMainInfoCard(Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount - prominent display
            Center(
              child: Column(
                children: [
                  Text(
                    CurrencyFormatter.format(
                      amount: expense.amount,
                      currencyCode: expense.currency,
                    ),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: expense.isValidSplit
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          expense.isValidSplit
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 16,
                          color: expense.isValidSplit
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expense.isValidSplit
                              ? 'Valid Split'
                              : 'Invalid Split',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: expense.isValidSplit
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              expense.description,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            if (expense.category != null) ...[
              const SizedBox(height: 16),
              Text(
                'Category',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  expense.category!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Payer info
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  'Paid by ${expense.payerName}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date info
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(expense.expenseDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsCard(Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Participants (${expense.participantCount})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ExpenseParticipantList(
              expense: expense,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ExpenseActionsWidget(
              expense: expense,
              onEditPressed: () => _navigateToEditExpense(expense),
              onDeletePressed: () => _confirmDeleteExpense(expense),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetadataRow('Created', _formatDateTime(expense.createdAt)),
            const SizedBox(height: 8),
            _buildMetadataRow(
              'Last Updated',
              _formatDateTime(expense.updatedAt),
            ),
            const SizedBox(height: 8),
            _buildMetadataRow('Expense ID', expense.id),
            if (!expense.isValidSplit) ...[
              const SizedBox(height: 8),
              _buildMetadataRow(
                'Split Total',
                CurrencyFormatter.format(
                  amount: expense.totalParticipantShares,
                  currencyCode: expense.currency,
                ),
                isError: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isError ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return 'Today';
    } else if (expenseDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final timeStr =
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  void _handleMenuAction(String action, Expense expense) {
    switch (action) {
      case 'edit':
        _navigateToEditExpense(expense);
      case 'delete':
        _confirmDeleteExpense(expense);
    }
  }

  void _navigateToEditExpense(Expense expense) {
    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (context) => EditExpensePage(
                expenseId: expense.id,
                groupId: widget.groupId,
              ),
            ),
          )
          .then((_) {
            // Refresh expense details after editing
            _loadExpenseDetails();
          }),
    );
  }

  void _confirmDeleteExpense(Expense expense) {
    unawaited(
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete "${expense.description}"?'
            ' This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed ?? false) {
          _expenseBloc.add(ExpenseDeleteRequested(expenseId: expense.id));
        }
      }),
    );
  }
}
