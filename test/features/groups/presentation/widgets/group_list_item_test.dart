import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/presentation/widgets/group_list_item.dart';

void main() {
  group('GroupListItem Widget Tests', () {
    late Group testGroup;
    late bool onTapCalled;

    setUp(() {
      onTapCalled = false;
      testGroup = Group(
        id: 'test-group-1',
        name: 'Test Group',
        currency: 'VND',
        creatorId: 'user-1',
        members: [
          GroupMember(
            id: 'member-1',
            userId: 'user-1',
            displayName: 'User One',
            role: MemberRole.administrator,
            joinedAt: DateTime.now(),
          ),
          GroupMember(
            id: 'member-2',
            userId: 'user-2',
            displayName: 'User Two',
            role: MemberRole.editor,
            joinedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display group information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: testGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      // Check group name
      expect(find.text('Test Group'), findsOneWidget);

      // Check member count
      expect(find.text('2 thành viên'), findsOneWidget);

      // Check currency symbol
      expect(find.text('₫'), findsOneWidget);

      // Check icons
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should display group initials correctly for single word', (
      tester,
    ) async {
      final singleWordGroup = testGroup.copyWith(name: 'Family');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: singleWordGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('should display group initials correctly for multiple words', (
      tester,
    ) async {
      final multiWordGroup = testGroup.copyWith(name: 'Family Trip');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: multiWordGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('FT'), findsOneWidget);
    });

    testWidgets('should handle empty group name', (tester) async {
      final emptyNameGroup = testGroup.copyWith(name: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: emptyNameGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('G'), findsOneWidget);
    });

    testWidgets('should display correct member count for single member', (
      tester,
    ) async {
      final singleMemberGroup = testGroup.copyWith(
        members: [testGroup.members.first],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: singleMemberGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('1 thành viên'), findsOneWidget);
    });

    testWidgets('should display different currency symbols correctly', (
      tester,
    ) async {
      final usdGroup = testGroup.copyWith(currency: 'USD');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: usdGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      expect(find.text(r'$'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: testGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(onTapCalled, isTrue);
    });

    testWidgets('should have proper card elevation and styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: testGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(2));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, equals(BorderRadius.circular(12)));
    });

    testWidgets('should truncate long group names', (tester) async {
      final longNameGroup = testGroup.copyWith(
        name: 'This is a very long group name that should be truncated',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Constrain width to force truncation
              child: GroupListItem(
                group: longNameGroup,
                onTap: () => onTapCalled = true,
              ),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(
        find.text('This is a very long group name that should be truncated'),
      );
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('should display CircleAvatar with correct properties', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: testGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, equals(24));
    });

    testWidgets('should handle groups with no members', (tester) async {
      final noMembersGroup = testGroup.copyWith(members: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupListItem(
              group: noMembersGroup,
              onTap: () => onTapCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('0 thành viên'), findsOneWidget);
    });
  });
}
