// These diagnostics are ignored because property-based tests often use
// dynamic data generation and mock configurations that may not strictly
// adhere to type safety or immutability rules.
// ignore_for_file: argument_type_not_assignable, must_be_immutable
import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/data/repositories/supabase_group_repository.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';
import 'package:grex/features/groups/domain/entities/member_role.dart';
import 'package:grex/features/groups/domain/failures/group_failure.dart';
import 'package:grex/features/groups/domain/repositories/group_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockPostgrestQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}

class _FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T>, Future<T> {
  _FakePostgrestTransformBuilder(this._value);
  final T _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) async {
    return onValue(_value);
  }

  @override
  Future<T> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return Future<T>.value(_value);
  }

  @override
  Stream<T> asStream() {
    return Stream<T>.value(_value);
  }

  @override
  Future<T> timeout(
    Duration timeLimit, {
    FutureOr<T> Function()? onTimeout,
  }) {
    return Future<T>.value(_value);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return Future<T>.value(_value);
  }
}

class _FakePostgrestFilterBuilderForAwait<T> extends Fake
    implements PostgrestFilterBuilder<T>, Future<T> {
  _FakePostgrestFilterBuilderForAwait(this._value);
  final T _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) async {
    return onValue(_value);
  }

  @override
  Future<T> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return Future<T>.value(_value);
  }

  @override
  Stream<T> asStream() {
    return Stream<T>.value(_value);
  }
}

/// Property-based test generators for Group entities
class GroupTestGenerators {
  static final Random _random = Random();

  /// Generate a random valid group name
  static String generateGroupName() {
    final prefixes = ['Team', 'Family', 'Friends', 'Work', 'Travel', 'House'];
    final suffixes = ['Group', 'Squad', 'Crew', 'Gang', 'Club', 'Circle'];

    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final suffix = suffixes[_random.nextInt(suffixes.length)];
    final number = _random.nextInt(100);

    return '$prefix $suffix $number';
  }

  /// Generate a random valid currency code
  static String generateCurrency() {
    final currencies = ['VND', 'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
    return currencies[_random.nextInt(currencies.length)];
  }

  /// Generate a random user ID
  static String generateUserId() {
    return 'user-${_random.nextInt(10000)}';
  }

  /// Generate a random group ID
  static String generateGroupId() {
    return 'group-${_random.nextInt(10000)}';
  }

  /// Generate a random display name
  static String generateDisplayName() {
    final firstNames = ['John', 'Jane', 'Alice', 'Bob', 'Charlie', 'Diana'];
    final lastNames = [
      'Smith',
      'Johnson',
      'Brown',
      'Davis',
      'Wilson',
      'Miller',
    ];

    final firstName = firstNames[_random.nextInt(firstNames.length)];
    final lastName = lastNames[_random.nextInt(lastNames.length)];

    return '$firstName $lastName';
  }

  /// Generate a random Group entity for testing
  static Group generateGroup({
    String? id,
    String? name,
    String? currency,
    String? creatorId,
    List<GroupMember>? members,
  }) {
    return Group(
      id: id ?? generateGroupId(),
      name: name ?? generateGroupName(),
      currency: currency ?? generateCurrency(),
      creatorId: creatorId ?? generateUserId(),
      members: members ?? [generateGroupMember()],
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a random GroupMember entity for testing
  static GroupMember generateGroupMember({
    String? userId,
    String? displayName,
    MemberRole? role,
  }) {
    return GroupMember(
      id: 'member-${_random.nextInt(10000)}',
      userId: userId ?? generateUserId(),
      displayName: displayName ?? generateDisplayName(),
      role:
          role ?? MemberRole.values[_random.nextInt(MemberRole.values.length)],
      joinedAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
    );
  }
}

/// Helper function to setup successful group creation mocks
void _setupSuccessfulGroupCreationMocks(
  MockSupabaseClient mockClient,
  Group testGroup,
) {
  // Mock group insertion
  final mockQueryBuilder = MockPostgrestQueryBuilder();
  final mockFilterBuilder =
      MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

  when(mockClient.from('groups')).thenReturn(mockQueryBuilder);
  when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
  when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
  when(mockFilterBuilder.single()).thenReturn(
    _FakePostgrestTransformBuilder({
      'id': 'generated-group-id',
      'name': testGroup.name,
      'currency': testGroup.currency,
      'creator_id': testGroup.creatorId,
      'created_at': testGroup.createdAt.toIso8601String(),
      'updated_at': testGroup.updatedAt.toIso8601String(),
    }),
  );

  // Mock member insertion
  final mockMemberQueryBuilder = MockPostgrestQueryBuilder();
  when(mockClient.from('group_members')).thenReturn(mockMemberQueryBuilder);
  when(mockMemberQueryBuilder.insert(any)).thenReturn(
    _FakePostgrestFilterBuilderForAwait(<Map<String, dynamic>>[]),
  );

  // Mock getGroupById
  final mockGetQueryBuilder = MockPostgrestQueryBuilder();
  final mockGetFilterBuilder =
      MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

  when(mockClient.from('groups')).thenReturn(mockGetQueryBuilder);
  when(mockGetQueryBuilder.select(any)).thenReturn(mockGetFilterBuilder);
  when(
    mockGetFilterBuilder.eq('id', 'generated-group-id'),
  ).thenReturn(mockGetFilterBuilder);
  when(mockGetFilterBuilder.single()).thenReturn(
    _FakePostgrestTransformBuilder({
      'id': 'generated-group-id',
      'name': testGroup.name,
      'currency': testGroup.currency,
      'creator_id': testGroup.creatorId,
      'created_at': testGroup.createdAt.toIso8601String(),
      'updated_at': testGroup.updatedAt.toIso8601String(),
      'group_members': [
        {
          'id': 'member-id',
          'user_id': testGroup.creatorId,
          'display_name': 'Test User',
          'role': 'administrator',
          'joined_at': DateTime.now().toIso8601String(),
        },
      ],
    }),
  );
}

/// Helper function to setup permission check mocks
void _setupPermissionMock(
  MockSupabaseClient mockClient,
  String groupId,
  String action,
  bool hasPermission,
) {
  final mockPermissionQueryBuilder = MockPostgrestQueryBuilder();
  final mockPermissionFilterBuilder =
      MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

  when(mockClient.from('group_members')).thenReturn(mockPermissionQueryBuilder);
  when(
    mockPermissionQueryBuilder.select('role'),
  ).thenReturn(mockPermissionFilterBuilder);
  when(
    mockPermissionFilterBuilder.eq('group_id', groupId),
  ).thenReturn(mockPermissionFilterBuilder);
  when(
    mockPermissionFilterBuilder.eq('user_id', 'test-user-id'),
  ).thenReturn(mockPermissionFilterBuilder);

  when(mockPermissionFilterBuilder.maybeSingle()).thenReturn(
    _FakePostgrestTransformBuilder<Map<String, dynamic>?>(
      hasPermission ? {'role': 'administrator'} : null,
    ),
  );
}

void main() {
  group('GroupRepository Property Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late GroupRepository repository;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();

      // Setup basic mocks
      when(mockSupabaseClient.auth).thenReturn(mockAuth);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('test-user-id');

      repository = SupabaseGroupRepository(mockSupabaseClient);
    });

    group('Property 1: Group creation assigns administrator role', () {
      test(
        'should assign administrator role to creator for any valid group',
        () async {
          // Property: For any valid group data, when a group is created,
          // the creator should be assigned the administrator role

          const iterations = 100;

          for (var i = 0; i < iterations; i++) {
            // Generate random valid group data
            final testGroup = GroupTestGenerators.generateGroup(
              id: '', // Will be generated by database
              creatorId: 'test-user-id', // Current user
            );

            // Mock successful group creation
            final mockQueryBuilder = MockPostgrestQueryBuilder();
            final mockFilterBuilder =
                MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

            when(
              mockSupabaseClient.from('groups'),
            ).thenReturn(mockQueryBuilder);
            when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
            when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
            when(mockFilterBuilder.single()).thenReturn(
              _FakePostgrestTransformBuilder({
                'id': 'generated-group-id',
                'name': testGroup.name,
                'currency': testGroup.currency,
                'creator_id': testGroup.creatorId,
                'created_at': testGroup.createdAt.toIso8601String(),
                'updated_at': testGroup.updatedAt.toIso8601String(),
              }),
            );

            // Mock member insertion
            final mockMemberQueryBuilder = MockPostgrestQueryBuilder();
            when(
              mockSupabaseClient.from('group_members'),
            ).thenReturn(mockMemberQueryBuilder);
            when(mockMemberQueryBuilder.insert(any)).thenReturn(
              _FakePostgrestFilterBuilderForAwait(<Map<String, dynamic>>[]),
            );

            // Mock getGroupById for final result
            final mockGetQueryBuilder = MockPostgrestQueryBuilder();
            final mockGetFilterBuilder =
                MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

            when(
              mockSupabaseClient.from('groups'),
            ).thenReturn(mockGetQueryBuilder);
            when(
              mockGetQueryBuilder.select(any),
            ).thenReturn(mockGetFilterBuilder);
            when(
              mockGetFilterBuilder.eq('id', 'generated-group-id'),
            ).thenReturn(mockGetFilterBuilder);
            when(mockGetFilterBuilder.single()).thenReturn(
              _FakePostgrestTransformBuilder({
                'id': 'generated-group-id',
                'name': testGroup.name,
                'currency': testGroup.currency,
                'creator_id': testGroup.creatorId,
                'created_at': testGroup.createdAt.toIso8601String(),
                'updated_at': testGroup.updatedAt.toIso8601String(),
                'group_members': [
                  {
                    'id': 'member-id',
                    'user_id': 'test-user-id',
                    'display_name': 'Test User',
                    'role': 'administrator',
                    'joined_at': DateTime.now().toIso8601String(),
                  },
                ],
              }),
            );

            // Act
            final result = await repository.createGroup(
              name: testGroup.name,
              currency: testGroup.currency,
            );

            // Assert - Property: Creator should always be assigned
            // administrator role
            expect(
              result.isRight(),
              isTrue,
              reason:
                  'Group creation should succeed for valid data (iteration $i)',
            );

            result.fold(
              (failure) =>
                  fail('Should not fail for valid group data: $failure'),
              (createdGroup) {
                final creatorMember = createdGroup.members.firstWhere(
                  (member) => member.userId == testGroup.creatorId,
                  orElse: () =>
                      throw StateError('Creator not found in members'),
                );

                expect(
                  creatorMember.role,
                  equals(MemberRole.administrator),
                  reason:
                      'Creator should always be assigned administrator role '
                      '(iteration $i)',
                );

                // Additional property: Group should have at least one
                // administrator
                final adminCount = createdGroup.members
                    .where((member) => member.role == MemberRole.administrator)
                    .length;

                expect(
                  adminCount,
                  greaterThanOrEqualTo(1),
                  reason:
                      'Group should have at least one administrator '
                      '(iteration $i)',
                );
              },
            );
          }
        },
      );

      test(
        'should maintain administrator role invariant across different group '
        'configurations',
        () async {
          // Property: Regardless of group name, currency, or other properties,
          // the creator should always become an administrator

          const iterations = 50;
          final currencies = ['VND', 'USD', 'EUR', 'GBP', 'JPY'];

          for (var i = 0; i < iterations; i++) {
            // Test with different currencies
            final currency = currencies[i % currencies.length];

            // Test with edge case names
            final names = [
              'A', // Minimum length
              'Group with very long name that tests boundary conditions',
              'Group-with-special-chars!@#',
              'Группа', // Unicode characters
              '123 Numeric Group',
            ];
            final name = names[i % names.length];

            final testGroup = GroupTestGenerators.generateGroup(
              name: name,
              currency: currency,
              creatorId: 'test-user-id',
            );

            // Mock the same successful creation flow
            _setupSuccessfulGroupCreationMocks(mockSupabaseClient, testGroup);

            // Act
            final result = await repository.createGroup(
              name: testGroup.name,
              currency: testGroup.currency,
            );

            // Assert - Property holds regardless of group configuration
            expect(result.isRight(), isTrue);
            result.fold(
              (failure) => fail('Should not fail: $failure'),
              (createdGroup) {
                final creatorMember = createdGroup.members.firstWhere(
                  (member) => member.userId == testGroup.creatorId,
                );

                expect(
                  creatorMember.role,
                  equals(MemberRole.administrator),
                  reason:
                      'Administrator role should be assigned regardless of '
                      'group config (iteration $i)',
                );
              },
            );
          }
        },
      );

      test(
        'should handle concurrent group creation while maintaining '
        'administrator assignment',
        () async {
          // Property: Even with concurrent operations, each group creator
          // should be assigned administrator role

          const iterations = 20;
          final futures = <Future<void>>[];

          for (var i = 0; i < iterations; i++) {
            final testGroup = GroupTestGenerators.generateGroup(
              creatorId: 'test-user-$i', // Different users
            );

            // Mock for each concurrent operation
            _setupSuccessfulGroupCreationMocks(mockSupabaseClient, testGroup);

            final future = repository
                .createGroup(
                  name: testGroup.name,
                  currency: testGroup.currency,
                )
                .then((result) {
                  expect(result.isRight(), isTrue);
                  result.fold(
                    (failure) =>
                        fail('Concurrent creation should not fail: $failure'),
                    (createdGroup) {
                      final creatorMember = createdGroup.members.firstWhere(
                        (member) => member.userId == testGroup.creatorId,
                      );

                      expect(
                        creatorMember.role,
                        equals(MemberRole.administrator),
                        reason:
                            'Administrator role should be assigned in '
                            'concurrent scenario',
                      );
                    },
                  );
                });

            futures.add(future);
          }

          // Wait for all concurrent operations to complete
          await Future.wait(futures);
        },
      );
    });

    group('Property 2: Group membership visibility is accurate', () {
      test('should only return groups where user is a member', () async {
        // Property: getUserGroups should only return groups where the
        // current user is actually a member, never groups where they are not
        // a member

        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          const currentUserId = 'test-user-id';

          // Generate random groups - some where user is member, some where
          // they're not
          final userGroups = List.generate(
            Random().nextInt(5) + 1, // 1-5 groups where user is member
            (index) => GroupTestGenerators.generateGroup(
              members: [
                GroupTestGenerators.generateGroupMember(userId: currentUserId),
                ...List.generate(
                  Random().nextInt(3), // 0-3 other members
                  (i) => GroupTestGenerators.generateGroupMember(),
                ),
              ],
            ),
          );

          // Mock successful query that returns only user's groups (RLS
          // filtering)
          final mockQueryBuilder = MockPostgrestQueryBuilder();
          final mockFilterBuilder =
              MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

          when(mockSupabaseClient.from('groups')).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
          when(
            mockFilterBuilder.eq('group_members.user_id', currentUserId),
          ).thenReturn(mockFilterBuilder);
          when(
            mockFilterBuilder.order('created_at', ascending: false),
          ).thenAnswer(
            (_) => _FakePostgrestTransformBuilder(
              userGroups
                  .map(
                    (group) => <String, dynamic>{
                      'id': group.id,
                      'name': group.name,
                      'currency': group.currency,
                      'creator_id': group.creatorId,
                      'created_at': group.createdAt.toIso8601String(),
                      'updated_at': group.updatedAt.toIso8601String(),
                      'group_members': group.members
                          .map(
                            (member) => <String, dynamic>{
                              'id': 'member-${member.userId}',
                              'user_id': member.userId,
                              'display_name': member.displayName,
                              'role': member.role.toJson(),
                              'joined_at': member.joinedAt.toIso8601String(),
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
            ),
          );

          // Act
          final result = await repository.getUserGroups();

          // Assert - Property: All returned groups should have current user as
          // member
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail: $failure'),
            (groups) {
              for (final group in groups) {
                final userIsMember = group.members.any(
                  (member) => member.userId == currentUserId,
                );

                expect(
                  userIsMember,
                  isTrue,
                  reason:
                      'All returned groups should have current user as member '
                      '(iteration $i, group ${group.id})',
                );
              }

              // Property: Number of groups should match expected
              expect(
                groups.length,
                equals(userGroups.length),
                reason:
                    'Should return exactly the groups where user is member '
                    '(iteration $i)',
              );
            },
          );
        }
      });

      test('should accurately reflect membership '
          'changes in real-time', () async {
        // Property: When membership changes occur, the visibility should update
        // accordingly

        const iterations = 50;

        for (var i = 0; i < iterations; i++) {
          const currentUserId = 'test-user-id';

          // Initial state: user is member of some groups
          final initialGroups = List.generate(
            Random().nextInt(3) + 1,
            (index) => GroupTestGenerators.generateGroup(
              members: [
                GroupTestGenerators.generateGroupMember(userId: currentUserId),
              ],
            ),
          );

          // Simulate membership change: user added to new group
          final newGroup = GroupTestGenerators.generateGroup(
            members: [
              GroupTestGenerators.generateGroupMember(userId: currentUserId),
            ],
          );

          final updatedGroups = [...initialGroups, newGroup];

          // Mock the updated query result
          final mockQueryBuilder = MockPostgrestQueryBuilder();
          final mockFilterBuilder =
              MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

          when(mockSupabaseClient.from('groups')).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
          when(
            mockFilterBuilder.eq('group_members.user_id', currentUserId),
          ).thenReturn(mockFilterBuilder);
          when(
            mockFilterBuilder.order('created_at', ascending: false),
          ).thenAnswer(
            (_) => _FakePostgrestTransformBuilder(
              updatedGroups
                  .map(
                    (group) => <String, dynamic>{
                      'id': group.id,
                      'name': group.name,
                      'currency': group.currency,
                      'creator_id': group.creatorId,
                      'created_at': group.createdAt.toIso8601String(),
                      'updated_at': group.updatedAt.toIso8601String(),
                      'group_members': group.members
                          .map(
                            (member) => <String, dynamic>{
                              'id': 'member-${member.userId}',
                              'user_id': member.userId,
                              'display_name': member.displayName,
                              'role': member.role.toJson(),
                              'joined_at': member.joinedAt.toIso8601String(),
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
            ),
          );

          // Act
          final result = await repository.getUserGroups();

          // Assert - Property: Should reflect the updated membership
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail: $failure'),
            (groups) {
              expect(
                groups.length,
                equals(updatedGroups.length),
                reason:
                    'Should reflect updated membership count (iteration $i)',
              );

              // Property: Should include the new group
              final newGroupExists = groups.any(
                (group) => group.id == newGroup.id,
              );
              expect(
                newGroupExists,
                isTrue,
                reason: 'Should include newly joined group (iteration $i)',
              );

              // Property: All groups should still have user as member
              for (final group in groups) {
                final userIsMember = group.members.any(
                  (member) => member.userId == currentUserId,
                );
                expect(
                  userIsMember,
                  isTrue,
                  reason:
                      'User should be member of all returned groups (iteration '
                      '$i)',
                );
              }
            },
          );
        }
      });

      test('should handle empty membership correctly', () async {
        // Property: When user is not a member of any groups, should return
        // empty list

        const iterations = 20;

        for (var i = 0; i < iterations; i++) {
          const currentUserId = 'test-user-id';

          // Mock empty result (user not member of any groups)
          final mockQueryBuilder = MockPostgrestQueryBuilder();
          final mockFilterBuilder =
              MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

          when(mockSupabaseClient.from('groups')).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
          when(
            mockFilterBuilder.eq('group_members.user_id', currentUserId),
          ).thenReturn(mockFilterBuilder);
          when(
            mockFilterBuilder.order('created_at', ascending: false),
          ).thenAnswer(
            (_) => _FakePostgrestTransformBuilder(<Map<String, dynamic>>[]),
          );

          // Act
          final result = await repository.getUserGroups();

          // Assert - Property: Should return empty list when no memberships
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not fail for empty result: $failure'),
            (groups) {
              expect(
                groups,
                isEmpty,
                reason:
                    'Should return empty list when user has no group '
                    'memberships (iteration $i)',
              );
            },
          );
        }
      });
    });

    group('Property 3: Member invitations default to editor role', () {
      test('should assign editor role to all invited members', () async {
        // Property: When inviting members to a group, they should always
        // be assigned the editor role by default

        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          final groupId = GroupTestGenerators.generateGroupId();
          final invitedEmail = 'invited$i@test.com';
          final invitedUserId = 'invited-user-$i';
          final invitedDisplayName = GroupTestGenerators.generateDisplayName();

          // Mock permission check (user has invite permission)
          _setupPermissionMock(mockSupabaseClient, groupId, 'invite', true);

          // Mock user lookup by email
          final mockUserQueryBuilder = MockPostgrestQueryBuilder();
          final mockUserFilterBuilder =
              MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

          when(
            mockSupabaseClient.from('users'),
          ).thenReturn(mockUserQueryBuilder);
          when(
            mockUserQueryBuilder.select('id, display_name'),
          ).thenReturn(mockUserFilterBuilder);
          when(
            mockUserFilterBuilder.eq('email', invitedEmail),
          ).thenReturn(mockUserFilterBuilder);
          when(mockUserFilterBuilder.maybeSingle()).thenReturn(
            _FakePostgrestTransformBuilder(<String, dynamic>{
              'id': invitedUserId,
              'display_name': invitedDisplayName,
            }),
          );

          // Mock existing member check (user not already member)
          final mockExistingQueryBuilder = MockPostgrestQueryBuilder();
          final mockExistingFilterBuilder =
              MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

          when(
            mockSupabaseClient.from('group_members'),
          ).thenReturn(mockExistingQueryBuilder);
          when(
            mockExistingQueryBuilder.select('id'),
          ).thenReturn(mockExistingFilterBuilder);
          when(
            mockExistingFilterBuilder.eq('group_id', groupId),
          ).thenReturn(mockExistingFilterBuilder);
          when(
            mockExistingFilterBuilder.eq('user_id', invitedUserId),
          ).thenReturn(mockExistingFilterBuilder);
          when(mockExistingFilterBuilder.maybeSingle()).thenReturn(
            _FakePostgrestTransformBuilder<Map<String, dynamic>?>(null),
          );

          // Mock member insertion - capture the inserted data
          Map<String, dynamic>? insertedMemberData;
          final mockInsertQueryBuilder = MockPostgrestQueryBuilder();
          when(
            mockSupabaseClient.from('group_members'),
          ).thenReturn(mockInsertQueryBuilder);
          when(mockInsertQueryBuilder.insert(any)).thenAnswer((invocation) {
            insertedMemberData =
                invocation.positionalArguments[0] as Map<String, dynamic>;
            return _FakePostgrestFilterBuilderForAwait(<String, dynamic>{});
          });

          // Act
          final result = await repository.inviteMember(
            groupId: groupId,
            email: invitedEmail,
            displayName: invitedDisplayName,
          );

          // Assert - Property: Invited member should have editor role
          expect(result.isRight(), isTrue);
          expect(
            insertedMemberData,
            isNotNull,
            reason: 'Member data should be inserted (iteration $i)',
          );

          if (insertedMemberData != null) {
            expect(
              insertedMemberData!['role'],
              equals('editor'),
              reason:
                  'Invited member should default to editor role (iteration $i)',
            );

            expect(
              insertedMemberData!['user_id'],
              equals(invitedUserId),
              reason: 'Should invite the correct user (iteration $i)',
            );

            expect(
              insertedMemberData!['group_id'],
              equals(groupId),
              reason: 'Should add to correct group (iteration $i)',
            );
          }
        }
      });
    });

    group('Property 4: Role changes update permissions', () {
      test(
        'should successfully update member roles when user has permission',
        () async {
          // Property: When a user with appropriate permissions changes a
          // member's role, the role should be updated successfully

          const iterations = 50;

          for (var i = 0; i < iterations; i++) {
            final groupId = GroupTestGenerators.generateGroupId();
            final memberId = 'member-$i';
            final newRole =
                MemberRole.values[Random().nextInt(MemberRole.values.length)];

            // Mock permission check (user has manage_roles permission)
            _setupPermissionMock(
              mockSupabaseClient,
              groupId,
              'manage_roles',
              true,
            );

            // Mock administrator count check (ensure we don't remove last
            // admin)
            final mockAdminQueryBuilder = MockPostgrestQueryBuilder();
            final mockAdminFilterBuilder =
                MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

            when(
              mockSupabaseClient.from('group_members'),
            ).thenReturn(mockAdminQueryBuilder);
            when(
              mockAdminQueryBuilder.select('id'),
            ).thenReturn(mockAdminFilterBuilder);
            when(
              mockAdminFilterBuilder.eq('group_id', groupId),
            ).thenReturn(mockAdminFilterBuilder);
            when(mockAdminFilterBuilder.eq('role', 'administrator')).thenReturn(
              _FakePostgrestFilterBuilderForAwait(<Map<String, dynamic>>[
                {'id': 'admin1'},
                {'id': 'admin2'},
              ]),
            );

            // Mock current member lookup
            final mockMemberQueryBuilder = MockPostgrestQueryBuilder();
            final mockMemberFilterBuilder =
                MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

            when(
              mockSupabaseClient.from('group_members'),
            ).thenReturn(mockMemberQueryBuilder);
            when(
              mockMemberQueryBuilder.select(),
            ).thenReturn(mockMemberFilterBuilder);
            when(
              mockMemberFilterBuilder.eq('id', memberId),
            ).thenReturn(mockMemberFilterBuilder);
            when(mockMemberFilterBuilder.maybeSingle()).thenReturn(
              _FakePostgrestTransformBuilder(<String, dynamic>{
                'id': memberId,
                'user_id': 'some-user',
                'display_name': 'Some User',
                'role': 'editor', // Current role
                'joined_at': DateTime.now().toIso8601String(),
              }),
            );

            // Mock role update - capture the updated data
            Map<String, dynamic>? updatedRoleData;
            final mockUpdateQueryBuilder = MockPostgrestQueryBuilder();
            final mockUpdateFilterBuilder =
                MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

            when(
              mockSupabaseClient.from('group_members'),
            ).thenReturn(mockUpdateQueryBuilder);
            when(
              mockUpdateQueryBuilder.update(
                argThat(isA<Map<String, dynamic>>()),
              ),
            ).thenAnswer((invocation) {
              updatedRoleData =
                  invocation.positionalArguments[0] as Map<String, dynamic>;
              return mockUpdateFilterBuilder;
            });
            when(mockUpdateFilterBuilder.eq('id', memberId)).thenReturn(
              _FakePostgrestFilterBuilderForAwait(<Map<String, dynamic>>[]),
            );

            // Act
            final result = await repository.updateMemberRole(
              groupId: groupId,
              userId: memberId,
              newRole: newRole,
            );

            // Assert - Property: Role should be updated successfully
            expect(
              result.isRight(),
              isTrue,
              reason:
                  'Role update should succeed with proper permissions '
                  '(iteration $i)',
            );

            expect(
              updatedRoleData,
              isNotNull,
              reason: 'Role data should be updated (iteration $i)',
            );

            if (updatedRoleData != null) {
              expect(
                updatedRoleData!['role'],
                equals(newRole.toJson()),
                reason: 'Should update to the specified role (iteration $i)',
              );
            }
          }
        },
      );

      test('should prevent removing last administrator', () async {
        // Property: The system should never allow removing the last
        // administrator from a group, maintaining group management continuity

        const iterations = 30;

        for (var i = 0; i < iterations; i++) {
          final groupId = GroupTestGenerators.generateGroupId();
          final lastAdminMemberId = 'last-admin-$i';
          final newRole = MemberRole.values
              .where((role) => role != MemberRole.administrator)
              .toList()[Random().nextInt(2)]; // editor or viewer

          // Mock permission check (user has manage_roles permission)
          _setupPermissionMock(
            mockSupabaseClient,
            groupId,
            'manage_roles',
            true,
          );

          // Mock administrator count check (only one admin)
          final mockAdminQueryBuilder = MockPostgrestQueryBuilder();
          final mockAdminFilterBuilder =
              MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

          when(
            mockSupabaseClient.from('group_members'),
          ).thenReturn(mockAdminQueryBuilder);
          when(
            mockAdminQueryBuilder.select('id'),
          ).thenReturn(mockAdminFilterBuilder);
          when(
            mockAdminFilterBuilder.eq('group_id', groupId),
          ).thenReturn(mockAdminFilterBuilder);
          when(mockAdminFilterBuilder.eq('role', 'administrator')).thenReturn(
            _FakePostgrestFilterBuilderForAwait(<Map<String, dynamic>>[
              {'id': lastAdminMemberId}, // Only one admin
            ]),
          );

          // Mock current member lookup (is administrator)
          final mockMemberQueryBuilder = MockPostgrestQueryBuilder();
          final mockMemberFilterBuilder =
              MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

          when(
            mockSupabaseClient.from('group_members'),
          ).thenReturn(mockMemberQueryBuilder);
          when(
            mockMemberQueryBuilder.select(),
          ).thenReturn(mockMemberFilterBuilder);
          when(
            mockMemberFilterBuilder.eq('id', lastAdminMemberId),
          ).thenReturn(mockMemberFilterBuilder);
          when(mockMemberFilterBuilder.maybeSingle()).thenReturn(
            _FakePostgrestTransformBuilder(<String, dynamic>{
              'id': lastAdminMemberId,
              'user_id': 'admin-user',
              'display_name': 'Admin User',
              'role': 'administrator',
              'joined_at': DateTime.now().toIso8601String(),
            }),
          );

          // Act
          final result = await repository.updateMemberRole(
            groupId: groupId,
            userId: lastAdminMemberId,
            newRole: newRole,
          );

          // Assert - Property: Should prevent removing last administrator
          expect(
            result.isLeft(),
            isTrue,
            reason: 'Should prevent removing last administrator (iteration $i)',
          );

          result.fold(
            (failure) {
              expect(
                failure,
                isA<LastAdministratorFailure>(),
                reason: 'Should return LastAdministratorFailure (iteration $i)',
              );
            },
            (success) =>
                fail('Should not succeed when removing last administrator'),
          );
        }
      });
    });

    group('Property 5: Member removal restricts access', () {
      test(
        'should successfully remove members when user has permission',
        () async {
          // Property: When a user with appropriate permissions removes a
          // member, the member should be successfully removed from the group

          const iterations = 50;

          for (var i = 0; i < iterations; i++) {
            final groupId = GroupTestGenerators.generateGroupId();
            final memberId = 'member-$i';

            // Mock permission check (user has remove_members permission)
            _setupPermissionMock(
              mockSupabaseClient,
              groupId,
              'remove_members',
              true,
            );

            // Mock member lookup (not an administrator, safe to remove)
            final mockMemberQueryBuilder = MockPostgrestQueryBuilder();
            final mockMemberFilterBuilder =
                MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

            when(
              mockSupabaseClient.from('group_members'),
            ).thenReturn(mockMemberQueryBuilder);
            when(
              mockMemberQueryBuilder.select(),
            ).thenReturn(mockMemberFilterBuilder);
            when(
              mockMemberFilterBuilder.eq('id', memberId),
            ).thenReturn(mockMemberFilterBuilder);
            when(mockMemberFilterBuilder.maybeSingle()).thenReturn(
              _FakePostgrestTransformBuilder(<String, dynamic>{
                'id': memberId,
                'user_id': 'some-user',
                'display_name': 'Some User',
                'role': 'editor', // Not administrator
                'joined_at': DateTime.now().toIso8601String(),
              }),
            );

            // Mock member deletion
            var memberDeleted = false;
            final mockDeleteQueryBuilder = MockPostgrestQueryBuilder();
            final mockDeleteFilterBuilder =
                MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

            when(
              mockSupabaseClient.from('group_members'),
            ).thenReturn(mockDeleteQueryBuilder);
            when(
              mockDeleteQueryBuilder.delete(),
            ).thenReturn(mockDeleteFilterBuilder);
            when(mockDeleteFilterBuilder.eq('id', memberId)).thenAnswer((_) {
              memberDeleted = true;
              return _FakePostgrestFilterBuilderForAwait(
                <Map<String, dynamic>>[],
              );
            });

            // Act
            final result = await repository.removeMember(
              groupId: groupId,
              userId: memberId,
            );

            // Assert - Property: Member should be successfully removed
            expect(
              result.isRight(),
              isTrue,
              reason:
                  'Member removal should succeed with proper permissions '
                  '(iteration $i)',
            );

            expect(
              memberDeleted,
              isTrue,
              reason: 'Member should be deleted from database (iteration $i)',
            );
          }
        },
      );

      test(
        'should prevent removing last administrator via member removal',
        () async {
          // Property: The system should prevent removing the last
          // administrator even through the removeMember operation

          const iterations = 30;

          for (var i = 0; i < iterations; i++) {
            final groupId = GroupTestGenerators.generateGroupId();
            final lastAdminMemberId = 'last-admin-$i';

            // Mock permission check (user has remove_members permission)
            _setupPermissionMock(
              mockSupabaseClient,
              groupId,
              'remove_members',
              true,
            );

            // Mock member lookup (is administrator)
            final mockMemberQueryBuilder = MockPostgrestQueryBuilder();
            final mockMemberFilterBuilder =
                MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

            when(
              mockSupabaseClient.from('group_members'),
            ).thenReturn(mockMemberQueryBuilder);
            when(
              mockMemberQueryBuilder.select(),
            ).thenReturn(mockMemberFilterBuilder);
            when(
              mockMemberFilterBuilder.eq('id', lastAdminMemberId),
            ).thenReturn(mockMemberFilterBuilder);
            when(mockMemberFilterBuilder.maybeSingle()).thenReturn(
              _FakePostgrestTransformBuilder(<String, dynamic>{
                'id': lastAdminMemberId,
                'user_id': 'admin-user',
                'display_name': 'Admin User',
                'role': 'administrator',
                'joined_at': DateTime.now().toIso8601String(),
              }),
            );

            // Mock administrator count check (only one admin)
            final mockAdminQueryBuilder = MockPostgrestQueryBuilder();
            final mockAdminFilterBuilder =
                MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

            when(
              mockSupabaseClient.from('group_members'),
            ).thenReturn(mockAdminQueryBuilder);
            when(
              mockAdminQueryBuilder.select('id'),
            ).thenReturn(mockAdminFilterBuilder);
            when(
              mockAdminFilterBuilder.eq('group_id', groupId),
            ).thenReturn(mockAdminFilterBuilder);
            when(mockAdminFilterBuilder.eq('role', 'administrator')).thenReturn(
              _FakePostgrestFilterBuilderForAwait(<Map<String, dynamic>>[
                {'id': lastAdminMemberId}, // Only one admin
              ]),
            );

            // Act
            final result = await repository.removeMember(
              groupId: groupId,
              userId: lastAdminMemberId,
            );

            // Assert - Property: Should prevent removing last administrator
            expect(
              result.isLeft(),
              isTrue,
              reason:
                  'Should prevent removing last administrator via removeMember '
                  '(iteration $i)',
            );

            result.fold(
              (failure) {
                expect(
                  failure,
                  isA<LastAdministratorFailure>(),
                  reason:
                      'Should return LastAdministratorFailure (iteration $i)',
                );
              },
              (success) =>
                  fail('Should not succeed when removing last administrator'),
            );
          }
        },
      );
    });
  });
}
