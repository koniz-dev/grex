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
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'auth_bloc_existing_user_navigation_property_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
  SocialAuthRepository,
  SessionManager,
  AuthDeepLinkHandler,
  SocialLoginAnalytics,
])
void main() {
  group('AuthBloc Existing User Navigation Property Tests', () {
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
    });

    test(
      'Property 5: Existing Users Navigate to Main Screen',
      () async {
        // Feature: social-login, Property 5: Existing Users Navigate to Main
        // Screen
        // Validates: Requirements 1.5, 2.5
        // Test with 100+ iterations for both providers
        // Verify direct navigation to main screen
        // Verify authenticated state established

        const iterations = 100;
        final providers = ['google', 'apple'];
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          // Generate random provider
          final provider = providers[random.nextInt(providers.length)];
          final isGoogle = provider == 'google';

          // Create test user and profile
          final testUser = User(
            id: 'existing-user-$i',
            email: 'existing$i@example.com',
            createdAt: DateTime.now(),
            appMetadata: {
              'providers': [provider],
            },
            userMetadata: {
              'full_name': 'Existing User $i',
            },
          );

          final testProfile = UserProfile(
            id: testUser.id,
            email: testUser.email,
            displayName: 'Existing User $i',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Mock successful OAuth for existing user
          if (isGoogle) {
            when(
              mockSocialAuthRepository.signInWithGoogle(),
            ).thenAnswer((_) async => Right(testUser));
          } else {
            when(
              mockSocialAuthRepository.signInWithApple(),
            ).thenAnswer((_) async => Right(testUser));
          }

          // Mock existing user profile
          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));

          // Mock session management
          when(mockAuthRepository.currentSession).thenReturn(
            supabase.Session(
              accessToken: 'test-token-$i',
              tokenType: 'bearer',
              user: supabase.User(
                id: testUser.id,
                appMetadata: testUser.appMetadata ?? {},
                userMetadata: testUser.userMetadata ?? {},
                aud: 'authenticated',
                createdAt: testUser.createdAt.toIso8601String(),
                email: testUser.email,
              ),
            ),
          );

          when(
            mockSessionManager.startSession(
              accessToken: 'test-token-$i',
              refreshToken: '',
              user: testUser,
              userProfile: testProfile,
            ),
          ).thenAnswer((_) async => const Right(null));

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
              isA<AuthAuthenticated>(),
            ]),
          );
          testBloc.add(AuthSocialLoginRequested(provider));
          await expectation;

          // Verify final state is authenticated
          expect(testBloc.state, isA<AuthAuthenticated>());
          final authState = testBloc.state as AuthAuthenticated;

          // Property: Existing users should navigate directly to main screen
          expect(
            authState.user.id,
            equals(testUser.id),
            reason:
                'Iteration $i: User should be authenticated with correct ID',
          );
          expect(
            authState.profile,
            isNotNull,
            reason: 'Iteration $i: Profile should be loaded for existing user',
          );
          expect(
            authState.profile!.id,
            equals(testProfile.id),
            reason: 'Iteration $i: Profile should match the existing user',
          );

          // Property: Session should be established
          verify(
            mockSessionManager.startSession(
              accessToken: 'test-token-$i',
              refreshToken: '',
              user: testUser,
              userProfile: testProfile,
            ),
          ).called(1);

          await testBloc.close();
        }
      },
    );

    test(
      'Property 5 Extended: Existing User Profile Data Integrity',
      () async {
        // Extended property test to verify profile data integrity for existing
        // users
        const iterations = 100;
        final providers = ['google', 'apple'];
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          final provider = providers[random.nextInt(providers.length)];
          final isGoogle = provider == 'google';

          // Generate random existing user data
          final displayName = 'User ${random.nextInt(1000)}';
          final currency = ['VND', 'USD', 'EUR'][random.nextInt(3)];
          final language = ['vi', 'en', 'es'][random.nextInt(3)];

          final testUser = User(
            id: 'user-$i',
            email: 'user$i@example.com',
            createdAt: DateTime.now(),
            appMetadata: {
              'providers': [provider],
            },
            userMetadata: {'full_name': displayName},
          );

          final testProfile = UserProfile(
            id: testUser.id,
            email: testUser.email,
            displayName: displayName,
            preferredCurrency: currency,
            languageCode: language,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Mock OAuth success
          if (isGoogle) {
            when(mockSocialAuthRepository.signInWithGoogle()).thenAnswer(
              (_) async => Right(testUser),
            );
          } else {
            when(mockSocialAuthRepository.signInWithApple()).thenAnswer(
              (_) async => Right(testUser),
            );
          }

          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));

          when(mockAuthRepository.currentSession).thenReturn(
            supabase.Session(
              accessToken: 'token-$i',
              tokenType: 'bearer',
              user: supabase.User(
                id: testUser.id,
                appMetadata: testUser.appMetadata ?? {},
                userMetadata: testUser.userMetadata ?? {},
                aud: 'authenticated',
                createdAt: testUser.createdAt.toIso8601String(),
                email: testUser.email,
              ),
            ),
          );

          when(
            mockSessionManager.startSession(
              accessToken: 'token-$i',
              refreshToken: '',
              user: testUser,
              userProfile: testProfile,
            ),
          ).thenAnswer((_) async => const Right(null));

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

          // Verify profile data integrity
          expect(testBloc.state, isA<AuthAuthenticated>());
          final authState = testBloc.state as AuthAuthenticated;

          // Property: All profile data should be preserved
          expect(
            authState.profile!.displayName,
            equals(displayName),
            reason: 'Iteration $i: Display name should be preserved',
          );
          expect(
            authState.profile!.preferredCurrency,
            equals(currency),
            reason: 'Iteration $i: Currency should be preserved',
          );
          expect(
            authState.profile!.languageCode,
            equals(language),
            reason: 'Iteration $i: Language should be preserved',
          );
          expect(
            authState.profile!.email,
            equals(testUser.email),
            reason: 'Iteration $i: Email should match user email',
          );

          await testBloc.close();
        }
      },
    );

    test(
      'Property 5 Session Management: Existing Users Get Valid Sessions',
      () async {
        // Test that existing users get properly configured sessions
        const iterations = 100;
        final providers = ['google', 'apple'];
        final random = Random();

        for (var i = 0; i < iterations; i++) {
          final provider = providers[random.nextInt(providers.length)];
          final isGoogle = provider == 'google';

          final testUser = User(
            id: 'session-user-$i',
            email: 'session$i@example.com',
            createdAt: DateTime.now(),
            appMetadata: {
              'providers': [provider],
            },
          );

          final testProfile = UserProfile(
            id: testUser.id,
            email: testUser.email,
            displayName: 'Session User $i',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Mock OAuth success
          if (isGoogle) {
            when(mockSocialAuthRepository.signInWithGoogle()).thenAnswer(
              (_) async => Right(testUser),
            );
          } else {
            when(mockSocialAuthRepository.signInWithApple()).thenAnswer(
              (_) async => Right(testUser),
            );
          }

          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));

          // Mock session with specific tokens
          final accessToken = 'access-token-$i';
          final refreshToken = 'refresh-token-$i';
          when(mockAuthRepository.currentSession).thenReturn(
            supabase.Session(
              accessToken: accessToken,
              tokenType: 'bearer',
              refreshToken: refreshToken,
              user: supabase.User(
                id: testUser.id,
                appMetadata: testUser.appMetadata ?? {},
                userMetadata: testUser.userMetadata ?? {},
                aud: 'authenticated',
                createdAt: testUser.createdAt.toIso8601String(),
                email: testUser.email,
              ),
            ),
          );

          when(
            mockSessionManager.startSession(
              accessToken: accessToken,
              refreshToken: refreshToken,
              user: testUser,
              userProfile: testProfile,
            ),
          ).thenAnswer((_) async => const Right(null));

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

          // Property: Session should be started with correct parameters
          verify(
            mockSessionManager.startSession(
              accessToken: accessToken,
              refreshToken: refreshToken,
              user: testUser,
              userProfile: testProfile,
            ),
          ).called(1);

          await testBloc.close();
        }
      },
    );
  });
}
