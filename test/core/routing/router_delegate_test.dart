import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/router_delegate.dart';

void main() {
  group('AppRouterDelegate', () {
    group('handleDeepLink', () {
      test('should handle group invite links', () {
        const inviteLink = 'https://app.grex.com/invite/abc123';
        final result = AppRouterDelegate.handleDeepLink(inviteLink);
        expect(result, equals('/invite/abc123'));
      });

      test('should handle direct group links', () {
        const groupLink = 'https://app.grex.com/group/test-group-id';
        final result = AppRouterDelegate.handleDeepLink(groupLink);
        expect(result, equals('/group/test-group-id'));
      });

      test('should handle group settings links', () {
        const settingsLink =
            'https://app.grex.com/group/test-group-id/settings';
        final result = AppRouterDelegate.handleDeepLink(settingsLink);
        expect(result, equals('/group/test-group-id/settings'));
      });

      test('should handle expenses links', () {
        const expensesLink =
            'https://app.grex.com/group/test-group-id/expenses';
        final result = AppRouterDelegate.handleDeepLink(expensesLink);
        expect(result, equals('/group/test-group-id/expenses'));
      });

      test('should handle expense details links', () {
        const expenseDetailsLink =
            'https://app.grex.com/group/test-group-id/expenses/expense-123';
        final result = AppRouterDelegate.handleDeepLink(expenseDetailsLink);
        expect(result, equals('/group/test-group-id/expenses/expense-123'));
      });

      test('should handle edit expense links', () {
        const editExpenseLink =
            'https://app.grex.com/group/test-group-id/expenses/expense-123/edit';
        final result = AppRouterDelegate.handleDeepLink(editExpenseLink);
        expect(
          result,
          equals('/group/test-group-id/expenses/expense-123/edit'),
        );
      });

      test('should handle payments links', () {
        const paymentsLink =
            'https://app.grex.com/group/test-group-id/payments';
        final result = AppRouterDelegate.handleDeepLink(paymentsLink);
        expect(result, equals('/group/test-group-id/payments'));
      });

      test('should handle balances links', () {
        const balancesLink =
            'https://app.grex.com/group/test-group-id/balances';
        final result = AppRouterDelegate.handleDeepLink(balancesLink);
        expect(result, equals('/group/test-group-id/balances'));
      });

      test('should handle settlement plan links', () {
        const settlementLink =
            'https://app.grex.com/group/test-group-id/balances/settlement';
        final result = AppRouterDelegate.handleDeepLink(settlementLink);
        expect(result, equals('/group/test-group-id/balances/settlement'));
      });

      test('should handle export links with query parameters', () {
        const exportLink =
            'https://app.grex.com/group/test-group-id/export?groupName=Test%20Group';
        final result = AppRouterDelegate.handleDeepLink(exportLink);
        expect(
          result,
          equals('/group/test-group-id/export?groupName=Test%20Group'),
        );
      });

      test('should handle export links without query parameters', () {
        const exportLink = 'https://app.grex.com/group/test-group-id/export';
        final result = AppRouterDelegate.handleDeepLink(exportLink);
        expect(result, equals('/group/test-group-id/export'));
      });

      test('should default to groups for unrecognized links', () {
        const unknownLink = 'https://app.grex.com/unknown/path';
        final result = AppRouterDelegate.handleDeepLink(unknownLink);
        expect(result, equals('/'));
      });

      test('should handle malformed URLs gracefully', () {
        const malformedLink = 'not-a-valid-url';
        final result = AppRouterDelegate.handleDeepLink(malformedLink);
        expect(result, equals('/'));
      });
    });

    group('generateBreadcrumbs', () {
      testWidgets('should generate breadcrumbs for groups page', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => Builder(
                    builder: (context) {
                      final breadcrumbs = AppRouterDelegate.generateBreadcrumbs(
                        context,
                      );
                      expect(breadcrumbs.length, equals(1));
                      expect(breadcrumbs[0].title, equals('Groups'));
                      expect(breadcrumbs[0].path, equals('/'));
                      return const Scaffold();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });

      testWidgets('should generate breadcrumbs for group details page', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/group/test-id',
              routes: [
                GoRoute(
                  path: '/group/:groupId',
                  builder: (context, state) => Builder(
                    builder: (context) {
                      final breadcrumbs = AppRouterDelegate.generateBreadcrumbs(
                        context,
                      );
                      expect(breadcrumbs.length, equals(2));
                      expect(breadcrumbs[0].title, equals('Groups'));
                      expect(breadcrumbs[1].title, equals('Group Details'));
                      return const Scaffold();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });

      testWidgets('should generate breadcrumbs for expenses page', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/group/test-id/expenses',
              routes: [
                GoRoute(
                  path: '/group/:groupId/expenses',
                  builder: (context, state) => Builder(
                    builder: (context) {
                      final breadcrumbs = AppRouterDelegate.generateBreadcrumbs(
                        context,
                      );
                      expect(breadcrumbs.length, equals(3));
                      expect(breadcrumbs[0].title, equals('Groups'));
                      expect(breadcrumbs[1].title, equals('Group Details'));
                      expect(breadcrumbs[2].title, equals('Expenses'));
                      return const Scaffold();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });

      testWidgets('should generate breadcrumbs for create expense page', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/group/test-id/expenses/create',
              routes: [
                GoRoute(
                  path: '/group/:groupId/expenses/create',
                  builder: (context, state) => Builder(
                    builder: (context) {
                      final breadcrumbs = AppRouterDelegate.generateBreadcrumbs(
                        context,
                      );
                      expect(breadcrumbs.length, equals(4));
                      expect(breadcrumbs[0].title, equals('Groups'));
                      expect(breadcrumbs[1].title, equals('Group Details'));
                      expect(breadcrumbs[2].title, equals('Expenses'));
                      expect(breadcrumbs[3].title, equals('Create Expense'));
                      return const Scaffold();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });

      testWidgets('should generate breadcrumbs for expense details page', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/group/test-id/expenses/expense-123',
              routes: [
                GoRoute(
                  path: '/group/:groupId/expenses/:expenseId',
                  builder: (context, state) => Builder(
                    builder: (context) {
                      final breadcrumbs = AppRouterDelegate.generateBreadcrumbs(
                        context,
                      );
                      expect(breadcrumbs.length, equals(4));
                      expect(breadcrumbs[0].title, equals('Groups'));
                      expect(breadcrumbs[1].title, equals('Group Details'));
                      expect(breadcrumbs[2].title, equals('Expenses'));
                      expect(breadcrumbs[3].title, equals('Expense Details'));
                      return const Scaffold();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });

      testWidgets('should generate breadcrumbs for edit expense page', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/group/test-id/expenses/expense-123/edit',
              routes: [
                GoRoute(
                  path: '/group/:groupId/expenses/:expenseId/edit',
                  builder: (context, state) => Builder(
                    builder: (context) {
                      final breadcrumbs = AppRouterDelegate.generateBreadcrumbs(
                        context,
                      );
                      expect(breadcrumbs.length, equals(5));
                      expect(breadcrumbs[0].title, equals('Groups'));
                      expect(breadcrumbs[1].title, equals('Group Details'));
                      expect(breadcrumbs[2].title, equals('Expenses'));
                      expect(breadcrumbs[3].title, equals('Expense Details'));
                      expect(breadcrumbs[4].title, equals('Edit Expense'));
                      return const Scaffold();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });
    });

    group('BreadcrumbItem', () {
      test('should create breadcrumb item with title and path', () {
        const item = BreadcrumbItem(
          title: 'Test Title',
          path: '/test/path',
        );

        expect(item.title, equals('Test Title'));
        expect(item.path, equals('/test/path'));
      });
    });
  });
}
