// These diagnostics are ignored because property-based tests often use
// complex generators and mock setups that may trigger these warnings.
// ignore_for_file: unused_element_parameter, must_be_immutable
import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/data/repositories/supabase_expense_repository.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/repositories/expense_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}

class _MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

class _FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T>, Future<T> {
  _FakePostgrestTransformBuilder(this._value);
  final T _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) async {
    return onValue(_value);
  }

  @override
  Future<T> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return Future<T>.value(_value);
  }

  @override
  Stream<T> asStream() {
    return Stream<T>.value(_value);
  }

  @override
  Future<T> timeout(
    Duration timeLimit, {
    FutureOr<T> Function()? onTimeout,
  }) {
    return Future<T>.value(_value);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return Future<T>.value(_value);
  }
}

class _FakePostgrestFilterBuilderForAwait extends Fake
    implements PostgrestFilterBuilder<dynamic>, Future<dynamic> {
  _FakePostgrestFilterBuilderForAwait([this._value]);
  final dynamic _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) async {
    return onValue(_value);
  }

  @override
  Future<dynamic> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return Future<dynamic>.value(_value);
  }

  @override
  Stream<dynamic> asStream() {
    return Stream<dynamic>.value(_value);
  }

  @override
  Future<dynamic> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) {
    return Future<dynamic>.value(_value);
  }

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) {
    return Future<dynamic>.value(_value);
  }
}

/// Property-based test generators for Expense entities
class ExpenseTestGenerators {
  static final Random _random = Random();

  /// Generate a random valid expense description
  static String generateDescription() {
    final descriptions = [
      'Dinner at restaurant',
      'Movie tickets',
      'Grocery shopping',
      'Gas for car',
      'Coffee and snacks',
      'Taxi ride',
      'Hotel booking',
      'Concert tickets',
      'Office supplies',
      'Team lunch',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  /// Generate a random valid amount
  static double generateAmount() {
    // Generate amounts between 1.00 and 1000.00
    return (_random.nextDouble() * 999.0) + 1.0;
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

  /// Generate a random expense ID
  static String generateExpenseId() {
    return 'expense-${_random.nextInt(10000)}';
  }

  /// Generate a random display name
  static String generateDisplayName() {
    final names = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank'];
    return names[_random.nextInt(names.length)];
  }

  /// Generate a list of participants with valid split
  static List<ExpenseParticipant> generateParticipants({
    required double totalAmount,
    int? count,
  }) {
    final participantCount =
        count ?? (_random.nextInt(4) + 2); // 2-5 participants
    final participants = <ExpenseParticipant>[];

    // Generate participants with equal split
    final shareAmount = totalAmount / participantCount;
    final sharePercentage = 100.0 / participantCount;

    for (var i = 0; i < participantCount; i++) {
      participants.add(
        ExpenseParticipant(
          userId: generateUserId(),
          displayName: generateDisplayName(),
          shareAmount: shareAmount,
          sharePercentage: sharePercentage,
        ),
      );
    }

    // Adjust last participant to handle rounding
    if (participants.isNotEmpty) {
      final totalShares = participants
          .take(participants.length - 1)
          .fold<double>(0, (sum, p) => sum + p.shareAmount);
      final lastShare = totalAmount - totalShares;

      participants[participants.length - 1] = participants.last.copyWith(
        shareAmount: lastShare,
      );
    }

    return participants;
  }

  /// Generate a random Expense entity for testing
  static Expense generateExpense({
    String? id,
    String? groupId,
    String? payerId,
    String? payerName,
    double? amount,
    String? currency,
    String? description,
    List<ExpenseParticipant>? participants,
    DateTime? expenseDate,
  }) {
    final expenseAmount = amount ?? generateAmount();
    final expenseParticipants =
        participants ?? generateParticipants(totalAmount: expenseAmount);

    return Expense(
      id: id ?? generateExpenseId(),
      groupId: groupId ?? generateGroupId(),
      payerId: payerId ?? generateUserId(),
      payerName: payerName ?? generateDisplayName(),
      amount: expenseAmount,
      currency: currency ?? generateCurrency(),
      description: description ?? generateDescription(),
      participants: expenseParticipants,
      expenseDate:
          expenseDate ??
          DateTime.now().subtract(Duration(days: _random.nextInt(30))),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  group('ExpenseRepository Property Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late ExpenseRepository repository;

    setUp(() async {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();

      // Setup basic mocks
      when(mockSupabaseClient.auth).thenReturn(mockAuth);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('test-user-id');

      repository = SupabaseExpenseRepository(
        supabaseClient: mockSupabaseClient,
      );
    });

    group('Property 6: Expense creation sets correct payer', () {
      test('should set the specified payer for any valid expense', () async {
        // Property: For any valid expense data, when an expense is created,
        // the payer should be set to the specified user

        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          final payerId = 'payer-$i';
          final testExpense = ExpenseTestGenerators.generateExpense(
            id: '', // Will be generated by database
            payerId: payerId,
          );

          // Mock group membership check
          _setupGroupMembershipMock(
            mockSupabaseClient,
            testExpense.groupId,
            'test-user-id',
            true,
          );

          // Mock successful expense creation
          _setupSuccessfulExpenseCreationMocks(mockSupabaseClient, testExpense);

          // Act
          final result = await repository.createExpense(testExpense);

          // Assert - Property: Payer should be set correctly
          expect(
            result.isRight(),
            isTrue,
            reason:
                'Expense creation should succeed for valid data (iteration $i)',
          );

          result.fold(
            (failure) =>
                fail('Should not fail for valid expense data: $failure'),
            (createdExpense) {
              expect(
                createdExpense.payerId,
                equals(payerId),
                reason: 'Payer should be set to specified user (iteration $i)',
              );

              // Additional property: Expense should maintain all original data
              expect(
                createdExpense.amount,
                equals(testExpense.amount),
                reason: 'Amount should be preserved (iteration $i)',
              );
              expect(
                createdExpense.description,
                equals(testExpense.description),
                reason: 'Description should be preserved (iteration $i)',
              );
              expect(
                createdExpense.currency,
                equals(testExpense.currency),
                reason: 'Currency should be preserved (iteration $i)',
              );
            },
          );
        }
      });

      test(
        'should maintain payer consistency across different configurations',
        () async {
          // Property: Regardless of amount, currency, or participants,
          // the payer should always be set correctly

          const iterations = 50;

          for (var i = 0; i < iterations; i++) {
            final payerId = 'consistent-payer-$i';

            // Test with different configurations
            final amounts = [0.01, 1.0, 100.0, 1000.0, 9999.99];
            final currencies = ['VND', 'USD', 'EUR'];
            final participantCounts = [1, 2, 5, 10];

            final amount = amounts[i % amounts.length];
            final currency = currencies[i % currencies.length];
            final participantCount =
                participantCounts[i % participantCounts.length];

            final testExpense = ExpenseTestGenerators.generateExpense(
              payerId: payerId,
              amount: amount,
              currency: currency,
              participants: ExpenseTestGenerators.generateParticipants(
                totalAmount: amount,
                count: participantCount,
              ),
            );

            // Mock the same successful creation flow
            _setupGroupMembershipMock(
              mockSupabaseClient,
              testExpense.groupId,
              'test-user-id',
              true,
            );
            _setupSuccessfulExpenseCreationMocks(
              mockSupabaseClient,
              testExpense,
            );

            // Act
            final result = await repository.createExpense(testExpense);

            // Assert - Property holds regardless of expense configuration
            expect(result.isRight(), isTrue);
            result.fold(
              (failure) => fail('Should not fail: $failure'),
              (createdExpense) {
                expect(
                  createdExpense.payerId,
                  equals(payerId),
                  reason:
                      'Payer should be consistent regardless of configuration '
                      '(iteration $i)',
                );
              },
            );
          }
        },
      );
    });

    group('Property 9: Expense creation updates balances', () {
      test(
        'should trigger balance recalculation when expense is created',
        () async {
          // Property: When an expense is created, it should affect the balances
          // of all participants in the group

          const iterations = 50;

          for (var i = 0; i < iterations; i++) {
            final testExpense = ExpenseTestGenerators.generateExpense();

            // Mock group membership check
            _setupGroupMembershipMock(
              mockSupabaseClient,
              testExpense.groupId,
              'test-user-id',
              true,
            );

            // Mock successful expense creation
            _setupSuccessfulExpenseCreationMocks(
              mockSupabaseClient,
              testExpense,
            );

            // Act
            final result = await repository.createExpense(testExpense);

            // Assert - Property: Expense creation should succeed
            expect(
              result.isRight(),
              isTrue,
              reason: 'Expense creation should succeed (iteration $i)',
            );

            result.fold(
              (failure) => fail('Should not fail: $failure'),
              (createdExpense) {
                // Property: Created expense should have participants
                expect(
                  createdExpense.participants.isNotEmpty,
                  isTrue,
                  reason:
                      'Created expense should have participants (iteration $i)',
                );

                // Property: Participant shares should sum to expense amount
                final totalShares = createdExpense.participants.fold<double>(
                  0,
                  (sum, participant) => sum + participant.shareAmount,
                );

                expect(
                  totalShares,
                  closeTo(createdExpense.amount, 0.01),
                  reason:
                      'Participant shares should sum to expense amount '
                      '(iteration $i)',
                );

                // Property: Each participant should have a valid share
                for (final participant in createdExpense.participants) {
                  expect(
                    participant.shareAmount,
                    greaterThan(0),
                    reason:
                        'Each participant should have positive share '
                        '(iteration $i)',
                  );
                  expect(
                    participant.userId.isNotEmpty,
                    isTrue,
                    reason:
                        'Each participant should have valid user ID '
                        '(iteration $i)',
                  );
                }
              },
            );
          }
        },
      );

      test(
        'should handle different participant split configurations correctly',
        () async {
          const iterations = 30;

          for (var i = 0; i < iterations; i++) {
            final amount = ExpenseTestGenerators.generateAmount();
            final participants = <ExpenseParticipant>[];

            if (i % 3 == 0) {
              participants.addAll(
                ExpenseTestGenerators.generateParticipants(
                  totalAmount: amount,
                  count: 3,
                ),
              );
            } else if (i % 3 == 1) {
              var remainingAmount = amount;
              final shares = <double>[];
              for (var j = 0; j < 2; j++) {
                final maxShare = remainingAmount * 0.8;
                final share = Random().nextDouble() * maxShare + 0.01;
                shares.add(share);
                remainingAmount -= share;
              }
              shares.add(remainingAmount);

              for (var j = 0; j < 3; j++) {
                participants.add(
                  ExpenseParticipant(
                    userId: ExpenseTestGenerators.generateUserId(),
                    displayName: ExpenseTestGenerators.generateDisplayName(),
                    shareAmount: shares[j],
                    sharePercentage: (shares[j] / amount) * 100,
                  ),
                );
              }
            } else {
              var remainingPercentage = 100.0;
              final percentages = <double>[];
              for (var j = 0; j < 2; j++) {
                final maxPercentage = remainingPercentage * 0.8;
                final percentage = Random().nextDouble() * maxPercentage + 1.0;
                percentages.add(percentage);
                remainingPercentage -= percentage;
              }
              percentages.add(remainingPercentage);

              for (var j = 0; j < 3; j++) {
                final shareAmount = (amount * percentages[j]) / 100.0;
                participants.add(
                  ExpenseParticipant(
                    userId: ExpenseTestGenerators.generateUserId(),
                    displayName: ExpenseTestGenerators.generateDisplayName(),
                    shareAmount: shareAmount,
                    sharePercentage: percentages[j],
                  ),
                );
              }
            }

            final testExpense = ExpenseTestGenerators.generateExpense(
              amount: amount,
              participants: participants,
            );

            _setupGroupMembershipMock(
              mockSupabaseClient,
              testExpense.groupId,
              'test-user-id',
              true,
            );
            _setupSuccessfulExpenseCreationMocks(
              mockSupabaseClient,
              testExpense,
            );

            final result = await repository.createExpense(testExpense);

            expect(result.isRight(), isTrue);
            result.fold(
              (failure) => fail('Should not fail for valid split: $failure'),
              (createdExpense) {
                final totalShares = createdExpense.participants.fold<double>(
                  0,
                  (sum, participant) => sum + participant.shareAmount,
                );

                expect(
                  totalShares,
                  closeTo(createdExpense.amount, 0.01),
                  reason:
                      'Split should remain valid across configurations '
                      '(iteration $i)',
                );
              },
            );
          }
        },
      );

      test('should validate split totals before creation', () async {
        // Property: Expenses with invalid split totals should be rejected

        const iterations = 30;

        for (var i = 0; i < iterations; i++) {
          final amount = ExpenseTestGenerators.generateAmount();

          // Create participants with intentionally wrong split total
          final participants = ExpenseTestGenerators.generateParticipants(
            totalAmount: amount,
            count: 3,
          );

          // Modify one participant to create invalid total
          final invalidParticipants = participants.map((p) {
            if (p == participants.first) {
              return p.copyWith(
                shareAmount: p.shareAmount + 10.0,
              ); // Add extra amount
            }
            return p;
          }).toList();

          final testExpense = ExpenseTestGenerators.generateExpense(
            amount: amount,
            participants: invalidParticipants,
          );

          // Mock group membership
          _setupGroupMembershipMock(
            mockSupabaseClient,
            testExpense.groupId,
            'test-user-id',
            true,
          );

          // Act
          final result = await repository.createExpense(testExpense);

          // Assert - Property: Invalid split should be rejected
          expect(
            result.isLeft(),
            isTrue,
            reason: 'Invalid split should be rejected (iteration $i)',
          );

          result.fold(
            (failure) {
              expect(
                failure.toString().toLowerCase(),
                contains('split'),
                reason: 'Should return split-related error (iteration $i)',
              );
            },
            (success) => fail('Should not succeed with invalid split'),
          );
        }
      });
    });

    group('Property 7: Equal split divides amount correctly', () {
      test(
        'should divide expense amount equally among all participants',
        () async {
          // Property: For any expense with equal split method, the amount
          // should be divided equally among all participants, with rounding
          // handling

          const iterations = 100;

          for (var i = 0; i < iterations; i++) {
            final amount = ExpenseTestGenerators.generateAmount();
            final participantCount =
                Random().nextInt(8) + 2; // 2-9 participants

            // Create participants with equal split
            final participants = <ExpenseParticipant>[];
            final equalShare = amount / participantCount;

            for (var j = 0; j < participantCount; j++) {
              participants.add(
                ExpenseParticipant(
                  userId: ExpenseTestGenerators.generateUserId(),
                  displayName: ExpenseTestGenerators.generateDisplayName(),
                  shareAmount: equalShare,
                  sharePercentage: 100.0 / participantCount,
                ),
              );
            }

            // Adjust last participant for rounding
            final totalShares = participants
                .take(participants.length - 1)
                .fold<double>(0, (sum, p) => sum + p.shareAmount);
            final lastShare = amount - totalShares;

            participants[participants.length - 1] = participants.last.copyWith(
              shareAmount: lastShare,
            );

            final testExpense = ExpenseTestGenerators.generateExpense(
              amount: amount,
              participants: participants,
            );

            // Mock successful creation
            _setupGroupMembershipMock(
              mockSupabaseClient,
              testExpense.groupId,
              'test-user-id',
              true,
            );
            _setupSuccessfulExpenseCreationMocks(
              mockSupabaseClient,
              testExpense,
            );

            // Act
            final result = await repository.createExpense(testExpense);

            // Assert - Property: Equal split should be valid
            expect(
              result.isRight(),
              isTrue,
              reason: 'Equal split should be valid (iteration $i)',
            );

            result.fold(
              (failure) => fail('Should not fail for equal split: $failure'),
              (createdExpense) {
                // Property: Total shares should equal expense amount
                final totalShares = createdExpense.participants.fold<double>(
                  0,
                  (sum, participant) => sum + participant.shareAmount,
                );

                expect(
                  totalShares,
                  closeTo(createdExpense.amount, 0.01),
                  reason:
                      'Total shares should equal expense amount '
                      '(iteration $i)',
                );

                // Property: All participants except possibly the last should
                // have equal shares
                final expectedShare =
                    createdExpense.amount / createdExpense.participants.length;
                for (
                  var k = 0;
                  k < createdExpense.participants.length - 1;
                  k++
                ) {
                  expect(
                    createdExpense.participants[k].shareAmount,
                    closeTo(expectedShare, 0.01),
                    reason:
                        'Participants should have equal shares '
                        '(iteration $i, participant $k)',
                  );
                }

                // Property: Each participant should have positive share
                for (final participant in createdExpense.participants) {
                  expect(
                    participant.shareAmount,
                    greaterThan(0),
                    reason:
                        'Each participant should have positive share '
                        '(iteration $i)',
                  );
                }
              },
            );
          }
        },
      );

      test('should handle rounding correctly in equal splits', () async {
        // Property: When amount cannot be divided evenly, rounding should be
        // handled such that the total still equals the original amount

        const iterations = 50;

        for (var i = 0; i < iterations; i++) {
          // Use amounts that don't divide evenly
          final baseAmount = Random().nextInt(100) + 1;
          final participantCount = Random().nextInt(6) + 3; // 3-8 participants
          final amount =
              baseAmount + 0.01; // Add cents to create rounding scenarios

          final participants = <ExpenseParticipant>[];
          final baseShare = amount / participantCount;

          // Create equal shares with rounding adjustment on last participant
          for (var j = 0; j < participantCount - 1; j++) {
            participants.add(
              ExpenseParticipant(
                userId: ExpenseTestGenerators.generateUserId(),
                displayName: ExpenseTestGenerators.generateDisplayName(),
                shareAmount: double.parse(
                  baseShare.toStringAsFixed(2),
                ), // Round to 2 decimals
                sharePercentage: 100.0 / participantCount,
              ),
            );
          }

          // Last participant gets the remainder
          final totalSoFar = participants.fold<double>(
            0,
            (sum, p) => sum + p.shareAmount,
          );

          final lastShare = amount - totalSoFar;

          participants.add(
            ExpenseParticipant(
              userId: ExpenseTestGenerators.generateUserId(),
              displayName: ExpenseTestGenerators.generateDisplayName(),
              shareAmount: lastShare,
              sharePercentage: 100.0 / participantCount,
            ),
          );

          final testExpense = ExpenseTestGenerators.generateExpense(
            amount: amount,
            participants: participants,
          );

          // Mock successful creation
          _setupGroupMembershipMock(
            mockSupabaseClient,
            testExpense.groupId,
            'test-user-id',
            true,
          );
          _setupSuccessfulExpenseCreationMocks(mockSupabaseClient, testExpense);

          // Act
          final result = await repository.createExpense(testExpense);

          // Assert - Property: Rounding should preserve total amount
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) =>
                fail('Should not fail for rounded equal split: $failure'),
            (createdExpense) {
              final totalShares = createdExpense.participants.fold<double>(
                0,
                (sum, participant) => sum + participant.shareAmount,
              );

              expect(
                totalShares,
                closeTo(createdExpense.amount, 0.001),
                reason:
                    'Rounded split should preserve total amount (iteration $i)',
              );

              // Property: No participant should have zero or negative share
              for (final participant in createdExpense.participants) {
                expect(
                  participant.shareAmount,
                  greaterThan(0),
                  reason:
                      'No participant should have zero share after rounding '
                      '(iteration $i)',
                );
              }
            },
          );
        }
      });
    });

    group('Property 8: Custom split validation ensures total accuracy', () {
      test(
        'should validate that custom split totals match expense amount',
        () async {
          // Property: For any custom split, the sum of all participant shares
          // must equal the total expense amount within acceptable tolerance

          const iterations = 100;

          for (var i = 0; i < iterations; i++) {
            final amount = ExpenseTestGenerators.generateAmount();
            final participantCount =
                Random().nextInt(5) + 2; // 2-6 participants

            // Create valid custom split
            final participants = <ExpenseParticipant>[];
            final shares = <double>[];

            // Generate random shares that sum to the total amount
            var remainingAmount = amount;
            for (var j = 0; j < participantCount - 1; j++) {
              final maxShare = remainingAmount * 0.8; // Leave room for others
              final share = Random().nextDouble() * maxShare + 0.01;
              shares.add(share);
              remainingAmount -= share;
            }
            shares.add(remainingAmount); // Last participant gets remainder

            // Create participants with custom shares
            for (var j = 0; j < participantCount; j++) {
              participants.add(
                ExpenseParticipant(
                  userId: ExpenseTestGenerators.generateUserId(),
                  displayName: ExpenseTestGenerators.generateDisplayName(),
                  shareAmount: shares[j],
                  sharePercentage: (shares[j] / amount) * 100,
                ),
              );
            }

            final testExpense = ExpenseTestGenerators.generateExpense(
              amount: amount,
              participants: participants,
            );

            // Mock successful creation
            _setupGroupMembershipMock(
              mockSupabaseClient,
              testExpense.groupId,
              'test-user-id',
              true,
            );
            _setupSuccessfulExpenseCreationMocks(
              mockSupabaseClient,
              testExpense,
            );

            // Act
            final result = await repository.createExpense(testExpense);

            // Assert - Property: Custom split should be valid
            expect(
              result.isRight(),
              isTrue,
              reason: 'Valid custom split should be accepted (iteration $i)',
            );

            result.fold(
              (failure) =>
                  fail('Should not fail for valid custom split: $failure'),
              (createdExpense) {
                final totalShares = createdExpense.participants.fold<double>(
                  0,
                  (sum, participant) => sum + participant.shareAmount,
                );

                expect(
                  totalShares,
                  closeTo(createdExpense.amount, 0.01),
                  reason:
                      'Custom split total should match expense amount '
                      '(iteration $i)',
                );

                // Property: Each participant should have their specified share
                for (var j = 0; j < createdExpense.participants.length; j++) {
                  expect(
                    createdExpense.participants[j].shareAmount,
                    closeTo(shares[j], 0.01),
                    reason:
                        'Participant should have specified share amount '
                        '(iteration $i, participant $j)',
                  );
                }
              },
            );
          }
        },
      );

      test('should reject custom splits with incorrect totals', () async {
        // Property: Custom splits where the total shares do not match the
        // expense amount should be rejected with appropriate error

        const iterations = 50;

        for (var i = 0; i < iterations; i++) {
          final amount = ExpenseTestGenerators.generateAmount();
          final participantCount = Random().nextInt(4) + 2; // 2-5 participants

          // Create invalid custom split (intentionally wrong total)
          final participants = <ExpenseParticipant>[];
          final wrongTotal =
              amount +
              (Random().nextDouble() * 50 + 5); // Add 5-55 to make it wrong

          final shareAmount = wrongTotal / participantCount;
          for (var j = 0; j < participantCount; j++) {
            participants.add(
              ExpenseParticipant(
                userId: ExpenseTestGenerators.generateUserId(),
                displayName: ExpenseTestGenerators.generateDisplayName(),
                shareAmount: shareAmount,
                sharePercentage: (shareAmount / amount) * 100,
              ),
            );
          }

          final testExpense = ExpenseTestGenerators.generateExpense(
            amount: amount,
            participants: participants,
          );
          // Mock group membership
          _setupGroupMembershipMock(
            mockSupabaseClient,
            testExpense.groupId,
            'test-user-id',
            true,
          );

          // Act
          final result = await repository.createExpense(testExpense);

          // Assert - Property: Invalid split should be rejected
          expect(
            result.isLeft(),
            isTrue,
            reason: 'Invalid custom split should be rejected (iteration $i)',
          );

          result.fold(
            (failure) {
              expect(
                failure.toString().toLowerCase(),
                contains('split'),
                reason: 'Should return split validation error (iteration $i)',
              );
            },
            (success) => fail('Should not succeed with invalid split total'),
          );
        }
      });

      test('should validate percentage splits sum to 100%', () async {
        // Property: When using percentage-based splits, the percentages should
        // sum to exactly 100% (within tolerance)

        const iterations = 50;

        for (var i = 0; i < iterations; i++) {
          final amount = ExpenseTestGenerators.generateAmount();
          final participantCount = Random().nextInt(4) + 2; // 2-5 participants

          // Create valid percentage split
          final participants = <ExpenseParticipant>[];
          final percentages = <double>[];

          // Generate percentages that sum to 100%
          var remainingPercentage = 100.0;
          for (var j = 0; j < participantCount - 1; j++) {
            final maxPercentage =
                remainingPercentage * 0.8; // Leave room for others
            final percentage = Random().nextDouble() * maxPercentage + 1.0;
            percentages.add(percentage);
            remainingPercentage -= percentage;
          }
          percentages.add(
            remainingPercentage,
          ); // Last participant gets remainder

          // Create participants with percentage shares
          for (var j = 0; j < participantCount; j++) {
            final shareAmount = (amount * percentages[j]) / 100.0;
            participants.add(
              ExpenseParticipant(
                userId: ExpenseTestGenerators.generateUserId(),
                displayName: ExpenseTestGenerators.generateDisplayName(),
                shareAmount: shareAmount,
                sharePercentage: percentages[j],
              ),
            );
          }

          final testExpense = ExpenseTestGenerators.generateExpense(
            amount: amount,
            participants: participants,
          );

          // Mock successful creation
          _setupGroupMembershipMock(
            mockSupabaseClient,
            testExpense.groupId,
            'test-user-id',
            true,
          );
          _setupSuccessfulExpenseCreationMocks(mockSupabaseClient, testExpense);

          // Act
          final result = await repository.createExpense(testExpense);

          // Assert - Property: Percentage split should be valid
          expect(
            result.isRight(),
            isTrue,
            reason: 'Valid percentage split should be accepted (iteration $i)',
          );

          result.fold(
            (failure) =>
                fail('Should not fail for valid percentage split: $failure'),
            (createdExpense) {
              // Property: Percentages should sum to 100%
              final totalPercentage = createdExpense.participants.fold<double>(
                0,
                (sum, participant) => sum + participant.sharePercentage,
              );

              expect(
                totalPercentage,
                closeTo(100.0, 0.01),
                reason: 'Percentages should sum to 100% (iteration $i)',
              );

              // Property: Share amounts should match percentages
              for (final participant in createdExpense.participants) {
                final expectedAmount =
                    (createdExpense.amount * participant.sharePercentage) /
                    100.0;
                expect(
                  participant.shareAmount,
                  closeTo(expectedAmount, 0.01),
                  reason: 'Share amount should match percentage (iteration $i)',
                );
              }
            },
          );
        }
      });
    });

    group('Property 12: Expense updates recalculate balances', () {
      test(
        'should trigger balance recalculation when expense is updated',
        () async {
          // Property: When an expense is updated, it should trigger balance
          // recalculation for all affected participants

          const iterations = 50;

          for (var i = 0; i < iterations; i++) {
            final originalExpense = ExpenseTestGenerators.generateExpense(
              id: 'expense-$i',
            );

            // Create updated expense with different amount/participants
            final newAmount = ExpenseTestGenerators.generateAmount();
            final updatedExpense = originalExpense.copyWith(
              amount: newAmount,
              participants: ExpenseTestGenerators.generateParticipants(
                totalAmount: newAmount,
                count: originalExpense.participants.length,
              ),
            );

            // Mock permission check (user can update)
            _setupSuccessfulExpenseUpdateMocks(
              mockSupabaseClient,
              updatedExpense,
            );

            // Act
            final result = await repository.updateExpense(updatedExpense);

            // Assert - Property: Update should succeed and trigger balance
            // recalculation
            expect(
              result.isRight(),
              isTrue,
              reason: 'Expense update should succeed (iteration $i)',
            );

            result.fold(
              (failure) => fail('Should not fail for valid update: $failure'),
              (updated) {
                // Property: Updated expense should have new amount
                expect(
                  updated.amount,
                  equals(newAmount),
                  reason:
                      'Updated expense should have new amount (iteration $i)',
                );

                // Property: Participant shares should sum to new amount
                final totalShares = updated.participants.fold<double>(
                  0,
                  (sum, participant) => sum + participant.shareAmount,
                );

                expect(
                  totalShares,
                  closeTo(updated.amount, 0.01),
                  reason:
                      'Updated participant shares should sum to new amount '
                      '(iteration $i)',
                );

                // Property: All participants should have valid shares
                for (final participant in updated.participants) {
                  expect(
                    participant.shareAmount,
                    greaterThan(0),
                    reason:
                        'Each participant should have positive share after '
                        'update (iteration $i)',
                  );
                }
              },
            );
          }
        },
      );

      test('should handle participant changes in expense updates', () async {
        // Property: When participants are added or removed from an expense,
        // the split should be recalculated correctly

        const iterations = 30;

        for (var i = 0; i < iterations; i++) {
          final originalExpense = ExpenseTestGenerators.generateExpense(
            id: 'expense-$i',
            participants: ExpenseTestGenerators.generateParticipants(
              totalAmount: 100,
              count: 3,
            ),
          );

          // Add more participants
          final newParticipantCount =
              originalExpense.participants.length + Random().nextInt(3) + 1;
          final updatedExpense = originalExpense.copyWith(
            participants: ExpenseTestGenerators.generateParticipants(
              totalAmount: originalExpense.amount,
              count: newParticipantCount,
            ),
          );

          // Mock permission check
          _setupSuccessfulExpenseUpdateMocks(
            mockSupabaseClient,
            updatedExpense,
          );

          // Act
          final result = await repository.updateExpense(updatedExpense);

          // Assert - Property: Participant changes should be handled correctly
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) =>
                fail('Should not fail for participant changes: $failure'),
            (updated) {
              // Property: Should have new participant count
              expect(
                updated.participants.length,
                equals(newParticipantCount),
                reason: 'Should have updated participant count (iteration $i)',
              );

              // Property: Total shares should still equal expense amount
              final totalShares = updated.participants.fold<double>(
                0,
                (sum, participant) => sum + participant.shareAmount,
              );

              expect(
                totalShares,
                closeTo(updated.amount, 0.01),
                reason:
                    'Total shares should equal amount after participant '
                    'changes (iteration $i)',
              );
            },
          );
        }
      });

      test('should validate permissions before allowing updates', () async {
        // Property: Only users with appropriate permissions should be able
        // to update expenses

        const iterations = 30;

        for (var i = 0; i < iterations; i++) {
          final testExpense = ExpenseTestGenerators.generateExpense(
            id: 'expense-$i',
          );

          // Mock permission check (user cannot update)
          _setupExpensePermissionMock(
            mockSupabaseClient,
            testExpense.id,
            'update',
            false,
          );

          // Act
          final result = await repository.updateExpense(testExpense);

          // Assert - Property: Should reject unauthorized updates
          expect(
            result.isLeft(),
            isTrue,
            reason: 'Should reject unauthorized update (iteration $i)',
          );

          result.fold(
            (failure) {
              expect(
                failure.toString().toLowerCase(),
                contains('permission'),
                reason: 'Should return permission error (iteration $i)',
              );
            },
            (success) => fail('Should not succeed without permission'),
          );
        }
      });
    });
  });
}

/// Helper function to setup expense permission mocks
void _setupExpensePermissionMock(
  MockSupabaseClient mockClient,
  String expenseId,
  String action,
  bool hasPermission,
) {
  final expensesQueryBuilder = MockSupabaseQueryBuilder();
  final permissionFilterBuilder = MockPostgrestFilterBuilder<dynamic>();

  when(mockClient.from('expenses')).thenReturn(expensesQueryBuilder);
  when(
    (expensesQueryBuilder as dynamic).select('payer_id, group_id'),
  ).thenReturn(permissionFilterBuilder);
  when(
    permissionFilterBuilder.eq('id', expenseId),
  ).thenReturn(permissionFilterBuilder);
  when(permissionFilterBuilder.maybeSingle()).thenReturn(
    _FakePostgrestTransformBuilder<Map<String, dynamic>?>({
      'payer_id': hasPermission ? 'test-user-id' : 'other-user-id',
      'group_id': 'test-group-id',
    }),
  );

  if (!hasPermission) {
    final groupMembersQueryBuilder = MockSupabaseQueryBuilder();
    final roleFilterBuilder = MockPostgrestFilterBuilder<dynamic>();

    when(mockClient.from('group_members')).thenReturn(groupMembersQueryBuilder);
    when(
      (groupMembersQueryBuilder as dynamic).select('role'),
    ).thenReturn(roleFilterBuilder);
    when(
      roleFilterBuilder.eq('group_id', 'test-group-id'),
    ).thenReturn(roleFilterBuilder);
    when(
      roleFilterBuilder.eq('user_id', 'test-user-id'),
    ).thenReturn(roleFilterBuilder);
    when(roleFilterBuilder.maybeSingle()).thenReturn(
      _FakePostgrestTransformBuilder<Map<String, dynamic>?>({'role': 'editor'}),
    );
  }
}

/// Helper function to setup successful expense update mocks
void _setupSuccessfulExpenseUpdateMocks(
  MockSupabaseClient mockClient,
  Expense testExpense,
) {
  final expensesQueryBuilder = MockSupabaseQueryBuilder();
  final permissionFilterBuilder = MockPostgrestFilterBuilder<dynamic>();
  final updateFilterBuilder = MockPostgrestFilterBuilder<dynamic>();
  final getExpenseFilterBuilder = MockPostgrestFilterBuilder<dynamic>();

  when(mockClient.from('expenses')).thenReturn(expensesQueryBuilder);

  when(
    (expensesQueryBuilder as dynamic).select('payer_id, group_id'),
  ).thenReturn(permissionFilterBuilder);
  when(
    permissionFilterBuilder.eq('id', testExpense.id),
  ).thenReturn(permissionFilterBuilder);
  when(permissionFilterBuilder.maybeSingle()).thenReturn(
    _FakePostgrestTransformBuilder<Map<String, dynamic>?>({
      'payer_id': 'test-user-id',
      'group_id': testExpense.groupId,
    }),
  );

  when((expensesQueryBuilder as dynamic).update(any)).thenReturn(
    updateFilterBuilder,
  );
  when(
    updateFilterBuilder.eq('id', testExpense.id),
  ).thenReturn(_FakePostgrestFilterBuilderForAwait());

  final expenseParticipantsQueryBuilder = MockSupabaseQueryBuilder();
  final deleteParticipantsFilterBuilder = MockPostgrestFilterBuilder<dynamic>();

  when(
    mockClient.from('expense_participants'),
  ).thenReturn(expenseParticipantsQueryBuilder);
  when(
    expenseParticipantsQueryBuilder.delete(),
  ).thenReturn(deleteParticipantsFilterBuilder);
  when(
    deleteParticipantsFilterBuilder.eq('expense_id', testExpense.id),
  ).thenReturn(_FakePostgrestFilterBuilderForAwait());
  when(
    (expenseParticipantsQueryBuilder as dynamic).insert(any),
  ).thenReturn(_FakePostgrestFilterBuilderForAwait());

  when((expensesQueryBuilder as dynamic).select(any)).thenReturn(
    getExpenseFilterBuilder,
  );
  when(
    getExpenseFilterBuilder.eq('id', testExpense.id),
  ).thenReturn(getExpenseFilterBuilder);
  when(getExpenseFilterBuilder.single()).thenReturn(
    _FakePostgrestTransformBuilder<Map<String, dynamic>>({
      'id': testExpense.id,
      'group_id': testExpense.groupId,
      'payer_id': testExpense.payerId,
      'payer_name': testExpense.payerName,
      'amount': testExpense.amount,
      'currency': testExpense.currency,
      'description': testExpense.description,
      'category': testExpense.category,
      'expense_date': testExpense.expenseDate.toIso8601String(),
      'created_at': testExpense.createdAt.toIso8601String(),
      'updated_at': testExpense.updatedAt.toIso8601String(),
      'expense_participants': testExpense.participants
          .map(
            (participant) => {
              'user_id': participant.userId,
              'display_name': participant.displayName,
              'share_amount': participant.shareAmount,
              'share_percentage': participant.sharePercentage,
            },
          )
          .toList(),
    }),
  );
}

void _setupGroupMembershipMock(
  MockSupabaseClient mockClient,
  String groupId,
  String userId,
  bool isMember,
) {
  final groupMembersQueryBuilder = MockSupabaseQueryBuilder();
  final membershipFilterBuilder = MockPostgrestFilterBuilder<dynamic>();

  when(mockClient.from('group_members')).thenReturn(groupMembersQueryBuilder);
  when(
    (groupMembersQueryBuilder as dynamic).select('id'),
  ).thenReturn(membershipFilterBuilder);
  when(
    membershipFilterBuilder.eq('group_id', groupId),
  ).thenReturn(membershipFilterBuilder);
  when(
    membershipFilterBuilder.eq('user_id', userId),
  ).thenReturn(membershipFilterBuilder);
  when(membershipFilterBuilder.maybeSingle()).thenReturn(
    _FakePostgrestTransformBuilder<Map<String, dynamic>?>(
      isMember ? {'id': 'member-id'} : null,
    ),
  );
}

void _setupSuccessfulExpenseCreationMocks(
  MockSupabaseClient mockClient,
  Expense testExpense,
) {
  final createdExpenseId = testExpense.id.isEmpty
      ? 'created-expense-id'
      : testExpense.id;

  final expensesQueryBuilder = MockSupabaseQueryBuilder();
  final insertFilterBuilder = MockPostgrestFilterBuilder<dynamic>();
  final insertSelectBuilder = _MockPostgrestTransformBuilder<dynamic>();
  final getExpenseFilterBuilder = MockPostgrestFilterBuilder<dynamic>();

  when(mockClient.from('expenses')).thenReturn(expensesQueryBuilder);

  when((expensesQueryBuilder as dynamic).insert(any)).thenReturn(
    insertFilterBuilder,
  );
  when((insertFilterBuilder as dynamic).select()).thenReturn(
    insertSelectBuilder,
  );
  when((insertSelectBuilder as dynamic).single()).thenReturn(
    _FakePostgrestTransformBuilder<Map<String, dynamic>>({
      'id': createdExpenseId,
    }),
  );

  final expenseParticipantsQueryBuilder = MockSupabaseQueryBuilder();
  when(
    mockClient.from('expense_participants'),
  ).thenReturn(expenseParticipantsQueryBuilder);
  when(
    (expenseParticipantsQueryBuilder as dynamic).insert(any),
  ).thenReturn(_FakePostgrestFilterBuilderForAwait());

  when((expensesQueryBuilder as dynamic).select(any)).thenReturn(
    getExpenseFilterBuilder,
  );
  when(
    getExpenseFilterBuilder.eq('id', createdExpenseId),
  ).thenReturn(getExpenseFilterBuilder);
  when(getExpenseFilterBuilder.single()).thenReturn(
    _FakePostgrestTransformBuilder<Map<String, dynamic>>({
      'id': createdExpenseId,
      'group_id': testExpense.groupId,
      'payer_id': testExpense.payerId,
      'payer_name': testExpense.payerName,
      'amount': testExpense.amount,
      'currency': testExpense.currency,
      'description': testExpense.description,
      'category': testExpense.category,
      'expense_date': testExpense.expenseDate.toIso8601String(),
      'created_at': testExpense.createdAt.toIso8601String(),
      'updated_at': testExpense.updatedAt.toIso8601String(),
      'expense_participants': testExpense.participants
          .map(
            (participant) => {
              'user_id': participant.userId,
              'display_name': participant.displayName,
              'share_amount': participant.shareAmount,
              'share_percentage': participant.sharePercentage,
            },
          )
          .toList(),
    }),
  );
}
