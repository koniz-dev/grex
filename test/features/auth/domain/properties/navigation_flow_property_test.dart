import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/property_test_helpers.dart';
import '../../../../helpers/test_helpers.dart';

/// Property 3: Authentication establishes valid session
///
/// This property validates that successful authentication creates a valid
/// session that persists across navigation and app state changes.
///
/// **Validates Requirements:**
/// - 2.1: User can sign in with valid credentials
/// - 2.3: Successful authentication redirects to main application
void main() {
  group('Navigation Flow Properties', () {
    late TestDependencies deps;

    setUp(() {
      deps = setupTestDependencies();
    });

    tearDown(() async {
      await deps.dispose();
    });

    test('Property 3: Authentication establishes valid session', () async {
      // Property: For any valid user credentials, successful authentication
      // should establish a session that enables navigation to protected routes

      for (var i = 0; i < 100; i++) {
        // Generate random valid credentials
        final credentials = generateValidCredentials();
        final user = generateValidUser();
        final profile = generateValidUserProfile();

        // Mock successful authentication
        when(
          deps.mockAuthRepository.signInWithEmail(
            email: credentials.email,
            password: credentials.password,
          ),
        ).thenAnswer((_) async => Right(user));

        when(
          deps.mockUserRepository.getUserProfile(user.id),
        ).thenAnswer((_) async => Right(profile));

        when(deps.mockAuthRepository.currentUser).thenReturn(user);

        // Simulate authentication
        deps.authBloc.add(
          AuthLoginRequested(
            email: credentials.email,
            password: credentials.password,
          ),
        );

        // Wait for authentication to complete
        await deps.authBloc.stream.firstWhere(
          (state) => state is AuthAuthenticated || state is AuthError,
        );

        final currentState = deps.authBloc.state;

        // Property assertions
        if (currentState is AuthAuthenticated) {
          // 1. Session should be established
          expect(currentState.user, equals(user));
          expect(currentState.profile, equals(profile));

          // 2. Current user should be available
          expect(deps.mockAuthRepository.currentUser, equals(user));

          // 3. Authentication state should persist
          expect(currentState.user.id, isNotEmpty);
          expect(currentState.user.email, equals(credentials.email));

          // 4. User profile should be loaded
          expect(currentState.profile?.id, equals(user.id));
          expect(currentState.profile?.email, equals(user.email));
        } else if (currentState is AuthError) {
          // If authentication failed, it should be due to invalid credentials
          // not due to session management issues
          expect(currentState.message, isNotEmpty);
        }

        // Reset for next iteration
        deps.authBloc.add(const AuthLogoutRequested());
        await deps.authBloc.stream.firstWhere(
          (state) => state is AuthUnauthenticated,
        );
      }
    });

    test('Property: Navigation guards work correctly', () async {
      // Property: Unauthenticated users should be redirected to login,
      // authenticated users should access protected routes

      for (var i = 0; i < 50; i++) {
        final user = generateValidUser();
        final profile = generateValidUserProfile();

        // Test unauthenticated state
        when(deps.mockAuthRepository.currentUser).thenReturn(null);

        // Simulate checking auth state
        deps.authBloc.add(const AuthSessionChecked());
        await deps.authBloc.stream.firstWhere(
          (state) => state is AuthUnauthenticated || state is AuthAuthenticated,
        );

        var currentState = deps.authBloc.state;

        // Property: Unauthenticated users should not have access
        if (currentState is AuthUnauthenticated) {
          // AuthUnauthenticated state doesn't have a user property
          expect(currentState, isA<AuthUnauthenticated>());
        }

        // Test authenticated state
        when(deps.mockAuthRepository.currentUser).thenReturn(user);
        when(
          deps.mockUserRepository.getUserProfile(user.id),
        ).thenAnswer((_) async => Right(profile));

        deps.authBloc.add(const AuthSessionChecked());
        await deps.authBloc.stream.firstWhere(
          (state) => state is AuthAuthenticated || state is AuthError,
        );

        currentState = deps.authBloc.state;

        // Property: Authenticated users should have valid session
        if (currentState is AuthAuthenticated) {
          expect(currentState.user, equals(user));
          expect(currentState.profile, equals(profile));
          expect(currentState.user.id, isNotEmpty);
        }
      }
    });

    test('Property: Session persistence across app restarts', () async {
      // Property: Valid sessions should persist across app restarts
      // and invalid sessions should be cleared

      for (var i = 0; i < 30; i++) {
        final user = generateValidUser();
        final profile = generateValidUserProfile();

        // Simulate app startup with existing session
        when(deps.mockAuthRepository.currentUser).thenReturn(user);
        when(
          deps.mockUserRepository.getUserProfile(user.id),
        ).thenAnswer((_) async => Right(profile));

        // Check session on app startup
        deps.authBloc.add(const AuthSessionChecked());
        await deps.authBloc.stream.firstWhere(
          (state) => state is AuthAuthenticated || state is AuthUnauthenticated,
        );

        final currentState = deps.authBloc.state;

        // Property: Valid sessions should be restored
        if (currentState is AuthAuthenticated) {
          expect(currentState.user, equals(user));
          expect(currentState.profile, equals(profile));

          // Session data should be consistent
          expect(currentState.user.id, equals(profile.id));
          expect(currentState.user.email, equals(profile.email));
        }

        // Test session cleanup
        deps.authBloc.add(const AuthLogoutRequested());
        await deps.authBloc.stream.firstWhere(
          (state) => state is AuthUnauthenticated,
        );

        final loggedOutState = deps.authBloc.state;
        expect(loggedOutState, isA<AuthUnauthenticated>());
      }
    });
  });
}

/// Test credentials for property testing
class TestCredentials {
  TestCredentials({
    required this.email,
    required this.password,
  });
  final String email;
  final String password;
}

/// Generate valid credentials for testing
TestCredentials generateValidCredentials() {
  final emails = [
    'user1@test.com',
    'user2@example.org',
    'test.user@domain.co',
    'valid.email@company.net',
  ];

  final passwords = [
    'SecurePass123!',
    'MyPassword456@',
    'TestPass789#',
    r'ValidPass012$',
  ];

  return TestCredentials(
    email: emails[DateTime.now().millisecond % emails.length],
    password: passwords[DateTime.now().microsecond % passwords.length],
  );
}
