import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grex/features/expenses/presentation/widgets/participant_selection_widget.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';

void main() {
  group('ParticipantSelectionWidget Widget Tests', () {
    late List<GroupMember> testMembers;
    late List<Map<String, dynamic>> selectedParticipants;

    setUp(() {
      testMembers = [
        GroupMember(
          id: 'mem-1',
          userId: 'user-1',
          displayName: 'John Doe',
          role: MemberRole.administrator,
          joinedAt: DateTime.now(),
        ),
        GroupMember(
          id: 'mem-2',
          userId: 'user-2',
          displayName: 'Jane Smith',
          role: MemberRole.editor,
          joinedAt: DateTime.now(),
        ),
        GroupMember(
          id: 'mem-3',
          userId: 'user-3',
          displayName: 'Bob Johnson',
          role: MemberRole.viewer,
          joinedAt: DateTime.now(),
        ),
      ];

      selectedParticipants = [
        {'userId': 'user-1', 'displayName': 'John Doe'},
      ];
    });

    Widget createTestWidget({
      List<GroupMember>? members,
      List<Map<String, dynamic>>? selected,
      ValueChanged<List<Map<String, dynamic>>>? onSelectionChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ParticipantSelectionWidget(
            groupMembers: members ?? testMembers,
            selectedParticipants: selected ?? selectedParticipants,
            onSelectionChanged: onSelectionChanged ?? (participants) {},
          ),
        ),
      );
    }

    testWidgets('should display empty state when no members', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(members: []));

      // Assert
      expect(find.text('No group members found'), findsOneWidget);
    });

    testWidgets('should display all group members', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
    });

    testWidgets('should display member roles', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('Viewer'), findsOneWidget);
    });

    testWidgets('should display member avatars with initials', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CircleAvatar), findsNWidgets(3));
      expect(find.text('J'), findsNWidgets(2)); // John and Jane
      expect(find.text('B'), findsOneWidget); // Bob
    });

    testWidgets('should display selection count', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('should display Select All and Select None buttons', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Select None'), findsOneWidget);
    });

    testWidgets('should show correct checkbox states', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );

      // John Doe should be selected
      expect(checkboxes.first.value, isTrue);

      // Jane Smith and Bob Johnson should not be selected
      expect(checkboxes.elementAt(1).value, isFalse);
      expect(checkboxes.elementAt(2).value, isFalse);
    });

    testWidgets('should call onSelectionChanged when participant is selected', (
      tester,
    ) async {
      // Arrange
      List<Map<String, dynamic>>? changedSelection;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          onSelectionChanged: (participants) {
            changedSelection = participants;
          },
        ),
      );

      // Tap Jane Smith checkbox
      await tester.tap(find.byType(CheckboxListTile).at(1));

      // Assert
      expect(changedSelection, isNotNull);
      expect(changedSelection!.length, equals(2));
      expect(changedSelection!.any((p) => p['userId'] == 'user-2'), isTrue);
    });

    testWidgets(
      'should call onSelectionChanged when participant is deselected',
      (tester) async {
        // Arrange
        List<Map<String, dynamic>>? changedSelection;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            onSelectionChanged: (participants) {
              changedSelection = participants;
            },
          ),
        );

        // Tap John Doe checkbox (currently selected)
        await tester.tap(find.byType(CheckboxListTile).first);

        // Assert
        expect(changedSelection, isNotNull);
        expect(changedSelection!.length, equals(0));
      },
    );

    testWidgets('should select all participants when Select All is tapped', (
      tester,
    ) async {
      // Arrange
      List<Map<String, dynamic>>? changedSelection;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          selected: [], // Start with none selected
          onSelectionChanged: (participants) {
            changedSelection = participants;
          },
        ),
      );

      await tester.tap(find.text('Select All'));

      // Assert
      expect(changedSelection, isNotNull);
      expect(changedSelection!.length, equals(3));
      expect(changedSelection!.any((p) => p['userId'] == 'user-1'), isTrue);
      expect(changedSelection!.any((p) => p['userId'] == 'user-2'), isTrue);
      expect(changedSelection!.any((p) => p['userId'] == 'user-3'), isTrue);
    });

    testWidgets('should deselect all participants when Select None is tapped', (
      tester,
    ) async {
      // Arrange
      List<Map<String, dynamic>>? changedSelection;
      final allSelected = [
        {'userId': 'user-1', 'displayName': 'John Doe'},
        {'userId': 'user-2', 'displayName': 'Jane Smith'},
        {'userId': 'user-3', 'displayName': 'Bob Johnson'},
      ];

      // Act
      await tester.pumpWidget(
        createTestWidget(
          selected: allSelected,
          onSelectionChanged: (participants) {
            changedSelection = participants;
          },
        ),
      );

      await tester.tap(find.text('Select None'));

      // Assert
      expect(changedSelection, isNotNull);
      expect(changedSelection!.length, equals(0));
    });

    testWidgets('should update selection count when participants change', (
      tester,
    ) async {
      // Arrange
      final allSelected = [
        {'userId': 'user-1', 'displayName': 'John Doe'},
        {'userId': 'user-2', 'displayName': 'Jane Smith'},
        {'userId': 'user-3', 'displayName': 'Bob Johnson'},
      ];

      // Act
      await tester.pumpWidget(createTestWidget(selected: allSelected));

      // Assert
      expect(find.text('3 selected'), findsOneWidget);
    });

    testWidgets('should handle empty display names gracefully', (tester) async {
      // Arrange
      final membersWithEmptyName = [
        GroupMember(
          id: 'mem-1',
          userId: 'user-1',
          displayName: '',
          role: MemberRole.editor,
          joinedAt: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        createTestWidget(
          members: membersWithEmptyName,
          selected: [],
        ),
      );

      // Assert
      expect(find.text('?'), findsOneWidget); // Avatar should show '?'
      expect(find.text(''), findsOneWidget); // Empty display name
    });

    testWidgets(
      'should not duplicate participants when selecting already selected',
      (tester) async {
        // Arrange
        List<Map<String, dynamic>>? changedSelection;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            onSelectionChanged: (participants) {
              changedSelection = participants;
            },
          ),
        );

        // Tap John Doe checkbox twice (select, then deselect, then select
        // again)
        await tester.tap(find.byType(CheckboxListTile).first); // Deselect
        await tester.pump();
        await tester.tap(find.byType(CheckboxListTile).first); // Select again

        // Assert
        expect(changedSelection, isNotNull);
        expect(changedSelection!.length, equals(1));
        expect(
          changedSelection!.where((p) => p['userId'] == 'user-1').length,
          equals(1),
        );
      },
    );

    testWidgets('should display correct participant data structure', (
      tester,
    ) async {
      // Arrange
      List<Map<String, dynamic>>? changedSelection;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          selected: [],
          onSelectionChanged: (participants) {
            changedSelection = participants;
          },
        ),
      );

      // Select Jane Smith
      await tester.tap(find.byType(CheckboxListTile).at(1));

      // Assert
      expect(changedSelection, isNotNull);
      expect(changedSelection!.first['userId'], equals('user-2'));
      expect(changedSelection!.first['displayName'], equals('Jane Smith'));
      expect(changedSelection!.first.containsKey('userId'), isTrue);
      expect(changedSelection!.first.containsKey('displayName'), isTrue);
    });

    testWidgets('should handle single member correctly', (tester) async {
      // Arrange
      final singleMember = [testMembers.first];

      // Act
      await tester.pumpWidget(
        createTestWidget(
          members: singleMember,
          selected: [],
        ),
      );

      // Assert
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('0 selected'), findsOneWidget);
    });

    testWidgets('should maintain selection state across rebuilds', (
      tester,
    ) async {
      // Arrange
      var currentSelection = <Map<String, dynamic>>[];

      Widget buildWidget() {
        return createTestWidget(
          selected: currentSelection,
          onSelectionChanged: (participants) {
            currentSelection = participants;
          },
        );
      }

      // Act
      await tester.pumpWidget(buildWidget());

      // Select a participant
      await tester.tap(find.byType(CheckboxListTile).first);

      // Rebuild widget with updated selection
      await tester.pumpWidget(buildWidget());

      // Assert
      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, isTrue);
    });

    testWidgets('should handle large number of members', (tester) async {
      // Arrange
      final manyMembers = List.generate(
        20,
        (index) => GroupMember(
          id: 'mem-$index',
          userId: 'user-$index',
          displayName: 'User $index',
          role: MemberRole.editor,
          joinedAt: DateTime.now(),
        ),
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          members: manyMembers,
          selected: [],
        ),
      );

      // Assert
      expect(find.byType(CheckboxListTile), findsNWidgets(20));
      expect(find.text('0 selected'), findsOneWidget);
    });
  });
}
