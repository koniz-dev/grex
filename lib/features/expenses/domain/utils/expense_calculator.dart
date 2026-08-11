import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/entities/split_method.dart';

/// Utility class for calculating expense splits among participants
class ExpenseCalculator {
  /// Split amount equally among participants with proper rounding
  static Map<String, double> splitEqually({
    required double totalAmount,
    required List<String> participantIds,
  }) {
    if (participantIds.isEmpty) {
      throw ArgumentError('Participant list cannot be empty');
    }

    final participantCount = participantIds.length;
    final totalCents = _toCents(totalAmount);

    // Divide in minor units, then hand the leftover cents out one each to the
    // first participants, so the shares always sum back to the total exactly.
    final baseCents = (totalCents / participantCount).floor();
    final leftoverCents = totalCents - baseCents * participantCount;

    final result = <String, double>{};
    for (var i = 0; i < participantCount; i++) {
      result[participantIds[i]] = _fromCents(
        baseCents + (i < leftoverCents ? 1 : 0),
      );
    }

    return result;
  }

  /// Split amount by percentage among participants
  static Map<String, double> splitByPercentage({
    required double totalAmount,
    required Map<String, double> percentages,
  }) {
    if (percentages.isEmpty) {
      throw ArgumentError('Percentages map cannot be empty');
    }

    // Validate percentages sum to 100. Use the full double value, not
    // `.toInt()`, so e.g. {33.33, 33.33, 33.34} = 100.00 is accepted
    // instead of being truncated to 99.
    final totalPercentage = percentages.values.fold<double>(
      0,
      (sum, percentage) => sum + percentage,
    );
    if ((totalPercentage - 100.0).abs() > 0.01) {
      throw ArgumentError(
        'Percentages must sum to 100%, got $totalPercentage%',
      );
    }

    final totalCents = _toCents(totalAmount);
    final result = <String, double>{};
    var assignedCents = 0;
    final participantIds = percentages.keys.toList();

    // Calculate amounts for all but the last participant
    for (var i = 0; i < participantIds.length - 1; i++) {
      final participantId = participantIds[i];
      final percentage = percentages[participantId]!;
      final cents = (totalCents * percentage / 100).round();
      result[participantId] = _fromCents(cents);
      assignedCents += cents;
    }

    // Assign remaining amount to last participant to ensure total matches
    final lastParticipantId = participantIds.last;
    result[lastParticipantId] = _fromCents(totalCents - assignedCents);

    return result;
  }

  /// Split amount by exact amounts among participants
  static Map<String, double> splitByExactAmounts({
    required double totalAmount,
    required Map<String, double> exactAmounts,
  }) {
    if (exactAmounts.isEmpty) {
      throw ArgumentError('Exact amounts map cannot be empty');
    }

    // Validate exact amounts sum to total, in minor units. Folding doubles
    // through `.toInt()` truncates every step, so any amount with cents in it
    // fails a sum that is in fact exact.
    final exactCents = exactAmounts.map(
      (key, value) => MapEntry(key, _toCents(value)),
    );
    final totalExactCents = exactCents.values.fold<int>(
      0,
      (sum, cents) => sum + cents,
    );
    final totalCents = _toCents(totalAmount);
    if (totalExactCents != totalCents) {
      throw ArgumentError(
        'Exact amounts must sum to total amount. '
        'Expected: $totalAmount, Got: ${_fromCents(totalExactCents)}',
      );
    }

    return exactCents.map((key, cents) => MapEntry(key, _fromCents(cents)));
  }

  /// Split amount by shares among participants
  static Map<String, double> splitByShares({
    required double totalAmount,
    required Map<String, int> shares,
  }) {
    if (shares.isEmpty) {
      throw ArgumentError('Shares map cannot be empty');
    }

    final totalShares = shares.values.fold(0, (sum, share) => sum + share);
    if (totalShares == 0) {
      throw ArgumentError('Total shares cannot be zero');
    }

    final totalCents = _toCents(totalAmount);
    final result = <String, double>{};
    var assignedCents = 0;
    final participantIds = shares.keys.toList();

    // Calculate amounts for all but the last participant
    for (var i = 0; i < participantIds.length - 1; i++) {
      final participantId = participantIds[i];
      final share = shares[participantId]!;
      final cents = (totalCents * share / totalShares).round();
      result[participantId] = _fromCents(cents);
      assignedCents += cents;
    }

    // Assign remaining amount to last participant to ensure total matches
    final lastParticipantId = participantIds.last;
    result[lastParticipantId] = _fromCents(totalCents - assignedCents);

    return result;
  }

  /// Validate that split amounts sum to total amount
  static bool validateSplit({
    required double totalAmount,
    required Map<String, double> splitAmounts,
  }) {
    final totalSplitCents = splitAmounts.values.fold<int>(
      0,
      (sum, amount) => sum + _toCents(amount),
    );
    return totalSplitCents == _toCents(totalAmount);
  }

  /// Round amount to two decimal places
  static double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

  /// Convert a currency amount to integer minor units (cents).
  ///
  /// All split arithmetic runs in minor units: a cent is the smallest thing
  /// this app can owe anyone, and integers neither drift nor lose a remainder.
  static int _toCents(double amount) => (amount * 100).round();

  /// Convert integer minor units (cents) back to a currency amount
  static double _fromCents(int cents) => cents / 100;

  /// Calculate percentage for each participant based on their amount
  static Map<String, double> calculatePercentages({
    required double totalAmount,
    required Map<String, double> splitAmounts,
  }) {
    if (totalAmount == 0) {
      return splitAmounts.map((key, value) => MapEntry(key, 0));
    }

    return splitAmounts.map(
      (key, value) =>
          MapEntry(key, _roundToTwoDecimals((value / totalAmount) * 100)),
    );
  }

  /// Calculate expense split using domain entities
  static List<ExpenseParticipant> calculateSplit({
    required double totalAmount,
    required SplitMethod splitMethod,
    required List<Map<String, dynamic>> participantData,
  }) {
    if (participantData.isEmpty) {
      throw ArgumentError('Participant data cannot be empty');
    }

    Map<String, double> splitAmounts;

    switch (splitMethod) {
      case SplitMethod.equal:
        final participantIds = participantData
            .map((p) => p['userId'] as String)
            .toList();
        splitAmounts = splitEqually(
          totalAmount: totalAmount,
          participantIds: participantIds,
        );

      case SplitMethod.percentage:
        final percentages = <String, double>{};
        for (final participant in participantData) {
          percentages[participant['userId'] as String] =
              participant['percentage'] as double;
        }
        splitAmounts = splitByPercentage(
          totalAmount: totalAmount,
          percentages: percentages,
        );

      case SplitMethod.exact:
        final exactAmounts = <String, double>{};
        for (final participant in participantData) {
          exactAmounts[participant['userId'] as String] =
              participant['amount'] as double;
        }
        splitAmounts = splitByExactAmounts(
          totalAmount: totalAmount,
          exactAmounts: exactAmounts,
        );

      case SplitMethod.shares:
        final shares = <String, int>{};
        for (final participant in participantData) {
          shares[participant['userId'] as String] =
              participant['shares'] as int;
        }
        splitAmounts = splitByShares(
          totalAmount: totalAmount,
          shares: shares,
        );
    }

    // Calculate percentages for all participants
    final percentages = calculatePercentages(
      totalAmount: totalAmount,
      splitAmounts: splitAmounts,
    );

    // Create ExpenseParticipant entities
    return participantData.map((participant) {
      final userId = participant['userId'] as String;
      final displayName = participant['displayName'] as String;
      final shareAmount = splitAmounts[userId]!;
      final sharePercentage = percentages[userId]!;

      return ExpenseParticipant(
        userId: userId,
        displayName: displayName,
        shareAmount: shareAmount,
        sharePercentage: sharePercentage,
      );
    }).toList();
  }

  /// Validate split configuration before calculation
  static String? validateSplitConfiguration({
    required double totalAmount,
    required SplitMethod splitMethod,
    required List<Map<String, dynamic>> participantData,
  }) {
    if (totalAmount <= 0) {
      return 'Total amount must be positive';
    }

    if (participantData.isEmpty) {
      return 'At least one participant is required';
    }

    // Check for duplicate participants
    final userIds = participantData.map((p) => p['userId'] as String).toSet();
    if (userIds.length != participantData.length) {
      return 'Duplicate participants are not allowed';
    }

    switch (splitMethod) {
      case SplitMethod.equal:
        // No additional validation needed for equal split
        break;

      case SplitMethod.percentage:
        double totalPercentage = 0;
        for (final participant in participantData) {
          final percentage = participant['percentage'] as double?;
          if (percentage == null || percentage < 0 || percentage > 100) {
            return 'All percentages must be between 0 and 100';
          }
          totalPercentage += percentage;
        }
        if ((totalPercentage - 100.0).abs() > 0.01) {
          return 'Percentages must sum to 100% '
              '(currently ${totalPercentage.toStringAsFixed(1)}%)';
        }

      case SplitMethod.exact:
        // Sum in minor units, on the same terms as `splitByExactAmounts`.
        // A looser check here would pass the form and then throw from
        // `calculateSplit`, which is the failure this pre-check exists to
        // catch.
        var totalExactCents = 0;
        for (final participant in participantData) {
          final amount = participant['amount'] as double?;
          if (amount == null || amount < 0) {
            return 'All amounts must be non-negative';
          }
          totalExactCents += _toCents(amount);
        }
        if (totalExactCents != _toCents(totalAmount)) {
          return 'Exact amounts must sum to total amount '
              '(${_fromCents(totalExactCents).toStringAsFixed(2)} ≠ '
              '${totalAmount.toStringAsFixed(2)})';
        }

      case SplitMethod.shares:
        var totalShares = 0;
        for (final participant in participantData) {
          final shares = participant['shares'] as int?;
          if (shares == null || shares <= 0) {
            return 'All share counts must be positive integers';
          }
          totalShares += shares;
        }
        if (totalShares == 0) {
          return 'Total shares must be greater than zero';
        }
    }

    return null; // No validation errors
  }

  /// Recalculate a split when the expense amount changes.
  ///
  /// [ExpenseParticipant] records only the amount and percentage each person
  /// ended up with -- not the share counts or exact amounts that produced them
  /// -- so the original configuration cannot be recovered after the fact. What
  /// is recoverable, and is what actually matters, is each participant's
  /// proportion of the total, so every method except [SplitMethod.equal]
  /// rescales the existing shares to the new total in integer minor units.
  ///
  /// This replaces a reconstruction that inferred share counts from rounded
  /// percentages against `currentParticipants.length * 1` -- i.e. it assumed
  /// one share each -- which silently turned a 3:1 split into 2:1 on the first
  /// amount change, and which threw for [SplitMethod.exact] because it fed the
  /// old amounts against the new total. See #25.
  static List<ExpenseParticipant> recalculateSplit({
    required double newTotalAmount,
    required List<ExpenseParticipant> currentParticipants,
    required SplitMethod splitMethod,
  }) {
    if (currentParticipants.isEmpty) {
      throw ArgumentError('Participant list cannot be empty');
    }

    final splitAmounts = splitMethod == SplitMethod.equal
        ? splitEqually(
            totalAmount: newTotalAmount,
            participantIds: currentParticipants
                .map((participant) => participant.userId)
                .toList(),
          )
        : _rescaleToTotal(
            participants: currentParticipants,
            newTotalCents: _toCents(newTotalAmount),
          );

    final percentages = calculatePercentages(
      totalAmount: newTotalAmount,
      splitAmounts: splitAmounts,
    );

    return currentParticipants
        .map(
          (participant) => ExpenseParticipant(
            userId: participant.userId,
            displayName: participant.displayName,
            shareAmount: splitAmounts[participant.userId]!,
            sharePercentage: percentages[participant.userId]!,
          ),
        )
        .toList();
  }

  /// Scale existing shares to [newTotalCents], preserving each participant's
  /// proportion and conserving the total exactly.
  static Map<String, double> _rescaleToTotal({
    required List<ExpenseParticipant> participants,
    required int newTotalCents,
  }) {
    final oldCents = [
      for (final participant in participants) _toCents(participant.shareAmount),
    ];
    final oldTotalCents = oldCents.fold<int>(0, (sum, cents) => sum + cents);

    // A split that currently totals nothing carries no proportions to
    // preserve, so fall back to an equal division rather than dividing by zero.
    if (oldTotalCents == 0) {
      return splitEqually(
        totalAmount: _fromCents(newTotalCents),
        participantIds: participants
            .map((participant) => participant.userId)
            .toList(),
      );
    }

    final result = <String, double>{};
    var assignedCents = 0;

    for (var i = 0; i < participants.length - 1; i++) {
      final cents = (newTotalCents * oldCents[i] / oldTotalCents).round();
      result[participants[i].userId] = _fromCents(cents);
      assignedCents += cents;
    }

    // The last participant absorbs the rounding remainder, so the shares sum
    // back to the new total exactly.
    result[participants.last.userId] = _fromCents(
      newTotalCents - assignedCents,
    );

    return result;
  }

  /// Check if split method supports adding/removing participants
  static bool canModifyParticipants(SplitMethod splitMethod) {
    switch (splitMethod) {
      case SplitMethod.equal:
      case SplitMethod.shares:
        return true; // Can easily add/remove participants
      case SplitMethod.percentage:
      case SplitMethod.exact:
        return false; // Would require reconfiguring all amounts/percentages
    }
  }

  /// Get default participant data for a split method
  static Map<String, dynamic> getDefaultParticipantData({
    required SplitMethod splitMethod,
    required String userId,
    required String displayName,
    int participantCount = 1,
  }) {
    final data = <String, dynamic>{
      'userId': userId,
      'displayName': displayName,
    };

    switch (splitMethod) {
      case SplitMethod.equal:
        // No additional data needed
        break;
      case SplitMethod.percentage:
        data['percentage'] = 100.0 / participantCount;
      case SplitMethod.exact:
        data['amount'] = 0.0;
      case SplitMethod.shares:
        data['shares'] = 1;
    }

    return data;
  }
}
