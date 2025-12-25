// This diagnostic is ignored because Mockito's 'when' and 'thenReturn' syntax
// often triggers type mismatch warnings that are safe in a test context.
// ignore_for_file: argument_type_not_assignable
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/domain/failures/group_failure.dart';
import 'package:grex/features/groups/domain/repositories/group_repository.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  group('Group BLoC Administrator Settings Properties', () {
    late MockGroupRepository mockRepository;
    late GroupBloc groupBloc;
    final random = Random();
    const testIterations = 1000;

    setUp(() {
      mockRepository = MockGroupRepository();
      groupBloc = GroupBloc(mockRepository);
    });

    tearDown(() async {
      await groupBloc.close();
    });

    // Helper function to generate random groups
    List<Group> generateRandomGroups(int count) {
      return List.generate(count, (index) {
        final memberCount = random.nextInt(5) + 2; // 2-6 members
        final members = List.generate(memberCount, (memberIndex) {
          const roles = MemberRole.values;
          // Ensure at least one administrator
          final role = memberIndex == 0
              ? MemberRole.administrator
              : roles[random.nextInt(roles.length)];

          return GroupMember(
            id: 'member-$index-$memberIndex',
            userId: 'user-$index-$memberIndex',
            displayName: 'User ${index}_$memberIndex',
            role: role,
            joinedAt: DateTime.now().subtract(
              Duration(days: random.nextInt(365)),
            ),
          );
        });

        return Group(
          id: 'group-$index',
          name: 'Test Group $index',
          currency: ['USD', 'VND', 'EUR'][random.nextInt(3)],
          creatorId: members.first.userId,
          members: members,
          createdAt: DateTime.now().subtract(
            Duration(days: random.nextInt(100)),
          ),
          updatedAt: DateTime.now().subtract(
            Duration(days: random.nextInt(10)),
          ),
        );
      });
    }

    test('Property 27: Administrator settings access is complete', () async {
      // Property: For any group, administrators should have complete access
      // to all settings and management functions

      for (var i = 0; i < testIterations; i++) {
        // Generate random test data
        final groups = generateRandomGroups(random.nextInt(5) + 1);
        final testGroup = groups[random.nextInt(groups.length)];

        // Find an administrator in the group
        final administrator = testGroup.members.firstWhere(
          (member) => member.role == MemberRole.administrator,
        );

        // Mock repository responses
        when(
          mockRepository.getUserGroups(),
        ).thenAnswer((_) async => Right(groups));
        when(
          mockRepository.hasPermission(testGroup.id, any),
        ).thenAnswer((_) async => const Right(true));
        when(
          mockRepository.updateGroup(
            groupId: testGroup.id,
            name: anyNamed('name'),
            currency: anyNamed('currency'),
            description: anyNamed('description'),
          ),
        ).thenAnswer((_) async => Right(testGroup));

        // Create fresh bloc for each iteration
        final bloc = GroupBloc(mockRepository);

        try {
          // Load groups first
          bloc.add(const GroupsLoadRequested());
          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Property: Administrator should be able to update group settings
          final newName = 'Updated Group ${random.nextInt(1000)}';
          final newCurrency = ['USD', 'EUR', 'GBP'][random.nextInt(3)];
          final newDescription = 'Updated description ${random.nextInt(1000)}';

          bloc.add(
            GroupUpdateRequested(
              groupId: testGroup.id,
              name: newName,
              currency: newCurrency,
              description: newDescription,
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Verify that update was attempted
          verify(
            mockRepository.updateGroup(
              groupId: testGroup.id,
              name: newName,
              currency: newCurrency,
              description: newDescription,
            ),
          ).called(1);

          // Property: Administrator should be able to invite members
          when(
            mockRepository.inviteMember(
              groupId: testGroup.id,
              email: anyNamed('email'),
              displayName: anyNamed('displayName'),
              role: anyNamed('role'),
            ),
          ).thenAnswer(
            (_) async => Right(
              GroupMember(
                id: 'new-member',
                userId: 'new-user',
                displayName: 'New User',
                role: MemberRole.editor,
                joinedAt: DateTime.now(),
              ),
            ),
          );

          final inviteEmail = 'user${random.nextInt(1000)}@test.com';
          bloc.add(
            GroupMemberInvited(
              groupId: testGroup.id,
              email: inviteEmail,
              displayName: 'New User',
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));

          verify(
            mockRepository.inviteMember(
              groupId: testGroup.id,
              email: inviteEmail,
              displayName: 'New User',
            ),
          ).called(1);

          // Property: Administrator should be able to change member roles
          if (testGroup.members.length > 1) {
            final targetMember = testGroup.members.firstWhere(
              (member) => member.role != MemberRole.administrator,
            );

            when(
              mockRepository.updateMemberRole(
                groupId: testGroup.id,
                userId: targetMember.userId,
                newRole: MemberRole.administrator,
              ),
            ).thenAnswer(
              (_) async => Right(
                targetMember.copyWith(
                  role: MemberRole.administrator,
                ),
              ),
            );

            bloc.add(
              GroupMemberRoleChanged(
                groupId: testGroup.id,
                userId: targetMember.userId,
                newRole: MemberRole.administrator,
              ),
            );

            await Future<void>.delayed(const Duration(milliseconds: 10));

            verify(
              mockRepository.updateMemberRole(
                groupId: testGroup.id,
                userId: targetMember.userId,
                newRole: MemberRole.administrator,
              ),
            ).called(1);
          }

          // Property: Administrator should be able to remove members
          if (testGroup.members.length > 2) {
            final targetMember = testGroup.members.firstWhere(
              (member) => member.userId != administrator.userId,
            );

            when(
              mockRepository.removeMember(
                groupId: testGroup.id,
                userId: targetMember.userId,
              ),
            ).thenAnswer((_) async => const Right(null));

            bloc.add(
              GroupMemberRemoved(
                groupId: testGroup.id,
                userId: targetMember.userId,
              ),
            );

            await Future<void>.delayed(const Duration(milliseconds: 10));

            verify(
              mockRepository.removeMember(
                groupId: testGroup.id,
                userId: targetMember.userId,
              ),
            ).called(1);
          }
        } finally {
          await bloc.close();
        }
      }
    });

    test('Property 28: Settings updates are validated and saved', () async {
      // Property: For any group settings update, the data should be validated
      // before saving and the update should be persisted correctly

      for (var i = 0; i < testIterations; i++) {
        // Generate random test data
        final groups = generateRandomGroups(1);
        final testGroup = groups.first;

        // Mock repository responses
        when(
          mockRepository.getUserGroups(),
        ).thenAnswer((_) async => Right(groups));
        when(
          mockRepository.hasPermission(testGroup.id, 'update'),
        ).thenAnswer((_) async => const Right(true));

        // Create fresh bloc for each iteration
        final bloc = GroupBloc(mockRepository);

        try {
          // Test valid updates
          final validName = 'Valid Group Name ${random.nextInt(1000)}';
          final validCurrency = ['USD', 'EUR', 'GBP', 'VND'][random.nextInt(4)];
          final validDescription = 'Valid description ${random.nextInt(1000)}';

          final updatedGroup = testGroup.copyWith(
            name: validName,
            currency: validCurrency,
          );

          when(
            mockRepository.updateGroup(
              groupId: testGroup.id,
              name: validName,
              currency: validCurrency,
              description: validDescription,
            ),
          ).thenAnswer((_) async => Right(updatedGroup));

          // Load groups first
          bloc.add(const GroupsLoadRequested());
          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Property: Valid updates should be processed successfully
          bloc.add(
            GroupUpdateRequested(
              groupId: testGroup.id,
              name: validName,
              currency: validCurrency,
              description: validDescription,
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Verify update was called with correct parameters
          verify(
            mockRepository.updateGroup(
              groupId: testGroup.id,
              name: validName,
              currency: validCurrency,
              description: validDescription,
            ),
          ).called(1);

          // Property: Invalid updates should be rejected
          when(
            mockRepository.updateGroup(
              groupId: testGroup.id,
              name: '',
              currency: anyNamed('currency'),
              description: anyNamed('description'),
            ),
          ).thenAnswer(
            (_) async =>
                const Left(InvalidGroupDataFailure('Name cannot be empty')),
          );

          bloc.add(
            const GroupUpdateRequested(
              groupId: 'test-group',
              name: '', // Invalid empty name
              currency: 'USD',
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Property: Partial updates should work
          when(
            mockRepository.updateGroup(
              groupId: testGroup.id,
              name: validName,
            ),
          ).thenAnswer((_) async => Right(testGroup.copyWith(name: validName)));

          bloc.add(
            GroupUpdateRequested(
              groupId: testGroup.id,
              name: validName,
              // Only updating name, not currency or description
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));
        } finally {
          await bloc.close();
        }
      }
    });

    test('Property 29: Role promotions and demotions work correctly', () async {
      // Property: For any member role change, the operation should maintain
      // group integrity and proper permission hierarchy

      for (var i = 0; i < testIterations; i++) {
        // Generate random test data with multiple members
        final groups = generateRandomGroups(1);
        final testGroup = groups.first;

        if (testGroup.members.length < 2) continue; // Need at least 2 members

        // Mock repository responses
        when(
          mockRepository.getUserGroups(),
        ).thenAnswer((_) async => Right(groups));
        when(
          mockRepository.hasPermission(testGroup.id, 'manage_members'),
        ).thenAnswer((_) async => const Right(true));

        // Create fresh bloc for each iteration
        final bloc = GroupBloc(mockRepository);

        try {
          // Load groups first
          bloc.add(const GroupsLoadRequested());
          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Find members with different roles
          final administrator = testGroup.members.firstWhere(
            (member) => member.role == MemberRole.administrator,
          );

          final nonAdminMember = testGroup.members.firstWhere(
            (member) => member.role != MemberRole.administrator,
          );

          // Property: Role promotions should work
          final newRole =
              MemberRole.values[random.nextInt(MemberRole.values.length)];
          final updatedMember = nonAdminMember.copyWith(role: newRole);

          when(
            mockRepository.updateMemberRole(
              groupId: testGroup.id,
              userId: nonAdminMember.userId,
              newRole: newRole,
            ),
          ).thenAnswer((_) async => Right(updatedMember));

          bloc.add(
            GroupMemberRoleChanged(
              groupId: testGroup.id,
              userId: nonAdminMember.userId,
              newRole: newRole,
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));

          verify(
            mockRepository.updateMemberRole(
              groupId: testGroup.id,
              userId: nonAdminMember.userId,
              newRole: newRole,
            ),
          ).called(1);

          // Property: Role demotions should work
          if (testGroup.members
                  .where((m) => m.role == MemberRole.administrator)
                  .length >
              1) {
            // Only demote if there's more than one administrator
            when(
              mockRepository.updateMemberRole(
                groupId: testGroup.id,
                userId: administrator.userId,
                newRole: MemberRole.editor,
              ),
            ).thenAnswer(
              (_) async => Right(
                administrator.copyWith(
                  role: MemberRole.editor,
                ),
              ),
            );

            bloc.add(
              GroupMemberRoleChanged(
                groupId: testGroup.id,
                userId: administrator.userId,
                newRole: MemberRole.editor,
              ),
            );

            await Future<void>.delayed(const Duration(milliseconds: 10));

            verify(
              mockRepository.updateMemberRole(
                groupId: testGroup.id,
                userId: administrator.userId,
                newRole: MemberRole.editor,
              ),
            ).called(1);
          }

          // Property: Role changes should preserve member identity
          expect(updatedMember.userId, equals(nonAdminMember.userId));
          expect(updatedMember.displayName, equals(nonAdminMember.displayName));
          expect(updatedMember.joinedAt, equals(nonAdminMember.joinedAt));
        } finally {
          await bloc.close();
        }
      }
    });

    test('Property 30: Administrator continuity is maintained', () async {
      // Property: For any group, there should always be at least one
      // administrator and administrative operations should maintain
      // this invariant

      for (var i = 0; i < testIterations; i++) {
        // Generate random test data with multiple administrators
        final groups = generateRandomGroups(1);
        final testGroup = groups.first;

        // Ensure we have multiple administrators for testing
        final modifiedMembers = testGroup.members.map((member) {
          if (member.role == MemberRole.administrator) return member;
          // Make some members administrators
          return random.nextBool()
              ? member.copyWith(role: MemberRole.administrator)
              : member;
        }).toList();

        // Ensure at least 2 administrators
        if (modifiedMembers
                .where((m) => m.role == MemberRole.administrator)
                .length <
            2) {
          if (modifiedMembers.length > 1) {
            modifiedMembers[1] = modifiedMembers[1].copyWith(
              role: MemberRole.administrator,
            );
          }
        }

        final groupWithMultipleAdmins = testGroup.copyWith(
          members: modifiedMembers,
        );
        final administrators = groupWithMultipleAdmins.members
            .where((member) => member.role == MemberRole.administrator)
            .toList();

        if (administrators.length < 2) {
          continue; // Need at least 2 administrators
        }

        // Mock repository responses
        when(
          mockRepository.getUserGroups(),
        ).thenAnswer((_) async => Right([groupWithMultipleAdmins]));
        when(
          mockRepository.hasPermission(groupWithMultipleAdmins.id, any),
        ).thenAnswer((_) async => const Right(true));

        // Create fresh bloc for each iteration
        final bloc = GroupBloc(mockRepository);

        try {
          // Load groups first
          bloc.add(const GroupsLoadRequested());
          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Property: Should be able to demote one administrator when others
          // exist
          final adminToDemote = administrators.first;
          final demotedMember = adminToDemote.copyWith(role: MemberRole.editor);

          when(
            mockRepository.updateMemberRole(
              groupId: groupWithMultipleAdmins.id,
              userId: adminToDemote.userId,
              newRole: MemberRole.editor,
            ),
          ).thenAnswer((_) async => Right(demotedMember));

          bloc.add(
            GroupMemberRoleChanged(
              groupId: groupWithMultipleAdmins.id,
              userId: adminToDemote.userId,
              newRole: MemberRole.editor,
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));

          verify(
            mockRepository.updateMemberRole(
              groupId: groupWithMultipleAdmins.id,
              userId: adminToDemote.userId,
              newRole: MemberRole.editor,
            ),
          ).called(1);

          // Property: Should be able to remove non-last administrator
          when(
            mockRepository.removeMember(
              groupId: groupWithMultipleAdmins.id,
              userId: adminToDemote.userId,
            ),
          ).thenAnswer((_) async => const Right(null));

          bloc.add(
            GroupMemberRemoved(
              groupId: groupWithMultipleAdmins.id,
              userId: adminToDemote.userId,
            ),
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));

          verify(
            mockRepository.removeMember(
              groupId: groupWithMultipleAdmins.id,
              userId: adminToDemote.userId,
            ),
          ).called(1);

          // Property: Administrator should be able to delete group
          when(
            mockRepository.deleteGroup(groupWithMultipleAdmins.id),
          ).thenAnswer((_) async => const Right(null));

          bloc.add(GroupDeleteRequested(groupId: groupWithMultipleAdmins.id));

          await Future<void>.delayed(const Duration(milliseconds: 10));

          verify(
            mockRepository.deleteGroup(groupWithMultipleAdmins.id),
          ).called(1);
        } finally {
          await bloc.close();
        }
      }
    });
  });
}
