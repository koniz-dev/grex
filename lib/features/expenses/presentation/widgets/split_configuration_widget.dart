import 'package:flutter/material.dart';
import 'package:grex/features/expenses/domain/entities/split_method.dart';
import 'package:grex/features/expenses/domain/utils/expense_calculator.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Widget for configuring how an expense is split among participants
class SplitConfigurationWidget extends StatefulWidget {
  /// Creates a [SplitConfigurationWidget] instance
  const SplitConfigurationWidget({
    required this.splitMethod,
    required this.participants,
    required this.totalAmount,
    required this.currency,
    required this.onConfigurationChanged,
    super.key,
  });

  /// The method used to split the expense
  final SplitMethod splitMethod;

  /// The list of participants and their current split data
  final List<Map<String, dynamic>> participants;

  /// The total amount to be split
  final double totalAmount;

  /// The currency code of the expense
  final String currency;

  /// Callback when the configuration changes
  final ValueChanged<List<Map<String, dynamic>>> onConfigurationChanged;

  @override
  State<SplitConfigurationWidget> createState() =>
      _SplitConfigurationWidgetState();
}

/// State class for SplitConfigurationWidget
class _SplitConfigurationWidgetState extends State<SplitConfigurationWidget> {
  late List<Map<String, dynamic>> _participantData;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeParticipantData();
  }

  @override
  void didUpdateWidget(SplitConfigurationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinitialize if participants or split method changed
    if (oldWidget.participants != widget.participants ||
        oldWidget.splitMethod != widget.splitMethod ||
        oldWidget.totalAmount != widget.totalAmount) {
      _initializeParticipantData();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeParticipantData() {
    // Clear existing controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    // Initialize participant data based on split method
    _participantData = widget.participants.map((participant) {
      final data = ExpenseCalculator.getDefaultParticipantData(
        splitMethod: widget.splitMethod,
        userId: participant['userId'] as String,
        displayName: participant['displayName'] as String,
        participantCount: widget.participants.length,
      );

      // Create controllers for input fields
      final userId = participant['userId'] as String;
      switch (widget.splitMethod) {
        case SplitMethod.percentage:
          _controllers[userId] = TextEditingController(
            text: (data['percentage'] as double).toStringAsFixed(1),
          );
        case SplitMethod.exact:
          _controllers[userId] = TextEditingController(
            text: (data['amount'] as double).toStringAsFixed(2),
          );
        case SplitMethod.shares:
          _controllers[userId] = TextEditingController(
            text: (data['shares'] as int).toString(),
          );
        case SplitMethod.equal:
          // No input needed for equal split
          break;
      }

      return data;
    }).toList();

    _calculateAndNotify();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.participants.isEmpty || widget.totalAmount <= 0) {
      return const Text('Configure participants and amount first');
    }

    switch (widget.splitMethod) {
      case SplitMethod.equal:
        return _buildEqualSplitView();
      case SplitMethod.percentage:
        return _buildPercentageSplitView();
      case SplitMethod.exact:
        return _buildExactAmountSplitView();
      case SplitMethod.shares:
        return _buildSharesSplitView();
    }
  }

  Widget _buildEqualSplitView() {
    final splitAmounts = ExpenseCalculator.splitEqually(
      totalAmount: widget.totalAmount,
      participantIds: widget.participants
          .map((p) => p['userId'] as String)
          .toList(),
    );

    return Column(
      children: [
        Text(
          'Each participant pays the same amount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.participants.map((participant) {
          final userId = participant['userId'] as String;
          final displayName = participant['displayName'] as String;
          final amount = splitAmounts[userId] ?? 0.0;

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              ),
            ),
            title: Text(displayName),
            trailing: Text(
              CurrencyFormatter.format(
                amount: amount,
                currencyCode: widget.currency,
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPercentageSplitView() {
    return Column(
      children: [
        Text(
          'Enter percentage for each participant (must total 100%)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.participants.map((participant) {
          final userId = participant['userId'] as String;
          final displayName = participant['displayName'] as String;
          final controller = _controllers[userId]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(displayName),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffixText: '%',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _updateParticipantData(
                        userId,
                        'percentage',
                        double.tryParse(value) ?? 0.0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    _getCalculatedAmount(userId),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
        _buildTotalSummary(),
      ],
    );
  }

  Widget _buildExactAmountSplitView() {
    return Column(
      children: [
        Text(
          'Enter exact amount for each participant',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.participants.map((participant) {
          final userId = participant['userId'] as String;
          final displayName = participant['displayName'] as String;
          final controller = _controllers[userId]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(displayName),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: CurrencyFormatter.getCurrencySymbol(
                        widget.currency,
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _updateParticipantData(
                        userId,
                        'amount',
                        double.tryParse(value) ?? 0.0,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        _buildTotalSummary(),
      ],
    );
  }

  Widget _buildSharesSplitView() {
    return Column(
      children: [
        Text(
          'Enter number of shares for each participant',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.participants.map((participant) {
          final userId = participant['userId'] as String;
          final displayName = participant['displayName'] as String;
          final controller = _controllers[userId]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(displayName),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffixText: 'shares',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _updateParticipantData(
                        userId,
                        'shares',
                        int.tryParse(value) ?? 1,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    _getCalculatedAmount(userId),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
        _buildTotalSummary(),
      ],
    );
  }

  Widget _buildTotalSummary() {
    final totalConfigured = _getTotalConfiguredAmount();
    final isValid = (totalConfigured - widget.totalAmount).abs() <= 0.01;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(
                  amount: totalConfigured,
                  currencyCode: widget.currency,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isValid
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              Text(
                'Target: ${CurrencyFormatter.format(
                  amount: widget.totalAmount,
                  currencyCode: widget.currency,
                )}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isValid
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateParticipantData(String userId, String field, dynamic value) {
    final participantIndex = _participantData.indexWhere(
      (p) => p['userId'] == userId,
    );
    if (participantIndex >= 0) {
      _participantData[participantIndex][field] = value;
      _calculateAndNotify();
    }
  }

  void _calculateAndNotify() {
    widget.onConfigurationChanged(_participantData);
  }

  String _getCalculatedAmount(String userId) {
    try {
      final splitAmounts = _calculateCurrentSplit();
      final amount = splitAmounts[userId] ?? 0.0;
      return CurrencyFormatter.format(
        amount: amount,
        currencyCode: widget.currency,
      );
    } on Exception catch (_) {
      return '-';
    }
  }

  double _getTotalConfiguredAmount() {
    try {
      final splitAmounts = _calculateCurrentSplit();
      return splitAmounts.values.fold(0, (sum, amount) => sum + amount);
    } on Exception catch (_) {
      return 0;
    }
  }

  Map<String, double> _calculateCurrentSplit() {
    switch (widget.splitMethod) {
      case SplitMethod.equal:
        return ExpenseCalculator.splitEqually(
          totalAmount: widget.totalAmount,
          participantIds: _participantData
              .map((p) => p['userId'] as String)
              .toList(),
        );

      case SplitMethod.percentage:
        final percentages = <String, double>{};
        for (final participant in _participantData) {
          percentages[participant['userId'] as String] =
              (participant['percentage'] as double?) ?? 0.0;
        }
        return ExpenseCalculator.splitByPercentage(
          totalAmount: widget.totalAmount,
          percentages: percentages,
        );

      case SplitMethod.exact:
        final exactAmounts = <String, double>{};
        for (final participant in _participantData) {
          exactAmounts[participant['userId'] as String] =
              (participant['amount'] as double?) ?? 0.0;
        }
        return exactAmounts;

      case SplitMethod.shares:
        final shares = <String, int>{};
        for (final participant in _participantData) {
          shares[participant['userId'] as String] =
              (participant['shares'] as int?) ?? 1;
        }
        return ExpenseCalculator.splitByShares(
          totalAmount: widget.totalAmount,
          shares: shares,
        );
    }
  }
}
