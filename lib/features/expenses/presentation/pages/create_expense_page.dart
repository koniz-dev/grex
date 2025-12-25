import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/expenses/domain/entities/split_method.dart';
import 'package:grex/features/expenses/domain/utils/expense_calculator.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_event.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/expenses/presentation/widgets/participant_selection_widget.dart';
import 'package:grex/features/expenses/presentation/widgets/split_configuration_widget.dart';
import 'package:grex/features/expenses/presentation/widgets/split_method_selector.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page for creating a new expense with form validation and split configuration
class CreateExpensePage extends StatefulWidget {
  /// Creates a [CreateExpensePage] instance
  const CreateExpensePage({
    required this.groupId,
    required this.groupCurrency,
    super.key,
  });

  /// The ID of the group where the expense is created
  final String groupId;

  /// The functional currency of the group
  final String groupCurrency;

  @override
  State<CreateExpensePage> createState() => _CreateExpensePageState();
}

class _CreateExpensePageState extends State<CreateExpensePage> {
  late final ExpenseBloc _expenseBloc;
  late final GroupBloc _groupBloc;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Form state
  DateTime _expenseDate = DateTime.now();
  String _selectedCurrency = '';
  SplitMethod _splitMethod = SplitMethod.equal;
  List<Map<String, dynamic>> _selectedParticipants = [];
  List<Map<String, dynamic>> _participantSplitData = [];

  // UI state
  bool _isLoading = false;
  String? _splitValidationError;

  @override
  void initState() {
    super.initState();
    _expenseBloc = getIt<ExpenseBloc>();
    _groupBloc = getIt<GroupBloc>();
    _selectedCurrency = widget.groupCurrency;

    // Load groups to get group members
    _groupBloc.add(const GroupsLoadRequested());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    unawaited(_expenseBloc.close());
    unawaited(_groupBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _expenseBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Expense'),
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

            if (state is ExpenseOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense created successfully'),
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                        : const Text('Create Expense'),
                  ),
                ),
              ],
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
              builder: (context, groupState) {
                if (groupState is GroupsLoaded) {
                  final group = groupState.getGroupById(widget.groupId);
                  if (group != null) {
                    return ParticipantSelectionWidget(
                      groupMembers: group.members,
                      selectedParticipants: _selectedParticipants,
                      onSelectionChanged: (participants) {
                        setState(() {
                          _selectedParticipants = participants;
                        });
                        _updateSplitCalculation();
                      },
                    );
                  }
                }

                if (groupState is GroupError) {
                  return Text(
                    'Error loading group members: '
                    '${groupState.userFriendlyMessage}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
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

    _expenseBloc.add(
      ExpenseCreateRequested(
        groupId: widget.groupId,
        description: _descriptionController.text.trim(),
        amount: amount,
        currency: _selectedCurrency,
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        expenseDate: _expenseDate,
        splitMethod: _splitMethod,
        participants: participants,
      ),
    );
  }
}
