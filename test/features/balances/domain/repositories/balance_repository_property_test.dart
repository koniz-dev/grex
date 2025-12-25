// This diagnostic is ignored because property-based tests often use
// generators that require non-final fields for flexibility.
// ignore_for_file: must_be_immutable
import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/balances/data/repositories/supabase_balance_repository.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/domain/entities/settlement.dart';
import 'package:grex/features/balances/domain/repositories/balance_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// Fake class for maybeSingle() which returns PostgrestTransformBuilder
// that also implements Future
class _FakePostgrestTransformBuilderForMaybeSingle extends Fake
    implements
        PostgrestTransformBuilder<Map<String, dynamic>?>,
        Future<Map<String, dynamic>?> {
  _FakePostgrestTransformBuilderForMaybeSingle(this._value);
  final Map<String, dynamic>? _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic>? value) onValue, {
    Function? onError,
  }) async {
    return onValue(_value);
  }

  @override
  Future<Map<String, dynamic>?> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return Future<Map<String, dynamic>?>.value(_value);
  }

  @override
  Stream<Map<String, dynamic>?> asStream() {
    return Stream<Map<String, dynamic>?>.value(_value);
  }

  @override
  Future<Map<String, dynamic>?> timeout(
    Duration timeLimit, {
    FutureOr<Map<String, dynamic>?> Function()? onTimeout,
  }) {
    return Future<Map<String, dynamic>?>.value(_value);
  }

  @override
  Future<Map<String, dynamic>?> whenComplete(
    FutureOr<void> Function() action,
  ) {
    return Future<Map<String, dynamic>?>.value(_value);
  }
}

// Fake class for select() which returns
// PostgrestFilterBuilder<List<Map<String, dynamic>>>
class _FakePostgrestFilterBuilderForSelect extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  _FakePostgrestFilterBuilderForSelect();

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return _FakePostgrestTransformBuilderForMaybeSingle(null);
  }
}

// Fake class for rpc() which returns PostgrestFilterBuilder that also
// implements Future
class _FakePostgrestFilterBuilderForRpc extends Fake
    implements
        PostgrestFilterBuilder<List<Map<String, dynamic>>>,
        Future<List<Map<String, dynamic>>> {
  _FakePostgrestFilterBuilderForRpc(this._value);
  final List<Map<String, dynamic>> _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    return onValue(_value);
  }

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return Future<List<Map<String, dynamic>>>.value(_value);
  }

  @override
  Stream<List<Map<String, dynamic>>> asStream() {
    return Stream<List<Map<String, dynamic>>>.value(_value);
  }

  @override
  Future<List<Map<String, dynamic>>> timeout(
    Duration timeLimit, {
    FutureOr<List<Map<String, dynamic>>> Function()? onTimeout,
  }) {
    return Future<List<Map<String, dynamic>>>.value(_value);
  }

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
    FutureOr<void> Function() action,
  ) {
    return Future<List<Map<String, dynamic>>>.value(_value);
  }
}

/// Property-based test generators for Balance entities
class BalanceTestGenerators {
  static final Random _random = Random();

  /// Generate a random balance amount (can be positive, negative, or zero)
  static double generateBalanceAmount() {
    // Generate balances between -1000 and 1000
    return (_random.nextDouble() * 2000) - 1000;
  }

  /// Generate a random currency code
  static String generateCurrency() {
    final currencies = ['VND', 'USD', 'EUR', 'GBP', 'JPY'];
    return currencies[_random.nextInt(currencies.length)];
  }

  /// Generate a random user ID
  static String generateUserId() {
    return 'user-${_random.nextInt(10000)}';
  }

  /// Generate a random group ID
  static String generateGroupId() {
    return 'group-${_random.nextInt(10000)}';
  }

  /// Generate a random display name
  static String generateDisplayName() {
    final names = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank'];
    return names[_random.nextInt(names.length)];
  }

  /// Generate a random Balance entity for testing

  /// Generate a list of balances that sum to zero (balanced group)
  static List<Balance> generateBalancedGroup({
    required String currency,
    int? memberCount,
  }) {
    final count = memberCount ?? (_random.nextInt(5) + 2); // 2-6 members
    final balances = <Balance>[];

    // Generate random balances for all but the last member
    var totalBalance = 0.0;
    for (var i = 0; i < count - 1; i++) {
      final balance = generateBalanceAmount();
      totalBalance += balance;

      balances.add(
        Balance(
          userId: generateUserId(),
          displayName: generateDisplayName(),
          balance: balance,
          currency: currency,
        ),
      );
    }

    // Last member gets the negative of the total to balance the group
    balances.add(
      Balance(
        userId: generateUserId(),
        displayName: generateDisplayName(),
        balance: -totalBalance,
        currency: currency,
      ),
    );

    return balances;
  }

  /// Generate a random Settlement entity for testing
}

void main() {
  group('BalanceRepository Property Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late BalanceRepository repository;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();

      // Setup basic mocks
      when(mockSupabaseClient.auth).thenReturn(mockAuth);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('test-user-id');

      repository = SupabaseBalanceRepository(
        supabaseClient: mockSupabaseClient,
      );
    });

    group('Property 18: Balance display shows net amounts', () {
      test(
        'should display correct net amounts for any group configuration',
        () async {
          // Property: For any group with expenses and payments, the displayed
          // balances should represent the net amounts each member owes or
          // is owed

          const iterations = 100;

          for (var i = 0; i < iterations; i++) {
            final groupId = BalanceTestGenerators.generateGroupId();
            final currency = BalanceTestGenerators.generateCurrency();

            // Generate balanced group (balances sum to zero)
            final balances = BalanceTestGenerators.generateBalancedGroup(
              currency: currency,
              memberCount: Random().nextInt(6) + 2, // 2-7 members
            );

            // Mock group membership check
            _setupGroupMembershipMock(
              mockSupabaseClient,
              groupId,
              'test-user-id',
              true,
            );

            // Mock balance calculation function
            _setupBalanceCalculationMock(mockSupabaseClient, groupId, balances);

            // Act
            final result = await repository.getGroupBalances(groupId);

            // Assert - Property: Balances should represent net amounts
            expect(
              result.isRight(),
              isTrue,
              reason: 'Balance calculation should succeed (iteration $i)',
            );

            result.fold(
              (failure) => fail('Should not fail for valid group: $failure'),
              (calculatedBalances) {
                // Property: All balances should have the same currency
                final currencies = calculatedBalances
                    .map((b) => b.currency)
                    .toSet();
                expect(
                  currencies.length,
                  equals(1),
                  reason:
                      'All balances should have same currency (iteration $i)',
                );

                // Property: Total of all balances should be zero
                // (or very close)
                final totalBalance = calculatedBalances.fold<double>(
                  0,
                  (sum, balance) => sum + balance.balance,
                );

                expect(
                  totalBalance,
                  closeTo(0.0, 0.01),
                  reason: 'Total balances should sum to zero (iteration $i)',
                );

                // Property: Each balance should be a valid number
                for (final balance in calculatedBalances) {
                  expect(
                    balance.balance.isFinite,
                    isTrue,
                    reason: 'Balance should be finite number (iteration $i)',
                  );
                  expect(
                    balance.userId.isNotEmpty,
                    isTrue,
                    reason: 'Balance should have valid user ID (iteration $i)',
                  );
                  expect(
                    balance.displayName.isNotEmpty,
                    isTrue,
                    reason: 'Balance should have display name (iteration $i)',
                  );
                }
              },
            );
          }
        },
      );

      test('should handle zero balances correctly', () async {
        // Property: When all members have zero balance, the group should be
        // considered settled

        const iterations = 30;

        for (var i = 0; i < iterations; i++) {
          final groupId = BalanceTestGenerators.generateGroupId();
          final currency = BalanceTestGenerators.generateCurrency();
          final memberCount = Random().nextInt(5) + 2; // 2-6 members

          // Generate all zero balances
          final balances = List.generate(
            memberCount,
            (index) => Balance(
              userId: BalanceTestGenerators.generateUserId(),
              displayName: BalanceTestGenerators.generateDisplayName(),
              balance: 0,
              currency: currency,
            ),
          );

          // Mock group membership and balance calculation
          _setupGroupMembershipMock(
            mockSupabaseClient,
            groupId,
            'test-user-id',
            true,
          );
          _setupBalanceCalculationMock(mockSupabaseClient, groupId, balances);

          // Act
          final result = await repository.getGroupBalances(groupId);

          // Assert - Property: Zero balances should be handled correctly
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail for zero balances: $failure'),
            (calculatedBalances) {
              // Property: All balances should be zero
              for (final balance in calculatedBalances) {
                expect(
                  balance.balance,
                  equals(0.0),
                  reason: 'All balances should be zero (iteration $i)',
                );
              }

              // Property: Group should be considered settled
              final totalBalance = calculatedBalances.fold<double>(
                0,
                (sum, balance) => sum + balance.balance,
              );
              expect(
                totalBalance,
                equals(0.0),
                reason:
                    'Total should be exactly zero for settled group '
                    '(iteration $i)',
              );
            },
          );
        }
      });

      test('should preserve balance precision', () async {
        // Property: Balance calculations should preserve reasonable precision
        // and handle rounding correctly

        const iterations = 50;

        for (var i = 0; i < iterations; i++) {
          final groupId = BalanceTestGenerators.generateGroupId();
          final currency = BalanceTestGenerators.generateCurrency();

          // Generate balances with various precision levels
          final balances = <Balance>[];
          final precisionAmounts = [
            0.01, // 2 decimal places
            0.001, // 3 decimal places
            1.0, // Whole number
            99.99, // Standard currency amount
            0.333333, // Repeating decimal
          ];

          var totalBalance = 0.0;
          for (var j = 0; j < precisionAmounts.length - 1; j++) {
            final amount = precisionAmounts[j] * (Random().nextBool() ? 1 : -1);
            totalBalance += amount;

            balances.add(
              Balance(
                userId: BalanceTestGenerators.generateUserId(),
                displayName: BalanceTestGenerators.generateDisplayName(),
                balance: amount,
                currency: currency,
              ),
            );
          }

          // Last balance to make total zero
          balances.add(
            Balance(
              userId: BalanceTestGenerators.generateUserId(),
              displayName: BalanceTestGenerators.generateDisplayName(),
              balance: -totalBalance,
              currency: currency,
            ),
          );

          // Mock setup
          _setupGroupMembershipMock(
            mockSupabaseClient,
            groupId,
            'test-user-id',
            true,
          );
          _setupBalanceCalculationMock(mockSupabaseClient, groupId, balances);

          // Act
          final result = await repository.getGroupBalances(groupId);

          // Assert - Property: Precision should be preserved
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail for precision test: $failure'),
            (calculatedBalances) {
              // Property: Total should still be zero within tolerance
              final totalBalance = calculatedBalances.fold<double>(
                0,
                (sum, balance) => sum + balance.balance,
              );

              expect(
                totalBalance,
                closeTo(0.0, 0.001),
                reason:
                    'Total should be zero within precision tolerance '
                    '(iteration $i)',
              );

              // Property: Individual balances should be reasonable
              for (final balance in calculatedBalances) {
                expect(
                  balance.balance.abs(),
                  lessThan(1000.0),
                  reason:
                      'Individual balances should be reasonable (iteration $i)',
                );
              }
            },
          );
        }
      });
    });

    group('Property 19: Balance calculation includes all transactions', () {
      test(
        'should include all expenses and payments in balance calculation',
        () async {
          // Property: Balance calculations should account for all expenses and
          // payments in the group, not missing any transactions

          const iterations = 50;

          for (var i = 0; i < iterations; i++) {
            final groupId = BalanceTestGenerators.generateGroupId();
            final currency = BalanceTestGenerators.generateCurrency();

            // Generate realistic balances that could result from transactions
            final balances = BalanceTestGenerators.generateBalancedGroup(
              currency: currency,
              memberCount: Random().nextInt(4) + 3, // 3-6 members
            );

            // Mock group membership and balance calculation
            _setupGroupMembershipMock(
              mockSupabaseClient,
              groupId,
              'test-user-id',
              true,
            );
            _setupBalanceCalculationMock(mockSupabaseClient, groupId, balances);

            // Act
            final result = await repository.getGroupBalances(groupId);

            // Assert - Property: All transactions should be included
            expect(
              result.isRight(),
              isTrue,
              reason: 'Balance calculation should succeed (iteration $i)',
            );

            result.fold(
              (failure) => fail('Should not fail: $failure'),
              (calculatedBalances) {
                // Property: Should have balance for each member
                expect(
                  calculatedBalances.isNotEmpty,
                  isTrue,
                  reason:
                      'Should have balances for group members (iteration $i)',
                );

                // Property: Each member should have exactly one balance entry
                final userIds = calculatedBalances
                    .map((b) => b.userId)
                    .toList();
                final uniqueUserIds = userIds.toSet();
                expect(
                  userIds.length,
                  equals(uniqueUserIds.length),
                  reason:
                      'Each user should have exactly one balance entry '
                      '(iteration $i)',
                );

                // Property: Total balances should sum to zero (all transactions
                // included)
                final totalBalance = calculatedBalances.fold<double>(
                  0,
                  (sum, balance) => sum + balance.balance,
                );

                expect(
                  totalBalance,
                  closeTo(0.0, 0.01),
                  reason:
                      'Total balances should sum to zero when all '
                      'transactions included (iteration $i)',
                );
              },
            );
          }
        },
      );

      test('should handle groups with no transactions', () async {
        // Property: Groups with no expenses or payments should have zero
        // balances

        const iterations = 20;

        for (var i = 0; i < iterations; i++) {
          final groupId = BalanceTestGenerators.generateGroupId();
          final currency = BalanceTestGenerators.generateCurrency();
          final memberCount = Random().nextInt(4) + 2; // 2-5 members

          // Generate zero balances (no transactions)
          final balances = List.generate(
            memberCount,
            (index) => Balance(
              userId: BalanceTestGenerators.generateUserId(),
              displayName: BalanceTestGenerators.generateDisplayName(),
              balance: 0,
              currency: currency,
            ),
          );

          // Mock setup
          _setupGroupMembershipMock(
            mockSupabaseClient,
            groupId,
            'test-user-id',
            true,
          );
          _setupBalanceCalculationMock(mockSupabaseClient, groupId, balances);

          // Act
          final result = await repository.getGroupBalances(groupId);

          // Assert - Property: No transactions should result in zero balances
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail for empty group: $failure'),
            (calculatedBalances) {
              // Property: All balances should be zero
              for (final balance in calculatedBalances) {
                expect(
                  balance.balance,
                  equals(0.0),
                  reason:
                      'Balance should be zero with no transactions '
                      '(iteration $i)',
                );
              }
            },
          );
        }
      });

      test(
        'should maintain consistency across multiple calculations',
        () async {
          // Property: Multiple calculations of the same group should return
          // consistent results (idempotent)

          const iterations = 30;

          for (var i = 0; i < iterations; i++) {
            final groupId = BalanceTestGenerators.generateGroupId();
            final currency = BalanceTestGenerators.generateCurrency();

            final balances = BalanceTestGenerators.generateBalancedGroup(
              currency: currency,
            );

            // Mock setup
            _setupGroupMembershipMock(
              mockSupabaseClient,
              groupId,
              'test-user-id',
              true,
            );
            _setupBalanceCalculationMock(mockSupabaseClient, groupId, balances);

            // Act - Calculate balances multiple times
            final result1 = await repository.getGroupBalances(groupId);
            final result2 = await repository.getGroupBalances(groupId);

            // Assert - Property: Results should be consistent
            expect(result1.isRight(), isTrue);
            expect(result2.isRight(), isTrue);

            result1.fold(
              (failure) => fail('First calculation should not fail: $failure'),
              (balances1) {
                result2.fold(
                  (failure) =>
                      fail('Second calculation should not fail: $failure'),
                  (balances2) {
                    // Property: Both calculations should return same results
                    expect(
                      balances1.length,
                      equals(balances2.length),
                      reason:
                          'Both calculations should return same number of '
                          'balances (iteration $i)',
                    );

                    // Sort by user ID for comparison
                    balances1.sort((a, b) => a.userId.compareTo(b.userId));
                    balances2.sort((a, b) => a.userId.compareTo(b.userId));

                    for (var j = 0; j < balances1.length; j++) {
                      expect(
                        balances1[j].userId,
                        equals(balances2[j].userId),
                        reason:
                            'User IDs should match (iteration $i, balance $j)',
                      );
                      expect(
                        balances1[j].balance,
                        closeTo(balances2[j].balance, 0.001),
                        reason:
                            'Balance amounts should match (iteration $i, '
                            'balance $j)',
                      );
                    }
                  },
                );
              },
            );
          }
        },
      );
    });

    group('Property 20: Settlement plan minimizes transactions', () {
      test(
        'should generate settlement plan that minimizes number of transactions',
        () async {
          // Property: For any group with non-zero balances, the settlement
          // plan should minimize the number of transactions needed to settle
          // all debts

          const iterations = 50;

          for (var i = 0; i < iterations; i++) {
            final groupId = BalanceTestGenerators.generateGroupId();
            final currency = BalanceTestGenerators.generateCurrency();

            // Generate unbalanced group (some owe, some are owed)
            final memberCount = Random().nextInt(4) + 3; // 3-6 members
            final balances = <Balance>[];

            // Create some positive and negative balances
            var totalBalance = 0;
            for (var j = 0; j < memberCount - 1; j++) {
              final balance = Random().nextDouble() * 200 - 100; // -100 to 100
              totalBalance += balance.toInt();

              balances.add(
                Balance(
                  userId: BalanceTestGenerators.generateUserId(),
                  displayName: BalanceTestGenerators.generateDisplayName(),
                  balance: balance,
                  currency: currency,
                ),
              );
            }

            // Last member balances the group
            balances.add(
              Balance(
                userId: BalanceTestGenerators.generateUserId(),
                displayName: BalanceTestGenerators.generateDisplayName(),
                balance: -totalBalance.toDouble(),
                currency: currency,
              ),
            );

            // Generate optimal settlement plan
            final settlements = _generateOptimalSettlements(balances);

            // Mock group membership and settlement plan
            _setupGroupMembershipMock(
              mockSupabaseClient,
              groupId,
              'test-user-id',
              true,
            );
            _setupSettlementPlanMock(mockSupabaseClient, groupId, settlements);

            // Act
            final result = await repository.getSettlementPlan(groupId);

            // Assert - Property: Settlement plan should minimize transactions
            expect(
              result.isRight(),
              isTrue,
              reason:
                  'Settlement plan generation should succeed (iteration $i)',
            );

            result.fold(
              (failure) => fail('Should not fail for valid group: $failure'),
              (settlementPlan) {
                // Property: Settlement plan should not be empty if balances
                // are non-zero
                final hasNonZeroBalances = balances.any(
                  (b) => b.balance.abs() > 0.01,
                );
                if (hasNonZeroBalances) {
                  expect(
                    settlementPlan.isNotEmpty,
                    isTrue,
                    reason:
                        'Settlement plan should not be empty for unbalanced '
                        'group (iteration $i)',
                  );
                }

                // Property: All settlement amounts should be positive
                for (final settlement in settlementPlan) {
                  expect(
                    settlement.amount,
                    greaterThan(0),
                    reason:
                        'Settlement amounts should be positive (iteration $i)',
                  );
                  expect(
                    settlement.payerId,
                    isNot(equals(settlement.recipientId)),
                    reason:
                        'Payer and recipient should be different '
                        '(iteration $i)',
                  );
                }

                // Property: Settlement plan should not exceed theoretical
                // minimum
                final debtors = balances.where((b) => b.balance < 0).length;
                final creditors = balances.where((b) => b.balance > 0).length;
                final theoreticalMinimum = min(debtors, creditors);

                expect(
                  settlementPlan.length,
                  lessThanOrEqualTo(theoreticalMinimum + 1),
                  reason:
                      'Settlement plan should not exceed theoretical '
                      'minimum (iteration $i)',
                );

                // Property: All settlements should have same currency
                if (settlementPlan.isNotEmpty) {
                  final currencies = settlementPlan
                      .map((s) => s.currency)
                      .toSet();
                  expect(
                    currencies.length,
                    equals(1),
                    reason:
                        'All settlements should have same currency '
                        '(iteration $i)',
                  );
                }
              },
            );
          }
        },
      );

      test('should generate empty settlement plan '
          'for balanced groups', () async {
        // Property: Groups where all balances are zero should have empty
        // settlement plan

        const iterations = 30;

        for (var i = 0; i < iterations; i++) {
          final groupId = BalanceTestGenerators.generateGroupId();

          // Empty settlement plan for balanced group
          final settlements = <Settlement>[];

          // Mock setup
          _setupGroupMembershipMock(
            mockSupabaseClient,
            groupId,
            'test-user-id',
            true,
          );
          _setupSettlementPlanMock(mockSupabaseClient, groupId, settlements);

          // Act
          final result = await repository.getSettlementPlan(groupId);

          // Assert - Property: Balanced group should have empty settlement plan
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail for balanced group: $failure'),
            (settlementPlan) {
              expect(
                settlementPlan,
                isEmpty,
                reason:
                    'Balanced group should have empty settlement plan '
                    '(iteration $i)',
              );
            },
          );
        }
      });

      test('should handle single debtor '
          'and single creditor optimally', () async {
        // Property: When there's only one debtor and one creditor,
        // settlement plan should have exactly one transaction

        const iterations = 30;

        for (var i = 0; i < iterations; i++) {
          final groupId = BalanceTestGenerators.generateGroupId();
          final currency = BalanceTestGenerators.generateCurrency();
          final amount = Random().nextDouble() * 100 + 1; // 1-101

          // Optimal settlement: one transaction
          final settlements = [
            Settlement(
              payerId: 'debtor-$i',
              payerName: 'Debtor',
              recipientId: 'creditor-$i',
              recipientName: 'Creditor',
              amount: amount,
              currency: currency,
            ),
          ];

          // Mock setup
          _setupGroupMembershipMock(
            mockSupabaseClient,
            groupId,
            'test-user-id',
            true,
          );
          _setupSettlementPlanMock(mockSupabaseClient, groupId, settlements);

          // Act
          final result = await repository.getSettlementPlan(groupId);

          // Assert - Property: Simple case should have exactly one transaction
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail for simple case: $failure'),
            (settlementPlan) {
              expect(
                settlementPlan.length,
                equals(1),
                reason:
                    'Simple two-person case should have exactly one '
                    'settlement (iteration $i)',
              );

              final settlement = settlementPlan.first;
              expect(
                settlement.amount,
                closeTo(amount, 0.01),
                reason:
                    'Settlement amount should match debt amount (iteration $i)',
              );
              expect(
                settlement.payerId,
                equals('debtor-$i'),
                reason: 'Payer should be the debtor (iteration $i)',
              );
              expect(
                settlement.recipientId,
                equals('creditor-$i'),
                reason: 'Recipient should be the creditor (iteration $i)',
              );
            },
          );
        }
      });

      test('should preserve total settlement amounts', () async {
        // Property: The total amount in the settlement plan should equal
        // the total amount owed by debtors (or owed to creditors)

        const iterations = 40;

        for (var i = 0; i < iterations; i++) {
          final groupId = BalanceTestGenerators.generateGroupId();
          final currency = BalanceTestGenerators.generateCurrency();

          // Generate unbalanced group
          final balances = BalanceTestGenerators.generateBalancedGroup(
            currency: currency,
            memberCount: Random().nextInt(4) + 3, // 3-6 members
          );

          // Calculate total debt and credit
          final totalDebt = balances
              .where((b) => b.balance < 0)
              .fold<double>(0, (sum, b) => sum + b.balance.abs());

          final totalCredit = balances
              .where((b) => b.balance > 0)
              .fold<double>(0, (sum, b) => sum + b.balance);

          // Generate settlement plan
          final settlements = _generateOptimalSettlements(balances);

          // Mock setup
          _setupGroupMembershipMock(
            mockSupabaseClient,
            groupId,
            'test-user-id',
            true,
          );
          _setupSettlementPlanMock(mockSupabaseClient, groupId, settlements);

          // Act
          final result = await repository.getSettlementPlan(groupId);

          // Assert - Property: Total settlement amounts should match total debt/credit
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail: $failure'),
            (settlementPlan) {
              final totalSettlements = settlementPlan.fold<double>(
                0,
                (sum, settlement) => sum + settlement.amount,
              );

              expect(
                totalSettlements,
                closeTo(totalDebt, 0.01),
                reason:
                    'Total settlements should equal total debt '
                    '(iteration $i)',
              );
              expect(
                totalSettlements,
                closeTo(totalCredit, 0.01),
                reason:
                    'Total settlements should equal total credit '
                    '(iteration $i)',
              );
            },
          );
        }
      });

      test('should handle complex multi-person '
          'scenarios efficiently', () async {
        // Property: Even in complex scenarios with multiple debtors and
        // creditors, the settlement plan should be efficient and correct

        const iterations = 20;

        for (var i = 0; i < iterations; i++) {
          final groupId = BalanceTestGenerators.generateGroupId();
          final currency = BalanceTestGenerators.generateCurrency();

          // Create complex scenario with multiple debtors and creditors
          final balances = <Balance>[];
          final amounts = [50.0, -30.0, 20.0, -40.0, 25.0, -25.0]; // Sums to 0

          for (var j = 0; j < amounts.length; j++) {
            balances.add(
              Balance(
                userId: 'user-$j',
                displayName: 'User $j',
                balance: amounts[j],
                currency: currency,
              ),
            );
          }

          // Generate settlement plan
          final settlements = _generateOptimalSettlements(balances);

          // Mock setup
          _setupGroupMembershipMock(
            mockSupabaseClient,
            groupId,
            'test-user-id',
            true,
          );
          _setupSettlementPlanMock(mockSupabaseClient, groupId, settlements);

          // Act
          final result = await repository.getSettlementPlan(groupId);

          // Assert - Property: Complex scenario should be handled efficiently
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail for complex scenario: $failure'),
            (settlementPlan) {
              // Property: Should not have excessive number of transactions
              expect(
                settlementPlan.length,
                lessThanOrEqualTo(4),
                reason:
                    'Complex scenario should not require excessive '
                    'transactions (iteration $i)',
              );

              // Property: All settlements should be valid
              for (final settlement in settlementPlan) {
                expect(
                  settlement.amount,
                  greaterThan(0),
                  reason:
                      'All settlement amounts should be positive '
                      '(iteration $i)',
                );
                expect(
                  settlement.payerId,
                  isNot(equals(settlement.recipientId)),
                  reason:
                      'Payer and recipient should be different (iteration $i)',
                );
              }

              // Property: Total settlements should be reasonable
              final totalSettlements = settlementPlan.fold<double>(
                0,
                (sum, settlement) => sum + settlement.amount,
              );
              expect(
                totalSettlements,
                lessThanOrEqualTo(200.0),
                reason: 'Total settlements should be reasonable (iteration $i)',
              );
            },
          );
        }
      });
    });
  });
}

/// Helper function to setup group membership mocks
void _setupGroupMembershipMock(
  MockSupabaseClient mockClient,
  String groupId,
  String userId,
  bool isMember,
) {
  final mockSupabaseQueryBuilder = MockSupabaseQueryBuilder();
  final fakeFilterBuilderForSelect = _FakePostgrestFilterBuilderForSelect();
  when(mockClient.from('group_members')).thenReturn(mockSupabaseQueryBuilder);
  when(
    mockSupabaseQueryBuilder.select('id'),
  ).thenReturn(fakeFilterBuilderForSelect);
  when(
    fakeFilterBuilderForSelect.eq('group_id', groupId),
  ).thenReturn(fakeFilterBuilderForSelect);
  when(
    fakeFilterBuilderForSelect.eq('user_id', userId),
  ).thenReturn(fakeFilterBuilderForSelect);
  when(fakeFilterBuilderForSelect.maybeSingle()).thenReturn(
    _FakePostgrestTransformBuilderForMaybeSingle(
      isMember ? {'id': 'member-id'} : null,
    ),
  );
}

/// Helper function to setup balance calculation mocks
void _setupBalanceCalculationMock(
  MockSupabaseClient mockClient,
  String groupId,
  List<Balance> balances,
) {
  final rpcResult = balances
      .map(
        (balance) => {
          'user_id': balance.userId,
          'display_name': balance.displayName,
          'balance': balance.balance,
          'currency': balance.currency,
        },
      )
      .toList();
  when(
    mockClient.rpc<List<Map<String, dynamic>>>(
      'calculate_group_balances',
      params: {
        'group_id_param': groupId,
      },
    ),
  ).thenReturn(_FakePostgrestFilterBuilderForRpc(rpcResult));
}

/// Helper function to generate optimal settlements from balances
List<Settlement> _generateOptimalSettlements(List<Balance> balances) {
  final settlements = <Settlement>[];

  // Separate debtors and creditors
  final debtors = balances.where((b) => b.balance < 0).toList();
  final creditors = balances.where((b) => b.balance > 0).toList();

  // Sort by amount (largest debts and credits first)
  debtors.sort((a, b) => a.balance.compareTo(b.balance));
  creditors.sort((a, b) => b.balance.compareTo(a.balance));

  // Create working copies
  final workingDebtors = debtors
      .map(
        (d) => {
          'userId': d.userId,
          'amount': d.balance.abs(),
          'currency': d.currency,
        },
      )
      .toList();

  final workingCreditors = creditors
      .map(
        (c) => {
          'userId': c.userId,
          'amount': c.balance,
          'currency': c.currency,
        },
      )
      .toList();

  // Generate settlements using greedy algorithm
  var debtorIndex = 0;
  var creditorIndex = 0;

  while (debtorIndex < workingDebtors.length &&
      creditorIndex < workingCreditors.length) {
    final debtor = workingDebtors[debtorIndex];
    final creditor = workingCreditors[creditorIndex];

    final debtAmount = debtor['amount']! as double;
    final creditAmount = creditor['amount']! as double;

    if (debtAmount <= 0.01 || creditAmount <= 0.01) {
      if (debtAmount <= 0.01) debtorIndex++;
      if (creditAmount <= 0.01) creditorIndex++;
      continue;
    }

    final settlementAmount = min(debtAmount, creditAmount);

    // Get display names from balances
    final debtorBalance = debtors.firstWhere(
      (d) => d.userId == debtor['userId']! as String,
    );
    final creditorBalance = creditors.firstWhere(
      (c) => c.userId == creditor['userId']! as String,
    );

    settlements.add(
      Settlement(
        payerId: debtor['userId']! as String,
        payerName: debtorBalance.displayName,
        recipientId: creditor['userId']! as String,
        recipientName: creditorBalance.displayName,
        amount: settlementAmount,
        currency: debtor['currency']! as String,
      ),
    );

    // Update remaining amounts
    debtor['amount'] = debtAmount - settlementAmount;
    creditor['amount'] = creditAmount - settlementAmount;

    // Move to next if current is settled
    if (debtor['amount']! as double <= 0.01) debtorIndex++;
    if (creditor['amount']! as double <= 0.01) creditorIndex++;
  }

  return settlements;
}

/// Helper function to setup settlement plan mocks
void _setupSettlementPlanMock(
  MockSupabaseClient mockClient,
  String groupId,
  List<Settlement> settlements,
) {
  final rpcResult = settlements
      .map(
        (settlement) => {
          'payer_id': settlement.payerId,
          'payer_name': settlement.payerName,
          'recipient_id': settlement.recipientId,
          'recipient_name': settlement.recipientName,
          'amount': settlement.amount,
          'currency': settlement.currency,
        },
      )
      .toList();
  when(
    mockClient.rpc<List<Map<String, dynamic>>>(
      'generate_settlement_plan',
      params: {
        'group_id_param': groupId,
      },
    ),
  ).thenReturn(_FakePostgrestFilterBuilderForRpc(rpcResult));
}
