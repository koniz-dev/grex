import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/app_routes.dart';
import 'package:grex/features/auth/presentation/screens/auth_screen_wrappers.dart';
import 'package:grex/features/balances/presentation/pages/balance_page.dart';
import 'package:grex/features/balances/presentation/pages/settlement_plan_page.dart';
import 'package:grex/features/expenses/presentation/pages/create_expense_page.dart';
import 'package:grex/features/expenses/presentation/pages/edit_expense_page.dart';
import 'package:grex/features/expenses/presentation/pages/expense_details_page.dart';
import 'package:grex/features/expenses/presentation/pages/expense_list_page.dart';
import 'package:grex/features/export/presentation/pages/export_page.dart';
import 'package:grex/features/groups/presentation/pages/create_group_page.dart';
import 'package:grex/features/groups/presentation/pages/group_details_page.dart';
import 'package:grex/features/groups/presentation/pages/group_list_page.dart';
import 'package:grex/features/groups/presentation/pages/group_settings_page.dart';
import 'package:grex/features/payments/presentation/pages/create_payment_page.dart';
import 'package:grex/features/payments/presentation/pages/payment_list_page.dart';

/// Main app router configuration using GoRouter
class AppRouter {
  /// List of routes for the application
  static final List<RouteBase> routes = [
    // Auth Routes
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.loginName,
      builder: (context, state) => const LoginScreenWrapper(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: AppRoutes.registerName,
      builder: (context, state) => const RegisterScreenWrapper(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: AppRoutes.forgotPasswordName,
      builder: (context, state) => const ForgotPasswordScreenWrapper(),
    ),
    GoRoute(
      path: AppRoutes.emailVerification,
      name: AppRoutes.emailVerificationName,
      builder: (context, state) => const EmailVerificationScreenWrapper(),
    ),

    // Group Management Routes
    GoRoute(
      path: AppRoutes.groups,
      name: AppRoutes.groupsName,
      builder: (context, state) => const GroupListPage(),
    ),
    GoRoute(
      path: AppRoutes.createGroup,
      name: AppRoutes.createGroupName,
      builder: (context, state) => const CreateGroupPage(),
    ),
    GoRoute(
      path: AppRoutes.groupDetails,
      name: AppRoutes.groupDetailsName,
      builder: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        return GroupDetailsPage(groupId: groupId);
      },
      routes: [
        // Nested routes under group details
        GoRoute(
          path: 'settings',
          name: AppRoutes.groupSettingsName,
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            return GroupSettingsPage(groupId: groupId);
          },
        ),
        GoRoute(
          path: 'expenses',
          name: AppRoutes.expensesName,
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            final groupName = state.uri.queryParameters['groupName'] ?? 'Group';
            final groupCurrency =
                state.uri.queryParameters['groupCurrency'] ?? 'USD';
            return ExpenseListPage(
              groupId: groupId,
              groupName: groupName,
              groupCurrency: groupCurrency,
            );
          },
          routes: [
            GoRoute(
              path: 'create',
              name: AppRoutes.createExpenseName,
              builder: (context, state) {
                final groupId = state.pathParameters['groupId']!;
                final groupCurrency =
                    state.uri.queryParameters['groupCurrency'] ?? 'USD';
                return CreateExpensePage(
                  groupId: groupId,
                  groupCurrency: groupCurrency,
                );
              },
            ),
            GoRoute(
              path: ':expenseId',
              name: AppRoutes.expenseDetailsName,
              builder: (context, state) {
                final groupId = state.pathParameters['groupId']!;
                final expenseId = state.pathParameters['expenseId']!;
                return ExpenseDetailsPage(
                  groupId: groupId,
                  expenseId: expenseId,
                );
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  name: AppRoutes.editExpenseName,
                  builder: (context, state) {
                    final groupId = state.pathParameters['groupId']!;
                    final expenseId = state.pathParameters['expenseId']!;
                    return EditExpensePage(
                      expenseId: expenseId,
                      groupId: groupId,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'payments',
          name: AppRoutes.paymentsName,
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            final groupName = state.uri.queryParameters['groupName'] ?? 'Group';
            final groupCurrency =
                state.uri.queryParameters['groupCurrency'] ?? 'USD';
            return PaymentListPage(
              groupId: groupId,
              groupName: groupName,
              groupCurrency: groupCurrency,
            );
          },
          routes: [
            GoRoute(
              path: 'create',
              name: AppRoutes.createPaymentName,
              builder: (context, state) {
                final groupId = state.pathParameters['groupId']!;
                final groupCurrency =
                    state.uri.queryParameters['groupCurrency'] ?? 'USD';
                return CreatePaymentPage(
                  groupId: groupId,
                  groupCurrency: groupCurrency,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'balances',
          name: AppRoutes.balancesName,
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            final groupName = state.uri.queryParameters['groupName'] ?? 'Group';
            final groupCurrency =
                state.uri.queryParameters['groupCurrency'] ?? 'USD';
            return BalancePage(
              groupId: groupId,
              groupName: groupName,
              groupCurrency: groupCurrency,
            );
          },
          routes: [
            GoRoute(
              path: 'settlement',
              name: AppRoutes.settlementPlanName,
              builder: (context, state) {
                final groupId = state.pathParameters['groupId']!;
                final groupName =
                    state.uri.queryParameters['groupName'] ?? 'Group';
                final groupCurrency =
                    state.uri.queryParameters['groupCurrency'] ?? 'USD';
                return SettlementPlanPage(
                  groupId: groupId,
                  groupName: groupName,
                  groupCurrency: groupCurrency,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'export',
          name: AppRoutes.exportName,
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            final groupName = state.uri.queryParameters['groupName'] ?? 'Group';
            return ExportPage(groupId: groupId, groupName: groupName);
          },
        ),
      ],
    ),
  ];

  /// Error builder for GoRouter
  static Widget errorBuilder(BuildContext context, GoRouterState state) =>
      Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'The page "${state.uri}" could not be found.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.groups),
                child: const Text('Go to Groups'),
              ),
            ],
          ),
        ),
      );
}
