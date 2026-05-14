import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/presentation/widgets/group_list_item.dart';
import 'package:grex/shared/theme/app_elevation.dart';

import '../../../../helpers/localized_pumper.dart';

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
      await pumpLocalized(
        tester,
        GroupListItem(
          group: testGroup,
          onTap: () => onTapCalled = true,
        ),
      );

      // Check group name
      expect(find.text('Test Group'), findsOneWidget);

      // Check pluralized member count (Vietnamese)
      expect(find.text('2 thành viên'), findsOneWidget);

      // Check currency symbol
      expect(find.text('₫'), findsOneWidget);

      // Check icons (rounded chevron used after the polish refactor)
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('should display group initials correctly for single word', (
      tester,
    ) async {
      final singleWordGroup = testGroup.copyWith(name: 'Family');

      await pumpLocalized(
        tester,
        GroupListItem(
          group: singleWordGroup,
          onTap: () => onTapCalled = true,
        ),
      );

      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('should display group initials correctly for multiple words', (
      tester,
    ) async {
      final multiWordGroup = testGroup.copyWith(name: 'Family Trip');

      await pumpLocalized(
        tester,
        GroupListItem(
          group: multiWordGroup,
          onTap: () => onTapCalled = true,
        ),
      );

      expect(find.text('FT'), findsOneWidget);
    });

    testWidgets('should handle empty group name', (tester) async {
      final emptyNameGroup = testGroup.copyWith(name: '');

      await pumpLocalized(
        tester,
        GroupListItem(
          group: emptyNameGroup,
          onTap: () => onTapCalled = true,
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

      await pumpLocalized(
        tester,
        GroupListItem(
          group: singleMemberGroup,
          onTap: () => onTapCalled = true,
        ),
      );

      expect(find.text('1 thành viên'), findsOneWidget);
    });

    testWidgets('should display different currency symbols correctly', (
      tester,
    ) async {
      final usdGroup = testGroup.copyWith(currency: 'USD');

      await pumpLocalized(
        tester,
        GroupListItem(
          group: usdGroup,
          onTap: () => onTapCalled = true,
        ),
      );

      expect(find.text(r'$'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      await pumpLocalized(
        tester,
        GroupListItem(
          group: testGroup,
          onTap: () => onTapCalled = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(onTapCalled, isTrue);
    });

    testWidgets('should have proper card elevation and rounded shape', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        GroupListItem(
          group: testGroup,
          onTap: () => onTapCalled = true,
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(AppElevation.card));
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('should display CircleAvatar with correct properties', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        GroupListItem(
          group: testGroup,
          onTap: () => onTapCalled = true,
        ),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, equals(24));
    });

    testWidgets('should handle groups with no members', (tester) async {
      final noMembersGroup = testGroup.copyWith(members: []);

      await pumpLocalized(
        tester,
        GroupListItem(
          group: noMembersGroup,
          onTap: () => onTapCalled = true,
        ),
      );

      expect(find.text('Chưa có thành viên'), findsOneWidget);
    });
  });
}
