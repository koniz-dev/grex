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
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'auth_bloc_profile_existence_check_property_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
  SocialAuthRepository,
  SessionManager,
  AuthDeepLinkHandler,
  SocialLoginAnalytics,
])
void main() {
  group('AuthBloc Profile Existence Check Property Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockSocialAuthRepository mockSocialAuthRepository;
    late MockSessionManager mockSessionManager;
    late MockAuthDeepLinkHandler mockDeepLinkHandler;
    late MockSocialLoginAnalytics mockAnalytics;
    late AuthBloc authBloc;

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

    test(
      'Property 9: Profile Existence Check After OAuth',
      () async {
        // Feature: social-login, Property 9: Profile Existence Check After OAuth
        // Validates: Requirements 4.1
        // Test with 100+ iterations
        // Verify profile check performed after successful OAuth
        // Verify correct navigation based on profile existence

        const iterations = 100;
        const providers = [SocialAuthProvider.google, SocialAuthProvider.apple];

        for (final provider in providers) {
          for (var i = 0; i < iterations; i++) {
            final testBloc = AuthBloc(
              authRepository: mockAuthRepository,
              userRepository: mockUserRepository,
              socialAuthRepository: mockSocialAuthRepository,
              sessionManager: mockSessionManager,
              deepLinkHandler: mockDeepLinkHandler,
              analytics: mockAnalytics,
            );

            try {
              // Alternate between existing and new users
              final hasExistingProfile = i.isEven;
              final userId = 'test-user-$i';
              final userEmail = 'test$i@example.com';

              final oauthUser = User(
                id: userId,
                email: userEmail,
                createdAt: DateTime.now(),
                appMetadata: {
                  'providers': [provider.name],
                },
                userMetadata: {'full_name': 'Test User $i'},
              );

              // Setup OAuth success
              when(
                provider == SocialAuthProvider.google
                    ? mockSocialAuthRepository.signInWithGoogle()
                    : mockSocialAuthRepository.signInWithApple(),
              ).thenAnswer((_) async => Right(oauthUser));

              if (hasExistingProfile) {
                // User has existing profile
                final existingProfile = UserProfile(
                  id: userId,
                  email: userEmail,
                  displayName: 'Existing User $i',
                  preferredCurrency: 'VND',
                  languageCode: 'vi',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                when(
                  mockUserRepository.getUserProfile(userId),
                ).thenAnswer((_) async => Right(existingProfile));
                when(mockAuthRepository.currentSession).thenReturn(
                  supabase.Session(
                    accessToken: 'test-token-$i',
                    tokenType: 'bearer',
                    user: supabase.User(
                      id: userId,
                      appMetadata: {},
                      userMetadata: {},
                      aud: 'authenticated',
                      createdAt: DateTime.now().toIso8601String(),
                      email: userEmail,
                    ),
                  ),
                );
                when(
                  mockSessionManager.startSession(
                    accessToken: anyNamed('accessToken'),
                    refreshToken: anyNamed('refreshToken'),
                    user: anyNamed('user'),
                    userProfile: anyNamed('userProfile'),
                  ),
                ).thenAnswer((_) async => const Right(null));
              } else {
                // User doesn't have profile (new user)
                when(
                  mockUserRepository.getUserProfile(userId),
                ).thenAnswer((_) async => const Left(UserNotFoundFailure()));
                when(
                  mockUserRepository.getUserProfileByEmail(userEmail),
                ).thenAnswer((_) async => const Right(null));
              }

              final states = <AuthState>[];
              final subscription = testBloc.stream.listen(states.add);

              testBloc.add(AuthSocialLoginRequested(provider.name));
              await Future<void>.delayed(const Duration(milliseconds: 100));

              // Verify profile check was performed
              verify(mockUserRepository.getUserProfile(userId)).called(1);

              // Verify correct navigation based on profile existence
              expect(states.length, greaterThanOrEqualTo(2));
              expect(states[0], isA<AuthSocialLoginInProgress>());

              if (hasExistingProfile) {
                // Should navigate to authenticated state
                expect(states[1], isA<AuthAuthenticated>());
                verify(
                  mockSessionManager.startSession(
                    accessToken: anyNamed('accessToken'),
                    refreshToken: anyNamed('refreshToken'),
                    user: anyNamed('user'),
                    userProfile: anyNamed('userProfile'),
                  ),
                ).called(1);
              } else {
                // Should navigate to profile setup
                expect(states[1], isA<AuthProfileSetupRequired>());
                // Should also check for email conflicts
                verify(
                  mockUserRepository.getUserProfileByEmail(userEmail),
                ).called(1);
              }

              await subscription.cancel();
            } finally {
              await testBloc.close();
            }
          }
        }
      },
    );

    test(
      'Property 9 Extended: Profile Check Handles Repository Failures',
      () async {
        // Extended property test to verify profile check handles repository failures gracefully
        const iterations = 50;

        for (var i = 0; i < iterations; i++) {
          final testBloc = AuthBloc(
            authRepository: mockAuthRepository,
            userRepository: mockUserRepository,
            socialAuthRepository: mockSocialAuthRepository,
            sessionManager: mockSessionManager,
            deepLinkHandler: mockDeepLinkHandler,
            analytics: mockAnalytics,
          );

          try {
            final userId = 'fail-user-$i';
            final userEmail = 'fail$i@example.com';

            final oauthUser = User(
              id: userId,
              email: userEmail,
              createdAt: DateTime.now(),
              appMetadata: const {
                'providers': ['google'],
              },
            );

            when(
              mockSocialAuthRepository.signInWithGoogle(),
            ).thenAnswer((_) async => Right(oauthUser));

            // Simulate repository failure
            when(mockUserRepository.getUserProfile(userId)).thenAnswer(
              (_) async => const Left(GenericUserFailure('Database error')),
            );
            when(
              mockUserRepository.getUserProfileByEmail(userEmail),
            ).thenAnswer(
              (_) async => const Left(GenericUserFailure('Database error')),
            );

            final states = <AuthState>[];
            final subscription = testBloc.stream.listen(states.add);

            testBloc.add(const AuthSocialLoginRequested('google'));
            await Future<void>.delayed(const Duration(milliseconds: 100));

            // Should handle failure gracefully by treating as new user
            expect(states.length, greaterThanOrEqualTo(2));
            expect(states[0], isA<AuthSocialLoginInProgress>());
            expect(states[1], isA<AuthProfileSetupRequired>());

            await subscription.cancel();
          } finally {
            await testBloc.close();
          }
        }
      },
    );

    test(
      'Property 9 Timing: Profile Check Occurs Immediately After OAuth',
      () async {
        // Test that profile check occurs immediately after successful OAuth
        const iterations = 50;

        for (var i = 0; i < iterations; i++) {
          final testBloc = AuthBloc(
            authRepository: mockAuthRepository,
            userRepository: mockUserRepository,
            socialAuthRepository: mockSocialAuthRepository,
            sessionManager: mockSessionManager,
            deepLinkHandler: mockDeepLinkHandler,
            analytics: mockAnalytics,
          );

          try {
            final userId = 'timing-user-$i';
            final userEmail = 'timing$i@example.com';

            final oauthUser = User(
              id: userId,
              email: userEmail,
              createdAt: DateTime.now(),
              appMetadata: const {
                'providers': ['google'],
              },
            );

            when(
              mockSocialAuthRepository.signInWithGoogle(),
            ).thenAnswer((_) async => Right(oauthUser));
            when(
              mockUserRepository.getUserProfile(userId),
            ).thenAnswer((_) async => const Left(UserNotFoundFailure()));
            when(
              mockUserRepository.getUserProfileByEmail(userEmail),
            ).thenAnswer((_) async => const Right(null));

            final states = <AuthState>[];
            final subscription = testBloc.stream.listen(states.add);

            final startTime = DateTime.now();
            testBloc.add(const AuthSocialLoginRequested('google'));
            await Future<void>.delayed(const Duration(milliseconds: 100));
            final endTime = DateTime.now();

            // Verify profile check was called
            verify(mockUserRepository.getUserProfile(userId)).called(1);

            // Verify timing - should complete quickly
            final duration = endTime.difference(startTime);
            expect(duration.inMilliseconds, lessThan(500));

            await subscription.cancel();
          } finally {
            await testBloc.close();
          }
        }
      },
    );
  });
}
