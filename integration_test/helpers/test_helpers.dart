import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestHelpers {
  static const String testUserId = 'test-user-integration';
  static const String testUserEmail = 'integration@test.com';
  static const String testUserDisplayName = 'Integration Test User';

  late SupabaseClient supabaseClient;

  Future<void> setupTestEnvironment() async {
    // Initialize Supabase for testing
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );

    supabaseClient = Supabase.instance.client;

    // Setup test user
    await _setupTestUser();
  }

  Future<void> cleanupTestEnvironment() async {
    // Clean up test data
    await _cleanupTestData();
  }

  Future<void> resetTestData() async {
    // Remove all test data for fresh test runs
    await _cleanupTestData();
    await _setupTestUser();
  }

  Future<void> authenticateTestUser(WidgetTester tester) async {
    // Check if already authenticated
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser?.id == testUserId) {
      return;
    }

    // Navigate to login if needed
    if (find.byKey(const Key('login_page')).evaluate().isNotEmpty) {
      await _performLogin(tester);
    }
  }

  Future<Group> createTestGroup({String? name, String? currency}) async {
    final groupData = {
      'name': name ?? 'Test Group ${DateTime.now().millisecondsSinceEpoch}',
      'currency': currency ?? 'VND',
      'creator_id': testUserId,
    };

    final response = await supabaseClient
        .from('groups')
        .insert(groupData)
        .select()
        .single();

    // Add creator as administrator
    await supabaseClient.from('group_members').insert({
      'group_id': response['id'],
      'user_id': testUserId,
      'role': 'administrator',
    });

    return Group.fromJson(response);
  }

  Future<Group> createTestGroupWithRole(MemberRole role) async {
    // Create group with another user as admin
    final adminUserId = 'admin-user-${DateTime.now().millisecondsSinceEpoch}';

    final groupData = {
      'name': 'Test Group ${role.name}',
      'currency': 'VND',
      'creator_id': adminUserId,
    };

    final response = await supabaseClient
        .from('groups')
        .insert(groupData)
        .select()
        .single();

    // Add admin user
    await supabaseClient.from('group_members').insert({
      'group_id': response['id'],
      'user_id': adminUserId,
      'role': 'administrator',
    });

    // Add test user with specified role
    await supabaseClient.from('group_members').insert({
      'group_id': response['id'],
      'user_id': testUserId,
      'role': role.name,
    });

    return Group.fromJson(response);
  }

  Future<Expense> createTestExpense(
    String groupId, {
    String? description,
    double? amount,
    String? payerId,
  }) async {
    final expenseData = {
      'group_id': groupId,
      'payer_id': payerId ?? testUserId,
      'amount': amount ?? 100.0,
      'currency': 'VND',
      'description': description ?? 'Test Expense',
      'expense_date': DateTime.now().toIso8601String(),
    };

    final response = await supabaseClient
        .from('expenses')
        .insert(expenseData)
        .select()
        .single();

    // Add expense participant
    await supabaseClient.from('expense_participants').insert({
      'expense_id': response['id'],
      'user_id': testUserId,
      'share_amount': amount ?? 100.0,
    });

    return Expense.fromJson(response);
  }

  Future<Payment> createTestPayment(
    String groupId, {
    String? payerId,
    String? recipientId,
    double? amount,
  }) async {
    final paymentData = {
      'group_id': groupId,
      'payer_id': payerId ?? testUserId,
      'recipient_id': recipientId ?? 'recipient-user',
      'amount': amount ?? 50.0,
      'currency': 'VND',
      'description': 'Test Payment',
    };

    final response = await supabaseClient
        .from('payments')
        .insert(paymentData)
        .select()
        .single();

    return Payment.fromJson(response);
  }

  Future<void> navigateToGroup(WidgetTester tester, String groupId) async {
    // Find group in list and tap it
    final groupTile = find.byKey(Key('group_tile_$groupId'));
    if (groupTile.evaluate().isNotEmpty) {
      await tester.tap(groupTile);
      await tester.pumpAndSettle();
    } else {
      // Navigate using deep link or manual navigation
      await _navigateToGroupManually(tester, groupId);
    }
  }

  Future<void> navigateToGroupSettings(
    WidgetTester tester,
    String groupId,
  ) async {
    await navigateToGroup(tester, groupId);

    final settingsButton = find.byKey(const Key('group_settings_button'));
    if (settingsButton.evaluate().isNotEmpty) {
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
    }
  }

  Future<void> navigateToExpenses(WidgetTester tester, String groupId) async {
    await navigateToGroup(tester, groupId);

    final expensesTab = find.byKey(const Key('expenses_tab'));
    await tester.tap(expensesTab);
    await tester.pumpAndSettle();
  }

  Future<void> navigateToPayments(WidgetTester tester, String groupId) async {
    await navigateToGroup(tester, groupId);

    final paymentsTab = find.byKey(const Key('payments_tab'));
    await tester.tap(paymentsTab);
    await tester.pumpAndSettle();
  }

  Future<void> navigateToBalances(WidgetTester tester, String groupId) async {
    await navigateToGroup(tester, groupId);

    final balancesTab = find.byKey(const Key('balances_tab'));
    await tester.tap(balancesTab);
    await tester.pumpAndSettle();
  }

  Future<void> simulateExternalMemberAddition(
    String groupId,
    String memberEmail,
  ) async {
    // Simulate another user being added by external action
    final memberId = 'external-${DateTime.now().millisecondsSinceEpoch}';

    // Create external user
    await supabaseClient.from('users').upsert({
      'id': memberId,
      'email': memberEmail,
      'display_name': 'External User',
    });

    // Add to group
    await supabaseClient.from('group_members').insert({
      'group_id': groupId,
      'user_id': memberId,
      'role': 'editor',
    });
  }

  Future<void> simulateExternalGroupUpdate(
    String groupId,
    String newName,
  ) async {
    await supabaseClient
        .from('groups')
        .update({'name': newName})
        .eq('id', groupId);
  }

  Future<void> simulateExternalRoleChange(
    String groupId,
    String memberEmail,
    MemberRole newRole,
  ) async {
    // Find user by email
    final user = await supabaseClient
        .from('users')
        .select('id')
        .eq('email', memberEmail)
        .single();

    // Update role
    await supabaseClient
        .from('group_members')
        .update({'role': newRole.name})
        .eq('group_id', groupId)
        .eq('user_id', user['id'] as String);
  }

  Future<void> simulateExternalExpenseAddition(
    String groupId, {
    String? description,
    double? amount,
  }) async {
    await createTestExpense(
      groupId,
      description: description ?? 'External Expense',
      amount: amount ?? 75.0,
      payerId: 'external-user',
    );
  }

  Future<void> simulateExternalPaymentAddition(
    String groupId, {
    double? amount,
  }) async {
    await createTestPayment(
      groupId,
      amount: amount ?? 25.0,
      payerId: 'external-user',
      recipientId: testUserId,
    );
  }

  Future<void> waitForRealTimeUpdate({Duration? timeout}) async {
    await Future<void>.delayed(timeout ?? const Duration(seconds: 2));
  }

  Future<void> _setupTestUser() async {
    // Create or update test user
    await supabaseClient.from('users').upsert({
      'id': testUserId,
      'email': testUserEmail,
      'display_name': testUserDisplayName,
      'preferred_currency': 'VND',
    });
  }

  Future<void> _cleanupTestData() async {
    // Clean up in reverse dependency order
    await supabaseClient
        .from('expense_participants')
        .delete()
        .like('expense_id', 'test-%');

    await supabaseClient.from('expenses').delete().like('description', 'Test%');

    await supabaseClient.from('payments').delete().like('description', 'Test%');

    await supabaseClient
        .from('group_members')
        .delete()
        .eq('user_id', testUserId);

    await supabaseClient.from('groups').delete().like('name', 'Test%');

    // Clean up external test users
    await supabaseClient.from('users').delete().like('id', 'external-%');

    await supabaseClient.from('users').delete().like('id', 'admin-user-%');
  }

  Future<void> _performLogin(WidgetTester tester) async {
    // Fill in login form
    final emailField = find.byKey(const Key('email_field'));
    final passwordField = find.byKey(const Key('password_field'));
    final loginButton = find.byKey(const Key('login_button'));

    await tester.enterText(emailField, testUserEmail);
    await tester.enterText(passwordField, 'testpassword123');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }

  Future<Group> createTestGroupWithMultipleMembers() async {
    // Create group with multiple members for testing
    final group = await createTestGroup();

    // Add additional members
    final memberIds = ['member1', 'member2', 'member3'];
    for (final memberId in memberIds) {
      // Create member user
      await supabaseClient.from('users').upsert({
        'id': memberId,
        'email': '$memberId@test.com',
        'display_name': 'Test Member $memberId',
      });

      // Add to group
      await supabaseClient.from('group_members').insert({
        'group_id': group.id,
        'user_id': memberId,
        'role': 'editor',
      });
    }

    return group;
  }

  Future<Group> createTestGroupForOtherUser() async {
    // Create group for another user (not accessible by test user)
    final otherUserId = 'other-user-${DateTime.now().millisecondsSinceEpoch}';

    // Create other user
    await supabaseClient.from('users').upsert({
      'id': otherUserId,
      'email': 'other@test.com',
      'display_name': 'Other User',
    });

    final groupData = {
      'name': 'Other User Group',
      'currency': 'VND',
      'creator_id': otherUserId,
    };

    final response = await supabaseClient
        .from('groups')
        .insert(groupData)
        .select()
        .single();

    // Add creator as administrator
    await supabaseClient.from('group_members').insert({
      'group_id': response['id'],
      'user_id': otherUserId,
      'role': 'administrator',
    });

    return Group.fromJson(response);
  }

  Future<void> simulateExternalExpenseUpdate(
    String expenseId, {
    String? description,
  }) async {
    await supabaseClient
        .from('expenses')
        .update({'description': description ?? 'Updated Expense'})
        .eq('id', expenseId);
  }

  Future<void> simulateExternalExpenseDeletion(String expenseId) async {
    // Delete expense participants first
    await supabaseClient
        .from('expense_participants')
        .delete()
        .eq('expense_id', expenseId);

    // Delete expense
    await supabaseClient.from('expenses').delete().eq('id', expenseId);
  }

  Future<void> _navigateToGroupManually(
    WidgetTester tester,
    String groupId,
  ) async {
    // Navigate to groups list first
    final groupsTab = find.byKey(const Key('groups_tab'));
    if (groupsTab.evaluate().isNotEmpty) {
      await tester.tap(groupsTab);
      await tester.pumpAndSettle();
    }

    // Find and tap the specific group
    final groupTile = find.byKey(Key('group_tile_$groupId'));
    expect(groupTile, findsOneWidget);
    await tester.tap(groupTile);
    await tester.pumpAndSettle();
  }
}
