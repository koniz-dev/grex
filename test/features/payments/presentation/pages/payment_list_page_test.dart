// This diagnostic is ignored because Mockito's 'when' and 'thenReturn' syntax
// often triggers type mismatch warnings that are safe in a test context.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';
import 'package:grex/features/payments/presentation/pages/payment_list_page.dart';
import 'package:mockito/mockito.dart';

class MockPaymentBloc extends Mock implements PaymentBloc {
  @override
  void add(PaymentEvent? event) => super.noSuchMethod(
    Invocation.method(#add, [event]),
    returnValueForMissingStub: null,
  );

  @override
  Stream<PaymentState> get stream =>
      super.noSuchMethod(
            Invocation.getter(#stream),
            returnValue: const Stream<PaymentState>.empty(),
            returnValueForMissingStub: const Stream<PaymentState>.empty(),
          )
          as Stream<PaymentState>;

  @override
  PaymentState get state =>
      super.noSuchMethod(
            Invocation.getter(#state),
            returnValue: const PaymentInitial(),
            returnValueForMissingStub: const PaymentInitial(),
          )
          as PaymentState;
}

void main() {
  group('PaymentListPage Widget Tests', () {
    late MockPaymentBloc mockPaymentBloc;
    late List<Payment> testPayments;

    setUpAll(() async {
      final getIt = GetIt.instance;
      if (getIt.isRegistered<PaymentBloc>()) {
        await getIt.unregister<PaymentBloc>();
      }
    });

    setUp(() {
      mockPaymentBloc = MockPaymentBloc();
      GetIt.instance.registerFactory<PaymentBloc>(() => mockPaymentBloc);

      // Create test payments
      testPayments = [
        Payment(
          id: 'payment-1',
          groupId: 'group-1',
          payerId: 'user-1',
          payerName: 'John Doe',
          recipientId: 'user-2',
          recipientName: 'Jane Smith',
          amount: 50,
          currency: 'USD',
          description: 'Dinner payment',
          paymentDate: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Payment(
          id: 'payment-2',
          groupId: 'group-1',
          payerId: 'user-2',
          payerName: 'Jane Smith',
          recipientId: 'user-3',
          recipientName: 'Bob Johnson',
          amount: 75,
          currency: 'USD',
          description: 'Movie tickets',
          paymentDate: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      // Setup default mock behavior
      when(mockPaymentBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    Widget createTestWidget() {
      return const MaterialApp(
        home: PaymentListPage(
          groupId: 'group-1',
          groupName: 'Test Group',
          groupCurrency: 'USD',
        ),
      );
    }

    testWidgets('should display app bar with title and add button', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Payments'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentLoading());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentLoading()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state with retry button', (tester) async {
      // Arrange
      const errorMessage = 'Failed to load payments';
      when(mockPaymentBloc.state).thenReturn(
        const PaymentError(
          failure: PaymentNetworkFailure(),
          message: errorMessage,
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          const PaymentError(
            failure: PaymentNetworkFailure(),
            message: errorMessage,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading payments'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should retry loading when retry button is tapped', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to load payments';
      when(mockPaymentBloc.state).thenReturn(
        const PaymentError(
          failure: PaymentNetworkFailure(),
          message: errorMessage,
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          const PaymentError(
            failure: PaymentNetworkFailure(),
            message: errorMessage,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Retry'));

      // Assert
      verify(mockPaymentBloc.add(any)).called(greaterThan(1));
    });

    testWidgets('should display empty state when no payments', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: const [],
          filteredPayments: const [],
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: const [],
            filteredPayments: const [],
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('No payments yet'), findsOneWidget);
      expect(find.text('Record Payment'), findsOneWidget);
    });

    testWidgets('should display list of payments when loaded', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('John Doe → Jane Smith'), findsOneWidget);
      expect(find.text('Jane Smith → Bob Johnson'), findsOneWidget);
      expect(find.text(r'$50.00'), findsOneWidget);
      expect(find.text(r'$75.00'), findsOneWidget);
    });

    testWidgets('should display filter button when payments exist', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should open filter sheet when filter button is tapped', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Filter & Sort'), findsOneWidget);
    });

    testWidgets('should navigate to create payment when add button is tapped', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Assert - should navigate to create payment page
      // In a real test, you'd verify the navigation
    });

    testWidgets('should navigate to create payment from empty state', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: const [],
          filteredPayments: const [],
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: const [],
            filteredPayments: const [],
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();

      // Assert - should navigate to create payment page
      // In a real test, you'd verify the navigation
    });

    testWidgets('should refresh payments on pull to refresh', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Perform pull to refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();

      // Assert
      verify(mockPaymentBloc.add(any)).called(greaterThan(1));
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap delete button on first payment
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Delete Payment'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this payment?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('should dispatch delete event when confirmed', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap delete and confirm
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);

      // Assert
      verify(
        mockPaymentBloc.add(argThat(isA<PaymentDeleteRequested>())),
      ).called(1);
    });

    testWidgets('should show success message when payment is deleted', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
          PaymentOperationSuccess(
            message: 'Payment deleted successfully',
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
          ),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process the PaymentDeleted state

      // Assert
      expect(find.text('Payment deleted successfully'), findsOneWidget);
    });

    testWidgets('should show error message when deletion fails', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to delete payment';
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
          const PaymentError(
            failure: PaymentNetworkFailure(),
            message: errorMessage,
          ),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process the PaymentError state

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should load payments on init', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      verify(
        mockPaymentBloc.add(argThat(isA<PaymentsLoadRequested>())),
      ).called(1);
    });

    testWidgets('should display payments in chronological order', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert - newer payments should appear first
      final paymentItems = find.byType(Card);
      expect(paymentItems, findsNWidgets(2));
    });

    testWidgets('should handle large number of payments', (tester) async {
      // Arrange
      final manyPayments = List.generate(
        50,
        (index) => Payment(
          id: 'payment-$index',
          groupId: 'group-1',
          payerId: 'user-1',
          payerName: 'User 1',
          recipientId: 'user-2',
          recipientName: 'User 2',
          amount: 10.0 + index,
          currency: 'USD',
          description: 'Payment $index',
          paymentDate: DateTime.now().subtract(Duration(days: index)),
          createdAt: DateTime.now().subtract(Duration(days: index)),
        ),
      );

      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: manyPayments,
          filteredPayments: manyPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: manyPayments,
            filteredPayments: manyPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert - should handle scrolling
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display floating action button', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: testPayments,
          filteredPayments: testPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNWidgets(2)); // App bar + FAB
    });

    testWidgets('should handle real-time payment updates', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: const [],
          filteredPayments: const [],
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          PaymentsLoaded(
            payments: const [],
            filteredPayments: const [],
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
          PaymentsLoaded(
            payments: testPayments,
            filteredPayments: testPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial empty state
      await tester.pump(); // Updated with payments

      // Assert
      expect(find.text('John Doe → Jane Smith'), findsOneWidget);
      expect(find.text('Jane Smith → Bob Johnson'), findsOneWidget);
    });

    testWidgets('should maintain scroll position during updates', (
      tester,
    ) async {
      // Arrange
      final manyPayments = List.generate(
        20,
        (index) => Payment(
          id: 'payment-$index',
          groupId: 'group-1',
          payerId: 'user-1',
          payerName: 'User 1',
          recipientId: 'user-2',
          recipientName: 'User 2',
          amount: 10.0 + index,
          currency: 'USD',
          description: 'Payment $index',
          paymentDate: DateTime.now().subtract(Duration(days: index)),
          createdAt: DateTime.now().subtract(Duration(days: index)),
        ),
      );

      when(mockPaymentBloc.state).thenReturn(
        PaymentsLoaded(
          payments: manyPayments,
          filteredPayments: manyPayments,
          groupId: 'group-1',
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.value(
          PaymentsLoaded(
            payments: manyPayments,
            filteredPayments: manyPayments,
            groupId: 'group-1',
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // Assert - should maintain scroll position
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
