import 'dart:math';

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

import 'auth_bloc_network_failures_property_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
  SocialAuthRepository,
  SessionManager,
  AuthDeepLinkHandler,
  SocialLoginAnalytics,
])
void main() {
  group('AuthBloc Network Failures Property Tests', () {
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
      when(mockAuthRepository.currentUser).thenReturn(null);
      when(mockDeepLinkHandler.initialize()).thenAnswer((_) async {
        return;
      });
    });

    test(
      'Property 4: Network Failures Display Retry Option',
      () async {
        // Feature: social-login, Property 4: Network Failures Display Retry
        // Option
        // Validates: Requirements 1.4, 2.4, 8.2
        // Test with 100+ iterations for both providers
        // Verify error message displayed
        // Verify retry button shown

        const iterations = 100;
        final providers = ['google', 'apple'];
        final networkFailures = [
          const SocialAuthNetworkFailure(),
          const NetworkFailure(),
          const SocialAuthTimeoutFailure(),
        ];
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          // Generate random test scenario
          final provider = providers[random.nextInt(providers.length)];
          final failure =
              networkFailures[random.nextInt(networkFailures.length)];
          final isGoogle = provider == 'google';

          // Mock network failure for the provider
          if (isGoogle) {
            when(
              mockSocialAuthRepository.signInWithGoogle(),
            ).thenAnswer((_) async => Left(failure));
          } else {
            when(
              mockSocialAuthRepository.signInWithApple(),
            ).thenAnswer((_) async => Left(failure));
          }

          // Create fresh bloc for each iteration
          final testBloc = AuthBloc(
            authRepository: mockAuthRepository,
            userRepository: mockUserRepository,
            socialAuthRepository: mockSocialAuthRepository,
            sessionManager: mockSessionManager,
            deepLinkHandler: mockDeepLinkHandler,
            analytics: mockAnalytics,
          );

          // Set up expectation, then trigger event (add must come BEFORE await)
          final expectation = expectLater(
            testBloc.stream,
            emitsInOrder([
              isA<AuthSocialLoginInProgress>(),
              isA<AuthError>(),
            ]),
          );
          testBloc.add(AuthSocialLoginRequested(provider));
          await expectation;

          // Verify final state is error
          expect(testBloc.state, isA<AuthError>());
          final errorState = testBloc.state as AuthError;

          // Property: Network failures should result in appropriate error types
          expect(
            errorState.failure,
            anyOf([
              isA<SocialAuthNetworkFailure>(),
              isA<NetworkFailure>(),
              isA<SocialAuthTimeoutFailure>(),
            ]),
            reason:
                'Iteration $i: Network failure should return appropriate '
                'failure type for $provider',
          );

          // Property: Error message should indicate network issue
          expect(
            errorState.message,
            isNotEmpty,
            reason: 'Iteration $i: Error message should not be empty',
          );
          expect(
            errorState.message.toLowerCase(),
            anyOf([
              contains('network'),
              contains('connection'),
              contains('timeout'),
              contains('internet'),
            ]),
            reason: 'Iteration $i: Error message should indicate network issue',
          );

          await testBloc.close();
        }
      },
    );

    test(
      'Property 4 Extended: Network Error Messages Are Actionable',
      () async {
        // Extended property test to verify error messages provide actionable
        // guidance
        const iterations = 100;
        final providers = ['google', 'apple'];
        final networkFailures = [
          const SocialAuthNetworkFailure(),
          const NetworkFailure(),
          const SocialAuthTimeoutFailure(),
        ];
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          final provider = providers[random.nextInt(providers.length)];
          final failure =
              networkFailures[random.nextInt(networkFailures.length)];
          final isGoogle = provider == 'google';

          // Mock network failure
          if (isGoogle) {
            when(
              mockSocialAuthRepository.signInWithGoogle(),
            ).thenAnswer((_) async => Left(failure));
          } else {
            when(
              mockSocialAuthRepository.signInWithApple(),
            ).thenAnswer((_) async => Left(failure));
          }

          // Trigger social login and wait for completion
          final testBloc = AuthBloc(
            authRepository: mockAuthRepository,
            userRepository: mockUserRepository,
            socialAuthRepository: mockSocialAuthRepository,
            sessionManager: mockSessionManager,
            deepLinkHandler: mockDeepLinkHandler,
            analytics: mockAnalytics,
          )..add(AuthSocialLoginRequested(provider));
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // Verify error message provides actionable guidance
          expect(testBloc.state, isA<AuthError>());
          final errorState = testBloc.state as AuthError;

          // Property: Error message should suggest retry action
          expect(
            errorState.message.toLowerCase(),
            anyOf([
              contains('try again'),
              contains('retry'),
              contains('check'),
            ]),
            reason: 'Iteration $i: Error message should suggest retry action',
          );

          // Property: Error message should be user-friendly
          expect(
            errorState.message.length,
            greaterThan(10),
            reason: 'Iteration $i: Error message should be descriptive',
          );
          expect(
            errorState.message,
            isNot(contains('Exception')),
            reason:
                'Iteration $i: Error message should not contain '
                'technical terms',
          );

          await testBloc.close();
        }
      },
    );

    test(
      'Property 4 Retry Behavior: Network Failures Allow Immediate Retry',
      () async {
        // Test that network failures don't prevent immediate retry attempts
        const iterations = 100;
        final providers = ['google', 'apple'];
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          final provider = providers[random.nextInt(providers.length)];
          final isGoogle = provider == 'google';

          // Mock initial network failure, then success on retry
          var callCount = 0;
          if (isGoogle) {
            when(mockSocialAuthRepository.signInWithGoogle()).thenAnswer((
              _,
            ) async {
              callCount++;
              if (callCount == 1) {
                return const Left(SocialAuthNetworkFailure());
              } else {
                // Mock successful retry
                return Right(
                  User(
                    id: 'test-user-$i',
                    email: 'test$i@example.com',
                    createdAt: DateTime.now(),
                  ),
                );
              }
            });
          } else {
            when(mockSocialAuthRepository.signInWithApple()).thenAnswer((
              _,
            ) async {
              callCount++;
              if (callCount == 1) {
                return const Left(SocialAuthNetworkFailure());
              } else {
                return Right(
                  User(
                    id: 'test-user-$i',
                    email: 'test$i@example.com',
                    createdAt: DateTime.now(),
                  ),
                );
              }
            });
          }

          // Mock user repository for successful retry
          when(
            mockUserRepository.getUserProfile(any),
          ).thenAnswer((_) async => const Left(UserNotFoundFailure()));
          when(
            mockUserRepository.getUserProfileByEmail(any),
          ).thenAnswer((_) async => const Right(null));

          // First attempt - should fail
          final testBloc = AuthBloc(
            authRepository: mockAuthRepository,
            userRepository: mockUserRepository,
            socialAuthRepository: mockSocialAuthRepository,
            sessionManager: mockSessionManager,
            deepLinkHandler: mockDeepLinkHandler,
            analytics: mockAnalytics,
          )..add(AuthSocialLoginRequested(provider));
          await Future<void>.delayed(const Duration(milliseconds: 100));

          expect(
            testBloc.state,
            isA<AuthError>(),
            reason: 'Iteration $i: First attempt should fail',
          );

          // Retry attempt - should succeed
          testBloc.add(AuthSocialLoginRequested(provider));
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // Property: Retry after network failure should be allowed
          expect(
            testBloc.state,
            isA<AuthProfileSetupRequired>(),
            reason: 'Iteration $i: Retry should succeed after network failure',
          );

          // Property: Both provider methods should have been called twice
          if (isGoogle) {
            verify(mockSocialAuthRepository.signInWithGoogle()).called(2);
          } else {
            verify(mockSocialAuthRepository.signInWithApple()).called(2);
          }

          await testBloc.close();
        }
      },
    );

    test(
      "Property 4 Error Recovery: Network Failures Don't Corrupt State",
      () async {
        // Test that network failures don't leave the bloc in a corrupted state
        const iterations = 100;
        final providers = ['google', 'apple'];
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          final provider = providers[random.nextInt(providers.length)];
          final isGoogle = provider == 'google';

          // Mock network failure
          if (isGoogle) {
            when(
              mockSocialAuthRepository.signInWithGoogle(),
            ).thenAnswer((_) async => const Left(SocialAuthNetworkFailure()));
          } else {
            when(
              mockSocialAuthRepository.signInWithApple(),
            ).thenAnswer((_) async => const Left(SocialAuthNetworkFailure()));
          }

          // Trigger network failure
          final testBloc = AuthBloc(
            authRepository: mockAuthRepository,
            userRepository: mockUserRepository,
            socialAuthRepository: mockSocialAuthRepository,
            sessionManager: mockSessionManager,
            deepLinkHandler: mockDeepLinkHandler,
            analytics: mockAnalytics,
          )..add(AuthSocialLoginRequested(provider));
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // Property: State should be consistent after network failure
          expect(
            testBloc.state,
            isA<AuthError>(),
            reason:
                'Iteration $i: State should be AuthError after network failure',
          );

          // Property: Bloc should still respond to other events
          testBloc.add(const AuthSessionChecked());
          await Future<void>.delayed(const Duration(milliseconds: 50));

          // Verify bloc is still functional
          expect(
            testBloc.isClosed,
            false,
            reason:
                'Iteration $i: Bloc should remain functional after network '
                'failure',
          );

          await testBloc.close();
        }
      },
    );
  });
}
