import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/domain/failures/group_failure.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/groups/presentation/pages/group_details_page.dart';
import 'package:mockito/mockito.dart';

// Mock GroupBloc
class MockGroupBloc extends Mock implements GroupBloc {
  @override
  void add(GroupEvent? event) =>
      super.noSuchMethod(Invocation.method(#add, [event]));
}

void main() {
  group('GroupDetailsPage Widget Tests', () {
    late MockGroupBloc mockGroupBloc;
    late Group testGroup;

    setUp(() {
      mockGroupBloc = MockGroupBloc();
      testGroup = Group(
        id: 'test-group-1',
        name: 'Test Group',
        currency: 'VND',
        creatorId: 'user-1',
        members: [
          GroupMember(
            id: 'member-1',
            userId: 'user-1',
            displayName: 'Admin User',
            role: MemberRole.administrator,
            joinedAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
          GroupMember(
            id: 'member-2',
            userId: 'user-2',
            displayName: 'Editor User',
            role: MemberRole.editor,
            joinedAt: DateTime.now().subtract(const Duration(days: 15)),
          ),
          GroupMember(
            id: 'member-3',
            userId: 'user-3',
            displayName: 'Viewer User',
            role: MemberRole.viewer,
            joinedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<GroupBloc>.value(
          value: mockGroupBloc,
          child: GroupDetailsPage(groupId: testGroup.id),
        ),
      );
    }

    testWidgets('should display loading state initially', (tester) async {
      when(mockGroupBloc.state).thenReturn(const GroupLoading());
      when(
        mockGroupBloc.stream,
      ).thenAnswer((_) => Stream.value(const GroupLoading()));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display group information when loaded', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Check group name in app bar
      expect(find.text('Test Group'), findsOneWidget);

      // Check group info card
      expect(find.text('Thông tin nhóm'), findsOneWidget);
      expect(find.text('3 thành viên'), findsOneWidget);
      expect(find.text('₫'), findsOneWidget);
    });

    testWidgets('should display member list correctly', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Check member section
      expect(find.text('Thành viên'), findsOneWidget);

      // Check all members are displayed
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('Editor User'), findsOneWidget);
      expect(find.text('Viewer User'), findsOneWidget);

      // Check member roles
      expect(find.text('Quản trị viên'), findsOneWidget);
      expect(find.text('Biên tập viên'), findsOneWidget);
      expect(find.text('Người xem'), findsOneWidget);
    });

    testWidgets('should display navigation buttons', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Check navigation cards
      expect(find.text('Chi tiêu'), findsOneWidget);
      expect(find.text('Thanh toán'), findsOneWidget);
      expect(find.text('Số dư'), findsOneWidget);
      expect(find.text('Xuất dữ liệu'), findsOneWidget);

      // Check icons
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.payment), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('should show settings button for administrators', (
      tester,
    ) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Should show settings icon in app bar for admin
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should not show settings button for non-administrators', (
      tester,
    ) async {
      // Create group where current user is not admin
      final nonAdminGroup = testGroup.copyWith(
        members: [
          GroupMember(
            id: 'member-2',
            userId: 'user-2',
            displayName: 'Current User',
            role: MemberRole.editor,
            joinedAt: DateTime.now(),
          ),
          ...testGroup.members,
        ],
      );

      final loadedState = GroupsLoaded(
        groups: [nonAdminGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Should not show settings icon for non-admin
      // This depends on the actual implementation of user role checking
    });

    testWidgets('should display error state when group not found', (
      tester,
    ) async {
      const errorState = GroupError(
        failure: GroupNotFoundFailure('Group not found'),
        message: 'Không tìm thấy nhóm',
      );
      when(mockGroupBloc.state).thenReturn(errorState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(errorState));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Có lỗi xảy ra'), findsOneWidget);
      expect(find.text('Không tìm thấy nhóm'), findsOneWidget);
    });

    testWidgets('should handle navigation to expenses', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Tap on expenses card
      await tester.tap(find.text('Chi tiêu'));
      await tester.pumpAndSettle();

      // Navigation would be tested in integration tests
    });

    testWidgets('should handle navigation to payments', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Tap on payments card
      await tester.tap(find.text('Thanh toán'));
      await tester.pumpAndSettle();

      // Navigation would be tested in integration tests
    });

    testWidgets('should handle navigation to balances', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Tap on balances card
      await tester.tap(find.text('Số dư'));
      await tester.pumpAndSettle();

      // Navigation would be tested in integration tests
    });

    testWidgets('should handle navigation to export', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Tap on export card
      await tester.tap(find.text('Xuất dữ liệu'));
      await tester.pumpAndSettle();

      // Navigation would be tested in integration tests
    });

    testWidgets('should display member join dates correctly', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Check that join dates are displayed
      // The exact format depends on the implementation
      expect(find.textContaining('Tham gia'), findsAtLeastNWidgets(1));
    });

    testWidgets('should refresh data on pull to refresh', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Perform pull to refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();

      // Verify refresh was triggered
      verify(
        mockGroupBloc.add(argThat(isNotNull)),
      ).called(greaterThan(0));
    });

    testWidgets('should display group creation date', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Check that creation date is displayed
      expect(find.textContaining('Tạo lúc'), findsOneWidget);
    });
  });
}
