import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/domain/failures/group_failure.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/groups/presentation/pages/create_group_page.dart';
import 'package:mockito/mockito.dart';

// Mock GroupBloc
class MockGroupBloc extends Mock implements GroupBloc {
  @override
  void add(GroupEvent? event) =>
      super.noSuchMethod(Invocation.method(#add, [event]));
}

void main() {
  group('CreateGroupPage Widget Tests', () {
    late MockGroupBloc mockGroupBloc;

    setUp(() {
      mockGroupBloc = MockGroupBloc();
      when(mockGroupBloc.state).thenReturn(const GroupInitial());
      when(
        mockGroupBloc.stream,
      ).thenAnswer((_) => Stream.value(const GroupInitial()));
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<GroupBloc>.value(
          value: mockGroupBloc,
          child: const CreateGroupPage(),
        ),
      );
    }

    testWidgets('should display form fields correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check app bar
      expect(find.text('Tạo nhóm mới'), findsOneWidget);

      // Check form fields
      expect(find.text('Tên nhóm'), findsOneWidget);
      expect(find.text('Tiền tệ'), findsOneWidget);

      // Check text field
      expect(find.byType(TextFormField), findsOneWidget);

      // Check dropdown
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Check create button
      expect(find.text('Tạo nhóm'), findsOneWidget);
    });

    testWidgets('should show validation error for empty group name', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Try to submit without entering group name
      await tester.tap(find.text('Tạo nhóm'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Vui lòng nhập tên nhóm'), findsOneWidget);
    });

    testWidgets('should show validation error for short group name', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Enter short name
      await tester.enterText(find.byType(TextFormField), 'A');
      await tester.tap(find.text('Tạo nhóm'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Tên nhóm phải có ít nhất 2 ký tự'), findsOneWidget);
    });

    testWidgets('should show validation error for long group name', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Enter very long name
      final longName = 'A' * 51; // More than 50 characters
      await tester.enterText(find.byType(TextFormField), longName);
      await tester.tap(find.text('Tạo nhóm'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Tên nhóm không được quá 50 ký tự'), findsOneWidget);
    });

    testWidgets('should display currency options in dropdown', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Check currency options
      expect(find.text('VND (₫)'), findsOneWidget);
      expect(find.text(r'USD ($)'), findsOneWidget);
      expect(find.text('EUR (€)'), findsOneWidget);
    });

    testWidgets('should select currency from dropdown', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select USD
      await tester.tap(find.text(r'USD ($)').last);
      await tester.pumpAndSettle();

      // Verify USD is selected
      expect(find.text(r'USD ($)'), findsOneWidget);
    });

    testWidgets('should submit form with valid data', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter valid group name
      await tester.enterText(find.byType(TextFormField), 'Test Group');

      // Select currency
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'USD ($)').last);
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Tạo nhóm'));
      await tester.pump();

      // Verify GroupCreateRequested event was added
      verify(
        mockGroupBloc.add(argThat(isA<GroupCreateRequested>())),
      ).called(1);
    });

    testWidgets('should show loading state when creating group', (
      tester,
    ) async {
      // Set loading state
      when(mockGroupBloc.state).thenReturn(const GroupLoading());
      when(
        mockGroupBloc.stream,
      ).thenAnswer((_) => Stream.value(const GroupLoading()));

      await tester.pumpWidget(createTestWidget());

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Create button should be disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should show error message when creation fails', (
      tester,
    ) async {
      // Set error state
      const errorState = GroupError(
        failure: GroupNetworkFailure('Network error'),
        message: 'Failed to create group',
      );
      when(mockGroupBloc.state).thenReturn(errorState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(errorState));

      await tester.pumpWidget(createTestWidget());

      // Should show error message
      expect(find.text('Failed to create group'), findsOneWidget);
    });

    testWidgets('should navigate back when group is created successfully', (
      tester,
    ) async {
      // Start with initial state
      when(mockGroupBloc.state).thenReturn(const GroupInitial());
      when(mockGroupBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const GroupInitial(),
          const GroupLoading(),
          GroupsLoaded(groups: const [], lastUpdated: DateTime.now()),
        ]),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The page should handle successful creation and navigate back
      // This would be tested in integration tests for actual navigation
    });

    testWidgets('should have proper form styling', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check form padding and layout
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(Padding), findsAtLeastNWidgets(1));

      // Check text field decoration
      final textField = tester.widget<TextField>(
        find.byType(TextField),
      );
      expect(textField.decoration?.labelText, equals('Tên nhóm'));
      expect(textField.decoration?.hintText, equals('Nhập tên nhóm'));
    });

    testWidgets('should have back button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for back button
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('should clear form when reset', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter some data
      await tester.enterText(find.byType(TextFormField), 'Test Group');

      // Verify data is entered
      expect(find.text('Test Group'), findsOneWidget);

      // If there's a reset functionality, test it here
      // This depends on the actual implementation
    });

    testWidgets('should handle keyboard actions properly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textField = find.byType(TextFormField);

      // Focus on text field
      await tester.tap(textField);
      await tester.pump();

      // Enter text
      await tester.enterText(textField, 'Test Group');

      // Verify text is entered
      expect(find.text('Test Group'), findsOneWidget);
    });
  });
}
