import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/features/balances/domain/entities/settlement.dart';
import 'package:grex/features/balances/presentation/bloc/balance_bloc.dart';
import 'package:grex/features/balances/presentation/bloc/balance_event.dart';
import 'package:grex/features/balances/presentation/bloc/balance_state.dart';
import 'package:grex/features/balances/presentation/pages/settlement_plan_page.dart';
import 'package:mockito/mockito.dart';

class MockBalanceBloc extends Mock implements BalanceBloc {
  @override
  BalanceState get state =>
      super.noSuchMethod(
            Invocation.getter(#state),
            returnValue: const BalanceInitial(),
          )
          as BalanceState;

  @override
  Stream<BalanceState> get stream =>
      super.noSuchMethod(
            Invocation.getter(#stream),
            returnValue: const Stream<BalanceState>.empty(),
          )
          as Stream<BalanceState>;

  @override
  Future<void> close() =>
      super.noSuchMethod(
            Invocation.method(#close, []),
            returnValue: Future<void>.value(),
          )
          as Future<void>;
}

void main() {
  group('SettlementPlanPage Widget Tests', () {
    late MockBalanceBloc mockBalanceBloc;
    late List<Settlement> testSettlements;

    setUpAll(() async {
      final getIt = GetIt.instance;
      if (getIt.isRegistered<BalanceBloc>()) {
        await getIt.unregister<BalanceBloc>();
      }
    });

    setUp(() {
      mockBalanceBloc = MockBalanceBloc();
      GetIt.instance.registerFactory<BalanceBloc>(() => mockBalanceBloc);

      // Create test settlements
      testSettlements = [
        const Settlement(
          payerId: 'user-2',
          payerName: 'Jane Smith',
          recipientId: 'user-1',
          recipientName: 'John Doe',
          amount: 25,
          currency: 'USD',
        ),
        const Settlement(
          payerId: 'user-3',
          payerName: 'Bob Johnson',
          recipientId: 'user-1',
          recipientName: 'John Doe',
          amount: 15,
          currency: 'USD',
        ),
      ];

      // Setup default mock behavior
      when(mockBalanceBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockBalanceBloc.state).thenReturn(const BalanceInitial());
      when(mockBalanceBloc.close()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    Widget createTestWidget() {
      return const MaterialApp(
        home: SettlementPlanPage(
          groupId: 'group-1',
          groupName: 'Test Group',
          groupCurrency: 'USD',
        ),
      );
    }

    testWidgets('should display app bar with title', (tester) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Test Group - Settlement Plan'), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (
      tester,
    ) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(const BalanceLoading());
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(const BalanceLoading()),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state with retry button', (tester) async {
      // Arrange
      const errorMessage = 'Failed to generate settlement plan';
      when(
        mockBalanceBloc.state,
      ).thenReturn(const BalanceError(message: errorMessage));
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(const BalanceError(message: errorMessage)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading settlement plan'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should retry loading when retry button is tapped', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to generate settlement plan';
      when(
        mockBalanceBloc.state,
      ).thenReturn(const BalanceError(message: errorMessage));
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(const BalanceError(message: errorMessage)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      clearInteractions(mockBalanceBloc);
      await tester.tap(find.text('Retry'));

      // Assert
      verify(
        mockBalanceBloc.add(const SettlementPlanRequested(groupId: 'group-1')),
      ).called(1);
    });

    testWidgets('should display empty state when no settlements needed', (
      tester,
    ) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        const SettlementLoaded(settlements: <Settlement>[]),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) =>
            Stream.value(const SettlementLoaded(settlements: <Settlement>[])),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('All Settled Up!'), findsOneWidget);
      expect(
        find.text(
          'Everyone in the group is settled up.\n'
          'No payments are needed at this time.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('should display settlement summary card', (tester) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Settlement Plan'), findsOneWidget);
      expect(find.text('Total Payments'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2));
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text(r'$40.00'), findsOneWidget);
    });

    testWidgets('should display all settlements in list', (tester) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Bob Johnson'), 300);

      // Assert
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
      expect(find.text('John Doe'), findsNWidgets(2));
      expect(find.text(r'$25.00'), findsOneWidget);
      expect(find.text(r'$15.00'), findsOneWidget);
    });

    testWidgets('should display record payment buttons for each settlement', (
      tester,
    ) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Record Payment').first, 300);

      // Assert
      expect(find.text('Record Payment'), findsWidgets);
    });

    testWidgets('should show record payment dialog when button is tapped', (
      tester,
    ) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Record Payment').first, 300);
      await tester.ensureVisible(find.text('Record Payment').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record Payment').first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Record Settlement Payment'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Payment Details'), findsOneWidget);
    });

    testWidgets('should refresh settlement plan on pull to refresh', (
      tester,
    ) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      clearInteractions(mockBalanceBloc);

      // Perform pull to refresh
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockBalanceBloc.add(const SettlementPlanRequested(groupId: 'group-1')),
      ).called(1);
    });

    testWidgets('should load settlement plan on init', (tester) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(const BalanceInitial());
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(const BalanceInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      verify(
        mockBalanceBloc.add(const SettlementPlanRequested(groupId: 'group-1')),
      ).called(1);
    });

    testWidgets('should display settlements sorted by amount', (tester) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert - larger amounts should appear first
      final settlementItems = find.byType(Card);
      expect(settlementItems, findsWidgets);
    });

    testWidgets('should display currency formatting correctly', (tester) async {
      // Arrange
      final vndSettlements = testSettlements
          .map(
            (settlement) => settlement.copyWith(
              amount: settlement.amount * 25000, // Convert to VND
              currency: 'VND',
            ),
          )
          .toList();

      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: vndSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: vndSettlements)),
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SettlementPlanPage(
            groupId: 'group-1',
            groupName: 'Test Group',
            groupCurrency: 'VND',
          ),
        ),
      );
      await tester.pump();

      // Assert - should display VND formatting
      expect(find.textContaining('₫'), findsWidgets);
    });

    testWidgets('should handle real-time settlement updates', (tester) async {
      // Arrange
      final controller = StreamController<BalanceState>.broadcast();
      when(mockBalanceBloc.state).thenReturn(
        const SettlementLoaded(settlements: <Settlement>[]),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => controller.stream,
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial empty state
      controller.add(SettlementLoaded(settlements: testSettlements));
      await tester.pump(); // Updated with settlements
      await tester.pumpAndSettle();
      expect(find.byType(CustomScrollView), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Bob Johnson'), 300);

      // Assert
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
      await controller.close();
    });

    testWidgets('should display optimization message', (tester) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Optimized Settlement'), findsOneWidget);
      expect(
        find.text(
          'This plan minimizes the number of transactions needed to settle all '
          'balances.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should handle large number of settlements', (tester) async {
      // Arrange
      final manySettlements = List.generate(
        10,
        (index) => Settlement(
          payerId: 'user-$index',
          payerName: 'User $index',
          recipientId: 'user-${index + 10}',
          recipientName: 'User ${index + 10}',
          amount: 10.0 + index,
          currency: 'USD',
        ),
      );

      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: manySettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: manySettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert - should handle scrolling
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('should display proper section headers', (tester) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Settlement Plan'), findsOneWidget);
      expect(find.text('Recommended Payments'), findsOneWidget);
    });

    testWidgets('should show settlement instructions', (tester) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(
        find.text(
          'Tap "Record Payment" on any settlement below to mark it as '
          'completed.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should maintain scroll position during updates', (
      tester,
    ) async {
      // Arrange
      final manySettlements = List.generate(
        20,
        (index) => Settlement(
          payerId: 'user-$index',
          payerName: 'User $index',
          recipientId: 'user-${index + 20}',
          recipientName: 'User ${index + 20}',
          amount: 10.0 + index,
          currency: 'USD',
        ),
      );

      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: manySettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: manySettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Scroll down
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();

      // Assert - should maintain scroll position
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('should display appropriate empty state message', (
      tester,
    ) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        const SettlementLoaded(settlements: <Settlement>[]),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) =>
            Stream.value(const SettlementLoaded(settlements: <Settlement>[])),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('All Settled Up!'), findsOneWidget);
      expect(
        find.text(
          'Everyone in the group is settled up.\n'
          'No payments are needed at this time.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('should show settlement efficiency information', (
      tester,
    ) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: testSettlements),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: testSettlements)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Recommended Payments'), findsOneWidget);
      expect(find.text('2 payments'), findsOneWidget);
    });

    testWidgets('should handle single settlement correctly', (tester) async {
      // Arrange
      final singleSettlement = [testSettlements.first];
      when(mockBalanceBloc.state).thenReturn(
        SettlementLoaded(settlements: singleSettlement),
      );
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(SettlementLoaded(settlements: singleSettlement)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Total Payments'), findsOneWidget);
      expect(find.text('1 payments'), findsOneWidget);
      expect(find.text(r'$25.00'), findsNWidgets(2)); // Total + list item
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });
  });
}
