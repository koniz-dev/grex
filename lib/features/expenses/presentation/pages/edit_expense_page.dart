import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/split_method.dart';
import 'package:grex/features/expenses/domain/utils/expense_calculator.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/expenses/presentation/widgets/participant_selection_widget.dart';
import 'package:grex/features/expenses/presentation/widgets/split_configuration_widget.dart';
import 'package:grex/features/expenses/presentation/widgets/split_method_selector.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page for editing an existing expense with permission checks
/// and split recalculation.
class EditExpensePage extends StatefulWidget {
  /// Creates an [EditExpensePage] instance
  const EditExpensePage({
    required this.expenseId,
    required this.groupId,
    this.expense,
    super.key,
  });

  /// The expense entity if already loaded
  final Expense? expense;

  /// The ID of the expense to edit
  final String expenseId;

  /// The ID of the group the expense belongs to
  final String groupId;

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

/// State class for EditExpensePage
class _EditExpensePageState extends State<EditExpensePage> {
  late final ExpenseBloc _expenseBloc;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;

  // Form state
  late DateTime _expenseDate;
  late String _selectedCurrency;
  late SplitMethod _splitMethod;
  late List<Map<String, dynamic>> _selectedParticipants;
  late List<Map<String, dynamic>> _participantSplitData;

  // UI state
  bool _isLoading = false;
  String? _splitValidationError;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _expenseBloc = getIt<ExpenseBloc>();

    if (widget.expense != null) {
      _initializeFormData();
    } else {
      // Load expense details first
      _expenseBloc.add(ExpenseLoadRequested(expenseId: widget.expenseId));
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    unawaited(_expenseBloc.close());
    super.dispose();
  }

  void _initializeFormData() {
    final expense = widget.expense ?? _getExpenseFromState();
    if (expense == null) return;

    // Initialize controllers with current expense data
    _descriptionController = TextEditingController(text: expense.description);
    _amountController = TextEditingController(text: expense.amount.toString());
    _categoryController = TextEditingController(text: expense.category ?? '');

    // Initialize form state
    _expenseDate = expense.expenseDate;
    _selectedCurrency = expense.currency;
    _splitMethod =
        SplitMethod.equal; // Default, will be determined from participants

    // Initialize participants
    _selectedParticipants = expense.participants
        .map(
          (participant) => {
            'userId': participant.userId,
            'displayName': participant.displayName,
          },
        )
        .toList();

    // Initialize split data based on current participants
    _participantSplitData = expense.participants
        .map(
          (participant) => {
            'userId': participant.userId,
            'displayName': participant.displayName,
            'amount': participant.shareAmount,
            'percentage': participant.sharePercentage,
            'shares': 1, // Default shares
          },
        )
        .toList();

    // Determine split method from current data
    _splitMethod = _determineSplitMethod(expense);

    // Add listeners to detect changes
    _descriptionController.addListener(_onFormChanged);
    _amountController.addListener(_onFormChanged);
    _categoryController.addListener(_onFormChanged);
  }

  Expense? _getExpenseFromState() {
    final state = _expenseBloc.state;
    if (state is ExpenseDetailLoaded) {
      return state.expense;
    }
    return null;
  }

  SplitMethod _determineSplitMethod(Expense expense) {
    // Check if it's an equal split
    final equalSplit = ExpenseCalculator.splitEqually(
      totalAmount: expense.amount,
      participantIds: expense.participants.map((p) => p.userId).toList(),
    );

    var isEqual = true;
    for (final participant in expense.participants) {
      final expectedAmount = equalSplit[participant.userId] ?? 0.0;
      if ((participant.shareAmount - expectedAmount).abs() > 0.01) {
        isEqual = false;
        break;
      }
    }

    if (isEqual) {
      return SplitMethod.equal;
    }

    // For now, default to exact amounts for non-equal splits
    // In a real app, you might want to store the split method with the expense
    return SplitMethod.exact;
  }

  void _onFormChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _expenseBloc,
      child: PopScope(
        canPop: !_hasChanges,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Edit Expense'),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _saveExpense,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: BlocListener<ExpenseBloc, ExpenseState>(
            listener: (context, state) {
              if (state is ExpenseLoading) {
                setState(() {
                  _isLoading = true;
                });
              } else {
                setState(() {
                  _isLoading = false;
                });
              }

              // Initialize form when expense is loaded
              if (widget.expense == null && state is ExpenseDetailLoaded) {
                _initializeFormData();
              }

              if (state is ExpenseOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense updated successfully'),
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
                // Show loading if expense is not provided and not yet loaded
                if (widget.expense == null && state is! ExpenseDetailLoaded) {
                  if (state is ExpenseLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ExpenseError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${state.message}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _expenseBloc.add(
                              ExpenseLoadRequested(expenseId: widget.expenseId),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                }

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Warning about changes
                      if (_hasChanges)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You have unsaved changes. '
                                  'Make sure to save before leaving.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Basic expense information
                      _buildBasicInfoSection(),

                      const SizedBox(height: 24),

                      // Participant selection
                      _buildParticipantSection(),

                      const SizedBox(height: 24),

                      // Split method selection
                      _buildSplitMethodSection(),

                      const SizedBox(height: 24),

                      // Split configuration
                      if (_selectedParticipants.isNotEmpty)
                        _buildSplitConfigurationSection(),

                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveExpense,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Update Expense'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'What was this expense for?',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                if (value.trim().length < 3) {
                  return 'Description must be at least 3 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // Amount and currency row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount *',
                      prefixText: CurrencyFormatter.getCurrencySymbol(
                        _selectedCurrency,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid positive amount';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _updateSplitCalculation();
                      _onFormChanged();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: CurrencyFormatter.getSupportedCurrencies()
                        .map(
                          (currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(
                              '$currency ${CurrencyFormatter.getCurrencySymbol(
                                currency,
                              )}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                        _updateSplitCalculation();
                        _onFormChanged();
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Category field (optional)
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (Optional)',
                hintText: 'e.g., Food, Transport, Entertainment',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _selectExpenseDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_formatDate(_expenseDate)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who participated?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<GroupBloc, GroupState>(
              builder: (context, state) {
                var members = <GroupMember>[];
                if (state is GroupsLoaded) {
                  final group = state.getGroupById(widget.groupId);
                  if (group != null) {
                    members = group.members;
                  }
                }

                if (state is GroupLoading && members.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ParticipantSelectionWidget(
                  groupMembers: members,
                  selectedParticipants: _selectedParticipants,
                  onSelectionChanged: (participants) {
                    setState(() {
                      _selectedParticipants = participants;
                    });
                    _updateSplitCalculation();
                    _onFormChanged();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to split?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SplitMethodSelector(
              selectedMethod: _splitMethod,
              onMethodChanged: (method) {
                setState(() {
                  _splitMethod = method;
                });
                _updateSplitCalculation();
                _onFormChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SplitConfigurationWidget(
              splitMethod: _splitMethod,
              participants: _selectedParticipants,
              totalAmount: double.tryParse(_amountController.text) ?? 0.0,
              currency: _selectedCurrency,
              onConfigurationChanged: (splitData) {
                setState(() {
                  _participantSplitData = splitData;
                  _splitValidationError = null;
                });
                _validateSplit();
                _onFormChanged();
              },
            ),
            if (_splitValidationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _splitValidationError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpenseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _expenseDate = date;
      });
      _onFormChanged();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _updateSplitCalculation() {
    if (_selectedParticipants.isEmpty || _amountController.text.isEmpty) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      return;
    }

    // Generate default split data based on method
    final defaultSplitData = _selectedParticipants.map((participant) {
      return ExpenseCalculator.getDefaultParticipantData(
        splitMethod: _splitMethod,
        userId: participant['userId'] as String,
        displayName: participant['displayName'] as String,
        participantCount: _selectedParticipants.length,
      );
    }).toList();

    setState(() {
      _participantSplitData = defaultSplitData;
    });

    _validateSplit();
  }

  void _validateSplit() {
    if (_participantSplitData.isEmpty || _amountController.text.isEmpty) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      return;
    }

    final validationError = ExpenseCalculator.validateSplitConfiguration(
      totalAmount: amount,
      splitMethod: _splitMethod,
      participantData: _participantSplitData,
    );

    setState(() {
      _splitValidationError = validationError;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to '
          'leave without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one participant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_splitValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Split configuration error: $_splitValidationError'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);

    // Calculate final split
    final participants = ExpenseCalculator.calculateSplit(
      totalAmount: amount,
      splitMethod: _splitMethod,
      participantData: _participantSplitData,
    );

    // Get current expense
    final currentExpense = widget.expense ?? _getExpenseFromState();
    if (currentExpense == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Expense not loaded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create updated expense
    final updatedExpense = currentExpense.copyWith(
      description: _descriptionController.text.trim(),
      amount: amount,
      currency: _selectedCurrency,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      expenseDate: _expenseDate,
      participants: participants,
      updatedAt: DateTime.now(),
    );

    _expenseBloc.add(
      ExpenseUpdateRequested(
        expenseId: widget.expenseId,
        description: updatedExpense.description,
        amount: updatedExpense.amount,
        currency: updatedExpense.currency,
        category: updatedExpense.category,
        expenseDate: updatedExpense.expenseDate,
        splitMethod: _splitMethod,
        participants: updatedExpense.participants,
      ),
    );
  }
}
