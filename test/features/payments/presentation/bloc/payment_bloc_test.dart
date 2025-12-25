// This diagnostic is ignored because Mockito's 'when' and 'thenReturn' syntax
// often triggers type mismatch warnings that are safe in a test context.
// ignore_for_file: argument_type_not_assignable
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';
import 'package:grex/features/payments/domain/repositories/payment_repository.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  group('PaymentBloc', () {
    late MockPaymentRepository mockRepository;
    late PaymentBloc paymentBloc;

    // Test data
    final testPayment = Payment(
      id: 'payment-1',
      groupId: 'group-1',
      payerId: 'user-1',
      payerName: 'Test Payer',
      recipientId: 'user-2',
      recipientName: 'Test Recipient',
      amount: 50,
      currency: 'USD',
      description: 'Test Payment',
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final testPayments = [testPayment];

    setUp(() {
      mockRepository = MockPaymentRepository();
      paymentBloc = PaymentBloc(mockRepository);
    });

    tearDown(() async {
      await paymentBloc.close();
    });

    group('PaymentsLoadRequested', () {
      blocTest<PaymentBloc, PaymentState>(
        'should emit [PaymentLoading, PaymentsLoaded] when payments are '
        'loaded successfully',
        build: () {
          when(
            mockRepository.getGroupPayments('group-1'),
          ).thenAnswer((_) async => Right(testPayments));
          when(
            mockRepository.watchGroupPayments('group-1'),
          ).thenAnswer((_) => Stream.value(testPayments));
          return paymentBloc;
        },
        act: (bloc) =>
            bloc.add(const PaymentsLoadRequested(groupId: 'group-1')),
        expect: () => [
          const PaymentLoading(),
          isA<PaymentsLoaded>()
              .having((state) => state.payments.length, 'payments length', 1)
              .having((state) => state.groupId, 'group id', 'group-1')
              .having(
                (state) => state.payments.first.id,
                'first payment id',
                'payment-1',
              ),
        ],
        verify: (_) {
          verify(mockRepository.getGroupPayments('group-1')).called(1);
        },
      );

      blocTest<PaymentBloc, PaymentState>(
        'should emit [PaymentLoading, PaymentError] when loading fails',
        build: () {
          when(mockRepository.getGroupPayments('group-1')).thenAnswer(
            (_) async => const Left(PaymentNetworkFailure('Network error')),
          );
          return paymentBloc;
        },
        act: (bloc) =>
            bloc.add(const PaymentsLoadRequested(groupId: 'group-1')),
        expect: () => [
          const PaymentLoading(),
          isA<PaymentError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<PaymentNetworkFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                'Failed to load payments',
              ),
        ],
        verify: (_) {
          verify(mockRepository.getGroupPayments('group-1')).called(1);
        },
      );
    });

    group('PaymentCreateRequested', () {
      blocTest<PaymentBloc, PaymentState>(
        'should emit [PaymentLoading, PaymentOperationSuccess] when payment '
        'is created successfully',
        build: () {
          when(
            mockRepository.createPayment(any),
          ).thenAnswer((_) async => Right(testPayment));
          when(
            mockRepository.getGroupPayments('group-1'),
          ).thenAnswer((_) async => Right(testPayments));
          return paymentBloc;
        },
        act: (bloc) => bloc.add(
          const PaymentCreateRequested(
            groupId: 'group-1',
            payerId: 'user-1',
            recipientId: 'user-2',
            amount: 100,
            currency: 'USD',
            description: 'New Payment',
          ),
        ),
        expect: () => [
          const PaymentLoading(message: 'Creating payment...'),
          isA<PaymentOperationSuccess>()
              .having(
                (state) => state.message,
                'message',
                'Payment created successfully',
              )
              .having((state) => state.groupId, 'group id', 'group-1'),
        ],
        verify: (_) {
          verify(
            mockRepository.createPayment(any),
          ).called(1);
          verify(mockRepository.getGroupPayments('group-1')).called(1);
        },
      );

      blocTest<PaymentBloc, PaymentState>(
        'should emit [PaymentLoading, PaymentError] when creation fails',
        build: () {
          when(
            mockRepository.createPayment(any),
          ).thenAnswer(
            (_) async => const Left(SelfPaymentFailure()),
          );
          return paymentBloc;
        },
        act: (bloc) => bloc.add(
          const PaymentCreateRequested(
            groupId: 'group-1',
            payerId: 'user-1',
            recipientId: 'user-1',
            amount: 100,
            currency: 'USD',
          ),
        ),
        expect: () => [
          const PaymentLoading(message: 'Creating payment...'),
          isA<PaymentError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<SelfPaymentFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                'Failed to create payment',
              ),
        ],
        verify: (_) {
          verify(
            mockRepository.createPayment(any),
          ).called(1);
        },
      );
    });

    group('PaymentDeleteRequested', () {
      blocTest<PaymentBloc, PaymentState>(
        'should emit [PaymentLoading, PaymentOperationSuccess] when payment '
        'is deleted successfully',
        build: () {
          when(
            mockRepository.deletePayment('payment-1'),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockRepository.getGroupPayments('group-1'),
          ).thenAnswer((_) async => const Right([])); // Empty after deletion
          return paymentBloc;
        },
        seed: () => PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) =>
            bloc.add(const PaymentDeleteRequested(paymentId: 'payment-1')),
        expect: () => [
          const PaymentLoading(message: 'Deleting payment...'),
          isA<PaymentOperationSuccess>().having(
            (state) => state.message,
            'message',
            'Payment deleted successfully',
          ),
        ],
        verify: (_) {
          verify(mockRepository.deletePayment('payment-1')).called(1);
          verify(mockRepository.getGroupPayments('group-1')).called(1);
        },
      );

      blocTest<PaymentBloc, PaymentState>(
        'should emit [PaymentLoading, PaymentError] when deletion fails',
        build: () {
          when(mockRepository.deletePayment('payment-1')).thenAnswer(
            (_) async =>
                const Left(PaymentNotFoundFailure('Payment not found')),
          );
          return paymentBloc;
        },
        seed: () => PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) =>
            bloc.add(const PaymentDeleteRequested(paymentId: 'payment-1')),
        expect: () => [
          const PaymentLoading(message: 'Deleting payment...'),
          isA<PaymentError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<PaymentNotFoundFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                'Failed to delete payment',
              ),
        ],
        verify: (_) {
          verify(mockRepository.deletePayment('payment-1')).called(1);
        },
      );
    });

    group('PaymentLoadRequested', () {
      blocTest<PaymentBloc, PaymentState>(
        'should emit [PaymentLoading, PaymentDetailLoaded] when payment is '
        'loaded successfully',
        build: () {
          when(
            mockRepository.getPaymentById('payment-1'),
          ).thenAnswer((_) async => Right(testPayment));
          return paymentBloc;
        },
        act: (bloc) =>
            bloc.add(const PaymentLoadRequested(paymentId: 'payment-1')),
        expect: () => [
          const PaymentLoading(message: 'Loading payment details...'),
          isA<PaymentDetailLoaded>()
              .having((state) => state.payment.id, 'payment id', 'payment-1')
              .having(
                (state) => state.payment.description,
                'description',
                'Test Payment',
              ),
        ],
        verify: (_) {
          verify(mockRepository.getPaymentById('payment-1')).called(1);
        },
      );

      blocTest<PaymentBloc, PaymentState>(
        'should emit [PaymentLoading, PaymentError] when loading fails',
        build: () {
          when(mockRepository.getPaymentById('payment-1')).thenAnswer(
            (_) async =>
                const Left(PaymentNotFoundFailure('Payment not found')),
          );
          return paymentBloc;
        },
        act: (bloc) =>
            bloc.add(const PaymentLoadRequested(paymentId: 'payment-1')),
        expect: () => [
          const PaymentLoading(message: 'Loading payment details...'),
          isA<PaymentError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<PaymentNotFoundFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                'Failed to load payment details',
              ),
        ],
        verify: (_) {
          verify(mockRepository.getPaymentById('payment-1')).called(1);
        },
      );
    });

    group('PaymentFilterRequested', () {
      blocTest<PaymentBloc, PaymentState>(
        'should apply filters to payments',
        build: () => paymentBloc,
        seed: () => PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const PaymentFilterRequested(
            groupId: 'group-1',
            payerId: 'user-1',
            minAmount: 10,
            maxAmount: 100,
          ),
        ),
        expect: () => [
          isA<PaymentsLoaded>()
              .having((state) => state.activeFilter, 'active filter', isNotNull)
              .having(
                (state) => state.activeFilter?.payerId,
                'filter payer id',
                'user-1',
              )
              .having(
                (state) => state.activeFilter?.minAmount,
                'filter min amount',
                10.0,
              )
              .having(
                (state) => state.activeFilter?.maxAmount,
                'filter max amount',
                100.0,
              ),
        ],
      );

      blocTest<PaymentBloc, PaymentState>(
        'should clear filters when all criteria are null',
        build: () => paymentBloc,
        seed: () => PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
          activeFilter: const PaymentFilter(payerId: 'user-1'),
        ),
        act: (bloc) => bloc.add(
          const PaymentFilterRequested(
            groupId: 'group-1',
          ),
        ),
        expect: () => [
          isA<PaymentsLoaded>().having(
            (state) => state.activeFilter,
            'active filter',
            isNull,
          ),
        ],
      );
    });

    group('PaymentFilterCleared', () {
      blocTest<PaymentBloc, PaymentState>(
        'should clear all filters',
        build: () => paymentBloc,
        seed: () => PaymentsLoaded(
          payments: testPayments,
          filteredPayments: const [],
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
          activeFilter: const PaymentFilter(payerId: 'user-1'),
        ),
        act: (bloc) => bloc.add(const PaymentFilterCleared(groupId: 'group-1')),
        expect: () => [
          isA<PaymentsLoaded>()
              .having((state) => state.activeFilter, 'active filter', isNull)
              .having(
                (state) => state.filteredPayments.length,
                'filtered count',
                1,
              ),
        ],
      );
    });

    group('PaymentSortRequested', () {
      final payment1 = testPayment.copyWith(
        id: 'payment-1',
        payerName: 'Alice',
        amount: 100,
        paymentDate: DateTime(2023),
      );
      final payment2 = testPayment.copyWith(
        id: 'payment-2',
        payerName: 'Bob',
        amount: 50,
        paymentDate: DateTime(2023, 1, 2),
      );
      final unsortedPayments = [payment2, payment1];

      blocTest<PaymentBloc, PaymentState>(
        'should sort payments by date ascending',
        build: () => paymentBloc,
        seed: () => PaymentsLoaded(
          payments: unsortedPayments,
          filteredPayments: unsortedPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const PaymentSortRequested(
            groupId: 'group-1',
            sortBy: PaymentSortCriteria.date,
            ascending: true,
          ),
        ),
        expect: () => [
          isA<PaymentsLoaded>()
              .having(
                (state) => state.payments.first.id,
                'first payment',
                'payment-1',
              )
              .having(
                (state) => state.sortBy,
                'sort criteria',
                PaymentSortCriteria.date,
              )
              .having((state) => state.sortAscending, 'sort ascending', true),
        ],
      );

      blocTest<PaymentBloc, PaymentState>(
        'should sort payments by amount descending',
        build: () => paymentBloc,
        seed: () => PaymentsLoaded(
          payments: unsortedPayments,
          filteredPayments: unsortedPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const PaymentSortRequested(
            groupId: 'group-1',
            sortBy: PaymentSortCriteria.amount,
          ),
        ),
        expect: () => [
          isA<PaymentsLoaded>()
              .having(
                (state) => state.payments.first.id,
                'first payment',
                'payment-1',
              )
              .having(
                (state) => state.sortBy,
                'sort criteria',
                PaymentSortCriteria.amount,
              )
              .having((state) => state.sortAscending, 'sort ascending', false),
        ],
      );

      blocTest<PaymentBloc, PaymentState>(
        'should sort payments by payer name ascending',
        build: () => paymentBloc,
        seed: () => PaymentsLoaded(
          payments: unsortedPayments,
          filteredPayments: unsortedPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(
          const PaymentSortRequested(
            groupId: 'group-1',
            sortBy: PaymentSortCriteria.payer,
            ascending: true,
          ),
        ),
        expect: () => [
          isA<PaymentsLoaded>()
              .having(
                (state) => state.payments.first.id,
                'first payment',
                'payment-1',
              )
              .having(
                (state) => state.sortBy,
                'sort criteria',
                PaymentSortCriteria.payer,
              )
              .having((state) => state.sortAscending, 'sort ascending', true),
        ],
      );
    });

    group('PaymentRefreshRequested', () {
      blocTest<PaymentBloc, PaymentState>(
        'should trigger PaymentsLoadRequested when refresh is requested',
        build: () {
          when(
            mockRepository.getGroupPayments('group-1'),
          ).thenAnswer((_) async => Right(testPayments));
          when(
            mockRepository.watchGroupPayments('group-1'),
          ).thenAnswer((_) => Stream.value(testPayments));
          return paymentBloc;
        },
        act: (bloc) =>
            bloc.add(const PaymentRefreshRequested(groupId: 'group-1')),
        expect: () => [
          const PaymentLoading(),
          isA<PaymentsLoaded>().having(
            (state) => state.payments.length,
            'payments length',
            1,
          ),
        ],
        verify: (_) {
          verify(mockRepository.getGroupPayments('group-1')).called(1);
        },
      );
    });

    group('Helper Methods', () {
      test('canDeletePayment should return true when payment exists', () {
        // Set up state with loaded payments
        paymentBloc.emit(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        );

        expect(paymentBloc.canDeletePayment('payment-1'), isTrue);
        expect(paymentBloc.canDeletePayment('nonexistent'), isFalse);
      });

      test('getFilterSummary should return correct summary', () {
        // No filters
        paymentBloc.emit(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        );
        expect(paymentBloc.getFilterSummary(), isNull);

        // With filters
        paymentBloc.emit(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
            activeFilter: const PaymentFilter(payerId: 'user-1'),
          ),
        );
        expect(paymentBloc.getFilterSummary(), contains('Payer: user-1'));
      });

      test('getPaymentsByUser should return correct payments', () {
        final payment1 = testPayment.copyWith(
          id: 'payment-1',
          payerId: 'user-1',
        );
        final payment2 = testPayment.copyWith(
          id: 'payment-2',
          recipientId: 'user-1',
        );
        final payment3 = testPayment.copyWith(
          id: 'payment-3',
          payerId: 'user-2',
        );
        final payments = [payment1, payment2, payment3];

        paymentBloc.emit(
          PaymentsLoaded(
            payments: payments,
            filteredPayments: payments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        );

        final userPayments = paymentBloc.getPaymentsByUser('user-1');
        expect(userPayments.length, equals(2));
        expect(
          userPayments.map((p) => p.id),
          containsAll(['payment-1', 'payment-2']),
        );
      });

      test('getTotalPaidByUser should return correct amount', () {
        final payment1 = testPayment.copyWith(
          id: 'payment-1',
          payerId: 'user-1',
          amount: 100,
        );
        final payment2 = testPayment.copyWith(
          id: 'payment-2',
          payerId: 'user-1',
          amount: 50,
        );
        final payment3 = testPayment.copyWith(
          id: 'payment-3',
          payerId: 'user-2',
          amount: 75,
        );
        final payments = [payment1, payment2, payment3];

        paymentBloc.emit(
          PaymentsLoaded(
            payments: payments,
            filteredPayments: payments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        );

        expect(paymentBloc.getTotalPaidByUser('user-1'), equals(150.0));
        expect(paymentBloc.getTotalPaidByUser('user-2'), equals(75.0));
      });

      test('getTotalReceivedByUser should return correct amount', () {
        final payment1 = testPayment.copyWith(
          id: 'payment-1',
          recipientId: 'user-1',
          amount: 100,
        );
        final payment2 = testPayment.copyWith(
          id: 'payment-2',
          recipientId: 'user-1',
          amount: 50,
        );
        final payment3 = testPayment.copyWith(
          id: 'payment-3',
          recipientId: 'user-2',
          amount: 75,
        );
        final payments = [payment1, payment2, payment3];

        paymentBloc.emit(
          PaymentsLoaded(
            payments: payments,
            filteredPayments: payments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        );

        expect(paymentBloc.getTotalReceivedByUser('user-1'), equals(150.0));
        expect(paymentBloc.getTotalReceivedByUser('user-2'), equals(75.0));
      });

      test('getNetPaymentForUser should return correct net amount', () {
        final payment1 = testPayment.copyWith(
          id: 'payment-1',
          payerId: 'user-1',
          amount: 100,
        );
        final payment2 = testPayment.copyWith(
          id: 'payment-2',
          recipientId: 'user-1',
          amount: 150,
        );
        final payments = [payment1, payment2];

        paymentBloc.emit(
          PaymentsLoaded(
            payments: payments,
            filteredPayments: payments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        );

        // User-1: received 150, paid 100, net = +50
        expect(paymentBloc.getNetPaymentForUser('user-1'), equals(50.0));
      });
    });

    group('Real-time Updates', () {
      blocTest<PaymentBloc, PaymentState>(
        'should handle real-time payment updates',
        build: () {
          when(
            mockRepository.getGroupPayments('group-1'),
          ).thenAnswer((_) async => Right(testPayments));
          when(mockRepository.watchGroupPayments('group-1')).thenAnswer(
            (_) => Stream.fromIterable([
              testPayments,
              [
                ...testPayments,
                testPayment.copyWith(
                  id: 'payment-2',
                  description: 'New Payment',
                ),
              ],
            ]),
          );
          return paymentBloc;
        },
        act: (bloc) =>
            bloc.add(const PaymentsLoadRequested(groupId: 'group-1')),
        expect: () => [
          const PaymentLoading(),
          isA<PaymentsLoaded>().having(
            (state) => state.payments.length,
            'payments length',
            1,
          ),
          isA<PaymentsLoaded>().having(
            (state) => state.payments.length,
            'payments length',
            2,
          ),
        ],
        verify: (_) {
          verify(mockRepository.getGroupPayments('group-1')).called(1);
        },
      );

      blocTest<PaymentBloc, PaymentState>(
        'should handle real-time connection errors gracefully',
        build: () {
          when(
            mockRepository.getGroupPayments('group-1'),
          ).thenAnswer((_) async => Right(testPayments));
          when(
            mockRepository.watchGroupPayments('group-1'),
          ).thenAnswer((_) => Stream.error('Connection error'));
          return paymentBloc;
        },
        act: (bloc) =>
            bloc.add(const PaymentsLoadRequested(groupId: 'group-1')),
        expect: () => [
          const PaymentLoading(),
          isA<PaymentsLoaded>().having(
            (state) => state.payments.length,
            'payments length',
            1,
          ),
          isA<PaymentError>()
              .having(
                (state) => state.failure,
                'failure',
                isA<PaymentNetworkFailure>(),
              )
              .having(
                (state) => state.message,
                'message',
                contains('Connection error'),
              ),
        ],
        verify: (_) {
          verify(mockRepository.getGroupPayments('group-1')).called(1);
        },
      );
    });

    group('State Transitions', () {
      test('PaymentsLoaded state helper methods work correctly', () {
        final state = PaymentsLoaded(
          payments: testPayments,
          filteredPayments: const [],
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
          activeFilter: const PaymentFilter(payerId: 'user-1'),
        );

        expect(state.getPaymentById('payment-1'), equals(testPayment));
        expect(state.getPaymentById('nonexistent'), isNull);
        expect(state.hasActiveFilters, isTrue);
        expect(state.filteredCount, equals(0));
        expect(state.totalCount, equals(1));
        expect(state.isFilteredEmpty, isTrue);
        expect(state.isEmpty, isFalse);
        expect(state.totalAmount, equals(50.0));
        expect(state.filteredTotalAmount, equals(0.0));
      });

      test('PaymentFilter matches method works correctly', () {
        final filter = PaymentFilter(
          payerId: 'user-1',
          minAmount: 10,
          maxAmount: 100,
          startDate: DateTime(2023),
          endDate: DateTime(2023, 12, 31),
        );

        final matchingPayment = testPayment.copyWith(
          payerId: 'user-1',
          amount: 50,
          paymentDate: DateTime(2023, 6, 15),
        );

        final nonMatchingPayment = testPayment.copyWith(
          payerId: 'user-2',
          amount: 150,
          paymentDate: DateTime(2024),
        );

        expect(filter.matches(matchingPayment), isTrue);
        expect(filter.matches(nonMatchingPayment), isFalse);
      });

      test('PaymentFilter description works correctly', () {
        final filter = PaymentFilter(
          payerId: 'user-1',
          minAmount: 10,
          maxAmount: 100,
          startDate: DateTime(2023),
          endDate: DateTime(2023, 12, 31),
        );

        final description = filter.description;
        expect(description, contains('Date:'));
        expect(description, contains('Payer: user-1'));
        expect(description, contains('Amount:'));
      });
    });
  });
}
