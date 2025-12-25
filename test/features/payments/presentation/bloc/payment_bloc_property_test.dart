// This diagnostic is ignored because Mockito's 'when' and 'thenReturn' syntax
// often triggers type mismatch warnings that are safe in a test context.
// ignore_for_file: argument_type_not_assignable
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/domain/repositories/payment_repository.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  group('PaymentBloc Property-Based Tests', () {
    late MockPaymentRepository mockRepository;
    late PaymentBloc paymentBloc;
    final random = Random();

    setUp(() {
      mockRepository = MockPaymentRepository();
      paymentBloc = PaymentBloc(mockRepository);
    });

    tearDown(() async {
      await paymentBloc.close();
    });

    /// Property 16: Payment listing includes timestamps
    /// Validates: Requirements 4.4
    group('Property 16: Payment listing includes timestamps', () {
      test(
        'should include valid timestamps for all payments with 1000+ '
        'iterations',
        () async {
          for (var iteration = 0; iteration < 1000; iteration++) {
            // Generate random payments with timestamps
            final payments = _generateRandomPaymentsWithTimestamps(
              random,
              3 + random.nextInt(12),
            );

            when(
              mockRepository.getGroupPayments(any),
            ).thenAnswer((_) async => Right(payments));
            when(
              mockRepository.watchGroupPayments(any),
            ).thenAnswer((_) => Stream.value(payments));

            // Load payments
            paymentBloc.add(const PaymentsLoadRequested(groupId: 'test-group'));

            // Wait for state to be loaded
            await expectLater(
              paymentBloc.stream,
              emitsInOrder([
                isA<PaymentLoading>(),
                isA<PaymentsLoaded>(),
              ]),
            );

            final state = paymentBloc.state;
            if (state is PaymentsLoaded) {
              final loadedPayments = state.payments;

              // Property: All payments must have valid timestamps
              for (final payment in loadedPayments) {
                // Payment date should not be in the future
                expect(
                  payment.paymentDate.isBefore(
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  isTrue,
                  reason:
                      'Payment date should not be in the future at iteration '
                      '$iteration',
                );

                // Created timestamp should not be in the future
                expect(
                  payment.createdAt.isBefore(
                    DateTime.now().add(const Duration(minutes: 1)),
                  ),
                  isTrue,
                  reason:
                      'Created timestamp should not be in the future at '
                      'iteration $iteration',
                );

                // Payment date should be before or equal to created timestamp
                expect(
                  payment.paymentDate.isBefore(
                        payment.createdAt.add(const Duration(days: 1)),
                      ) ||
                      payment.paymentDate.isAtSameMomentAs(payment.createdAt),
                  isTrue,
                  reason:
                      'Payment date should be before or close to created '
                      'timestamp at iteration $iteration',
                );
              }

              // Property: Payments should be sorted by date (newest first by
              // default)
              for (var i = 0; i < loadedPayments.length - 1; i++) {
                expect(
                  loadedPayments[i].paymentDate.isAfter(
                        loadedPayments[i + 1].paymentDate,
                      ) ||
                      loadedPayments[i].paymentDate.isAtSameMomentAs(
                        loadedPayments[i + 1].paymentDate,
                      ),
                  isTrue,
                  reason:
                      'Payments should be in chronological order (newest '
                      'first) at iteration $iteration',
                );
              }

              // Property: Last updated timestamp should be recent
              expect(
                state.lastUpdated.isAfter(
                  DateTime.now().subtract(const Duration(seconds: 5)),
                ),
                isTrue,
                reason:
                    'Last updated timestamp should be recent at iteration '
                    '$iteration',
              );
            }

            // Reset for next iteration
            await paymentBloc.close();
            paymentBloc = PaymentBloc(mockRepository);
          }
        },
      );

      test(
        'should maintain timestamp consistency during sorting with 500+ '
        'iterations',
        () async {
          for (var iteration = 0; iteration < 500; iteration++) {
            final payments = _generateRandomPaymentsWithTimestamps(
              random,
              5 + random.nextInt(10),
            );

            when(
              mockRepository.getGroupPayments(any),
            ).thenAnswer((_) async => Right(payments));
            when(
              mockRepository.watchGroupPayments(any),
            ).thenAnswer((_) => Stream.value(payments));

            // Load payments first
            paymentBloc.add(const PaymentsLoadRequested(groupId: 'test-group'));
            await expectLater(
              paymentBloc.stream,
              emitsInOrder([
                isA<PaymentLoading>(),
                isA<PaymentsLoaded>(),
              ]),
            );

            // Test different sorting criteria
            final sortCriteria = PaymentSortCriteria
                .values[random.nextInt(PaymentSortCriteria.values.length)];
            final ascending = random.nextBool();

            paymentBloc.add(
              PaymentSortRequested(
                groupId: 'test-group',
                sortBy: sortCriteria,
                ascending: ascending,
              ),
            );

            await expectLater(
              paymentBloc.stream,
              emits(isA<PaymentsLoaded>()),
            );

            final state = paymentBloc.state;
            if (state is PaymentsLoaded) {
              final sortedPayments = state.payments;

              // Property: All timestamps should remain valid after sorting
              for (final payment in sortedPayments) {
                expect(
                  payment.paymentDate.isBefore(
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  isTrue,
                  reason:
                      'Payment date should remain valid after sorting at '
                      'iteration $iteration',
                );
              }

              // Property: Payments should be sorted according to criteria
              if (sortCriteria == PaymentSortCriteria.date) {
                for (var i = 0; i < sortedPayments.length - 1; i++) {
                  final current = sortedPayments[i];
                  final next = sortedPayments[i + 1];
                  final comparison = current.paymentDate.compareTo(
                    next.paymentDate,
                  );

                  if (ascending) {
                    expect(
                      comparison,
                      lessThanOrEqualTo(0),
                      reason:
                          'Date sorting ascending failed at iteration '
                          '$iteration',
                    );
                  } else {
                    expect(
                      comparison,
                      greaterThanOrEqualTo(0),
                      reason:
                          'Date sorting descending failed at iteration '
                          '$iteration',
                    );
                  }
                }
              }

              // Property: Last updated timestamp should be updated
              expect(
                state.lastUpdated.isAfter(
                  DateTime.now().subtract(const Duration(seconds: 5)),
                ),
                isTrue,
                reason:
                    'Last updated should be recent after sorting at iteration '
                    '$iteration',
              );
            }

            // Reset for next iteration
            await paymentBloc.close();
            paymentBloc = PaymentBloc(mockRepository);
          }
        },
      );

      test(
        'should preserve timestamps during filtering with 500+ iterations',
        () async {
          for (var iteration = 0; iteration < 500; iteration++) {
            final payments = _generateRandomPaymentsWithTimestamps(
              random,
              5 + random.nextInt(10),
            );

            when(
              mockRepository.getGroupPayments(any),
            ).thenAnswer((_) async => Right(payments));
            when(
              mockRepository.watchGroupPayments(any),
            ).thenAnswer((_) => Stream.value(payments));

            // Load payments first
            paymentBloc.add(const PaymentsLoadRequested(groupId: 'test-group'));
            await expectLater(
              paymentBloc.stream,
              emitsInOrder([
                isA<PaymentLoading>(),
                isA<PaymentsLoaded>(),
              ]),
            );

            // Apply random filter
            final now = DateTime.now();
            final startDate = now.subtract(Duration(days: random.nextInt(30)));
            final endDate = now.subtract(Duration(days: random.nextInt(15)));

            paymentBloc.add(
              PaymentFilterRequested(
                groupId: 'test-group',
                startDate: startDate,
                endDate: endDate,
              ),
            );

            await expectLater(
              paymentBloc.stream,
              emits(isA<PaymentsLoaded>()),
            );

            final state = paymentBloc.state;
            if (state is PaymentsLoaded) {
              // Property: All filtered payments should have timestamps within
              // the filter range
              for (final payment in state.filteredPayments) {
                expect(
                  payment.paymentDate.isAfter(
                        startDate.subtract(const Duration(days: 1)),
                      ) &&
                      payment.paymentDate.isBefore(
                        endDate.add(const Duration(days: 1)),
                      ),
                  isTrue,
                  reason:
                      'Filtered payment dates should be within range at '
                      'iteration $iteration',
                );
              }

              // Property: Filter should be active
              expect(
                state.activeFilter,
                isNotNull,
                reason: 'Filter should be active at iteration $iteration',
              );

              // Property: Last updated timestamp should be recent
              expect(
                state.lastUpdated.isAfter(
                  DateTime.now().subtract(const Duration(seconds: 5)),
                ),
                isTrue,
                reason:
                    'Last updated should be recent after filtering at '
                    'iteration $iteration',
              );
            }

            // Reset for next iteration
            await paymentBloc.close();
            paymentBloc = PaymentBloc(mockRepository);
          }
        },
      );

      test(
        'should handle real-time updates with valid timestamps with 300+ '
        'iterations',
        () async {
          for (var iteration = 0; iteration < 300; iteration++) {
            final initialPayments = _generateRandomPaymentsWithTimestamps(
              random,
              3 + random.nextInt(5),
            );
            final newPayment = _generateRandomPaymentWithTimestamp(random);
            final updatedPayments = [...initialPayments, newPayment];

            when(
              mockRepository.getGroupPayments(any),
            ).thenAnswer((_) async => Right(initialPayments));
            when(mockRepository.watchGroupPayments(any)).thenAnswer(
              (_) => Stream.fromIterable([initialPayments, updatedPayments]),
            );

            // Load payments
            paymentBloc.add(const PaymentsLoadRequested(groupId: 'test-group'));

            // Wait for initial load and real-time update
            await expectLater(
              paymentBloc.stream,
              emitsInOrder([
                isA<PaymentLoading>(),
                isA<PaymentsLoaded>().having(
                  (state) => state.payments.length,
                  'initial count',
                  initialPayments.length,
                ),
                isA<PaymentsLoaded>().having(
                  (state) => state.payments.length,
                  'updated count',
                  updatedPayments.length,
                ),
              ]),
            );

            final state = paymentBloc.state;
            if (state is PaymentsLoaded) {
              // Property: All payments including new ones should have valid
              // timestamps
              for (final payment in state.payments) {
                expect(
                  payment.paymentDate.isBefore(
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  isTrue,
                  reason:
                      'Payment date should be valid after real-time update at '
                      'iteration $iteration',
                );
              }

              // Property: Last updated timestamp should be very recent (just
              // updated)
              expect(
                state.lastUpdated.isAfter(
                  DateTime.now().subtract(const Duration(seconds: 2)),
                ),
                isTrue,
                reason:
                    'Last updated should be very recent after real-time update '
                    'at iteration $iteration',
              );

              // Property: New payment should be included
              final hasNewPayment = state.payments.any(
                (p) => p.id == newPayment.id,
              );
              expect(
                hasNewPayment,
                isTrue,
                reason:
                    'New payment should be included after real-time update '
                    'at iteration $iteration',
              );
            }

            // Reset for next iteration
            await paymentBloc.close();
            paymentBloc = PaymentBloc(mockRepository);
          }
        },
      );

      test(
        'should maintain timestamp integrity across operations with 200+ '
        'iterations',
        () async {
          for (var iteration = 0; iteration < 200; iteration++) {
            final payments = _generateRandomPaymentsWithTimestamps(
              random,
              4 + random.nextInt(6),
            );

            when(
              mockRepository.getGroupPayments(any),
            ).thenAnswer((_) async => Right(payments));
            when(
              mockRepository.watchGroupPayments(any),
            ).thenAnswer((_) => Stream.value(payments));

            // Load payments
            paymentBloc.add(const PaymentsLoadRequested(groupId: 'test-group'));
            await expectLater(
              paymentBloc.stream,
              emitsInOrder([
                isA<PaymentLoading>(),
                isA<PaymentsLoaded>(),
              ]),
            );

            // Perform multiple operations
            final operations = random.nextInt(3) + 1;
            for (var op = 0; op < operations; op++) {
              final operationType = random.nextInt(3);

              switch (operationType) {
                case 0: // Sort
                  paymentBloc.add(
                    PaymentSortRequested(
                      groupId: 'test-group',
                      sortBy:
                          PaymentSortCriteria.values[random.nextInt(
                            PaymentSortCriteria.values.length,
                          )],
                      ascending: random.nextBool(),
                    ),
                  );
                case 1: // Filter
                  paymentBloc.add(
                    PaymentFilterRequested(
                      groupId: 'test-group',
                      startDate: DateTime.now().subtract(
                        Duration(days: random.nextInt(30)),
                      ),
                    ),
                  );
                case 2: // Clear filter
                  paymentBloc.add(
                    const PaymentFilterCleared(groupId: 'test-group'),
                  );
              }

              await expectLater(
                paymentBloc.stream,
                emits(isA<PaymentsLoaded>()),
              );
            }

            final state = paymentBloc.state;
            if (state is PaymentsLoaded) {
              // Property: After all operations, timestamps should still be
              // valid
              for (final payment in state.payments) {
                expect(
                  payment.paymentDate.isBefore(
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  isTrue,
                  reason:
                      'Payment date should remain valid after operations at '
                      'iteration $iteration',
                );
              }

              // Property: Last updated should be recent
              expect(
                state.lastUpdated.isAfter(
                  DateTime.now().subtract(const Duration(seconds: 10)),
                ),
                isTrue,
                reason:
                    'Last updated should be recent after operations at '
                    'iteration $iteration',
              );
            }

            // Reset for next iteration
            await paymentBloc.close();
            paymentBloc = PaymentBloc(mockRepository);
          }
        },
      );
    });
  });
}

/// Generate random payments with valid timestamps
List<Payment> _generateRandomPaymentsWithTimestamps(Random random, int count) {
  final payments = <Payment>[];
  final baseDate = DateTime.now().subtract(Duration(days: random.nextInt(90)));

  for (var i = 0; i < count; i++) {
    final paymentDate = baseDate.add(
      Duration(
        days: random.nextInt(30),
        hours: random.nextInt(24),
        minutes: random.nextInt(60),
      ),
    );

    final createdAt = paymentDate.add(Duration(minutes: random.nextInt(30)));

    payments.add(
      Payment(
        id: 'payment-$i-${random.nextInt(10000)}',
        groupId: 'test-group',
        payerId: 'user-${random.nextInt(5)}',
        payerName: 'Payer ${random.nextInt(5)}',
        recipientId: 'user-${random.nextInt(5) + 5}',
        recipientName: 'Recipient ${random.nextInt(5)}',
        amount: 10.0 + random.nextDouble() * 500,
        currency: 'USD',
        description: 'Payment $i',
        paymentDate: paymentDate,
        createdAt: createdAt,
      ),
    );
  }

  return payments;
}

/// Generate a single random payment with valid timestamp
Payment _generateRandomPaymentWithTimestamp(Random random) {
  final paymentDate = DateTime.now().subtract(
    Duration(days: random.nextInt(7)),
  );
  final createdAt = paymentDate.add(Duration(minutes: random.nextInt(30)));

  return Payment(
    id: 'payment-new-${random.nextInt(10000)}',
    groupId: 'test-group',
    payerId: 'user-${random.nextInt(5)}',
    payerName: 'Payer ${random.nextInt(5)}',
    recipientId: 'user-${random.nextInt(5) + 5}',
    recipientName: 'Recipient ${random.nextInt(5)}',
    amount: 10.0 + random.nextDouble() * 500,
    currency: 'USD',
    description: 'New Payment',
    paymentDate: paymentDate,
    createdAt: createdAt,
  );
}
