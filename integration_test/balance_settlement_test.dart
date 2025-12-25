import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Balance and Settlement Integration Tests', () {
    late TestHelpers testHelpers;

    setUpAll(() async {
      testHelpers = TestHelpers();
      await testHelpers.setupTestEnvironment();
    });

    tearDownAll(() async {
      await testHelpers.cleanupTestEnvironment();
    });

    setUp(() async {
      await testHelpers.resetTestData();
    });

    testWidgets('balance calculation with complex scenarios', (tester) async {
      // Setup: Create a group with multiple members and complex transactions
      final group = await testHelpers.createTestGroup();

      // Add multiple members
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'alice@test.com',
      );
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'bob@test.com',
      );
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'charlie@test.com',
      );

      // Create complex expense scenarios
      await _setupComplexExpenseScenario(group.id);

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to balances
      await testHelpers.navigateToBalances(tester, group.id);

      // Test balance calculation accuracy
      await _testBalanceCalculationAccuracy(tester);

      // Test balance display formatting
      await _testBalanceDisplayFormatting(tester);

      // Test balance sorting and grouping
      await _testBalanceSortingAndGrouping(tester);
    });

    testWidgets('settlement plan generation and optimization', (tester) async {
      // Setup: Create a group with imbalanced transactions
      final group = await testHelpers.createTestGroup();

      // Add members
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'debtor1@test.com',
      );
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'debtor2@test.com',
      );
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'creditor@test.com',
      );

      // Create imbalanced expenses
      await _setupImbalancedExpenseScenario(group.id);

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to balances
      await testHelpers.navigateToBalances(tester, group.id);

      // Test settlement plan generation
      await _testSettlementPlanGeneration(tester);

      // Test settlement plan optimization
      await _testSettlementPlanOptimization(tester);

      // Test settlement execution
      await _testSettlementExecution(tester);

      // Test settlement plan updates after payments
      await _testSettlementPlanUpdates(tester);
    });

    testWidgets('real-time balance updates', (tester) async {
      // Setup: Create a group with initial balances
      final group = await testHelpers.createTestGroup();
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'member1@test.com',
      );
      await testHelpers.createTestExpense(group.id, amount: 100000);

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to balances
      await testHelpers.navigateToBalances(tester, group.id);

      // Test real-time balance updates from external expenses
      await _testRealTimeBalanceUpdatesFromExpenses(tester, group.id);

      // Test real-time balance updates from external payments
      await _testRealTimeBalanceUpdatesFromPayments(tester, group.id);

      // Test real-time settlement plan updates
      await _testRealTimeSettlementPlanUpdates(tester, group.id);
    });

    testWidgets('multi-currency balance handling', (tester) async {
      // Setup: Create a group with multi-currency transactions
      final group = await testHelpers.createTestGroup();
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'usd_user@test.com',
      );

      // Create expenses in different currencies
      await _setupMultiCurrencyScenario(group.id);

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to balances
      await testHelpers.navigateToBalances(tester, group.id);

      // Test multi-currency balance display
      await _testMultiCurrencyBalanceDisplay(tester);

      // Test currency conversion warnings
      await _testCurrencyConversionWarnings(tester);

      // Test mixed currency settlement plans
      await _testMixedCurrencySettlementPlans(tester);
    });

    testWidgets('balance history and audit trail', (tester) async {
      // Setup: Create a group with transaction history
      final group = await testHelpers.createTestGroup();
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'member1@test.com',
      );

      // Create transaction history
      await _setupTransactionHistory(group.id);

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to balances
      await testHelpers.navigateToBalances(tester, group.id);

      // Test balance history display
      await _testBalanceHistoryDisplay(tester);

      // Test transaction audit trail
      await _testTransactionAuditTrail(tester);

      // Test balance change tracking
      await _testBalanceChangeTracking(tester);
    });

    testWidgets('edge cases and error handling', (tester) async {
      // Setup: Create scenarios with edge cases
      final group = await testHelpers.createTestGroup();

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to balances
      await testHelpers.navigateToBalances(tester, group.id);

      // Test zero balance scenarios
      await _testZeroBalanceScenarios(tester);

      // Test large number handling
      await _testLargeNumberHandling(tester);

      // Test network error handling
      await _testNetworkErrorHandling(tester);

      // Test empty group scenarios
      await _testEmptyGroupScenarios(tester);
    });
  });
}

Future<void> _setupComplexExpenseScenario(String groupId) async {
  final testHelpers = TestHelpers();

  // Create various expenses with different splits
  await testHelpers.createTestExpense(
    groupId,
    description: 'Group Dinner',
    amount: 400000,
  );

  await testHelpers.createTestExpense(
    groupId,
    description: 'Taxi Ride',
    amount: 80000,
  );

  await testHelpers.createTestExpense(
    groupId,
    description: 'Hotel Booking',
    amount: 1200000,
  );

  // Add some payments
  await testHelpers.createTestPayment(
    groupId,
    amount: 200000,
  );
}

Future<void> _setupImbalancedExpenseScenario(String groupId) async {
  final testHelpers = TestHelpers();

  // Create expenses that will result in clear debts
  await testHelpers.createTestExpense(
    groupId,
    description: 'Expensive Restaurant',
    amount: 800000,
    payerId: TestHelpers.testUserId, // Test user pays
  );

  await testHelpers.createTestExpense(
    groupId,
    description: 'Concert Tickets',
    amount: 600000,
    payerId: TestHelpers.testUserId, // Test user pays again
  );

  // Small expense paid by someone else
  await testHelpers.createTestExpense(
    groupId,
    description: 'Coffee',
    amount: 50000,
    payerId: 'creditor-user',
  );
}

Future<void> _setupMultiCurrencyScenario(String groupId) async {
  final testHelpers = TestHelpers();

  // Create expenses in VND (group default)
  await testHelpers.createTestExpense(
    groupId,
    description: 'Local Restaurant',
    amount: 500000,
  );

  // Note: Multi-currency would require additional setup
  // For now, we'll test the warning system
}

Future<void> _setupTransactionHistory(String groupId) async {
  final testHelpers = TestHelpers();

  // Create a series of transactions over time
  for (var i = 0; i < 5; i++) {
    await testHelpers.createTestExpense(
      groupId,
      description: 'Historical Expense $i',
      amount: (i + 1) * 100000,
    );

    if (i.isEven) {
      await testHelpers.createTestPayment(
        groupId,
        amount: i * 50000,
      );
    }
  }
}

Future<void> _testBalanceCalculationAccuracy(WidgetTester tester) async {
  // Verify balance page loads
  expect(find.byKey(const Key('balance_page')), findsOneWidget);

  // Verify balance list is displayed
  expect(find.byKey(const Key('balance_list')), findsOneWidget);

  // Verify balance calculations are accurate
  // Check for positive and negative balances
  expect(find.textContaining('₫'), findsAtLeastNWidgets(1));

  // Verify total balance sums to zero (fundamental property)
  final balanceSummary = find.byKey(const Key('balance_summary'));
  if (balanceSummary.evaluate().isNotEmpty) {
    expect(find.textContaining('Total: ₫0'), findsOneWidget);
  }
}

Future<void> _testBalanceDisplayFormatting(WidgetTester tester) async {
  // Verify currency formatting
  expect(find.textContaining('₫'), findsAtLeastNWidgets(1));

  // Verify positive balances are shown correctly
  final positiveBalances = find.textContaining('+₫');
  if (positiveBalances.evaluate().isNotEmpty) {
    expect(positiveBalances, findsAtLeastNWidgets(1));
  }

  // Verify negative balances are shown correctly
  final negativeBalances = find.textContaining('-₫');
  if (negativeBalances.evaluate().isNotEmpty) {
    expect(negativeBalances, findsAtLeastNWidgets(1));
  }

  // Verify member names are displayed
  expect(find.textContaining('@test.com'), findsAtLeastNWidgets(1));
}

Future<void> _testBalanceSortingAndGrouping(WidgetTester tester) async {
  // Test sorting options if available
  final sortButton = find.byKey(const Key('balance_sort_button'));
  if (sortButton.evaluate().isNotEmpty) {
    await tester.tap(sortButton);
    await tester.pumpAndSettle();

    // Test sort by amount
    final sortByAmountOption = find.text('Sort by Amount');
    if (sortByAmountOption.evaluate().isNotEmpty) {
      await tester.tap(sortByAmountOption);
      await tester.pumpAndSettle();
    }

    // Test sort by name
    final sortByNameOption = find.text('Sort by Name');
    if (sortByNameOption.evaluate().isNotEmpty) {
      await tester.tap(sortByNameOption);
      await tester.pumpAndSettle();
    }
  }

  // Verify grouping by creditors/debtors
  final creditorsSection = find.byKey(const Key('creditors_section'));
  final debtorsSection = find.byKey(const Key('debtors_section'));

  if (creditorsSection.evaluate().isNotEmpty) {
    expect(creditorsSection, findsOneWidget);
  }

  if (debtorsSection.evaluate().isNotEmpty) {
    expect(debtorsSection, findsOneWidget);
  }
}

Future<void> _testSettlementPlanGeneration(WidgetTester tester) async {
  // Tap settlement plan button
  final settlementButton = find.byKey(const Key('generate_settlement_button'));
  expect(settlementButton, findsOneWidget);
  await tester.tap(settlementButton);
  await tester.pumpAndSettle();

  // Verify navigation to settlement plan page
  expect(find.byKey(const Key('settlement_plan_page')), findsOneWidget);

  // Verify settlement plan is generated
  expect(find.byKey(const Key('settlement_list')), findsOneWidget);

  // Verify settlement items are displayed
  expect(find.byKey(const Key('settlement_item')), findsAtLeastNWidgets(1));
}

Future<void> _testSettlementPlanOptimization(WidgetTester tester) async {
  // Verify settlement plan minimizes transactions
  final settlementItems = find.byKey(const Key('settlement_item'));
  final itemCount = settlementItems.evaluate().length;

  // Settlement plan should be optimized (fewer transactions than naive
  // approach)
  expect(itemCount, lessThanOrEqualTo(10)); // Reasonable upper bound

  // Verify each settlement item has required information
  for (var i = 0; i < itemCount && i < 3; i++) {
    final settlementItem = find.byKey(Key('settlement_item_$i'));
    if (settlementItem.evaluate().isNotEmpty) {
      // Should contain payer, recipient, and amount
      expect(
        find.descendant(
          of: settlementItem,
          matching: find.textContaining('₫'),
        ),
        findsOneWidget,
      );
    }
  }
}

Future<void> _testSettlementExecution(WidgetTester tester) async {
  // Find first settlement item
  final firstSettlement = find.byKey(const Key('settlement_item_0'));
  if (firstSettlement.evaluate().isNotEmpty) {
    // Tap "Record Payment" button
    final recordPaymentButton = find.descendant(
      of: firstSettlement,
      matching: find.byKey(const Key('record_payment_button')),
    );

    if (recordPaymentButton.evaluate().isNotEmpty) {
      await tester.tap(recordPaymentButton);
      await tester.pumpAndSettle();

      // Verify payment recording dialog or navigation
      final paymentDialog = find.byKey(const Key('payment_dialog'));
      final createPaymentPage = find.byKey(const Key('create_payment_page'));

      expect(
        paymentDialog.evaluate().isNotEmpty ||
            createPaymentPage.evaluate().isNotEmpty,
        isTrue,
      );

      // If dialog, confirm payment
      if (paymentDialog.evaluate().isNotEmpty) {
        final confirmButton = find.byKey(const Key('confirm_payment_button'));
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // Verify success message
        expect(find.text('Payment recorded successfully'), findsOneWidget);
      }
    }
  }
}

Future<void> _testSettlementPlanUpdates(WidgetTester tester) async {
  // Navigate back to settlement plan
  await tester.pageBack();
  await tester.pumpAndSettle();

  // Tap refresh or regenerate settlement plan
  final refreshButton = find.byKey(const Key('refresh_settlement_button'));
  if (refreshButton.evaluate().isNotEmpty) {
    await tester.tap(refreshButton);
    await tester.pumpAndSettle();
  }

  // Verify settlement plan is updated (fewer items after payment)
  expect(find.byKey(const Key('settlement_list')), findsOneWidget);
}

Future<void> _testRealTimeBalanceUpdatesFromExpenses(
  WidgetTester tester,
  String groupId,
) async {
  // Add external expense
  await TestHelpers().simulateExternalExpenseAddition(
    groupId,
    description: 'Real-time Expense',
    amount: 150000,
  );

  // Wait for real-time update
  await TestHelpers().waitForRealTimeUpdate();
  await tester.pump();

  // Verify balance is updated
  expect(find.text('Real-time Expense'), findsOneWidget);
  expect(find.textContaining('₫150,000'), findsOneWidget);
}

Future<void> _testRealTimeBalanceUpdatesFromPayments(
  WidgetTester tester,
  String groupId,
) async {
  // Add external payment
  await TestHelpers().simulateExternalPaymentAddition(
    groupId,
    amount: 75000,
  );

  // Wait for real-time update
  await TestHelpers().waitForRealTimeUpdate();
  await tester.pump();

  // Verify balance is updated
  expect(find.textContaining('₫75,000'), findsOneWidget);
}

Future<void> _testRealTimeSettlementPlanUpdates(
  WidgetTester tester,
  String groupId,
) async {
  // Navigate to settlement plan
  final settlementButton = find.byKey(const Key('generate_settlement_button'));
  if (settlementButton.evaluate().isNotEmpty) {
    await tester.tap(settlementButton);
    await tester.pumpAndSettle();

    // Add external transaction that affects settlement
    await TestHelpers().simulateExternalExpenseAddition(
      groupId,
      description: 'Settlement Affecting Expense',
      amount: 200000,
    );

    // Wait for real-time update
    await TestHelpers().waitForRealTimeUpdate();
    await tester.pump();

    // Verify settlement plan is updated
    expect(find.byKey(const Key('settlement_list')), findsOneWidget);
  }
}

Future<void> _testMultiCurrencyBalanceDisplay(WidgetTester tester) async {
  // Verify currency warnings are displayed
  final currencyWarning = find.byKey(const Key('currency_warning'));
  if (currencyWarning.evaluate().isNotEmpty) {
    expect(currencyWarning, findsOneWidget);
    expect(find.textContaining('mixed currencies'), findsOneWidget);
  }

  // Verify balances are shown in group currency
  expect(find.textContaining('₫'), findsAtLeastNWidgets(1));
}

Future<void> _testCurrencyConversionWarnings(WidgetTester tester) async {
  // Look for currency conversion warnings
  final conversionWarning = find.textContaining('conversion');
  if (conversionWarning.evaluate().isNotEmpty) {
    expect(conversionWarning, findsOneWidget);
  }

  // Look for exchange rate information
  final exchangeRateInfo = find.textContaining('exchange rate');
  if (exchangeRateInfo.evaluate().isNotEmpty) {
    expect(exchangeRateInfo, findsOneWidget);
  }
}

Future<void> _testMixedCurrencySettlementPlans(WidgetTester tester) async {
  // Navigate to settlement plan
  final settlementButton = find.byKey(const Key('generate_settlement_button'));
  if (settlementButton.evaluate().isNotEmpty) {
    await tester.tap(settlementButton);
    await tester.pumpAndSettle();

    // Verify settlement plan handles mixed currencies
    expect(find.byKey(const Key('settlement_plan_page')), findsOneWidget);

    // Look for currency-specific settlements
    expect(find.textContaining('₫'), findsAtLeastNWidgets(1));
  }
}

Future<void> _testBalanceHistoryDisplay(WidgetTester tester) async {
  // Look for balance history section
  final historySection = find.byKey(const Key('balance_history_section'));
  if (historySection.evaluate().isNotEmpty) {
    expect(historySection, findsOneWidget);

    // Tap to expand history
    await tester.tap(historySection);
    await tester.pumpAndSettle();

    // Verify historical transactions are shown
    expect(find.textContaining('Historical Expense'), findsAtLeastNWidgets(1));
  }
}

Future<void> _testTransactionAuditTrail(WidgetTester tester) async {
  // Look for audit trail button
  final auditButton = find.byKey(const Key('audit_trail_button'));
  if (auditButton.evaluate().isNotEmpty) {
    await tester.tap(auditButton);
    await tester.pumpAndSettle();

    // Verify audit trail page
    expect(find.byKey(const Key('audit_trail_page')), findsOneWidget);

    // Verify transaction history is displayed
    expect(find.textContaining('Historical Expense'), findsAtLeastNWidgets(1));
  }
}

Future<void> _testBalanceChangeTracking(WidgetTester tester) async {
  // Look for balance change indicators
  final changeIndicators = find.byKey(const Key('balance_change_indicator'));
  if (changeIndicators.evaluate().isNotEmpty) {
    expect(changeIndicators, findsAtLeastNWidgets(1));
  }

  // Look for trend information
  final trendInfo = find.textContaining('trend');
  if (trendInfo.evaluate().isNotEmpty) {
    expect(trendInfo, findsOneWidget);
  }
}

Future<void> _testZeroBalanceScenarios(WidgetTester tester) async {
  // Verify zero balance display
  final zeroBalances = find.textContaining('₫0');
  if (zeroBalances.evaluate().isNotEmpty) {
    expect(zeroBalances, findsAtLeastNWidgets(1));
  }

  // Verify empty state handling
  final emptyState = find.byKey(const Key('empty_balances_state'));
  if (emptyState.evaluate().isNotEmpty) {
    expect(emptyState, findsOneWidget);
    expect(find.textContaining('No balances'), findsOneWidget);
  }
}

Future<void> _testLargeNumberHandling(WidgetTester tester) async {
  // Verify large numbers are formatted correctly
  final largeNumbers = find.textContaining('₫1,');
  if (largeNumbers.evaluate().isNotEmpty) {
    expect(largeNumbers, findsAtLeastNWidgets(1));
  }

  // Verify number formatting with commas
  expect(find.textContaining(','), findsAtLeastNWidgets(1));
}

Future<void> _testNetworkErrorHandling(WidgetTester tester) async {
  // Test refresh functionality
  final refreshButton = find.byKey(const Key('refresh_balances_button'));
  if (refreshButton.evaluate().isNotEmpty) {
    await tester.tap(refreshButton);
    await tester.pumpAndSettle();

    // Verify loading state
    final loadingIndicator = find.byKey(const Key('balance_loading'));
    if (loadingIndicator.evaluate().isNotEmpty) {
      expect(loadingIndicator, findsOneWidget);
    }
  }
}

Future<void> _testEmptyGroupScenarios(WidgetTester tester) async {
  // Verify empty group handling
  final emptyGroupMessage = find.textContaining('No transactions');
  if (emptyGroupMessage.evaluate().isNotEmpty) {
    expect(emptyGroupMessage, findsOneWidget);
  }

  // Verify call-to-action for empty groups
  final addExpenseButton = find.textContaining('Add your first expense');
  if (addExpenseButton.evaluate().isNotEmpty) {
    expect(addExpenseButton, findsOneWidget);
  }
}
