import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/app_routes.dart';

/// Extension methods for easy navigation using GoRouter
extension NavigationExtensions on BuildContext {
  // Group navigation

  /// Navigates to the groups list page.
  void goToGroups() => go(AppRoutes.groups);

  /// Pushes the group creation page onto the stack so the system back
  /// gesture returns to the previous list. On successful create the
  /// success handler calls [goToGroups] which replaces the stack to a
  /// clean `/groups` root, so the pushed entry is dropped along with it.
  void goToCreateGroup() => push(AppRoutes.createGroup);

  // Drill-down routes use `push` so the system back gesture + AppBar
  // leading arrow pop back to the previous page. `go` would replace the
  // stack and leave nothing to pop. Top-level destinations (login,
  // /groups list) keep `go` so they reset the stack cleanly.

  /// Pushes the details page for a specific group.
  void goToGroupDetails(String groupId) =>
      push(AppRoutes.groupDetailsPath(groupId));

  /// Pushes the settings page for a specific group.
  void goToGroupSettings(String groupId) =>
      push(AppRoutes.groupSettingsPath(groupId));

  // Expense navigation

  /// Pushes the expenses list page for a specific group.
  void goToExpenses(String groupId) => push(AppRoutes.expensesPath(groupId));

  /// Pushes the expense creation page for a specific group.
  void goToCreateExpense(String groupId) =>
      push(AppRoutes.createExpensePath(groupId));

  /// Pushes the details page for a specific expense.
  void goToExpenseDetails(String groupId, String expenseId) =>
      push(AppRoutes.expenseDetailsPath(groupId, expenseId));

  /// Pushes the expense editing page for a specific expense.
  void goToEditExpense(String groupId, String expenseId) =>
      push(AppRoutes.editExpensePath(groupId, expenseId));

  // Payment navigation

  /// Pushes the payments list page for a specific group.
  void goToPayments(String groupId) => push(AppRoutes.paymentsPath(groupId));

  /// Pushes the payment creation page for a specific group.
  void goToCreatePayment(String groupId) =>
      push(AppRoutes.createPaymentPath(groupId));

  // Balance navigation

  /// Pushes the balances list page for a specific group.
  void goToBalances(String groupId) => push(AppRoutes.balancesPath(groupId));

  /// Pushes the settlement plan page for a specific group.
  void goToSettlementPlan(String groupId) =>
      push(AppRoutes.settlementPlanPath(groupId));

  // Export navigation

  /// Pushes the export page for a specific group.
  void goToExport(String groupId, {String? groupName}) =>
      push(AppRoutes.exportPath(groupId, groupName: groupName));

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
