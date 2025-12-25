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
import 'package:grex/features/groups/presentation/pages/group_settings_page.dart';
import 'package:mockito/mockito.dart';

// Mock GroupBloc
class MockGroupBloc extends Mock implements GroupBloc {
  @override
  void add(GroupEvent? event) =>
      super.noSuchMethod(Invocation.method(#add, [event]));
}

void main() {
  group('GroupSettingsPage Widget Tests', () {
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
          child: GroupSettingsPage(groupId: testGroup.id),
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

    testWidgets('should display group settings form when loaded', (
      tester,
    ) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Check app bar
      expect(find.text('Cài đặt nhóm'), findsOneWidget);

      // Check form sections
      expect(find.text('Thông tin cơ bản'), findsOneWidget);
      expect(find.text('Quản lý thành viên'), findsOneWidget);

      // Check form fields
      expect(find.text('Tên nhóm'), findsOneWidget);
      expect(find.text('Tiền tệ'), findsOneWidget);
    });

    testWidgets('should pre-populate form with current group data', (
      tester,
    ) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Check that form is pre-populated
      expect(find.text('Test Group'), findsOneWidget);
      expect(find.text('VND (₫)'), findsOneWidget);
    });

    testWidgets('should display member list with roles', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Check member list
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('Editor User'), findsOneWidget);
      expect(find.text('Viewer User'), findsOneWidget);

      // Check role displays
      expect(find.text('Quản trị viên'), findsOneWidget);
      expect(find.text('Biên tập viên'), findsOneWidget);
      expect(find.text('Người xem'), findsOneWidget);
    });

    testWidgets('should show invite member button', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Mời thành viên'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('should validate group name input', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Clear the group name
      await tester.enterText(find.byType(TextFormField), '');

      // Try to save
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Vui lòng nhập tên nhóm'), findsOneWidget);
    });

    testWidgets('should enable save button when changes are made', (
      tester,
    ) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Initially save button should be disabled
      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
      );
      expect(saveButton.onPressed, isNull);

      // Make a change
      await tester.enterText(find.byType(TextFormField), 'Updated Group Name');
      await tester.pump();

      // Save button should now be enabled
      final updatedSaveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
      );
      expect(updatedSaveButton.onPressed, isNotNull);
    });

    testWidgets('should show member management options for administrators', (
      tester,
    ) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Should show member management options
      expect(find.byIcon(Icons.more_vert), findsAtLeastNWidgets(1));
    });

    testWidgets('should show role change options in member menu', (
      tester,
    ) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Tap on member menu
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Should show role change options
      expect(find.text('Thay đổi vai trò'), findsOneWidget);
      expect(find.text('Xóa khỏi nhóm'), findsOneWidget);
    });

    testWidgets(
      'should show invite member dialog when invite button is tapped',
      (tester) async {
        final loadedState = GroupsLoaded(
          groups: [testGroup],
          lastUpdated: DateTime.now(),
        );
        when(mockGroupBloc.state).thenReturn(loadedState);
        when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

        await tester.pumpWidget(createTestWidget());

        // Tap invite member button
        await tester.tap(find.text('Mời thành viên'));
        await tester.pumpAndSettle();

        // Should show invite dialog
        expect(find.text('Mời thành viên mới'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Vai trò'), findsOneWidget);
      },
    );

    testWidgets('should show role selection dialog when changing member role', (
      tester,
    ) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Tap on member menu
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Tap change role
      await tester.tap(find.text('Thay đổi vai trò'));
      await tester.pumpAndSettle();

      // Should show role selection dialog
      expect(find.text('Chọn vai trò mới'), findsOneWidget);
      expect(find.text('Quản trị viên'), findsAtLeastNWidgets(1));
      expect(find.text('Biên tập viên'), findsAtLeastNWidgets(1));
      expect(find.text('Người xem'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show confirmation dialog when removing member', (
      tester,
    ) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Tap on member menu
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Tap remove member
      await tester.tap(find.text('Xóa khỏi nhóm'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Xác nhận xóa thành viên'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('should show leave group option for non-creators', (
      tester,
    ) async {
      // Create group where current user is not the creator
      final nonCreatorGroup = testGroup.copyWith(creatorId: 'other-user');

      final loadedState = GroupsLoaded(
        groups: [nonCreatorGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Should show leave group option
      expect(find.text('Rời khỏi nhóm'), findsOneWidget);
    });

    testWidgets('should show delete group option for creators', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Should show delete group option for creator
      expect(find.text('Xóa nhóm'), findsOneWidget);
    });

    testWidgets('should show error message when update fails', (tester) async {
      const errorState = GroupError(
        failure: GroupNetworkFailure('Network error'),
        message: 'Failed to update group',
      );
      when(mockGroupBloc.state).thenReturn(errorState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(errorState));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Failed to update group'), findsOneWidget);
    });

    testWidgets('should handle currency change', (tester) async {
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget());

      // Tap currency dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select different currency
      await tester.tap(find.text(r'USD ($)').last);
      await tester.pumpAndSettle();

      // Save button should be enabled
      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
      );
      expect(saveButton.onPressed, isNotNull);
    });
  });
}
