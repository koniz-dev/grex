import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page for creating a new payment with form validation
class CreatePaymentPage extends StatefulWidget {
  /// Creates a [CreatePaymentPage] instance
  const CreatePaymentPage({
    required this.groupId,
    required this.groupCurrency,
    super.key,
    this.groupMembers,
  });

  /// The ID of the group this payment belongs to
  final String groupId;

  /// The currency of the group
  final String groupCurrency;

  /// Optional list of group members to select from
  final List<GroupMember>? groupMembers;

  @override
  State<CreatePaymentPage> createState() => _CreatePaymentPageState();
}

/// State class for CreatePaymentPage
class _CreatePaymentPageState extends State<CreatePaymentPage> {
  late final PaymentBloc _paymentBloc;
  late final GroupBloc _groupBloc;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Form state
  DateTime _paymentDate = DateTime.now();
  String _selectedCurrency = '';
  String? _selectedPayerId;
  String? _selectedRecipientId;
  List<GroupMember> _groupMembers = [];

  // UI state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paymentBloc = getIt<PaymentBloc>();
    _groupBloc = getIt<GroupBloc>();
    _selectedCurrency = widget.groupCurrency;

    // Use provided group members or load from GroupBloc
    if (widget.groupMembers != null) {
      _groupMembers = widget.groupMembers!;
    } else {
      _loadGroupMembers();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    unawaited(_paymentBloc.close());
    unawaited(_groupBloc.close());
    super.dispose();
  }

  void _loadGroupMembers() {
    // Get group members from GroupBloc state
    final groupState = _groupBloc.state;
    if (groupState is GroupsLoaded) {
      final group = groupState.getGroupById(widget.groupId);
      if (group != null) {
        setState(() {
          _groupMembers = group.members;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _paymentBloc),
        BlocProvider.value(value: _groupBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Payment'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _savePayment,
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
        body: MultiBlocListener(
          listeners: [
            BlocListener<PaymentBloc, PaymentState>(
              listener: (context, state) {
                if (state is PaymentLoading) {
                  setState(() {
                    _isLoading = true;
                  });
                } else {
                  setState(() {
                    _isLoading = false;
                  });
                }

                if (state is PaymentOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                }

                if (state is PaymentError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
            ),
            BlocListener<GroupBloc, GroupState>(
              listener: (context, state) {
                if (state is GroupsLoaded) {
                  final group = state.getGroupById(widget.groupId);
                  if (group != null && _groupMembers.isEmpty) {
                    setState(() {
                      _groupMembers = group.members;
                    });
                  }
                }
              },
            ),
          ],
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Payment details section
                _buildPaymentDetailsSection(),

                const SizedBox(height: 24),

                // Payer and recipient selection
                _buildParticipantSelectionSection(),

                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePayment,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Create Payment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
                      helperText: 'Enter the payment amount',
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
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description field (optional)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'What was this payment for?',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _selectPaymentDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_formatDate(_paymentDate)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Participants',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Payer selection
            _buildMemberSelectionField(
              label: 'Who paid? *',
              selectedMemberId: _selectedPayerId,
              onChanged: (memberId) {
                setState(() {
                  _selectedPayerId = memberId;
                  // Prevent self-payment
                  if (_selectedRecipientId == memberId) {
                    _selectedRecipientId = null;
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select who made the payment';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Recipient selection
            _buildMemberSelectionField(
              label: 'Who received the payment? *',
              selectedMemberId: _selectedRecipientId,
              onChanged: (memberId) {
                setState(() {
                  _selectedRecipientId = memberId;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select who received the payment';
                }
                if (value == _selectedPayerId) {
                  return 'Payer and recipient cannot be the same person';
                }
                return null;
              },
              excludeMemberId: _selectedPayerId, // Prevent self-payment
            ),

            // Validation message for self-payment
            if (_selectedPayerId != null &&
                _selectedRecipientId == _selectedPayerId) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A person cannot pay themselves. '
                        'Please select different payer and recipient.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelectionField({
    required String label,
    required String? selectedMemberId,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
    String? excludeMemberId,
  }) {
    // Filter out excluded member
    final availableMembers = _groupMembers
        .where((member) => member.userId != excludeMemberId)
        .toList();

    return DropdownButtonFormField<String>(
      initialValue: selectedMemberId,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      items: availableMembers.map((member) {
        return DropdownMenuItem<String>(
          value: member.userId,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.displayName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      member.role.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Future<void> _selectPaymentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _paymentDate = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _savePayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select who made the payment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedRecipientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select who received the payment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedPayerId == _selectedRecipientId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payer and recipient cannot be the same person'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);

    _paymentBloc.add(
      PaymentCreateRequested(
        groupId: widget.groupId,
        payerId: _selectedPayerId!,
        recipientId: _selectedRecipientId!,
        amount: amount,
        currency: _selectedCurrency,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        paymentDate: _paymentDate,
      ),
    );
  }
}
