import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/app_routes.dart';

/// Extension methods for easy navigation using GoRouter
extension NavigationExtensions on BuildContext {
  // Group navigation

  /// Navigates to the groups list page.
  void goToGroups() => go(AppRoutes.groups);

  /// Navigates to the group creation page.
  void goToCreateGroup() => go(AppRoutes.createGroup);

  /// Navigates to the details page for a specific group.
  void goToGroupDetails(String groupId) =>
      go(AppRoutes.groupDetailsPath(groupId));

  /// Navigates to the settings page for a specific group.
  void goToGroupSettings(String groupId) =>
      go(AppRoutes.groupSettingsPath(groupId));

  // Expense navigation

  /// Navigates to the expenses list page for a specific group.
  void goToExpenses(String groupId) => go(AppRoutes.expensesPath(groupId));

  /// Navigates to the expense creation page for a specific group.
  void goToCreateExpense(String groupId) =>
      go(AppRoutes.createExpensePath(groupId));

  /// Navigates to the details page for a specific expense.
  void goToExpenseDetails(String groupId, String expenseId) =>
      go(AppRoutes.expenseDetailsPath(groupId, expenseId));

  /// Navigates to the expense editing page for a specific expense.
  void goToEditExpense(String groupId, String expenseId) =>
      go(AppRoutes.editExpensePath(groupId, expenseId));

  // Payment navigation

  /// Navigates to the payments list page for a specific group.
  void goToPayments(String groupId) => go(AppRoutes.paymentsPath(groupId));

  /// Navigates to the payment creation page for a specific group.
  void goToCreatePayment(String groupId) =>
      go(AppRoutes.createPaymentPath(groupId));

  // Balance navigation

  /// Navigates to the balances list page for a specific group.
  void goToBalances(String groupId) => go(AppRoutes.balancesPath(groupId));

  /// Navigates to the settlement plan page for a specific group.
  void goToSettlementPlan(String groupId) =>
      go(AppRoutes.settlementPlanPath(groupId));

  // Export navigation

  /// Navigates to the export page for a specific group.
  void goToExport(String groupId, {String? groupName}) =>
      go(AppRoutes.exportPath(groupId, groupName: groupName));

  // Push navigation (for modal-like behavior)

  /// Pushes the group creation page onto the navigation stack.
  void pushCreateGroup() => push(AppRoutes.createGroup);

  /// Pushes the expense creation page onto the navigation stack.
  void pushCreateExpense(String groupId) =>
      push(AppRoutes.createExpensePath(groupId));

  /// Pushes the payment creation page onto the navigation stack.
  void pushCreatePayment(String groupId) =>
      push(AppRoutes.createPaymentPath(groupId));

  /// Pushes the expense editing page onto the navigation stack.
  void pushEditExpense(String groupId, String expenseId) =>
      push(AppRoutes.editExpensePath(groupId, expenseId));

  // Named navigation (alternative approach)

  /// Navigates to group details using named routing.
  void goToGroupDetailsByName(String groupId) => goNamed(
    AppRoutes.groupDetailsName,
    pathParameters: {'groupId': groupId},
  );

  /// Navigates to expense details using named routing.
  void goToExpenseDetailsByName(String groupId, String expenseId) => goNamed(
    AppRoutes.expenseDetailsName,
    pathParameters: {
      'groupId': groupId,
      'expenseId': expenseId,
    },
  );

  // Utility methods

  /// Returns whether the current navigator can pop.
  bool canPop() => GoRouter.of(this).canPop();

  /// Pops the current route or navigates to the groups list if unable to pop.
  void popOrGoToGroups() {
    if (canPop()) {
      pop();
    } else {
      goToGroups();
    }
  }

  // Deep link handling

  /// Handles a group invitation code and navigates to the groups list.
  void handleGroupInvite(String inviteCode) {
    // This would typically validate the invite and navigate to
    // appropriate screen
    // For now, we'll navigate to groups list
    goToGroups();
  }
}
