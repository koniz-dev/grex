import 'package:grex/features/expenses/domain/entities/expense_participant.dart';

/// Data model for ExpenseParticipant that extends the domain entity
/// Provides additional functionality for data layer operations
class ExpenseParticipantModel extends ExpenseParticipant {
  /// Creates an [ExpenseParticipantModel] instance
  const ExpenseParticipantModel({
    required super.userId,
    required super.displayName,
    required super.shareAmount,
    required super.sharePercentage,
  });

  /// Create from JSON with enhanced error handling
  factory ExpenseParticipantModel.fromJson(Map<String, dynamic> json) {
    try {
      return ExpenseParticipantModel(
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        shareAmount: (json['share_amount'] as num).toDouble(),
        sharePercentage: (json['share_percentage'] as num).toDouble(),
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse ExpenseParticipantModel from JSON: $e',
      );
    }
  }

  /// Create from domain entity
  factory ExpenseParticipantModel.fromEntity(ExpenseParticipant entity) {
    return ExpenseParticipantModel(
      userId: entity.userId,
      displayName: entity.displayName,
      shareAmount: entity.shareAmount,
      sharePercentage: entity.sharePercentage,
    );
  }

  /// Convert to domain entity
  ExpenseParticipant toEntity() {
    return ExpenseParticipant(
      userId: userId,
      displayName: displayName,
      shareAmount: shareAmount,
      sharePercentage: sharePercentage,
    );
  }

  /// Convert to JSON for database operations
  @override
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'share_amount': shareAmount,
      'share_percentage': sharePercentage,
    };
  }

  /// Create JSON for database insertion
  Map<String, dynamic> toInsertJson({
    required String expenseId,
  }) {
    return {
      'expense_id': expenseId,
      'user_id': userId,
      'display_name': displayName,
      'share_amount': shareAmount,
      'share_percentage': sharePercentage,
    };
  }

  /// Create a copy with updated fields
  @override
  ExpenseParticipantModel copyWith({
    String? userId,
    String? displayName,
    double? shareAmount,
    double? sharePercentage,
  }) {
    return ExpenseParticipantModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      shareAmount: shareAmount ?? this.shareAmount,
      sharePercentage: sharePercentage ?? this.sharePercentage,
    );
  }
}
