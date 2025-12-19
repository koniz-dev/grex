import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();

    // Setup default auth state stream
    when(mockAuthRepository.authStateChanges).thenAnswer(
      (_) => const Stream<User?>.empty(),
    );

    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      userRepository: mockUserRepository,
      sessionManager: MockSessionManager(),
    );
  });

  tearDown(() async {
    await authBloc.close();
  });

  group('Property-Based Tests for AuthBloc', () {
    group('Property 3: Authentication establishes valid session', () {
      test(
        '**Feature: authentication, Property 3: Authentication establishes '
        'valid session** - **Validates: Requirements 2.1, 2.3**',
        () async {
          // Property: For any valid email and password combination,
          // successful authentication should result in an AuthAuthenticated
          // state
          // with a valid user and session data

          final testCases = [
            {
              'email': 'user1@example.com',
              'password': 'ValidPass123!',
              'userId': 'user-1',
              'displayName': 'User One',
            },
            {
              'email': 'test.user@domain.co.uk',
              'password': 'SecureP@ss456',
              'userId': 'user-2',
              'displayName': 'Test User',
            },
          ];

          for (final testCase in testCases) {
            final email = testCase['email']!;
            final password = testCase['password']!;
            final userId = testCase['userId']!;
            final displayName = testCase['displayName']!;

            // Create test user and profile
            final testUser = User(
              id: userId,
              email: email,
              createdAt: DateTime.now(),
              lastSignInAt: DateTime.now(),
            );

            final testProfile = UserProfile(
              id: userId,
              email: email,
              displayName: displayName,
              preferredCurrency: 'VND',
              languageCode: 'vi',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            // Setup mocks for successful authentication
            when(
              mockAuthRepository.signInWithEmail(
                email: email,
                password: password,
              ),
            ).thenAnswer((_) async => Right(testUser));

            when(
              mockUserRepository.getUserProfile(userId),
            ).thenAnswer((_) async => Right(testProfile));

            // Create fresh bloc for each test case
            final testBloc = AuthBloc(
              authRepository: mockAuthRepository,
              userRepository: mockUserRepository,
              sessionManager: MockSessionManager(),
            );

            // Test the property
            await expectLater(
              testBloc.stream,
              emitsInOrder([
                const AuthLoading(),
                AuthAuthenticated(user: testUser, profile: testProfile),
              ]),
            );

            // Trigger authentication
            testBloc.add(
              AuthLoginRequested(
                email: email,
                password: password,
              ),
            );

            // Wait for completion
            await Future<void>.delayed(const Duration(milliseconds: 100));

            // Verify final state
            expect(testBloc.state, isA<AuthAuthenticated>());
            final authState = testBloc.state as AuthAuthenticated;

            // Property assertions: Valid session must have:
            // 1. Valid user with correct ID and email
            expect(authState.user.id, equals(userId));
            expect(authState.user.email, equals(email));
            expect(authState.user.emailConfirmed, isTrue);

            // 2. Valid profile with matching user data
            expect(authState.profile, isNotNull);
            expect(authState.profile!.id, equals(userId));
            expect(authState.profile!.email, equals(email));
            expect(authState.profile!.displayName, equals(displayName));

            await testBloc.close();
          }
        },
      );
    });

    group('Property 9: Sign out clears session and data', () {
      test(
        '**Feature: authentication, Property 9: Sign out clears session and '
        'data** - **Validates: Requirements 5.1, 5.2, 5.3**',
        () async {
          // Property: For any authenticated user state,
          // sign out should always clear session and return to unauthenticated
          // state

          final signOutTestCases = [
            {
              'userId': 'signout-user-1',
              'email': 'signout1@example.com',
              'displayName': 'SignOut User 1',
            },
            {
              'userId': 'signout-user-2',
              'email': 'signout2@example.com',
              'displayName': 'SignOut User 2',
            },
          ];

          for (final testCase in signOutTestCases) {
            final userId = testCase['userId']!;
            final email = testCase['email']!;
            final displayName = testCase['displayName']!;

            // Create test user and profile for authenticated state
            final testUser = User(
              id: userId,
              email: email,
              createdAt: DateTime.now(),
              lastSignInAt: DateTime.now(),
            );

            final testProfile = UserProfile(
              id: userId,
              email: email,
              displayName: displayName,
              preferredCurrency: 'VND',
              languageCode: 'vi',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            // Setup mocks for successful sign out
            when(
              mockAuthRepository.signOut(),
            ).thenAnswer((_) async => const Right(null));

            // Create fresh bloc for each test case
            final testBloc = AuthBloc(
              authRepository: mockAuthRepository,
              userRepository: mockUserRepository,
              sessionManager: MockSessionManager(),
            );

            // First, establish authenticated state
            final stream = testBloc.stream;
            testBloc.emit(
              AuthAuthenticated(user: testUser, profile: testProfile),
            );

            // Verify we start in authenticated state
            expect(testBloc.state, isA<AuthAuthenticated>());

            // Test the sign out property
            await expectLater(
              stream,
              emitsInOrder([
                const AuthLoading(),
                const AuthUnauthenticated(),
              ]),
            );

            // Trigger sign out
            testBloc.add(const AuthLogoutRequested());

            // Wait for completion
            await Future<void>.delayed(const Duration(milliseconds: 100));

            // Property assertions: Sign out must clear all session data
            // 1. State should be AuthUnauthenticated
            expect(testBloc.state, isA<AuthUnauthenticated>());
            expect(testBloc.state, isNot(isA<AuthAuthenticated>()));

            // 2. Repository signOut should have been called
            verify(mockAuthRepository.signOut()).called(1);

            await testBloc.close();
          }
        },
      );
    });
  });
}
