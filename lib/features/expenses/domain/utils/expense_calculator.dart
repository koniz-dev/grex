import 'dart:math';
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
    final baseAmount = totalAmount / participantCount;
    final roundedBaseAmount = _roundToTwoDecimals(baseAmount);

    // Calculate the remainder after rounding
    final totalRounded = roundedBaseAmount * participantCount;
    final remainder = _roundToTwoDecimals(totalAmount - totalRounded);

    final result = <String, double>{};

    // Assign base amount to all participants
    for (var i = 0; i < participantIds.length; i++) {
      result[participantIds[i]] = roundedBaseAmount;
    }

    // Distribute remainder to first participants (if any)
    if (remainder != 0) {
      final remainderPerParticipant = _roundToTwoDecimals(
        remainder / participantCount,
      );
      if (remainderPerParticipant > 0) {
        for (var i = 0; i < participantIds.length && remainder > 0; i++) {
          final participantId = participantIds[i];
          result[participantId] = _roundToTwoDecimals(
            result[participantId]! + 0.01,
          );
        }
      }
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

    // Validate percentages sum to 100
    final totalPercentage = percentages.values.fold(
      0,
      (sum, percentage) => sum + percentage.toInt(),
    );
    if ((totalPercentage - 100.0).abs() > 0.01) {
      throw ArgumentError(
        'Percentages must sum to 100%, got $totalPercentage%',
      );
    }

    final result = <String, double>{};
    var assignedAmount = 0.0;
    final participantIds = percentages.keys.toList();

    // Calculate amounts for all but the last participant
    for (var i = 0; i < participantIds.length - 1; i++) {
      final participantId = participantIds[i];
      final percentage = percentages[participantId]!;
      final amount = _roundToTwoDecimals(totalAmount * percentage / 100);
      result[participantId] = amount;
      assignedAmount += amount;
    }

    // Assign remaining amount to last participant to ensure total matches
    final lastParticipantId = participantIds.last;
    result[lastParticipantId] = _roundToTwoDecimals(
      totalAmount - assignedAmount,
    );

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

    // Validate exact amounts sum to total
    final totalExactAmounts = exactAmounts.values.fold(
      0,
      (sum, amount) => (sum + amount).toInt(),
    );
    if ((totalExactAmounts - totalAmount).abs() > 0.01) {
      throw ArgumentError(
        'Exact amounts must sum to total amount. '
        'Expected: $totalAmount, Got: $totalExactAmounts',
      );
    }

    // Return rounded amounts
    return exactAmounts.map(
      (key, value) => MapEntry(key, _roundToTwoDecimals(value)),
    );
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

    final result = <String, double>{};
    var assignedAmount = 0.0;
    final participantIds = shares.keys.toList();

    // Calculate amounts for all but the last participant
    for (var i = 0; i < participantIds.length - 1; i++) {
      final participantId = participantIds[i];
      final share = shares[participantId]!;
      final amount = _roundToTwoDecimals(totalAmount * share / totalShares);
      result[participantId] = amount;
      assignedAmount += amount;
    }

    // Assign remaining amount to last participant to ensure total matches
    final lastParticipantId = participantIds.last;
    result[lastParticipantId] = _roundToTwoDecimals(
      totalAmount - assignedAmount,
    );

    return result;
  }

  /// Validate that split amounts sum to total amount
  static bool validateSplit({
    required double totalAmount,
    required Map<String, double> splitAmounts,
  }) {
    final totalSplit = splitAmounts.values.fold(
      0,
      (sum, amount) => sum + amount.toInt(),
    );
    return (totalSplit - totalAmount).abs() <= 0.01;
  }

  /// Round amount to two decimal places
  static double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

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
        double totalExactAmounts = 0;
        for (final participant in participantData) {
          final amount = participant['amount'] as double?;
          if (amount == null || amount < 0) {
            return 'All amounts must be non-negative';
          }
          totalExactAmounts += amount;
        }
        if ((totalExactAmounts - totalAmount).abs() > 0.01) {
          return 'Exact amounts must sum to total amount '
              '(${totalExactAmounts.toStringAsFixed(2)} ≠ '
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

  /// Recalculate split when expense amount changes
  static List<ExpenseParticipant> recalculateSplit({
    required double newTotalAmount,
    required List<ExpenseParticipant> currentParticipants,
    required SplitMethod splitMethod,
  }) {
    // Convert current participants back to participant data format
    final participantData = currentParticipants.map((participant) {
      final data = <String, dynamic>{
        'userId': participant.userId,
        'displayName': participant.displayName,
      };

      // Add method-specific data based on split method
      switch (splitMethod) {
        case SplitMethod.equal:
          // No additional data needed
          break;
        case SplitMethod.percentage:
          data['percentage'] = participant.sharePercentage;
        case SplitMethod.exact:
          // For exact amounts, we need to scale proportionally
          data['amount'] = participant.shareAmount;
        case SplitMethod.shares:
          // Calculate shares based on current percentage
          final totalShares =
              currentParticipants.length * 1; // Default to 1 share each
          data['shares'] = max(
            1,
            (participant.sharePercentage / 100 * totalShares).round(),
          );
      }

      return data;
    }).toList();

    return calculateSplit(
      totalAmount: newTotalAmount,
      splitMethod: splitMethod,
      participantData: participantData,
    );
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
