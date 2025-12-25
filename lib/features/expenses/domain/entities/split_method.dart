/// Enum representing different methods for splitting expenses
enum SplitMethod {
  /// Split equally among all participants
  equal,

  /// Split by percentage (each participant gets a percentage of the total)
  percentage,

  /// Split by exact amounts (specify exact amount for each participant)
  exact,

  /// Split by shares (each participant gets a number of shares)
  shares;

  /// Convert enum to string for database storage
  String toJson() => name;

  /// Create enum from string (from database)
  static SplitMethod fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'equal':
        return SplitMethod.equal;
      case 'percentage':
        return SplitMethod.percentage;
      case 'exact':
        return SplitMethod.exact;
      case 'shares':
        return SplitMethod.shares;
      default:
        throw ArgumentError('Invalid split method: $json');
    }
  }

  /// Get display name for the split method
  String get displayName {
    switch (this) {
      case SplitMethod.equal:
        return 'Equal Split';
      case SplitMethod.percentage:
        return 'Percentage Split';
      case SplitMethod.exact:
        return 'Exact Amount';
      case SplitMethod.shares:
        return 'Share-based Split';
    }
  }

  /// Get description for the split method
  String get description {
    switch (this) {
      case SplitMethod.equal:
        return 'Split the expense equally among all participants';
      case SplitMethod.percentage:
        return 'Split by percentage (must total 100%)';
      case SplitMethod.exact:
        return 'Specify exact amount for each participant';
      case SplitMethod.shares:
        return 'Split by shares (proportional to share count)';
    }
  }

  /// Check if this method requires custom input from user
  bool get requiresCustomInput {
    return this != SplitMethod.equal;
  }
}
