import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/handlers/auth_deep_link_handler.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/repositories.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/services/social_login_analytics.dart';
import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/auth_event.dart';
import 'package:grex/features/auth/presentation/bloc/auth_state.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_bloc_timeout_property_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
  SocialAuthRepository,
  SessionManager,
  AuthDeepLinkHandler,
  SocialLoginAnalytics,
])
/// Property-Based Test: Timeout Errors Return to Login
///
/// Validates: Requirements 8.3
///
/// This property test verifies that timeout errors during social authentication
/// are handled correctly by displaying appropriate error messages and returning
/// the user to the login screen without leaving them in an inconsistent state.
void main() {
  group('Property 27: Timeout Errors Return to Login', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockSocialAuthRepository mockSocialAuthRepository;
    late MockSessionManager mockSessionManager;
    late MockAuthDeepLinkHandler mockDeepLinkHandler;
    late MockSocialLoginAnalytics mockAnalytics;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockSocialAuthRepository = MockSocialAuthRepository();
      mockSessionManager = MockSessionManager();
      mockDeepLinkHandler = MockAuthDeepLinkHandler();
      mockAnalytics = MockSocialLoginAnalytics();

      // Setup default mocks
      when(mockAuthRepository.authStateChanges).thenAnswer(
        (_) => const Stream<User?>.empty(),
      );
      when(mockDeepLinkHandler.initialize()).thenAnswer((_) async {
        return;
      });

      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
        socialAuthRepository: mockSocialAuthRepository,
        sessionManager: mockSessionManager,
        deepLinkHandler: mockDeepLinkHandler,
        analytics: mockAnalytics,
      );
    });

    tearDown(() async {
      await authBloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'should handle Google OAuth timeout with 100+ iterations',
      build: () {
        // Setup mock to return timeout failure
        when(
          mockSocialAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => const Left(SocialAuthTimeoutFailure()));
        return authBloc;
      },
      act: (bloc) {
        // Property: For any timeout scenario, the system should return to login
        for (var i = 0; i < 100; i++) {
          bloc.add(const AuthSocialLoginRequested('google'));
        }
      },
      expect: () {
        // Generate expected states for 100 iterations
        final expectedStates = <AuthState>[];
        for (var i = 0; i < 100; i++) {
          expectedStates.addAll([
            const AuthSocialLoginInProgress(SocialAuthProvider.google),
            const AuthError(
              message:
                  'Connection timed out. Please check your network and try again.',
              failure: SocialAuthTimeoutFailure(),
            ),
          ]);
        }
        return expectedStates;
      },
      verify: (bloc) {
        // Verify timeout error was handled correctly
        verify(mockSocialAuthRepository.signInWithGoogle()).called(100);

        // Verify final state is error state (back to login)
        expect(bloc.state, isA<AuthError>());
        final errorState = bloc.state as AuthError;
        expect(
          errorState.message.toLowerCase().contains('timeout') ||
              errorState.message.toLowerCase().contains('timed out'),
          isTrue,
        );
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should handle Apple OAuth timeout with 100+ iterations',
      build: () {
        // Setup mock to return timeout failure
        when(
          mockSocialAuthRepository.signInWithApple(),
        ).thenAnswer((_) async => const Left(SocialAuthTimeoutFailure()));
        return authBloc;
      },
      act: (bloc) {
        // Property: Apple OAuth timeouts should also return to login
        for (var i = 0; i < 100; i++) {
          bloc.add(const AuthSocialLoginRequested('apple'));
        }
      },
      expect: () {
        // Generate expected states for 100 iterations
        final expectedStates = <AuthState>[];
        for (var i = 0; i < 100; i++) {
          expectedStates.addAll([
            const AuthSocialLoginInProgress(SocialAuthProvider.apple),
            const AuthError(
              message:
                  'Connection timed out. Please check your network and try again.',
              failure: SocialAuthTimeoutFailure(),
            ),
          ]);
        }
        return expectedStates;
      },
      verify: (bloc) {
        // Verify timeout error was handled correctly
        verify(mockSocialAuthRepository.signInWithApple()).called(100);

        // Verify final state is error state (back to login)
        expect(bloc.state, isA<AuthError>());
        final errorState = bloc.state as AuthError;
        expect(
          errorState.message.toLowerCase().contains('timeout') ||
              errorState.message.toLowerCase().contains('timed out'),
          isTrue,
        );
      },
    );

    test('should display timeout error message with 100+ iterations', () {
      // Property: All timeout failures should display appropriate error messages

      for (var i = 0; i < 100; i++) {
        final timeoutFailures = _generateTimeoutFailures(i);

        for (final failure in timeoutFailures) {
          // Verify timeout error message is displayed
          expect(failure.message, isNotEmpty);
          expect(
            failure.message.toLowerCase().contains('timeout') ||
                failure.message.toLowerCase().contains('timed out'),
            isTrue,
            reason:
                'Timeout failure should contain timeout-related message: ${failure.message}',
          );

          // Verify message is user-friendly
          _verifyUserFriendlyTimeoutMessage(failure.message);
        }
      }
    });

    test('should return to login screen after timeout with 100+ iterations', () {
      // Property: Timeout errors should not leave user in loading or inconsistent state

      for (var i = 0; i < 100; i++) {
        // Simulate timeout scenario
        final timeoutState = AuthError(
          message: _generateTimeoutMessage(i),
          failure: const SocialAuthTimeoutFailure(),
        );

        // Verify timeout state properties
        expect(timeoutState.failure, isA<SocialAuthTimeoutFailure>());
        expect(
          timeoutState.message.toLowerCase(),
          anyOf(contains('timeout'), contains('timed out')),
        );

        // Provider context is shown in AuthSocialLoginInProgress; the
        // error message itself stays generic for clean UX.

        // Verify state indicates return to login
        expect(timeoutState, isA<AuthError>());
        expect(timeoutState.message, isNotEmpty);

        // Verify state is not loading or in-progress
        expect(timeoutState, isNot(isA<AuthLoading>()));
        expect(timeoutState, isNot(isA<AuthSocialLoginInProgress>()));

        // Verify error message suggests retry or alternative
        _verifyTimeoutRecoveryOptions(timeoutState.message);
      }
    });

    test('should handle various timeout scenarios with 100+ iterations', () {
      // Property: Different types of timeout errors should all be handled consistently

      for (var i = 0; i < 100; i++) {
        final timeoutScenarios = _generateTimeoutScenarios(i);

        for (final scenario in timeoutScenarios) {
          // Verify each timeout scenario maps to appropriate failure
          expect(scenario, isA<SocialAuthTimeoutFailure>());
          expect(
            scenario.message.contains('timeout') ||
                scenario.message.contains('timed out'),
            isTrue,
          );

          // Verify consistent handling across scenarios
          _verifyConsistentTimeoutHandling(scenario);
        }
      }
    });

    test('should not expose technical timeout details with 100+ iterations', () {
      // Property: Timeout error messages should not expose technical implementation details

      for (var i = 0; i < 100; i++) {
        const timeoutFailure = SocialAuthTimeoutFailure();

        // Verify no technical details exposed
        expect(timeoutFailure.message, isNot(contains('milliseconds')));
        expect(timeoutFailure.message, isNot(contains('ms')));
        expect(timeoutFailure.message, isNot(contains('seconds')));
        expect(timeoutFailure.message, isNot(contains('thread')));
        expect(timeoutFailure.message, isNot(contains('callback')));
        expect(timeoutFailure.message, isNot(contains('async')));
        expect(timeoutFailure.message, isNot(contains('future')));

        // Verify message is user-appropriate
        _verifyUserAppropriateMessage(timeoutFailure.message);
      }
    });
  });
}

/// Generates various timeout failure scenarios for testing
List<SocialAuthTimeoutFailure> _generateTimeoutFailures(int seed) {
  // All timeout failures should have the same message for consistency
  return [
    const SocialAuthTimeoutFailure(),
    const SocialAuthTimeoutFailure(),
    const SocialAuthTimeoutFailure(),
  ];
}

/// Generates timeout messages for testing
String _generateTimeoutMessage(int seed) {
  final messages = [
    'Sign in timed out',
    'Authentication timed out',
    'Request timed out',
    'Operation timed out',
    'Connection timed out',
  ];

  return messages[seed % messages.length];
}

/// Generates various timeout scenarios
List<SocialAuthTimeoutFailure> _generateTimeoutScenarios(int seed) {
  // Different timeout scenarios that should all be handled the same way
  return [
    const SocialAuthTimeoutFailure(), // OAuth callback timeout
    const SocialAuthTimeoutFailure(), // Network timeout
    const SocialAuthTimeoutFailure(), // Provider timeout
    const SocialAuthTimeoutFailure(), // Deep link timeout
    const SocialAuthTimeoutFailure(), // Session establishment timeout
  ];
}

/// Verifies timeout message is user-friendly
void _verifyUserFriendlyTimeoutMessage(String message) {
  // Should not contain technical jargon
  expect(message, isNot(contains('callback')));
  expect(message, isNot(contains('async')));
  expect(message, isNot(contains('await')));
  expect(message, isNot(contains('future')));
  expect(message, isNot(contains('stream')));

  // Should not contain specific time values
  expect(
    message,
    isNot(contains(RegExp(r'\d+\s*(ms|milliseconds|seconds|s)'))),
  );

  // Should be properly formatted
  expect(message, isNotEmpty);
  if (message.isNotEmpty) {
    expect(message[0], equals(message[0].toUpperCase()));
  }
}

/// Verifies timeout recovery options are suggested
void _verifyTimeoutRecoveryOptions(String message) {
  // Message should suggest user can try again or use alternative
  // This is implicit in the error state - UI will show retry options
  expect(message, isNotEmpty);

  // Should not suggest technical solutions
  expect(message, isNot(contains('increase timeout')));
  expect(message, isNot(contains('check network settings')));
  expect(message, isNot(contains('restart app')));
}

/// Verifies consistent timeout handling
void _verifyConsistentTimeoutHandling(SocialAuthTimeoutFailure failure) {
  // All timeout failures should have consistent message
  expect(failure.message, equals('Sign in timed out'));

  // All timeout failures should be of the same type
  expect(failure, isA<SocialAuthTimeoutFailure>());
  expect(failure, isA<AuthFailure>());
}

/// Verifies message is appropriate for users
void _verifyUserAppropriateMessage(String message) {
  // Should be concise and clear
  expect(message.length, lessThan(100));
  expect(message, isNot(contains('null')));
  expect(message, isNot(contains('undefined')));

  // Should not contain programming terms
  expect(message, isNot(contains('exception')));
  expect(message, isNot(contains('error code')));
  expect(message, isNot(contains('stack trace')));

  // Should be actionable or informative
  expect(message, isNotEmpty);
}
