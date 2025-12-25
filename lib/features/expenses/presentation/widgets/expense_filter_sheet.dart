import 'package:flutter/material.dart';
import 'package:grex/features/expenses/domain/utils/expense_search_filter.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Bottom sheet for filtering and sorting expenses
class ExpenseFilterSheet extends StatefulWidget {
  /// Creates an [ExpenseFilterSheet] instance
  const ExpenseFilterSheet({
    required this.sortBy,
    required this.sortAscending,
    required this.groupCurrency,
    super.key,
    this.startDate,
    this.endDate,
    this.selectedParticipant,
    this.minAmount,
    this.maxAmount,
  });

  /// The start date for the date range filter
  final DateTime? startDate;

  /// The end date for the date range filter
  final DateTime? endDate;

  /// The participant ID to filter by
  final String? selectedParticipant;

  /// The minimum amount for the amount range filter
  final double? minAmount;

  /// The maximum amount for the amount range filter
  final double? maxAmount;

  /// The current sorting criteria
  final ExpenseSortCriteria sortBy;

  /// Whether sorting is in ascending order
  final bool sortAscending;

  /// The functional currency of the group
  final String groupCurrency;

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String? _selectedParticipant;
  late double? _minAmount;
  late double? _maxAmount;
  late ExpenseSortCriteria _sortBy;
  late bool _sortAscending;

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedParticipant = widget.selectedParticipant;
    _minAmount = widget.minAmount;
    _maxAmount = widget.maxAmount;
    _sortBy = widget.sortBy;
    _sortAscending = widget.sortAscending;

    if (_minAmount != null) {
      _minAmountController.text = CurrencyFormatter.formatForInput(
        amount: _minAmount!,
        currencyCode: widget.groupCurrency,
      );
    }
    if (_maxAmount != null) {
      _maxAmountController.text = CurrencyFormatter.formatForInput(
        amount: _maxAmount!,
        currencyCode: widget.groupCurrency,
      );
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Filter & Sort',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Date range section
                    _buildSectionHeader('Date Range'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Start Date',
                            date: _startDate,
                            onTap: _selectStartDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: 'End Date',
                            date: _endDate,
                            onTap: _selectEndDate,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Amount range section
                    _buildSectionHeader('Amount Range'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min Amount',
                              prefixText: CurrencyFormatter.getCurrencySymbol(
                                widget.groupCurrency,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _minAmount = double.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max Amount',
                              prefixText: CurrencyFormatter.getCurrencySymbol(
                                widget.groupCurrency,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _maxAmount = double.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sort section
                    _buildSectionHeader('Sort By'),
                    const SizedBox(height: 8),
                    RadioGroup<ExpenseSortCriteria>(
                      groupValue: _sortBy,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                          });
                        }
                      },
                      child: Column(
                        children: ExpenseSortCriteria.values.map((criteria) {
                          return RadioListTile<ExpenseSortCriteria>(
                            title: Text(criteria.displayName),
                            value: criteria,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sort order
                    SwitchListTile(
                      title: const Text('Ascending Order'),
                      subtitle: Text(
                        _sortAscending
                            ? 'Oldest to newest'
                            : 'Newest to oldest',
                      ),
                      value: _sortAscending,
                      onChanged: (value) {
                        setState(() {
                          _sortAscending = value;
                        });
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      if (label == 'Start Date') {
                        _startDate = null;
                      } else {
                        _endDate = null;
                      }
                    });
                  },
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? _formatDate(date) : 'Select date',
          style: TextStyle(
            color: date != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        // Ensure start date is not after end date
        if (_endDate != null && date.isAfter(_endDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedParticipant = null;
      _minAmount = null;
      _maxAmount = null;
      _sortBy = ExpenseSortCriteria.date;
      _sortAscending = false;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    // Validate amount range
    final validationError = ExpenseSearchFilter.validateFilterParameters(
      startDate: _startDate,
      endDate: _endDate,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
    );

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'startDate': _startDate,
      'endDate': _endDate,
      'selectedParticipant': _selectedParticipant,
      'minAmount': _minAmount,
      'maxAmount': _maxAmount,
      'sortBy': _sortBy,
      'sortAscending': _sortAscending,
    });
  }
}
