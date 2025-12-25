/// A central class containing all route definitions and path constants used
/// for navigation.
class AppRoutes {
  /// Route path for the login screen.
  static const String login = '/login';

  /// Route path for the user registration screen.
  static const String register = '/register';

  /// Route path for the password recovery screen.
  static const String forgotPassword = '/forgot-password';

  /// Route path for the email verification screen.
  static const String emailVerification = '/email-verification';

  /// Route path for the user profile screen.
  static const String profile = '/profile';

  /// Route path for editing the user profile.
  static const String editProfile = '/profile/edit';

  /// Root route path that maps to the groups list.
  static const String home = '/'; // Home maps to groups

  /// Route path for the groups list.
  static const String groups = '/';

  /// Route path for creating a new group.
  static const String createGroup = '/create-group';

  /// Route path for specific group details, requiring a `groupId`.
  static const String groupDetails = '/group/:groupId';

  /// Route path for group settings, requiring a `groupId`.
  static const String groupSettings = '/group/:groupId/settings';

  /// Route path for expense list within a group, requiring a `groupId`.
  static const String expenses = '/group/:groupId/expenses';

  /// Route path for creating a new expense, requiring a `groupId`.
  static const String createExpense = '/group/:groupId/expenses/create';

  /// Route path for specific expense details.
  static const String expenseDetails = '/group/:groupId/expenses/:expenseId';

  /// Route path for editing an expense.
  static const String editExpense = '/group/:groupId/expenses/:expenseId/edit';

  /// Route path for payments list within a group.
  static const String payments = '/group/:groupId/payments';

  /// Route path for creating a new payment.
  static const String createPayment = '/group/:groupId/payments/create';

  /// Route path for group balances.
  static const String balances = '/group/:groupId/balances';

  /// Route path for the settlement plan view.
  static const String settlementPlan = '/group/:groupId/balances/settlement';

  /// Route path for exporting group data.
  static const String export = '/group/:groupId/export';

  /// Navigation name for the login route.
  static const String loginName = 'login';

  /// Navigation name for the registration route.
  static const String registerName = 'register';

  /// Navigation name for the forgot password route.
  static const String forgotPasswordName = 'forgot-password';

  /// Navigation name for the email verification route.
  static const String emailVerificationName = 'email-verification';

  /// Navigation name for the profile route.
  static const String profileName = 'profile';

  /// Navigation name for the edit profile route.
  static const String editProfileName = 'edit-profile';

  /// Navigation name for the home route.
  static const String homeName = 'home';

  /// Navigation name for the groups route.
  static const String groupsName = 'groups';

  /// Navigation name for the create group route.
  static const String createGroupName = 'create-group';

  /// Navigation name for the group details route.
  static const String groupDetailsName = 'group-details';

  /// Navigation name for the group settings route.
  static const String groupSettingsName = 'group-settings';

  /// Navigation name for the expenses route.
  static const String expensesName = 'expenses';

  /// Navigation name for the create expense route.
  static const String createExpenseName = 'create-expense';

  /// Navigation name for the expense details route.
  static const String expenseDetailsName = 'expense-details';

  /// Navigation name for the edit expense route.
  static const String editExpenseName = 'edit-expense';

  /// Navigation name for the payments route.
  static const String paymentsName = 'payments';

  /// Navigation name for the create payment route.
  static const String createPaymentName = 'create-payment';

  /// Navigation name for the balances route.
  static const String balancesName = 'balances';

  /// Navigation name for the settlement plan route.
  static const String settlementPlanName = 'settlement-plan';

  /// Navigation name for the export route.
  static const String exportName = 'export';

  /// Returns the path for group details for the given [groupId].
  static String groupDetailsPath(String groupId) => '/group/$groupId';

  /// Returns the path for group settings for the given [groupId].
  static String groupSettingsPath(String groupId) => '/group/$groupId/settings';

  /// Returns the path for expenses list for the given [groupId].
  static String expensesPath(String groupId) => '/group/$groupId/expenses';

  /// Returns the path for creating an expense in the given [groupId].
  static String createExpensePath(String groupId) =>
      '/group/$groupId/expenses/create';

  /// Returns the path for expense details.
  static String expenseDetailsPath(String groupId, String expenseId) =>
      '/group/$groupId/expenses/$expenseId';

  /// Returns the path for editing an expense.
  static String editExpensePath(String groupId, String expenseId) =>
      '/group/$groupId/expenses/$expenseId/edit';

  /// Returns the path for payments list for the given [groupId].
  static String paymentsPath(String groupId) => '/group/$groupId/payments';

  /// Returns the path for creating a payment in the given [groupId].
  static String createPaymentPath(String groupId) =>
      '/group/$groupId/payments/create';

  /// Returns the path for group balances for the given [groupId].
  static String balancesPath(String groupId) => '/group/$groupId/balances';

  /// Returns the path for settlement plan for the given [groupId].
  static String settlementPlanPath(String groupId) =>
      '/group/$groupId/balances/settlement';

  /// Returns the path for exporting data from group [groupId].
  ///
  /// Optional [groupName] can be provided as a query parameter.
  static String exportPath(String groupId, {String? groupName}) {
    final path = '/group/$groupId/export';
    if (groupName != null) {
      return '$path?groupName=${Uri.encodeComponent(groupName)}';
    }
    return path;
  }

  /// The regex pattern for extraction group invitation codes from a path.
  static const String groupInvitePattern = '/invite/([a-zA-Z0-9-]+)';

  /// Returns the path for a group invitation code.
  static String groupInvitePath(String inviteCode) => '/invite/$inviteCode';
}
