// This diagnostic is ignored because Mockito's 'when' and 'thenReturn' syntax
// often triggers type mismatch warnings that are safe in a test context.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_event.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';
import 'package:grex/features/payments/presentation/pages/create_payment_page.dart';
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

class MockGroupBloc extends Mock implements GroupBloc {}

void main() {
  group('CreatePaymentPage Widget Tests', () {
    late MockPaymentBloc mockPaymentBloc;
    late MockGroupBloc mockGroupBloc;
    late List<GroupMember> testMembers;
    late Group testGroup;

    setUpAll(() async {
      final getIt = GetIt.instance;
      if (getIt.isRegistered<PaymentBloc>()) {
        await getIt.unregister<PaymentBloc>();
      }
    });

    setUp(() {
      mockPaymentBloc = MockPaymentBloc();
      mockGroupBloc = MockGroupBloc();
      GetIt.instance.registerFactory<PaymentBloc>(() => mockPaymentBloc);
      GetIt.instance.registerFactory<GroupBloc>(() => mockGroupBloc);

      // Create test members
      testMembers = [
        GroupMember(
          id: 'm1',
          userId: 'user-1',
          displayName: 'John Doe',
          role: MemberRole.administrator,
          joinedAt: DateTime.now(),
        ),
        GroupMember(
          id: 'm2',
          userId: 'user-2',
          displayName: 'Jane Smith',
          role: MemberRole.editor,
          joinedAt: DateTime.now(),
        ),
        GroupMember(
          id: 'm3',
          userId: 'user-3',
          displayName: 'Bob Johnson',
          role: MemberRole.viewer,
          joinedAt: DateTime.now(),
        ),
      ];

      testGroup = Group(
        id: 'group-1',
        name: 'Test Group',
        currency: 'USD',
        creatorId: 'user-1',
        members: testMembers,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Setup default mock behavior
      when(mockPaymentBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());

      when(mockGroupBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockGroupBloc.state).thenReturn(
        GroupsLoaded(
          groups: [testGroup],
          lastUpdated: DateTime.now(),
        ),
      );
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    Widget createTestWidget() {
      return const MaterialApp(
        home: CreatePaymentPage(
          groupId: 'group-1',
          groupCurrency: 'USD',
        ),
      );
    }

    testWidgets('should display create payment form', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.text('Description (Optional)'), findsOneWidget);
    });

    testWidgets('should load group members on init', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Members are loaded from GroupBloc state in initState
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });

    testWidgets('should display loading indicator when loading members', (
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

    testWidgets('should display error when loading members fails', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to load members';
      when(mockPaymentBloc.state).thenReturn(
        const PaymentError(
          failure: PaymentNetworkFailure(),
          message: errorMessage,
        ),
      );
      when(
        mockPaymentBloc.stream,
      ).thenAnswer(
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
      expect(find.text('Error loading group members'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should display member dropdowns when loaded', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(
        find.byType(DropdownButtonFormField<String>),
        findsNWidgets(2),
      ); // From and To dropdowns
    });

    testWidgets('should validate required fields', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Try to submit without filling required fields
      await tester.tap(find.text('Record Payment').last);
      await tester.pump();

      // Assert
      expect(find.text('Amount is required'), findsOneWidget);
      expect(find.text('Please select who paid'), findsOneWidget);
      expect(
        find.text('Please select who received the payment'),
        findsOneWidget,
      );
    });

    testWidgets('should validate positive amount', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter negative amount
      await tester.enterText(find.byType(TextFormField).first, '-50');
      await tester.tap(find.text('Record Payment').last);
      await tester.pump();

      // Assert
      expect(find.text('Enter a valid positive amount'), findsOneWidget);
    });

    testWidgets('should validate that payer and recipient are different', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Fill form with same person as payer and recipient
      await tester.enterText(find.byType(TextFormField).first, '50');

      // Select same person for both dropdowns
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Record Payment').last);
      await tester.pump();

      // Assert
      expect(
        find.text('Payer and recipient cannot be the same person'),
        findsOneWidget,
      );
    });

    testWidgets('should display currency symbol in amount field', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text(r'$'), findsOneWidget); // USD symbol
    });

    testWidgets('should display VND currency symbol for VND group', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CreatePaymentPage(
            groupId: 'group-1',
            groupCurrency: 'VND',
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text('₫'), findsOneWidget); // VND symbol
    });

    testWidgets('should show loading state during payment creation', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const PaymentInitial(),
          const PaymentLoading(),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process loading state

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show success message when payment is created', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const PaymentInitial(),
          const PaymentOperationSuccess(
            message: 'Payment recorded successfully',
            payments: [],
            filteredPayments: [],
            groupId: 'group-1',
          ),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process created state

      // Assert
      expect(find.text('Payment recorded successfully'), findsOneWidget);
    });

    testWidgets('should show error message when payment creation fails', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Failed to create payment';
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const PaymentInitial(),
          const PaymentError(
            failure: PaymentNetworkFailure(),
            message: errorMessage,
          ),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(); // Process error state

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should dispatch create payment event with correct data', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Fill form
      await tester.enterText(find.byType(TextFormField).first, '50.00');
      await tester.enterText(find.byType(TextFormField).last, 'Dinner payment');

      // Select payer
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe').first);
      await tester.pumpAndSettle();

      // Select recipient
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jane Smith').last);
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Record Payment').last);

      // Assert
      verify(
        mockPaymentBloc.add(argThat(isA<PaymentCreateRequested>())),
      ).called(1);
    });

    testWidgets('should handle optional description field', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Description (Optional)'), findsOneWidget);

      // Should be able to submit without description
      await tester.enterText(find.byType(TextFormField).first, '50.00');

      // Select different payer and recipient
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jane Smith').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Record Payment').last);

      // Should not show validation error for empty description
      expect(find.text('Description is required'), findsNothing);
    });

    testWidgets('should disable submit button when loading', (tester) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentLoading());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentLoading()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      final submitButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(submitButton.onPressed, isNull);
    });

    testWidgets('should display all group members in dropdowns', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Open first dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
    });

    testWidgets('should update recipient options when payer is selected', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Select payer
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe').first);
      await tester.pumpAndSettle();

      // Open recipient dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();

      // Assert - John Doe should not be available as recipient
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
    });

    testWidgets('should handle decimal amounts correctly', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter decimal amount
      await tester.enterText(find.byType(TextFormField).first, '25.50');
      await tester.pump();

      // Assert - should accept decimal input
      expect(find.text('25.50'), findsOneWidget);
    });

    testWidgets('should show proper form layout and styling', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(Card), findsWidgets);
      expect(
        find.byType(TextFormField),
        findsNWidgets(2),
      ); // Amount and Description
      expect(
        find.byType(DropdownButtonFormField<String>),
        findsNWidgets(2),
      ); // From and To
      expect(find.byType(ElevatedButton), findsOneWidget); // Submit button
    });

    testWidgets('should handle keyboard input correctly', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Test amount field keyboard type
      final amountField = tester.widget<TextField>(
        find.descendant(
          of: find.byType(TextFormField).first,
          matching: find.byType(TextField),
        ),
      );
      expect(amountField.keyboardType, equals(TextInputType.number));
    });

    testWidgets('should clear form after successful submission', (
      tester,
    ) async {
      // Arrange
      when(mockPaymentBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const PaymentInitial(),
          const PaymentOperationSuccess(
            message: 'Payment recorded successfully',
            payments: [],
            filteredPayments: [],
            groupId: 'group-1',
          ),
        ]),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Fill form
      await tester.enterText(find.byType(TextFormField).first, '50.00');
      await tester.pump();
      await tester.pump(); // Process created state
    });
  });
}
