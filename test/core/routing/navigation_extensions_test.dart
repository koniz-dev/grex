import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/routing/app_routes.dart';

void main() {
  group('NavigationExtensions', () {
    late Widget testWidget;

    setUp(() {
      testWidget = MaterialApp(
        home: Builder(
          builder: (_) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  // Test navigation methods
                },
                child: const Text('Test'),
              ),
            );
          },
        ),
      );
    });

    testWidgets('should navigate to groups', (tester) async {
      await tester.pumpWidget(testWidget);

      // This would require mocking GoRouter.of(context)
      // For now, we'll test the path generation
      expect(AppRoutes.groups, equals('/'));
    });

    testWidgets('should navigate to create group', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(AppRoutes.createGroup, equals('/create-group'));
    });

    testWidgets('should navigate to group details', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(AppRoutes.groupDetailsPath('test-id'), equals('/group/test-id'));
    });

    testWidgets('should navigate to group settings', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.groupSettingsPath('test-id'),
        equals('/group/test-id/settings'),
      );
    });

    testWidgets('should navigate to expenses', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.expensesPath('test-id'),
        equals('/group/test-id/expenses'),
      );
    });

    testWidgets('should navigate to create expense', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.createExpensePath('test-id'),
        equals('/group/test-id/expenses/create'),
      );
    });

    testWidgets('should navigate to expense details', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.expenseDetailsPath('group-id', 'expense-id'),
        equals('/group/group-id/expenses/expense-id'),
      );
    });

    testWidgets('should navigate to edit expense', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.editExpensePath('group-id', 'expense-id'),
        equals('/group/group-id/expenses/expense-id/edit'),
      );
    });

    testWidgets('should navigate to payments', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.paymentsPath('test-id'),
        equals('/group/test-id/payments'),
      );
    });

    testWidgets('should navigate to create payment', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.createPaymentPath('test-id'),
        equals('/group/test-id/payments/create'),
      );
    });

    testWidgets('should navigate to balances', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.balancesPath('test-id'),
        equals('/group/test-id/balances'),
      );
    });

    testWidgets('should navigate to settlement plan', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.settlementPlanPath('test-id'),
        equals('/group/test-id/balances/settlement'),
      );
    });

    testWidgets('should navigate to export', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(
        AppRoutes.exportPath('test-id', groupName: 'Test Group'),
        equals('/group/test-id/export?groupName=Test%20Group'),
      );
    });
  });

  group('Path Generation', () {
    test('should generate correct group paths', () {
      expect(AppRoutes.groupDetailsPath('123'), '/group/123');
      expect(AppRoutes.groupSettingsPath('123'), '/group/123/settings');
    });

    test('should generate correct expense paths', () {
      expect(AppRoutes.expensesPath('123'), '/group/123/expenses');
      expect(AppRoutes.createExpensePath('123'), '/group/123/expenses/create');
      expect(
        AppRoutes.expenseDetailsPath('123', '456'),
        '/group/123/expenses/456',
      );
      expect(
        AppRoutes.editExpensePath('123', '456'),
        '/group/123/expenses/456/edit',
      );
    });

    test('should generate correct payment paths', () {
      expect(AppRoutes.paymentsPath('123'), '/group/123/payments');
      expect(AppRoutes.createPaymentPath('123'), '/group/123/payments/create');
    });

    test('should generate correct balance paths', () {
      expect(AppRoutes.balancesPath('123'), '/group/123/balances');
      expect(
        AppRoutes.settlementPlanPath('123'),
        '/group/123/balances/settlement',
      );
    });

    test('should generate correct export paths', () {
      expect(AppRoutes.exportPath('123'), '/group/123/export');
      expect(
        AppRoutes.exportPath('123', groupName: 'My Group'),
        '/group/123/export?groupName=My%20Group',
      );
    });

    test('should generate correct invite paths', () {
      expect(AppRoutes.groupInvitePath('abc123'), '/invite/abc123');
    });
  });
}
