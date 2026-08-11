import 'package:flutter/material.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Displays the group's currency as a fixed, non-editable form field.
///
/// Expenses and payments are always recorded in the owning group's currency.
/// This used to be a free dropdown over all ten supported currencies, but
/// `calculate_group_balances` filters every CTE on `e.currency =
/// group_currency`, so anything recorded in another currency was accepted,
/// listed, exported -- and silently dropped from every balance. The UI invited
/// a choice the balance engine then discarded.
///
/// Until real multi-currency support exists (per-expense FX rate, a functional
/// currency for balances, a decision about who absorbs FX drift), the honest
/// interface is no choice at all. See issue #18.
class GroupCurrencyField extends StatelessWidget {
  /// Creates a [GroupCurrencyField].
  const GroupCurrencyField({
    required this.currency,
    required this.label,
    this.helperText,
    super.key,
  });

  /// The owning group's currency code, e.g. `USD`.
  final String currency;

  /// Label shown on the field.
  final String label;

  /// Optional explanation of why the value cannot be changed.
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final symbol = CurrencyFormatter.getCurrencySymbol(currency);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 3,
        border: const OutlineInputBorder(),
        // Read-only rather than a disabled dropdown: a greyed-out control
        // reads as "temporarily unavailable" and invites the user to hunt for
        // the way to enable it. There is no way, by design.
        enabled: false,
      ),
      child: Text(
        '$currency $symbol',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
