import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:grex/core/routing/app_router.dart';
import 'package:grex/core/routing/app_routes.dart';

void main() {
  group('AppRouter', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: AppRoutes.groups,
        routes: AppRouter.routes,
        errorBuilder: AppRouter.errorBuilder,
      );
    });

    testWidgets('should navigate to groups page by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Should start at groups page
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle group details route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to group details
      router.go(AppRoutes.groupDetailsPath('test-group-id'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle create group route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to create group
      router.go(AppRoutes.createGroup);
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle expenses route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to expenses
      router.go(AppRoutes.expensesPath('test-group-id'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle payments route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to payments
      router.go(AppRoutes.paymentsPath('test-group-id'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle balances route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to balances
      router.go(AppRoutes.balancesPath('test-group-id'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle export route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to export
      router.go(AppRoutes.exportPath('test-group-id', groupName: 'Test Group'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should show error page for invalid routes', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to invalid route
      router.go('/invalid-route');
      await tester.pumpAndSettle();

      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.text('Go to Groups'), findsOneWidget);
    });

    testWidgets('should handle nested routes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to nested expense details route
      router.go(
        AppRoutes.expenseDetailsPath('test-group-id', 'test-expense-id'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle edit expense route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to edit expense route
      router.go(AppRoutes.editExpensePath('test-group-id', 'test-expense-id'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle settlement plan route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to settlement plan
      router.go(AppRoutes.settlementPlanPath('test-group-id'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle group settings route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate to group settings
      router.go(AppRoutes.groupSettingsPath('test-group-id'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('AppRoutes', () {
    test('should generate correct paths', () {
      expect(AppRoutes.groupDetailsPath('123'), equals('/group/123'));
      expect(AppRoutes.expensesPath('123'), equals('/group/123/expenses'));
      expect(
        AppRoutes.createExpensePath('123'),
        equals('/group/123/expenses/create'),
      );
      expect(
        AppRoutes.expenseDetailsPath('123', '456'),
        equals('/group/123/expenses/456'),
      );
      expect(
        AppRoutes.editExpensePath('123', '456'),
        equals('/group/123/expenses/456/edit'),
      );
      expect(AppRoutes.paymentsPath('123'), equals('/group/123/payments'));
      expect(
        AppRoutes.createPaymentPath('123'),
        equals('/group/123/payments/create'),
      );
      expect(AppRoutes.balancesPath('123'), equals('/group/123/balances'));
      expect(
        AppRoutes.settlementPlanPath('123'),
        equals('/group/123/balances/settlement'),
      );
      expect(AppRoutes.groupSettingsPath('123'), equals('/group/123/settings'));
    });

    test('should generate export path with query parameters', () {
      expect(
        AppRoutes.exportPath('123', groupName: 'Test Group'),
        equals('/group/123/export?groupName=Test%20Group'),
      );
      expect(
        AppRoutes.exportPath('123'),
        equals('/group/123/export'),
      );
    });

    test('should generate group invite path', () {
      expect(AppRoutes.groupInvitePath('abc123'), equals('/invite/abc123'));
    });
  });
}
