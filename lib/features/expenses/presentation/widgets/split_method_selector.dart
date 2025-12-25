import 'package:flutter/material.dart';
import 'package:grex/features/expenses/domain/entities/split_method.dart';

/// Widget for selecting the expense split method
class SplitMethodSelector extends StatelessWidget {
  /// Creates a [SplitMethodSelector] instance
  const SplitMethodSelector({
    required this.selectedMethod,
    required this.onMethodChanged,
    super.key,
  });

  /// The currently selected split method
  final SplitMethod selectedMethod;

  /// Callback when the split method changes
  final ValueChanged<SplitMethod> onMethodChanged;

  @override
  Widget build(BuildContext context) {
    final content = RadioGroup<SplitMethod>(
      groupValue: selectedMethod,
      onChanged: (value) {
        if (value != null) {
          onMethodChanged(value);
        }
      },
      child: Column(
        children: SplitMethod.values.map((method) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<SplitMethod>(
              title: Text(method.displayName),
              subtitle: Text(method.description),
              value: method,
              secondary: Icon(_getMethodIcon(method)),
            ),
          );
        }).toList(),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedHeight) {
          return SingleChildScrollView(child: content);
        }
        return content;
      },
    );
  }

  IconData _getMethodIcon(SplitMethod method) {
    switch (method) {
      case SplitMethod.equal:
        return Icons.balance;
      case SplitMethod.percentage:
        return Icons.percent;
      case SplitMethod.exact:
        return Icons.calculate;
      case SplitMethod.shares:
        return Icons.pie_chart;
    }
  }
}
