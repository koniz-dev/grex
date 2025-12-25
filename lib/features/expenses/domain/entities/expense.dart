import 'package:equatable/equatable.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';

/// Entity representing an expense in a group
class Expense extends Equatable {
  /// Creates an [Expense] instance
  const Expense({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.payerName,
    required this.amount,
    required this.currency,
    required this.description,
    required this.expenseDate,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  /// Create from JSON from Supabase
  factory Expense.fromJson(Map<String, dynamic> json) {
    // Handle participants from joined query
    final participantsData =
        json['expense_participants'] as List<dynamic>? ?? [];
    final participants = participantsData
        .map(
          (participantJson) => ExpenseParticipant.fromJson(
            participantJson as Map<String, dynamic>,
          ),
        )
        .toList();

    return Expense(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      payerId: json['payer_id'] as String,
      payerName: json['payer_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      description: json['description'] as String,
      category: json['category'] as String?,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      participants: participants,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Unique identifier for the expense
  final String id;

  /// ID of the group this expense belongs to
  final String groupId;

  /// User ID of the person who paid for the expense
  final String payerId;

  /// Display name of the person who paid for the expense
  final String payerName;

  /// Total amount of the expense
  final double amount;

  /// Currency of the expense
  final String currency;

  /// Description of the expense
  final String description;

  /// Category of the expense (optional)
  final String? category;

  /// Date when the expense occurred
  final DateTime expenseDate;

  /// List of participants and their share amounts
  final List<ExpenseParticipant> participants;

  /// Date when the expense record was created
  final DateTime createdAt;

  /// Date when the expense record was last updated
  final DateTime updatedAt;

  /// Create a copy of this Expense with updated fields
  Expense copyWith({
    String? id,
    String? groupId,
    String? payerId,
    String? payerName,
    double? amount,
    String? currency,
    String? description,
    String? category,
    DateTime? expenseDate,
    List<ExpenseParticipant>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      payerId: payerId ?? this.payerId,
      payerName: payerName ?? this.payerName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'payer_id': payerId,
      'payer_name': payerName,
      'amount': amount,
      'currency': currency,
      'description': description,
      'category': category,
      'expense_date': expenseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // Note: participants are stored in a separate table
      // (expense_participants) and joined when fetching expenses
    };
  }

  /// Get participant by user ID
  ExpenseParticipant? getParticipantByUserId(String userId) {
    for (final participant in participants) {
      if (participant.userId == userId) {
        return participant;
      }
    }
    return null;
  }

  /// Check if user is a participant in this expense
  bool isParticipant(String userId) {
    return getParticipantByUserId(userId) != null;
  }

  /// Check if user is the payer of this expense
  bool isPayer(String userId) {
    return payerId == userId;
  }

  /// Get total amount of all participant shares
  double get totalParticipantShares {
    return participants.fold<double>(
      0,
      (sum, participant) => sum + participant.shareAmount,
    );
  }

  /// Check if the split is valid (shares sum to total amount)
  bool get isValidSplit {
    final totalShares = totalParticipantShares;
    return (totalShares - amount).abs() <= 0.01; // Allow for rounding errors
  }

  /// Get participant count
  int get participantCount => participants.length;

  /// Get display text for participant count
  String get participantCountText {
    if (participantCount == 1) return '1 participant';
    return '$participantCount participants';
  }

  /// Check if this expense involves multiple currencies
  bool get hasMultipleCurrencies {
    // For now, all participants use the same currency as the expense
    // This could be extended in the future for multi-currency support
    return false;
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    // This would use the CurrencyFormatter utility
    return '$currency $amount';
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    payerId,
    payerName,
    amount,
    currency,
    description,
    category,
    expenseDate,
    participants,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Expense(id: $id, groupId: $groupId, payerId: $payerId, '
        'amount: $amount, currency: $currency, description: $description, '
        'participantCount: $participantCount, expenseDate: $expenseDate)';
  }
}
