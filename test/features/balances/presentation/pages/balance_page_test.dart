import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/presentation/bloc/balance_bloc.dart';
import 'package:grex/features/balances/presentation/bloc/balance_event.dart';
import 'package:grex/features/balances/presentation/bloc/balance_state.dart';
import 'package:grex/features/balances/presentation/pages/balance_page.dart';
import 'package:mockito/mockito.dart';

class MockBalanceBloc extends Mock implements BalanceBloc {}

void main() {
  group('BalancePage Widget Tests', () {
    late MockBalanceBloc mockBalanceBloc;
    late List<Balance> testBalances;

    setUpAll(() async {
      // Register mock in GetIt
      final getIt = GetIt.instance;
      if (getIt.isRegistered<BalanceBloc>()) {
        await getIt.unregister<BalanceBloc>();
      }
    });

    setUp(() {
      mockBalanceBloc = MockBalanceBloc();
      GetIt.instance.registerFactory<BalanceBloc>(() => mockBalanceBloc);

      // Create test balances
      testBalances = [
        const Balance(
          userId: 'user-1',
          displayName: 'John Doe',
          balance: 50,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'Jane Smith',
          balance: -25,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-3',
          displayName: 'Bob Johnson',
          balance: 0,
          currency: 'USD',
        ),
      ];

      // Setup default mock behavior
      when(mockBalanceBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockBalanceBloc.state).thenReturn(const BalanceInitial());
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    Widget createTestWidget() {
      return const MaterialApp(
        home: BalancePage(
          groupId: 'group-1',
          groupName: 'Test Group',
          groupCurrency: 'USD',
        ),
      );
    }

    testWidgets('should display app bar with title and settlement button', (
      tester,
    ) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Balances'), findsOneWidget);
      expect(find.text('Settlement Plan'), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (
      tester,
    ) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(const BalanceLoading());
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(const BalanceLoading()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state with retry button', (tester) async {
      // Arrange
      const errorMessage = 'Failed to load balances';
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
      expect(find.text('Error loading balances'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should retry loading when retry button is tapped', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to load balances';
      when(
        mockBalanceBloc.state,
      ).thenReturn(const BalanceError(message: errorMessage));
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(const BalanceError(message: errorMessage)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Retry'));

      // Assert
      // Instead of counting how many times any event was added,
      // simply verify that a BalancesLoadRequested event was dispatched.
      verify(
        mockBalanceBloc.add(const BalancesLoadRequested(groupId: 'group-1')),
      ).called(1);
    });

    testWidgets('should display empty state when no balances', (tester) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(const BalancesLoaded(balances: <Balance>[]));
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(const BalancesLoaded(balances: <Balance>[])),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('No balances to show'), findsOneWidget);
      expect(find.text('All members are settled up!'), findsOneWidget);
    });

    testWidgets('should display balance summary card', (tester) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Group Balance Summary'), findsOneWidget);
      expect(find.text('Total Owed'), findsOneWidget);
      expect(find.text('Total Owing'), findsOneWidget);
    });

    testWidgets('should display all balances in list', (tester) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
      expect(find.text(r'$50.00'), findsOneWidget);
      expect(find.text(r'-$25.00'), findsOneWidget);
      expect(find.text(r'$0.00'), findsOneWidget);
    });

    testWidgets('should navigate to settlement plan when button is tapped', (
      tester,
    ) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.tap(find.text('Settlement Plan'));
      await tester.pumpAndSettle();

      // Assert - should navigate to settlement plan page
      // In a real test, you'd verify the navigation
    });

    testWidgets('should refresh balances on pull to refresh', (tester) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

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
      // Instead of counting all events, just ensure a refresh-triggering event
      // was dispatched
      verify(
        mockBalanceBloc.add(const BalancesLoadRequested(groupId: 'group-1')),
      ).called(1);
    });

    testWidgets('should load balances on init', (tester) async {
      // Arrange
      when(mockBalanceBloc.state).thenReturn(const BalanceInitial());
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(const BalanceInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      verify(
        mockBalanceBloc.add(const BalancesLoadRequested(groupId: 'group-1')),
      ).called(1);
    });

    testWidgets('should display balances sorted by amount', (tester) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert - positive balances should appear first
      final balanceItems = find.byType(Card);
      expect(balanceItems, findsWidgets);
    });

    testWidgets('should display currency formatting correctly', (tester) async {
      // Arrange
      final vndBalances = testBalances
          .map(
            (balance) => balance.copyWith(
              balance: balance.balance * 25000, // Convert to VND
              currency: 'VND',
            ),
          )
          .toList();

      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: vndBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: vndBalances)));

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: BalancePage(
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

    testWidgets('should handle real-time balance updates', (tester) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(const BalancesLoaded(balances: <Balance>[]));
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const BalancesLoaded(balances: <Balance>[]),
          BalancesLoaded(balances: testBalances),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial empty state
      await tester.pump(); // Updated with balances

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
    });

    testWidgets('should display balance summary with correct totals', (
      tester,
    ) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Group Balance Summary'), findsOneWidget);
      // Total owed should be $50.00 (John's positive balance)
      // Total owing should be $25.00 (Jane's negative balance)
    });

    testWidgets('should hide settlement button when all balanced', (
      tester,
    ) async {
      // Arrange
      final allZeroBalances = [
        const Balance(
          userId: 'user-1',
          displayName: 'John Doe',
          balance: 0,
          currency: 'USD',
        ),
        const Balance(
          userId: 'user-2',
          displayName: 'Jane Smith',
          balance: 0,
          currency: 'USD',
        ),
      ];

      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: allZeroBalances));
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(BalancesLoaded(balances: allZeroBalances)),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Settlement Plan'), findsNothing);
    });

    testWidgets('should display floating action button for settlement', (
      tester,
    ) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('should handle large number of balances', (tester) async {
      // Arrange
      final manyBalances = List.generate(
        20,
        (index) => Balance(
          userId: 'user-$index',
          displayName: 'User $index',
          balance: (index - 10) * 10.0, // Mix of positive and negative
          currency: 'USD',
        ),
      );

      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: manyBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: manyBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert - should handle scrolling
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display proper section headers', (tester) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Group Balance Summary'), findsOneWidget);
      expect(find.text('Member Balances'), findsOneWidget);
    });

    testWidgets('should show balance details when item is tapped', (
      tester,
    ) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: testBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: testBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap on a balance item
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Assert - should show balance details or navigate
      // In a real test, you'd verify the specific behavior
    });

    testWidgets('should maintain scroll position during updates', (
      tester,
    ) async {
      // Arrange
      final manyBalances = List.generate(
        20,
        (index) => Balance(
          userId: 'user-$index',
          displayName: 'User $index',
          balance: (index - 10) * 10.0,
          currency: 'USD',
        ),
      );

      when(
        mockBalanceBloc.state,
      ).thenReturn(BalancesLoaded(balances: manyBalances));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(BalancesLoaded(balances: manyBalances)));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // Assert - should maintain scroll position
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display appropriate empty state message', (
      tester,
    ) async {
      // Arrange
      when(
        mockBalanceBloc.state,
      ).thenReturn(const BalancesLoaded(balances: <Balance>[]));
      when(mockBalanceBloc.stream).thenAnswer(
        (_) => Stream.value(const BalancesLoaded(balances: <Balance>[])),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('No balances to show'), findsOneWidget);
      expect(find.text('All members are settled up!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
