import 'package:equatable/equatable.dart';

/// Entity representing a payment between two group members
class Payment extends Equatable {
  /// Creates a [Payment] instance
  const Payment({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.payerName,
    required this.recipientId,
    required this.recipientName,
    required this.amount,
    required this.currency,
    required this.paymentDate,
    required this.createdAt,
    this.description,
  });

  /// Create from JSON from Supabase
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      payerId: json['payer_id'] as String,
      payerName: json['payer_name'] as String,
      recipientId: json['recipient_id'] as String,
      recipientName: json['recipient_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      description: json['description'] as String?,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Unique identifier for the payment
  final String id;

  /// ID of the group this payment belongs to
  final String groupId;

  /// User ID of the person making the payment
  final String payerId;

  /// Display name of the person making the payment
  final String payerName;

  /// User ID of the person receiving the payment
  final String recipientId;

  /// Display name of the person receiving the payment
  final String recipientName;

  /// Amount of the payment
  final double amount;

  /// Currency of the payment
  final String currency;

  /// Optional description of the payment
  final String? description;

  /// Date when the payment was made
  final DateTime paymentDate;

  /// Date when the payment record was created
  final DateTime createdAt;

  /// Create a copy of this Payment with updated fields
  Payment copyWith({
    String? id,
    String? groupId,
    String? payerId,
    String? payerName,
    String? recipientId,
    String? recipientName,
    double? amount,
    String? currency,
    String? description,
    DateTime? paymentDate,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      payerId: payerId ?? this.payerId,
      payerName: payerName ?? this.payerName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'payer_id': payerId,
      'payer_name': payerName,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'amount': amount,
      'currency': currency,
      'description': description,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if user is the payer of this payment
  bool isPayer(String userId) {
    return payerId == userId;
  }

  /// Check if user is the recipient of this payment
  bool isRecipient(String userId) {
    return recipientId == userId;
  }

  /// Check if user is involved in this payment (either payer or recipient)
  bool involvesUser(String userId) {
    return isPayer(userId) || isRecipient(userId);
  }

  /// Validate payment amount is positive
  bool get isValidAmount {
    return amount > 0;
  }

  /// Validate payment is not a self-payment
  bool get isNotSelfPayment {
    return payerId != recipientId;
  }

  /// Validate payment constraints
  bool get isValid {
    return isValidAmount && isNotSelfPayment;
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    // This would use the CurrencyFormatter utility
    return '$currency $amount';
  }

  /// Get payment direction text for a specific user
  String getDirectionText(String userId) {
    if (isPayer(userId)) {
      return 'You paid $recipientName';
    } else if (isRecipient(userId)) {
      return '$payerName paid you';
    } else {
      return '$payerName paid $recipientName';
    }
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    payerId,
    payerName,
    recipientId,
    recipientName,
    amount,
    currency,
    description,
    paymentDate,
    createdAt,
  ];

  @override
  String toString() {
    return 'Payment(id: $id, groupId: $groupId, '
        'payerId: $payerId, recipientId: $recipientId, '
        'amount: $amount, currency: $currency, '
        'paymentDate: $paymentDate)';
  }
}
