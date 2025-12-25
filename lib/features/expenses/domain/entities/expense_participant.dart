import 'package:equatable/equatable.dart';

/// Entity representing a participant in an expense
class ExpenseParticipant extends Equatable {
  /// Creates an [ExpenseParticipant] instance
  const ExpenseParticipant({
    required this.userId,
    required this.displayName,
    required this.shareAmount,
    required this.sharePercentage,
  });

  /// Create from JSON from Supabase
  factory ExpenseParticipant.fromJson(Map<String, dynamic> json) {
    return ExpenseParticipant(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      shareAmount: (json['share_amount'] as num).toDouble(),
      sharePercentage: (json['share_percentage'] as num).toDouble(),
    );
  }

  /// User ID of the participant
  final String userId;

  /// Display name of the participant
  final String displayName;

  /// Amount this participant owes for the expense
  final double shareAmount;

  /// Percentage of the total expense this participant owes
  final double sharePercentage;

  /// Create a copy of this ExpenseParticipant with updated fields
  ExpenseParticipant copyWith({
    String? userId,
    String? displayName,
    double? shareAmount,
    double? sharePercentage,
  }) {
    return ExpenseParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      shareAmount: shareAmount ?? this.shareAmount,
      sharePercentage: sharePercentage ?? this.sharePercentage,
    );
  }

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'share_amount': shareAmount,
      'share_percentage': sharePercentage,
    };
  }

  /// Check if this participant's share is valid
  bool get isValidShare {
    return shareAmount >= 0 && sharePercentage >= 0 && sharePercentage <= 100;
  }

  @override
  List<Object?> get props => [
    userId,
    displayName,
    shareAmount,
    sharePercentage,
  ];

  @override
  String toString() {
    return 'ExpenseParticipant(userId: $userId, '
        'displayName: $displayName, '
        'shareAmount: $shareAmount, '
        'sharePercentage: $sharePercentage)';
  }
}
