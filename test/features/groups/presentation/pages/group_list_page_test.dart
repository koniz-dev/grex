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
import 'package:grex/features/groups/presentation/pages/group_list_page.dart';
import 'package:mockito/mockito.dart';

// Mock GroupBloc
class MockGroupBloc extends Mock implements GroupBloc {
  @override
  void add(GroupEvent? event) =>
      super.noSuchMethod(Invocation.method(#add, [event]));
}

void main() {
  group('GroupListPage Widget Tests', () {
    late MockGroupBloc mockGroupBloc;

    setUp(() {
      mockGroupBloc = MockGroupBloc();
    });

    testWidgets('should display loading indicator when state is loading', (
      tester,
    ) async {
      // Arrange
      when(mockGroupBloc.state).thenReturn(const GroupLoading());
      when(
        mockGroupBloc.stream,
      ).thenAnswer((_) => Stream.value(const GroupLoading()));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GroupBloc>.value(
            value: mockGroupBloc,
            child: const GroupListView(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no groups exist', (
      tester,
    ) async {
      // Arrange
      final emptyState = GroupsLoaded(
        groups: const [],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(emptyState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(emptyState));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GroupBloc>.value(
            value: mockGroupBloc,
            child: const GroupListView(),
          ),
        ),
      );

      // Assert
      expect(find.text('Chưa có nhóm nào'), findsOneWidget);
      expect(
        find.text(
          'Tạo nhóm đầu tiên để bắt đầu chia sẻ chi phí với bạn bè và gia đình',
        ),
        findsOneWidget,
      );
      expect(find.text('Tạo nhóm mới'), findsOneWidget);
    });

    testWidgets('should display groups when groups exist', (tester) async {
      // Arrange
      final testGroups = [
        Group(
          id: 'group-1',
          name: 'Test Group 1',
          currency: 'VND',
          creatorId: 'user-1',
          members: [
            GroupMember(
              id: 'member-1',
              userId: 'user-1',
              displayName: 'User 1',
              role: MemberRole.administrator,
              joinedAt: DateTime.now(),
            ),
            GroupMember(
              id: 'member-2',
              userId: 'user-2',
              displayName: 'User 2',
              role: MemberRole.editor,
              joinedAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final loadedState = GroupsLoaded(
        groups: testGroups,
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GroupBloc>.value(
            value: mockGroupBloc,
            child: const GroupListView(),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Group 1'), findsOneWidget);
      expect(find.text('2 thành viên'), findsOneWidget);
      expect(find.text('₫'), findsOneWidget);
    });

    testWidgets('should display error message when error occurs', (
      tester,
    ) async {
      // Arrange
      const errorState = GroupError(
        failure: GroupNetworkFailure('Network error'),
        message: 'Failed to load groups',
      );
      when(mockGroupBloc.state).thenReturn(errorState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(errorState));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GroupBloc>.value(
            value: mockGroupBloc,
            child: const GroupListView(),
          ),
        ),
      );

      // Assert
      expect(find.text('Có lỗi xảy ra'), findsOneWidget);
      expect(find.text('Failed to load groups'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('should show floating action button', (tester) async {
      // Arrange
      when(mockGroupBloc.state).thenReturn(const GroupInitial());
      when(
        mockGroupBloc.stream,
      ).thenAnswer((_) => Stream.value(const GroupInitial()));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GroupBloc>.value(
            value: mockGroupBloc,
            child: const GroupListView(),
          ),
        ),
      );

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should trigger refresh when pull to refresh', (tester) async {
      // Arrange
      final loadedState = GroupsLoaded(
        groups: const [],
        lastUpdated: DateTime.now(),
      );
      when(mockGroupBloc.state).thenReturn(loadedState);
      when(mockGroupBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GroupBloc>.value(
            value: mockGroupBloc,
            child: const GroupListView(),
          ),
        ),
      );

      // Trigger pull to refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();

      // Assert
      verify(mockGroupBloc.add(const GroupsLoadRequested())).called(1);
    });
  });
}
