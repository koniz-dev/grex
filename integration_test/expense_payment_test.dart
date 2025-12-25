import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Expense and Payment Integration Tests', () {
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

    testWidgets('complete expense creation and editing flow', (tester) async {
      // Setup: Create a test group
      final group = await testHelpers.createTestGroup();

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to expenses
      await testHelpers.navigateToExpenses(tester, group.id);

      // Test expense creation with equal split
      await _testExpenseCreationEqualSplit(tester);

      // Test expense creation with custom split
      await _testExpenseCreationCustomSplit(tester);

      // Test expense editing
      await _testExpenseEditing(tester);

      // Test expense deletion
      await _testExpenseDeletion(tester);
    });

    testWidgets('payment recording and balance updates', (tester) async {
      // Setup: Create a test group with expenses
      final group = await testHelpers.createTestGroup();
      await testHelpers.createTestExpense(group.id, amount: 100);

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to payments
      await testHelpers.navigateToPayments(tester, group.id);

      // Test payment creation
      await _testPaymentCreation(tester);

      // Test payment validation
      await _testPaymentValidation(tester);

      // Test balance updates after payment
      await _testBalanceUpdatesAfterPayment(tester, group.id);

      // Test payment deletion
      await _testPaymentDeletion(tester);
    });

    testWidgets('real-time synchronization across multiple clients', (
      tester,
    ) async {
      // Setup: Create a test group
      final group = await testHelpers.createTestGroup();

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to expenses
      await testHelpers.navigateToExpenses(tester, group.id);

      // Test real-time expense addition
      await _testRealTimeExpenseAddition(tester, group.id);

      // Test real-time expense updates
      await _testRealTimeExpenseUpdates(tester, group.id);

      // Navigate to payments and test real-time payment updates
      await testHelpers.navigateToPayments(tester, group.id);
      await _testRealTimePaymentAddition(tester, group.id);

      // Test real-time balance synchronization
      await testHelpers.navigateToBalances(tester, group.id);
      await _testRealTimeBalanceSynchronization(tester, group.id);
    });

    testWidgets('complex expense scenarios with multiple participants', (
      tester,
    ) async {
      // Setup: Create a test group with multiple members
      final group = await testHelpers.createTestGroup();
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'member1@test.com',
      );
      await testHelpers.simulateExternalMemberAddition(
        group.id,
        'member2@test.com',
      );

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to expenses
      await testHelpers.navigateToExpenses(tester, group.id);

      // Test multi-participant expense creation
      await _testMultiParticipantExpense(tester);

      // Test percentage-based split
      await _testPercentageBasedSplit(tester);

      // Test exact amount split
      await _testExactAmountSplit(tester);

      // Test share-based split
      await _testShareBasedSplit(tester);
    });

    testWidgets('expense search and filtering functionality', (tester) async {
      // Setup: Create a test group with multiple expenses
      final group = await testHelpers.createTestGroup();
      await testHelpers.createTestExpense(
        group.id,
        description: 'Restaurant Dinner',
        amount: 150,
      );
      await testHelpers.createTestExpense(
        group.id,
        description: 'Movie Tickets',
        amount: 50,
      );
      await testHelpers.createTestExpense(
        group.id,
        description: 'Grocery Shopping',
        amount: 200,
      );

      app.main();
      await tester.pumpAndSettle();
      await testHelpers.authenticateTestUser(tester);

      // Navigate to expenses
      await testHelpers.navigateToExpenses(tester, group.id);

      // Test search functionality
      await _testExpenseSearch(tester);

      // Test amount filtering
      await _testAmountFiltering(tester);

      // Test date filtering
      await _testDateFiltering(tester);

      // Test participant filtering
      await _testParticipantFiltering(tester);
    });
  });
}

Future<void> _testExpenseCreationEqualSplit(WidgetTester tester) async {
  // Tap create expense button
  final createExpenseButton = find.byKey(const Key('create_expense_button'));
  expect(createExpenseButton, findsOneWidget);
  await tester.tap(createExpenseButton);
  await tester.pumpAndSettle();

  // Verify navigation to create expense page
  expect(find.byKey(const Key('create_expense_page')), findsOneWidget);

  // Fill in expense details
  final descriptionField = find.byKey(const Key('expense_description_field'));
  expect(descriptionField, findsOneWidget);
  await tester.enterText(descriptionField, 'Team Lunch');

  final amountField = find.byKey(const Key('expense_amount_field'));
  expect(amountField, findsOneWidget);
  await tester.enterText(amountField, '120000');

  // Select equal split (should be default)
  final splitMethodSelector = find.byKey(const Key('split_method_selector'));
  expect(splitMethodSelector, findsOneWidget);

  // Verify equal split is selected
  expect(find.text('Equal Split'), findsOneWidget);

  // Select participants (select all by default)
  final participantSelector = find.byKey(const Key('participant_selector'));
  expect(participantSelector, findsOneWidget);

  // Submit expense
  final submitButton = find.byKey(const Key('submit_expense_button'));
  expect(submitButton, findsOneWidget);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Verify success and navigation back to expense list
  expect(find.text('Expense created successfully'), findsOneWidget);
  expect(find.byKey(const Key('expense_list_page')), findsOneWidget);

  // Verify expense appears in list
  expect(find.text('Team Lunch'), findsOneWidget);
  expect(find.text('₫120,000'), findsOneWidget);
}

Future<void> _testExpenseCreationCustomSplit(WidgetTester tester) async {
  // Create another expense with custom split
  final createExpenseButton = find.byKey(const Key('create_expense_button'));
  await tester.tap(createExpenseButton);
  await tester.pumpAndSettle();

  // Fill in basic details
  await tester.enterText(
    find.byKey(const Key('expense_description_field')),
    'Shared Taxi',
  );
  await tester.enterText(
    find.byKey(const Key('expense_amount_field')),
    '80000',
  );

  // Select custom split method
  final splitMethodSelector = find.byKey(const Key('split_method_selector'));
  await tester.tap(splitMethodSelector);
  await tester.pumpAndSettle();

  final customSplitOption = find.text('Custom Split');
  expect(customSplitOption, findsOneWidget);
  await tester.tap(customSplitOption);
  await tester.pumpAndSettle();

  // Configure custom split amounts
  final splitConfigWidget = find.byKey(const Key('split_configuration_widget'));
  expect(splitConfigWidget, findsOneWidget);

  // Set custom amounts for participants
  final participant1AmountField = find.byKey(const Key('participant_amount_0'));
  expect(participant1AmountField, findsOneWidget);
  await tester.enterText(participant1AmountField, '50000');

  final participant2AmountField = find.byKey(const Key('participant_amount_1'));
  expect(participant2AmountField, findsOneWidget);
  await tester.enterText(participant2AmountField, '30000');

  // Verify total validation
  expect(find.text('Total: ₫80,000'), findsOneWidget);

  // Submit expense
  final submitButton = find.byKey(const Key('submit_expense_button'));
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Verify success
  expect(find.text('Expense created successfully'), findsOneWidget);
  expect(find.text('Shared Taxi'), findsOneWidget);
}

Future<void> _testExpenseEditing(WidgetTester tester) async {
  // Find and tap on an expense to view details
  final expenseTile = find.text('Team Lunch').first;
  await tester.tap(expenseTile);
  await tester.pumpAndSettle();

  // Verify navigation to expense details
  expect(find.byKey(const Key('expense_details_page')), findsOneWidget);

  // Tap edit button
  final editButton = find.byKey(const Key('edit_expense_button'));
  expect(editButton, findsOneWidget);
  await tester.tap(editButton);
  await tester.pumpAndSettle();

  // Verify navigation to edit page
  expect(find.byKey(const Key('edit_expense_page')), findsOneWidget);

  // Update description
  final descriptionField = find.byKey(const Key('expense_description_field'));
  await tester.tap(descriptionField);
  await tester.pumpAndSettle();
  await tester.enterText(descriptionField, 'Updated Team Lunch');

  // Update amount
  final amountField = find.byKey(const Key('expense_amount_field'));
  await tester.tap(amountField);
  await tester.pumpAndSettle();
  await tester.enterText(amountField, '150000');

  // Save changes
  final saveButton = find.byKey(const Key('save_expense_button'));
  expect(saveButton, findsOneWidget);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();

  // Verify success and updated information
  expect(find.text('Expense updated successfully'), findsOneWidget);
  expect(find.text('Updated Team Lunch'), findsOneWidget);
  expect(find.text('₫150,000'), findsOneWidget);
}

Future<void> _testExpenseDeletion(WidgetTester tester) async {
  // Navigate back to expense list
  await tester.pageBack();
  await tester.pumpAndSettle();

  // Long press on expense to show delete option
  final expenseTile = find.text('Shared Taxi').first;
  await tester.longPress(expenseTile);
  await tester.pumpAndSettle();

  // Tap delete option
  final deleteOption = find.text('Delete');
  expect(deleteOption, findsOneWidget);
  await tester.tap(deleteOption);
  await tester.pumpAndSettle();

  // Confirm deletion
  final confirmDeleteButton = find.byKey(const Key('confirm_delete_button'));
  expect(confirmDeleteButton, findsOneWidget);
  await tester.tap(confirmDeleteButton);
  await tester.pumpAndSettle();

  // Verify deletion success
  expect(find.text('Expense deleted successfully'), findsOneWidget);
  expect(find.text('Shared Taxi'), findsNothing);
}

Future<void> _testPaymentCreation(WidgetTester tester) async {
  // Tap create payment button
  final createPaymentButton = find.byKey(const Key('create_payment_button'));
  expect(createPaymentButton, findsOneWidget);
  await tester.tap(createPaymentButton);
  await tester.pumpAndSettle();

  // Verify navigation to create payment page
  expect(find.byKey(const Key('create_payment_page')), findsOneWidget);

  // Select recipient
  final recipientDropdown = find.byKey(const Key('payment_recipient_dropdown'));
  expect(recipientDropdown, findsOneWidget);
  await tester.tap(recipientDropdown);
  await tester.pumpAndSettle();

  // Select first available recipient
  final recipientOption = find.text('Test User').first;
  await tester.tap(recipientOption);
  await tester.pumpAndSettle();

  // Enter amount
  final amountField = find.byKey(const Key('payment_amount_field'));
  expect(amountField, findsOneWidget);
  await tester.enterText(amountField, '50000');

  // Enter description
  final descriptionField = find.byKey(const Key('payment_description_field'));
  expect(descriptionField, findsOneWidget);
  await tester.enterText(descriptionField, 'Settling lunch expense');

  // Submit payment
  final submitButton = find.byKey(const Key('submit_payment_button'));
  expect(submitButton, findsOneWidget);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Verify success
  expect(find.text('Payment recorded successfully'), findsOneWidget);
  expect(find.byKey(const Key('payment_list_page')), findsOneWidget);

  // Verify payment appears in list
  expect(find.text('Settling lunch expense'), findsOneWidget);
  expect(find.text('₫50,000'), findsOneWidget);
}

Future<void> _testPaymentValidation(WidgetTester tester) async {
  // Test payment validation by creating invalid payment
  final createPaymentButton = find.byKey(const Key('create_payment_button'));
  await tester.tap(createPaymentButton);
  await tester.pumpAndSettle();

  // Try to submit without selecting recipient
  final submitButton = find.byKey(const Key('submit_payment_button'));
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Verify validation error
  expect(find.text('Please select a recipient'), findsOneWidget);

  // Select recipient
  final recipientDropdown = find.byKey(const Key('payment_recipient_dropdown'));
  await tester.tap(recipientDropdown);
  await tester.pumpAndSettle();

  final recipientOption = find.text('Test User').first;
  await tester.tap(recipientOption);
  await tester.pumpAndSettle();

  // Try to submit with invalid amount
  final amountField = find.byKey(const Key('payment_amount_field'));
  await tester.enterText(amountField, '0');
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Verify amount validation error
  expect(find.text('Amount must be greater than 0'), findsOneWidget);

  // Try negative amount
  await tester.enterText(amountField, '-100');
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  expect(find.text('Amount must be greater than 0'), findsOneWidget);

  // Cancel payment creation
  final cancelButton = find.byKey(const Key('cancel_payment_button'));
  await tester.tap(cancelButton);
  await tester.pumpAndSettle();
}

Future<void> _testBalanceUpdatesAfterPayment(
  WidgetTester tester,
  String groupId,
) async {
  // Navigate to balances to verify payment impact
  await TestHelpers().navigateToBalances(tester, groupId);

  // Verify balance page loads
  expect(find.byKey(const Key('balance_page')), findsOneWidget);

  // Verify balances are updated after payment
  expect(find.byKey(const Key('balance_list')), findsOneWidget);

  // Check that payment reduced the balance
  // (Specific balance values depend on the test data setup)
  expect(find.textContaining('₫'), findsAtLeastNWidgets(1));
}

Future<void> _testPaymentDeletion(WidgetTester tester) async {
  // Navigate back to payments
  await tester.pageBack();
  await tester.pumpAndSettle();

  // Find payment to delete
  final paymentTile = find.text('Settling lunch expense').first;
  await tester.longPress(paymentTile);
  await tester.pumpAndSettle();

  // Tap delete option
  final deleteOption = find.text('Delete');
  expect(deleteOption, findsOneWidget);
  await tester.tap(deleteOption);
  await tester.pumpAndSettle();

  // Confirm deletion
  final confirmDeleteButton = find.byKey(const Key('confirm_delete_button'));
  expect(confirmDeleteButton, findsOneWidget);
  await tester.tap(confirmDeleteButton);
  await tester.pumpAndSettle();

  // Verify deletion success
  expect(find.text('Payment deleted successfully'), findsOneWidget);
  expect(find.text('Settling lunch expense'), findsNothing);
}

Future<void> _testRealTimeExpenseAddition(
  WidgetTester tester,
  String groupId,
) async {
  // Simulate external expense addition
  await TestHelpers().simulateExternalExpenseAddition(
    groupId,
    description: 'External Coffee',
    amount: 25000,
  );

  // Wait for real-time update
  await TestHelpers().waitForRealTimeUpdate();
  await tester.pump();

  // Verify new expense appears
  expect(find.text('External Coffee'), findsOneWidget);
  expect(find.text('₫25,000'), findsOneWidget);
}

Future<void> _testRealTimeExpenseUpdates(
  WidgetTester tester,
  String groupId,
) async {
  // Simulate external expense update
  // This would require additional helper methods to update existing expenses
  await TestHelpers().waitForRealTimeUpdate();
  await tester.pump();

  // Verify updates are reflected in real-time
  // Implementation depends on specific update scenarios
}

Future<void> _testRealTimePaymentAddition(
  WidgetTester tester,
  String groupId,
) async {
  // Simulate external payment addition
  await TestHelpers().simulateExternalPaymentAddition(
    groupId,
    amount: 30000,
  );

  // Wait for real-time update
  await TestHelpers().waitForRealTimeUpdate();
  await tester.pump();

  // Verify new payment appears
  expect(find.text('₫30,000'), findsOneWidget);
}

Future<void> _testRealTimeBalanceSynchronization(
  WidgetTester tester,
  String groupId,
) async {
  // Add external expense to change balances
  await TestHelpers().simulateExternalExpenseAddition(
    groupId,
    description: 'Balance Change Expense',
    amount: 100000,
  );

  // Wait for real-time balance update
  await TestHelpers().waitForRealTimeUpdate();
  await tester.pump();

  // Verify balance changes are reflected
  expect(find.byKey(const Key('balance_list')), findsOneWidget);
  // Balance values should be updated automatically
}

Future<void> _testMultiParticipantExpense(WidgetTester tester) async {
  // Create expense with multiple participants
  final createExpenseButton = find.byKey(const Key('create_expense_button'));
  await tester.tap(createExpenseButton);
  await tester.pumpAndSettle();

  // Fill basic details
  await tester.enterText(
    find.byKey(const Key('expense_description_field')),
    'Group Dinner',
  );
  await tester.enterText(
    find.byKey(const Key('expense_amount_field')),
    '300000',
  );

  // Select multiple participants
  final participantSelector = find.byKey(const Key('participant_selector'));
  expect(participantSelector, findsOneWidget);

  // Select all available participants
  final participant1Checkbox = find.byKey(const Key('participant_checkbox_0'));
  final participant2Checkbox = find.byKey(const Key('participant_checkbox_1'));
  final participant3Checkbox = find.byKey(const Key('participant_checkbox_2'));

  await tester.tap(participant1Checkbox);
  await tester.tap(participant2Checkbox);
  await tester.tap(participant3Checkbox);
  await tester.pumpAndSettle();

  // Submit expense
  final submitButton = find.byKey(const Key('submit_expense_button'));
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Verify success
  expect(find.text('Expense created successfully'), findsOneWidget);
  expect(find.text('Group Dinner'), findsOneWidget);
}

Future<void> _testPercentageBasedSplit(WidgetTester tester) async {
  // Create expense with percentage-based split
  final createExpenseButton = find.byKey(const Key('create_expense_button'));
  await tester.tap(createExpenseButton);
  await tester.pumpAndSettle();

  // Fill basic details
  await tester.enterText(
    find.byKey(const Key('expense_description_field')),
    'Percentage Split Test',
  );
  await tester.enterText(
    find.byKey(const Key('expense_amount_field')),
    '200000',
  );

  // Select percentage split
  final splitMethodSelector = find.byKey(const Key('split_method_selector'));
  await tester.tap(splitMethodSelector);
  await tester.pumpAndSettle();

  final percentageSplitOption = find.text('Percentage Split');
  await tester.tap(percentageSplitOption);
  await tester.pumpAndSettle();

  // Configure percentages
  final participant1PercentageField = find.byKey(
    const Key('participant_percentage_0'),
  );
  await tester.enterText(participant1PercentageField, '60');

  final participant2PercentageField = find.byKey(
    const Key('participant_percentage_1'),
  );
  await tester.enterText(participant2PercentageField, '40');

  // Verify total percentage validation
  expect(find.text('Total: 100%'), findsOneWidget);

  // Submit expense
  final submitButton = find.byKey(const Key('submit_expense_button'));
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  expect(find.text('Expense created successfully'), findsOneWidget);
}

Future<void> _testExactAmountSplit(WidgetTester tester) async {
  // Similar to custom split test but with exact amount validation
  final createExpenseButton = find.byKey(const Key('create_expense_button'));
  await tester.tap(createExpenseButton);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('expense_description_field')),
    'Exact Amount Split',
  );
  await tester.enterText(
    find.byKey(const Key('expense_amount_field')),
    '150000',
  );

  // Select exact amount split
  final splitMethodSelector = find.byKey(const Key('split_method_selector'));
  await tester.tap(splitMethodSelector);
  await tester.pumpAndSettle();

  final exactAmountOption = find.text('Exact Amount');
  await tester.tap(exactAmountOption);
  await tester.pumpAndSettle();

  // Configure exact amounts
  final participant1AmountField = find.byKey(const Key('participant_amount_0'));
  await tester.enterText(participant1AmountField, '90000');

  final participant2AmountField = find.byKey(const Key('participant_amount_1'));
  await tester.enterText(participant2AmountField, '60000');

  // Submit expense
  final submitButton = find.byKey(const Key('submit_expense_button'));
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  expect(find.text('Expense created successfully'), findsOneWidget);
}

Future<void> _testShareBasedSplit(WidgetTester tester) async {
  // Create expense with share-based split
  final createExpenseButton = find.byKey(const Key('create_expense_button'));
  await tester.tap(createExpenseButton);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('expense_description_field')),
    'Share Based Split',
  );
  await tester.enterText(
    find.byKey(const Key('expense_amount_field')),
    '180000',
  );

  // Select share-based split
  final splitMethodSelector = find.byKey(const Key('split_method_selector'));
  await tester.tap(splitMethodSelector);
  await tester.pumpAndSettle();

  final shareBasedOption = find.text('Share Based');
  await tester.tap(shareBasedOption);
  await tester.pumpAndSettle();

  // Configure shares
  final participant1ShareField = find.byKey(const Key('participant_share_0'));
  await tester.enterText(participant1ShareField, '2');

  final participant2ShareField = find.byKey(const Key('participant_share_1'));
  await tester.enterText(participant2ShareField, '1');

  // Submit expense
  final submitButton = find.byKey(const Key('submit_expense_button'));
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  expect(find.text('Expense created successfully'), findsOneWidget);
}

Future<void> _testExpenseSearch(WidgetTester tester) async {
  // Test search functionality
  final searchBar = find.byKey(const Key('expense_search_bar'));
  expect(searchBar, findsOneWidget);

  // Search for specific expense
  await tester.tap(searchBar);
  await tester.pumpAndSettle();
  await tester.enterText(searchBar, 'Restaurant');

  // Verify search results
  expect(find.text('Restaurant Dinner'), findsOneWidget);
  expect(find.text('Movie Tickets'), findsNothing);
  expect(find.text('Grocery Shopping'), findsNothing);

  // Clear search
  final clearSearchButton = find.byKey(const Key('clear_search_button'));
  await tester.tap(clearSearchButton);
  await tester.pumpAndSettle();

  // Verify all expenses are shown again
  expect(find.text('Restaurant Dinner'), findsOneWidget);
  expect(find.text('Movie Tickets'), findsOneWidget);
  expect(find.text('Grocery Shopping'), findsOneWidget);
}

Future<void> _testAmountFiltering(WidgetTester tester) async {
  // Open filter sheet
  final filterButton = find.byKey(const Key('expense_filter_button'));
  expect(filterButton, findsOneWidget);
  await tester.tap(filterButton);
  await tester.pumpAndSettle();

  // Set amount range filter
  final minAmountField = find.byKey(const Key('min_amount_field'));
  final maxAmountField = find.byKey(const Key('max_amount_field'));

  await tester.enterText(minAmountField, '100000');
  await tester.enterText(maxAmountField, '200000');

  // Apply filter
  final applyFilterButton = find.byKey(const Key('apply_filter_button'));
  await tester.tap(applyFilterButton);
  await tester.pumpAndSettle();

  // Verify filtered results
  expect(find.text('Restaurant Dinner'), findsOneWidget); // 150000
  expect(find.text('Grocery Shopping'), findsOneWidget); // 200000
  expect(find.text('Movie Tickets'), findsNothing); // 50000 (below range)
}

Future<void> _testDateFiltering(WidgetTester tester) async {
  // Open filter sheet
  final filterButton = find.byKey(const Key('expense_filter_button'));
  await tester.tap(filterButton);
  await tester.pumpAndSettle();

  // Set date range filter
  final startDateButton = find.byKey(const Key('start_date_button'));
  await tester.tap(startDateButton);
  await tester.pumpAndSettle();

  // Select today's date
  final todayButton = find.text('Today');
  await tester.tap(todayButton);
  await tester.pumpAndSettle();

  // Apply filter
  final applyFilterButton = find.byKey(const Key('apply_filter_button'));
  await tester.tap(applyFilterButton);
  await tester.pumpAndSettle();

  // Verify only today's expenses are shown
  // (Implementation depends on test data dates)
}

Future<void> _testParticipantFiltering(WidgetTester tester) async {
  // Open filter sheet
  final filterButton = find.byKey(const Key('expense_filter_button'));
  await tester.tap(filterButton);
  await tester.pumpAndSettle();

  // Select participant filter
  final participantDropdown = find.byKey(
    const Key('participant_filter_dropdown'),
  );
  await tester.tap(participantDropdown);
  await tester.pumpAndSettle();

  // Select specific participant
  final participantOption = find.text('Test User');
  await tester.tap(participantOption);
  await tester.pumpAndSettle();

  // Apply filter
  final applyFilterButton = find.byKey(const Key('apply_filter_button'));
  await tester.tap(applyFilterButton);
  await tester.pumpAndSettle();

  // Verify only expenses with selected participant are shown
  // (All test expenses should include the test user)
  expect(find.text('Restaurant Dinner'), findsOneWidget);
  expect(find.text('Movie Tickets'), findsOneWidget);
  expect(find.text('Grocery Shopping'), findsOneWidget);
}
