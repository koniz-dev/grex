/// Enum representing the different roles a member can have in a group
enum MemberRole {
  /// Administrator role - can manage group settings, invite/remove members, change roles
  administrator,

  /// Editor role - can add/edit expenses and payments, but cannot manage group settings
  editor,

  /// Viewer role - can only view expenses and balances, cannot make changes
  viewer;

  /// Convert enum to string for database storage
  String toJson() => name;

  /// Create enum from string (from database)
  static MemberRole fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'administrator':
        return MemberRole.administrator;
      case 'editor':
        return MemberRole.editor;
      case 'viewer':
        return MemberRole.viewer;
      default:
        throw ArgumentError('Invalid member role: $json');
    }
  }

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case MemberRole.administrator:
        return 'Administrator';
      case MemberRole.editor:
        return 'Editor';
      case MemberRole.viewer:
        return 'Viewer';
    }
  }

  /// Check if this role can manage group settings
  bool get canManageGroup {
    return this == MemberRole.administrator;
  }

  /// Check if this role can edit expenses and payments
  bool get canEditExpenses {
    return this == MemberRole.administrator || this == MemberRole.editor;
  }

  /// Check if this role can invite members
  bool get canInviteMembers {
    return this == MemberRole.administrator;
  }

  /// Check if this role can change member roles
  bool get canChangeMemberRoles {
    return this == MemberRole.administrator;
  }

  /// Check if this role can remove members
  bool get canRemoveMembers {
    return this == MemberRole.administrator;
  }
}
