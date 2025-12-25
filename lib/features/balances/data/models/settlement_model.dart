import 'package:grex/features/balances/domain/entities/settlement.dart';

/// Data model for Settlement that extends the domain entity
/// Provides additional functionality for data layer operations
class SettlementModel extends Settlement {
  /// Creates a [SettlementModel] instance
  const SettlementModel({
    required super.payerId,
    required super.payerName,
    required super.recipientId,
    required super.recipientName,
    required super.amount,
    required super.currency,
  });

  /// Create from JSON with enhanced error handling
  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    try {
      return SettlementModel(
        payerId: json['payer_id'] as String,
        payerName: json['payer_name'] as String,
        recipientId: json['recipient_id'] as String,
        recipientName: json['recipient_name'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
      );
    } on Exception catch (_) {
      throw const FormatException('Failed to parse SettlementModel from JSON');
    }
  }

  /// Create from domain entity
  factory SettlementModel.fromEntity(Settlement entity) {
    return SettlementModel(
      payerId: entity.payerId,
      payerName: entity.payerName,
      recipientId: entity.recipientId,
      recipientName: entity.recipientName,
      amount: entity.amount,
      currency: entity.currency,
    );
  }

  /// Convert to domain entity
  Settlement toEntity() {
    return Settlement(
      payerId: payerId,
      payerName: payerName,
      recipientId: recipientId,
      recipientName: recipientName,
      amount: amount,
      currency: currency,
    );
  }

  /// Convert to JSON for database operations
  @override
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

  /// Create a copy with updated fields
  @override
  SettlementModel copyWith({
    String? payerId,
    String? payerName,
    String? recipientId,
    String? recipientName,
    double? amount,
    String? currency,
  }) {
    return SettlementModel(
      payerId: payerId ?? this.payerId,
      payerName: payerName ?? this.payerName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }

  /// Round amount to avoid floating point precision issues
  SettlementModel rounded() {
    return copyWith(amount: (amount * 100).round() / 100);
  }

  /// Validate settlement with enhanced business rules
  List<String> validateSettlement() {
    final errors = <String>[];

    if (!isValidAmount) {
      errors.add('Settlement amount must be positive');
    }

    if (!isNotSelfPayment) {
      errors.add('Cannot settle with yourself');
    }

    if (amount > 1000000) {
      errors.add('Settlement amount exceeds reasonable limit');
    }

    if (payerName.trim().isEmpty) {
      errors.add('Payer name cannot be empty');
    }

    if (recipientName.trim().isEmpty) {
      errors.add('Recipient name cannot be empty');
    }

    if (currency.trim().isEmpty) {
      errors.add('Currency cannot be empty');
    }

    return errors;
  }

  /// Check if settlement is valid
  bool get isValidSettlement {
    return validateSettlement().isEmpty;
  }
}
