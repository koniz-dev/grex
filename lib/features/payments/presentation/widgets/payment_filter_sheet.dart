import 'package:flutter/material.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Bottom sheet for filtering and sorting payments
class PaymentFilterSheet extends StatefulWidget {
  /// Creates a [PaymentFilterSheet] instance
  const PaymentFilterSheet({
    required this.sortBy,
    required this.sortAscending,
    required this.groupCurrency,
    super.key,
    this.startDate,
    this.endDate,
    this.selectedPayer,
    this.selectedRecipient,
    this.minAmount,
    this.maxAmount,
  });

  /// The start date for filtering
  final DateTime? startDate;

  /// The end date for filtering
  final DateTime? endDate;

  /// The ID of the selected payer
  final String? selectedPayer;

  /// The ID of the selected recipient
  final String? selectedRecipient;

  /// The minimum payment amount
  final double? minAmount;

  /// The maximum payment amount
  final double? maxAmount;

  /// The criteria to sort by
  final PaymentSortCriteria sortBy;

  /// Whether to sort in ascending order
  final bool sortAscending;

  /// The currency of the group
  final String groupCurrency;

  @override
  State<PaymentFilterSheet> createState() => _PaymentFilterSheetState();
}

/// State class for PaymentFilterSheet
class _PaymentFilterSheetState extends State<PaymentFilterSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String? _selectedPayer;
  late String? _selectedRecipient;
  late double? _minAmount;
  late double? _maxAmount;
  late PaymentSortCriteria _sortBy;
  late bool _sortAscending;

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedPayer = widget.selectedPayer;
    _selectedRecipient = widget.selectedRecipient;
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
    final l10n = context.l10n;
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
                      l10n.filterAndSortPayments,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: Text(l10n.clearAll),
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
                    _buildSectionHeader(l10n.dateRange),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: l10n.startDate,
                            date: _startDate,
                            onTap: _selectStartDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: l10n.endDate,
                            date: _endDate,
                            onTap: _selectEndDate,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Amount range section
                    _buildSectionHeader(l10n.amountRange),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.minAmount,
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
                              labelText: l10n.maxAmount,
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
                    _buildSectionHeader(l10n.sortBy),
                    const SizedBox(height: 8),
                    RadioGroup<PaymentSortCriteria>(
                      groupValue: _sortBy,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                          });
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: PaymentSortCriteria.values.map((criteria) {
                          return RadioListTile<PaymentSortCriteria>(
                            title: Text(criteria.displayName),
                            value: criteria,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sort order
                    SwitchListTile(
                      title: Text(l10n.ascendingOrder),
                      subtitle: Text(
                        _sortAscending
                            ? l10n.oldestToNewest
                            : l10n.newestToOldest,
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
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: Text(l10n.apply),
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
    final l10n = context.l10n;
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
                      if (label == l10n.startDate) {
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
          date != null ? _formatDate(date) : l10n.selectDate,
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
      _selectedPayer = null;
      _selectedRecipient = null;
      _minAmount = null;
      _maxAmount = null;
      _sortBy = PaymentSortCriteria.date;
      _sortAscending = false;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    final l10n = context.l10n;
    // Validate amount range
    if (_minAmount != null && _minAmount! < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.minAmountNegative),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_maxAmount != null && _maxAmount! < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maxAmountNegative),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_minAmount != null && _maxAmount != null && _minAmount! > _maxAmount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.minGreaterThanMax),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate date range
    if (_startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startAfterEnd),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'startDate': _startDate,
      'endDate': _endDate,
      'selectedPayer': _selectedPayer,
      'selectedRecipient': _selectedRecipient,
      'minAmount': _minAmount,
      'maxAmount': _maxAmount,
      'sortBy': _sortBy,
      'sortAscending': _sortAscending,
    });
  }
}
