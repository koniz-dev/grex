import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/app_routes.dart';

/// Custom router delegate for handling navigation state and deep links
class AppRouterDelegate {
  /// Handle deep link navigation
  static String? handleDeepLink(String link) {
    final uri = Uri.parse(link);

    // Handle group invite links
    final inviteMatch = RegExp(
      AppRoutes.groupInvitePattern,
    ).firstMatch(uri.path);
    if (inviteMatch != null) {
      final inviteCode = inviteMatch.group(1)!;
      return AppRoutes.groupInvitePath(inviteCode);
    }

    // Handle direct group links
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'group') {
      final groupId = uri.pathSegments[1];

      // Handle specific group pages
      if (uri.pathSegments.length >= 3) {
        switch (uri.pathSegments[2]) {
          case 'settings':
            return AppRoutes.groupSettingsPath(groupId);
          case 'expenses':
            if (uri.pathSegments.length >= 4) {
              final expenseId = uri.pathSegments[3];
              if (uri.pathSegments.length >= 5 &&
                  uri.pathSegments[4] == 'edit') {
                return AppRoutes.editExpensePath(groupId, expenseId);
              }
              return AppRoutes.expenseDetailsPath(groupId, expenseId);
            }
            return AppRoutes.expensesPath(groupId);
          case 'payments':
            return AppRoutes.paymentsPath(groupId);
          case 'balances':
            if (uri.pathSegments.length >= 4 &&
                uri.pathSegments[3] == 'settlement') {
              return AppRoutes.settlementPlanPath(groupId);
            }
            return AppRoutes.balancesPath(groupId);
          case 'export':
            final groupName = uri.queryParameters['groupName'];
            return AppRoutes.exportPath(groupId, groupName: groupName);
        }
      }

      return AppRoutes.groupDetailsPath(groupId);
    }

    // Default to groups list for unrecognized links
    return AppRoutes.groups;
  }

  /// Get current route information
  static RouteInformation getCurrentRoute(BuildContext context) {
    final router = GoRouter.of(context);
    return RouteInformation(
      uri: router.routeInformationProvider.value.uri,
    );
  }

  /// Check if current route matches pattern
  static bool isCurrentRoute(BuildContext context, String routeName) {
    final currentRoute = getCurrentRoute(context);
    return currentRoute.uri.path.contains(routeName);
  }

  /// Get route parameters from current route
  static Map<String, String> getCurrentRouteParameters(BuildContext context) {
    final state = GoRouterState.of(context);
    return state.pathParameters;
  }

  /// Get query parameters from current route
  static Map<String, String> getCurrentQueryParameters(BuildContext context) {
    final state = GoRouterState.of(context);
    return state.uri.queryParameters;
  }

  /// Navigate with replacement (useful for redirects)
  static void replaceWith(BuildContext context, String path) {
    context.pushReplacement(path);
  }

  /// Navigate and clear stack (useful for logout)
  static void clearAndNavigateTo(BuildContext context, String path) {
    while (context.canPop()) {
      context.pop();
    }
    context.pushReplacement(path);
  }

  /// Handle back button behavior
  static bool handleBackButton(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return true;
    }

    // If can't pop, navigate to groups (home)
    context.go(AppRoutes.groups);
    return true;
  }

  /// Generate breadcrumb navigation from current route
  static List<BreadcrumbItem> generateBreadcrumbs(BuildContext context) {
    final state = GoRouterState.of(context);
    final pathSegments = state.uri.pathSegments;
    // Always start with Groups
    final breadcrumbs = <BreadcrumbItem>[
      const BreadcrumbItem(
        title: 'Groups',
        path: AppRoutes.groups,
      ),
    ];

    if (pathSegments.isNotEmpty &&
        pathSegments[0] == 'group' &&
        pathSegments.length >= 2) {
      final groupId = pathSegments[1];

      // Add group details
      breadcrumbs.add(
        BreadcrumbItem(
          title: 'Group Details',
          path: AppRoutes.groupDetailsPath(groupId),
        ),
      );

      // Add specific pages
      if (pathSegments.length >= 3) {
        switch (pathSegments[2]) {
          case 'settings':
            breadcrumbs.add(
              BreadcrumbItem(
                title: 'Settings',
                path: AppRoutes.groupSettingsPath(groupId),
              ),
            );
          case 'expenses':
            breadcrumbs.add(
              BreadcrumbItem(
                title: 'Expenses',
                path: AppRoutes.expensesPath(groupId),
              ),
            );

            if (pathSegments.length >= 4) {
              final expenseId = pathSegments[3];
              if (expenseId == 'create') {
                breadcrumbs.add(
                  BreadcrumbItem(
                    title: 'Create Expense',
                    path: AppRoutes.createExpensePath(groupId),
                  ),
                );
              } else {
                breadcrumbs.add(
                  BreadcrumbItem(
                    title: 'Expense Details',
                    path: AppRoutes.expenseDetailsPath(groupId, expenseId),
                  ),
                );

                if (pathSegments.length >= 5 && pathSegments[4] == 'edit') {
                  breadcrumbs.add(
                    BreadcrumbItem(
                      title: 'Edit Expense',
                      path: AppRoutes.editExpensePath(groupId, expenseId),
                    ),
                  );
                }
              }
            }
          case 'payments':
            breadcrumbs.add(
              BreadcrumbItem(
                title: 'Payments',
                path: AppRoutes.paymentsPath(groupId),
              ),
            );

            if (pathSegments.length >= 4 && pathSegments[3] == 'create') {
              breadcrumbs.add(
                BreadcrumbItem(
                  title: 'Create Payment',
                  path: AppRoutes.createPaymentPath(groupId),
                ),
              );
            }
          case 'balances':
            breadcrumbs.add(
              BreadcrumbItem(
                title: 'Balances',
                path: AppRoutes.balancesPath(groupId),
              ),
            );

            if (pathSegments.length >= 4 && pathSegments[3] == 'settlement') {
              breadcrumbs.add(
                BreadcrumbItem(
                  title: 'Settlement Plan',
                  path: AppRoutes.settlementPlanPath(groupId),
                ),
              );
            }
          case 'export':
            breadcrumbs.add(
              BreadcrumbItem(
                title: 'Export',
                path: AppRoutes.exportPath(groupId),
              ),
            );
        }
      }
    }

    return breadcrumbs;
  }
}

/// Breadcrumb item for navigation
class BreadcrumbItem {
  /// Creates a new breadcrumb item.
  const BreadcrumbItem({
    required this.title,
    required this.path,
  });

  /// The display title of the breadcrumb.
  final String title;

  /// The navigation path associated with this breadcrumb.
  final String path;
}
