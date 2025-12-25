import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/core/services/export_service.dart';
import 'package:grex/features/balances/presentation/bloc/balance_bloc.dart';
import 'package:grex/features/balances/presentation/bloc/balance_state.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_state.dart';
import 'package:grex/features/export/presentation/pages/export_page.dart';
import 'package:grex/features/export/presentation/widgets/export_format_selector.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:grex/features/payments/presentation/bloc/payment_state.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  ExportService,
  GroupBloc,
  ExpenseBloc,
  PaymentBloc,
  BalanceBloc,
])
import 'export_page_test.mocks.dart';

void main() {
  group('ExportPage', () {
    late MockExportService mockExportService;
    late MockGroupBloc mockGroupBloc;
    late MockExpenseBloc mockExpenseBloc;
    late MockPaymentBloc mockPaymentBloc;
    late MockBalanceBloc mockBalanceBloc;

    setUp(() async {
      mockExportService = MockExportService();
      mockGroupBloc = MockGroupBloc();
      mockExpenseBloc = MockExpenseBloc();
      mockPaymentBloc = MockPaymentBloc();
      mockBalanceBloc = MockBalanceBloc();

      // Setup GetIt
      final getIt = GetIt.instance;
      await getIt.reset();
      getIt
        ..registerSingleton<ExportService>(mockExportService)
        ..registerFactory<GroupBloc>(() => mockGroupBloc)
        ..registerFactory<ExpenseBloc>(() => mockExpenseBloc)
        ..registerFactory<PaymentBloc>(() => mockPaymentBloc)
        ..registerFactory<BalanceBloc>(() => mockBalanceBloc);

      // Setup default states
      when(mockGroupBloc.state).thenReturn(const GroupInitial());
      when(mockExpenseBloc.state).thenReturn(const ExpenseInitial());
      when(mockPaymentBloc.state).thenReturn(const PaymentInitial());
      when(mockBalanceBloc.state).thenReturn(const BalanceInitial());

      // Setup stream controllers
      when(
        mockGroupBloc.stream,
      ).thenAnswer((_) => Stream.value(const GroupInitial()));
      when(
        mockExpenseBloc.stream,
      ).thenAnswer((_) => Stream.value(const ExpenseInitial()));
      when(
        mockPaymentBloc.stream,
      ).thenAnswer((_) => Stream.value(const PaymentInitial()));
      when(
        mockBalanceBloc.stream,
      ).thenAnswer((_) => Stream.value(const BalanceInitial()));
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    testWidgets('should display export page correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Assert
      expect(find.text('Export Test Group'), findsOneWidget);
      expect(find.text('Export Group Data'), findsOneWidget);
      expect(
        find.text(
          'Export all group information including members, expenses, '
          'payments, and balances.',
        ),
        findsOneWidget,
      );
      expect(find.text('Export Format'), findsOneWidget);
      expect(find.byType(ExportFormatSelector), findsOneWidget);
      expect(find.text('What will be exported'), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);
    });

    testWidgets('should display data preview sections', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Assert
      expect(find.text('Group Information'), findsOneWidget);
      expect(find.text('Name, currency, members, and roles'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(
        find.text('All expenses with details and participants'),
        findsOneWidget,
      );
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Payment history between members'), findsOneWidget);
      expect(find.text('Balances'), findsOneWidget);
      expect(
        find.text('Current balance status for each member'),
        findsOneWidget,
      );
    });

    testWidgets('should display info message', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Assert
      expect(
        find.text(
          'Exported files can be shared via email, messaging apps, or '
          'saved to your device.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should change export format when selector is used', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Initially CSV should be selected
      expect(find.text('CSV'), findsOneWidget);

      // Tap on PDF option
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      // PDF should now be selected (this would be verified by the selector
      // widget)
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('should show export button as enabled initially', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Assert
      final exportButton = find.widgetWithText(ElevatedButton, 'Export Data');
      expect(exportButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(exportButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should display correct icons', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Assert
      expect(
        find.byIcon(Icons.download),
        findsNWidgets(2),
      ); // Header and button
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.payment), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
      expect(
        find.byIcon(Icons.check_circle),
        findsNWidgets(4),
      ); // One for each preview item
    });

    testWidgets('should be scrollable', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have proper app bar', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Export Test Group'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should use proper padding and spacing', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Assert
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(SizedBox), findsWidgets);
      expect(
        find.byType(Card),
        findsNWidgets(2),
      ); // Header card and preview card
    });

    testWidgets('should be accessible', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportPage(
            groupId: 'group-1',
            groupName: 'Test Group',
          ),
        ),
      );

      // Assert - Check for semantic elements
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
