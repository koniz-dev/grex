import 'package:equatable/equatable.dart';

/// Entity representing a member's balance in a group
class Balance extends Equatable {
  /// Creates a [Balance] instance
  const Balance({
    required this.userId,
    required this.displayName,
    required this.balance,
    required this.currency,
  });

  /// Create from JSON from Supabase
  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }

  /// User ID of the member
  final String userId;

  /// Display name of the member
  final String displayName;

  /// Net balance amount (positive = owed money, negative = owes money)
  final double balance;

  /// Currency of the balance
  final String currency;

  /// Create a copy of this Balance with updated fields
  Balance copyWith({
    String? userId,
    String? displayName,
    double? balance,
    String? currency,
  }) {
    return Balance(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
    );
  }

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'balance': balance,
      'currency': currency,
    };
  }

  /// Check if this member owes money
  bool get owesMoneyToGroup {
    return balance < 0;
  }

  /// Check if this member is owed money
  bool get isOwedMoneyByGroup {
    return balance > 0;
  }

  /// Check if this member is settled (balance is zero)
  bool get isSettled {
    return balance.abs() < 0.01; // Allow for rounding errors
  }

  /// Get absolute balance amount
  double get absoluteBalance {
    return balance.abs();
  }

  /// Get formatted balance with currency
  String get formattedBalance {
    // This would use the CurrencyFormatter utility
    return '$currency ${balance.abs()}';
  }

  /// Get balance status text
  String get balanceStatusText {
    if (isSettled) {
      return 'Settled';
    } else if (owesMoneyToGroup) {
      return 'Owes $formattedBalance';
    } else {
      return 'Is owed $formattedBalance';
    }
  }

  /// Get balance color indicator
  BalanceStatus get status {
    if (isSettled) {
      return BalanceStatus.settled;
    } else if (owesMoneyToGroup) {
      return BalanceStatus.owes;
    } else {
      return BalanceStatus.owed;
    }
  }

  @override
  List<Object?> get props => [userId, displayName, balance, currency];

  @override
  String toString() {
    return 'Balance(userId: $userId, displayName: $displayName, '
        'balance: $balance, currency: $currency)';
  }
}

/// Enum representing the status of a balance
enum BalanceStatus {
  /// Member owes money to the group
  owes,

  /// Member is owed money by the group
  owed,

  /// Member is settled (balance is zero)
  settled;

  /// Get display color for the status
  String get displayColor {
    switch (this) {
      case BalanceStatus.owes:
        return 'red';
      case BalanceStatus.owed:
        return 'green';
      case BalanceStatus.settled:
        return 'gray';
    }
  }
}
