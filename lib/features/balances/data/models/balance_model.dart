import 'package:grex/features/balances/domain/entities/balance.dart';

/// Data model for Balance that extends the domain entity
/// Provides additional functionality for data layer operations
class BalanceModel extends Balance {
  /// Creates a [BalanceModel] instance
  const BalanceModel({
    required super.userId,
    required super.displayName,
    required super.balance,
    required super.currency,
  });

  /// Create from JSON with enhanced error handling
  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    try {
      return BalanceModel(
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        balance: (json['balance'] as num).toDouble(),
        currency: json['currency'] as String,
      );
    } on Exception catch (_) {
      throw const FormatException('Failed to parse BalanceModel from JSON');
    }
  }

  /// Create a zero balance for a user
  factory BalanceModel.zero({
    required String userId,
    required String displayName,
    required String currency,
  }) {
    return BalanceModel(
      userId: userId,
      displayName: displayName,
      balance: 0,
      currency: currency,
    );
  }

  /// Create from domain entity
  factory BalanceModel.fromEntity(Balance entity) {
    return BalanceModel(
      userId: entity.userId,
      displayName: entity.displayName,
      balance: entity.balance,
      currency: entity.currency,
    );
  }

  /// Convert to domain entity
  Balance toEntity() {
    return Balance(
      userId: userId,
      displayName: displayName,
      balance: balance,
      currency: currency,
    );
  }

  /// Convert to JSON for database operations
  @override
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'balance': balance,
      'currency': currency,
    };
  }

  /// Create a copy with updated fields
  @override
  BalanceModel copyWith({
    String? userId,
    String? displayName,
    double? balance,
    String? currency,
  }) {
    return BalanceModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
    );
  }

  /// Add amount to balance (positive for receiving money, negative for owing)
  BalanceModel addAmount(double amount) {
    return copyWith(balance: balance + amount);
  }

  /// Subtract amount from balance
  BalanceModel subtractAmount(double amount) {
    return copyWith(balance: balance - amount);
  }

  /// Round balance to avoid floating point precision issues
  BalanceModel rounded() {
    return copyWith(balance: (balance * 100).round() / 100);
  }
}
