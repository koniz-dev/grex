import 'package:equatable/equatable.dart';

/// Entity representing a suggested settlement payment between two members
class Settlement extends Equatable {
  /// Creates a [Settlement] instance
  const Settlement({
    required this.payerId,
    required this.payerName,
    required this.recipientId,
    required this.recipientName,
    required this.amount,
    required this.currency,
  });

  /// Create from JSON from Supabase
  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      payerId: json['payer_id'] as String,
      payerName: json['payer_name'] as String,
      recipientId: json['recipient_id'] as String,
      recipientName: json['recipient_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }

  /// User ID of the person who should make the payment
  final String payerId;

  /// Display name of the person who should make the payment
  final String payerName;

  /// User ID of the person who should receive the payment
  final String recipientId;

  /// Display name of the person who should receive the payment
  final String recipientName;

  /// Amount that should be paid
  final double amount;

  /// Currency of the settlement
  final String currency;

  /// Create a copy of this Settlement with updated fields
  Settlement copyWith({
    String? payerId,
    String? payerName,
    String? recipientId,
    String? recipientName,
    double? amount,
    String? currency,
  }) {
    return Settlement(
      payerId: payerId ?? this.payerId,
      payerName: payerName ?? this.payerName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'payer_id': payerId,
      'payer_name': payerName,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'amount': amount,
      'currency': currency,
    };
  }

  /// Check if user is the payer in this settlement
  bool isPayer(String userId) {
    return payerId == userId;
  }

  /// Check if user is the recipient in this settlement
  bool isRecipient(String userId) {
    return recipientId == userId;
  }

  /// Check if user is involved in this settlement
  bool involvesUser(String userId) {
    return isPayer(userId) || isRecipient(userId);
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    // This would use the CurrencyFormatter utility
    return '$currency $amount';
  }

  /// Get settlement description text
  String get settlementText {
    return '$payerName should pay $recipientName $formattedAmount';
  }

  /// Get settlement description for a specific user
  String getSettlementTextForUser(String userId) {
    if (isPayer(userId)) {
      return 'You should pay $recipientName $formattedAmount';
    } else if (isRecipient(userId)) {
      return '$payerName should pay you $formattedAmount';
    } else {
      return settlementText;
    }
  }

  /// Validate settlement amount is positive
  bool get isValidAmount {
    return amount > 0;
  }

  /// Validate settlement is not a self-payment
  bool get isNotSelfPayment {
    return payerId != recipientId;
  }

  /// Validate settlement
  bool get isValid {
    return isValidAmount && isNotSelfPayment;
  }

  @override
  List<Object?> get props => [
    payerId,
    payerName,
    recipientId,
    recipientName,
    amount,
    currency,
  ];

  @override
  String toString() {
    return 'Settlement(payerId: $payerId, recipientId: $recipientId, '
        'amount: $amount, currency: $currency)';
  }
}
