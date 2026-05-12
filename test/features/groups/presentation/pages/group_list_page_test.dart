import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/domain/failures/group_failure.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/groups/presentation/pages/group_list_page.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _FakeGroupEvent extends Fake implements GroupEvent {}

/// Wraps the widget under test in a MaterialApp with Vietnamese localizations,
/// matching what the empty-groups widget (and other group widgets) expect via
/// `context.l10n`.
Widget _wrap(Widget child, GroupBloc bloc) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<GroupBloc>.value(value: bloc, child: child),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeGroupEvent());
  });

  group('GroupListPage Widget Tests', () {
    late MockGroupBloc mockGroupBloc;

    setUp(() {
      mockGroupBloc = MockGroupBloc();
    });

    testWidgets('should display loading indicator when state is loading', (
      tester,
    ) async {
      whenListen(
        mockGroupBloc,
        Stream<GroupState>.value(const GroupLoading()),
        initialState: const GroupLoading(),
      );

      await tester.pumpWidget(_wrap(const GroupListView(), mockGroupBloc));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no groups exist', (
      tester,
    ) async {
      final emptyState = GroupsLoaded(
        groups: const [],
        lastUpdated: DateTime.now(),
      );
      whenListen(
        mockGroupBloc,
        Stream<GroupState>.value(emptyState),
        initialState: emptyState,
      );

      await tester.pumpWidget(_wrap(const GroupListView(), mockGroupBloc));

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
      whenListen(
        mockGroupBloc,
        Stream<GroupState>.value(loadedState),
        initialState: loadedState,
      );

      await tester.pumpWidget(_wrap(const GroupListView(), mockGroupBloc));

      expect(find.text('Test Group 1'), findsOneWidget);
      expect(find.text('2 thành viên'), findsOneWidget);
      expect(find.text('₫'), findsOneWidget);
    });

    testWidgets('should display error message when error occurs', (
      tester,
    ) async {
      const errorState = GroupError(
        failure: GroupNetworkFailure('Network error'),
        message: 'Failed to load groups',
      );
      whenListen(
        mockGroupBloc,
        Stream<GroupState>.value(errorState),
        initialState: errorState,
      );

      await tester.pumpWidget(_wrap(const GroupListView(), mockGroupBloc));

      expect(find.text('Có lỗi xảy ra'), findsOneWidget);
      // The page renders state.failure.toString() in the error body, not
      // state.message — so assert against what GroupNetworkFailure produces.
      expect(find.textContaining('Network error'), findsWidgets);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('should show floating action button', (tester) async {
      whenListen(
        mockGroupBloc,
        Stream<GroupState>.value(const GroupInitial()),
        initialState: const GroupInitial(),
      );

      await tester.pumpWidget(_wrap(const GroupListView(), mockGroupBloc));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should trigger refresh when pull to refresh', (tester) async {
      // Use a non-empty list so the body is a scrollable ListView — pull-to-
      // refresh on the empty-state widget doesn't trigger the RefreshIndicator
      // because EmptyGroupsWidget isn't scrollable.
      final testGroup = Group(
        id: 'group-1',
        name: 'Test Group',
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
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final loadedState = GroupsLoaded(
        groups: [testGroup],
        lastUpdated: DateTime.now(),
      );
      whenListen(
        mockGroupBloc,
        Stream<GroupState>.value(loadedState),
        initialState: loadedState,
      );

      await tester.pumpWidget(_wrap(const GroupListView(), mockGroupBloc));

      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      // pumpAndSettle so the RefreshIndicator's onRefresh callback actually
      // fires before we verify the dispatched event.
      await tester.pumpAndSettle();

      verify(
        () => mockGroupBloc.add(const GroupsLoadRequested()),
      ).called(1);
    });
  });
}
