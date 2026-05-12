import 'dart:async';

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

import 'auth_bloc_account_linking_property_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
  SocialAuthRepository,
  SessionManager,
  AuthDeepLinkHandler,
  SocialLoginAnalytics,
])
void main() {
  group('AuthBloc Account Linking Property Tests', () {
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
      when(mockAuthRepository.currentUser).thenReturn(
        User(
          id: 'default-current-user',
          email: 'current@example.com',
          createdAt: DateTime.now(),
        ),
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

    tearDown(() {
      unawaited(authBloc.close());
    });

    test(
      'Property 14: Email Matching Detects Account Linking',
      () async {
        // Feature: social-login, Property 14: Email Matching Detects Account
        // Linking
        // Validates: Requirements 5.1
        // Test with 100+ iterations with matching emails
        // Verify account linking scenario detected
        // Verify correct state emitted

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
              final sharedEmail = 'shared$i@example.com';
              final newUserId = 'new-user-$i';
              final existingUserId = 'existing-user-$i';

              // New OAuth user
              final newOAuthUser = User(
                id: newUserId,
                email: sharedEmail,
                createdAt: DateTime.now(),
                appMetadata: {
                  'providers': [provider.name],
                },
                userMetadata: {'full_name': 'New OAuth User $i'},
              );

              // Existing user profile with same email
              final existingProfile = UserProfile(
                id: existingUserId,
                email: sharedEmail,
                displayName: 'Existing User $i',
                preferredCurrency: 'VND',
                languageCode: 'vi',
                createdAt: DateTime.now().subtract(const Duration(days: 30)),
                updatedAt: DateTime.now(),
              );

              // Setup OAuth success
              when(
                provider == SocialAuthProvider.google
                    ? mockSocialAuthRepository.signInWithGoogle()
                    : mockSocialAuthRepository.signInWithApple(),
              ).thenAnswer((_) async => Right(newOAuthUser));

              // New user doesn't have profile yet
              when(
                mockUserRepository.getUserProfile(newUserId),
              ).thenAnswer((_) async => const Left(UserNotFoundFailure()));

              // But email matches existing profile
              when(
                mockUserRepository.getUserProfileByEmail(sharedEmail),
              ).thenAnswer((_) async => Right(existingProfile));

              final states = <AuthState>[];
              final subscription = testBloc.stream.listen(states.add);

              testBloc.add(AuthSocialLoginRequested(provider.name));
              await Future<void>.delayed(const Duration(milliseconds: 100));

              // Verify account linking scenario was detected
              expect(states.length, greaterThanOrEqualTo(2));
              expect(states[0], isA<AuthSocialLoginInProgress>());
              expect(states[1], isA<AuthAccountLinkingRequired>());

              // Verify correct data in linking state
              final linkingState = states[1] as AuthAccountLinkingRequired;
              expect(linkingState.newUser.id, equals(newUserId));
              expect(linkingState.newUser.email, equals(sharedEmail));
              expect(linkingState.existingProfile.id, equals(existingUserId));
              expect(linkingState.existingProfile.email, equals(sharedEmail));
              expect(linkingState.provider, equals(provider));

              // Verify both profile checks were performed
              verify(mockUserRepository.getUserProfile(newUserId)).called(1);
              verify(
                mockUserRepository.getUserProfileByEmail(sharedEmail),
              ).called(1);

              await subscription.cancel();
            } finally {
              unawaited(testBloc.close());
            }
          }
        }
      },
    );

    test(
      'Property 16: Confirmed Linking Connects OAuth Provider',
      () async {
        // Feature: social-login, Property 16: Confirmed Linking Connects OAuth
        // Provider
        // Validates: Requirements 5.3
        // Test with 100+ iterations
        // Verify OAuth provider linked to existing profile
        // Verify linking operation called

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
              final sharedEmail = 'linking$i@example.com';
              final existingUserId = 'existing-$i';

              final existingProfile = UserProfile(
                id: existingUserId,
                email: sharedEmail,
                displayName: 'Existing User $i',
                preferredCurrency: 'USD',
                languageCode: 'en',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              // Setup linking state
              final linkingState = AuthAccountLinkingRequired(
                newUser: User(
                  id: 'new-$i',
                  email: sharedEmail,
                  createdAt: DateTime.now(),
                  appMetadata: {
                    'providers': [provider.name],
                  },
                ),
                existingProfile: existingProfile,
                provider: provider,
              );

              testBloc.emit(linkingState);

              // Setup successful linking
              when(
                mockSocialAuthRepository.linkSocialProvider(
                  userId: existingUserId,
                  provider: provider,
                ),
              ).thenAnswer((_) async => const Right(null));
              when(
                mockUserRepository.getUserProfile(existingUserId),
              ).thenAnswer((_) async => Right(existingProfile));
              when(mockAuthRepository.currentSession).thenReturn(
                supabase.Session(
                  accessToken: 'linked-token-$i',
                  tokenType: 'bearer',
                  user: supabase.User(
                    id: existingUserId,
                    appMetadata: {},
                    userMetadata: {},
                    aud: 'authenticated',
                    createdAt: DateTime.now().toIso8601String(),
                    email: sharedEmail,
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

              final states = <AuthState>[];
              final subscription = testBloc.stream.listen(states.add);

              testBloc.add(AuthAccountLinkingConfirmed(existingUserId));
              await Future<void>.delayed(const Duration(milliseconds: 100));

              // Verify linking operation was called
              verify(
                mockSocialAuthRepository.linkSocialProvider(
                  userId: anyNamed('userId'),
                  provider: provider,
                ),
              ).called(1);

              // Verify successful authentication
              expect(states.length, greaterThanOrEqualTo(2));
              expect(states[0], isA<AuthLoading>());
              expect(states[1], isA<AuthAuthenticated>());

              // Verify session started with existing profile
              verify(
                mockSessionManager.startSession(
                  accessToken: anyNamed('accessToken'),
                  refreshToken: anyNamed('refreshToken'),
                  user: anyNamed('user'),
                  userProfile: anyNamed('userProfile'),
                ),
              ).called(1);

              await subscription.cancel();
            } finally {
              unawaited(testBloc.close());
            }
          }
        }
      },
    );

    test(
      'Property 17: Declined Linking Initiates New Account Flow',
      () async {
        // Feature: social-login, Property 17: Declined Linking Initiates New
        // Account Flow
        // Validates: Requirements 5.4
        // Test with 100+ iterations
        // Verify profile setup flow initiated
        // Verify treated as new account

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
              final sharedEmail = 'declined$i@example.com';
              final newUserId = 'new-declined-$i';
              final existingUserId = 'existing-declined-$i';

              final newUser = User(
                id: newUserId,
                email: sharedEmail,
                createdAt: DateTime.now(),
                appMetadata: {
                  'providers': [provider.name],
                },
                userMetadata: {'full_name': 'New User $i'},
              );

              final existingProfile = UserProfile(
                id: existingUserId,
                email: sharedEmail,
                displayName: 'Existing User $i',
                preferredCurrency: 'VND',
                languageCode: 'vi',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              // Setup linking state
              final linkingState = AuthAccountLinkingRequired(
                newUser: newUser,
                existingProfile: existingProfile,
                provider: provider,
              );

              testBloc.emit(linkingState);

              final states = <AuthState>[];
              final subscription = testBloc.stream.listen(states.add);

              testBloc.add(const AuthAccountLinkingDeclined());
              await Future<void>.delayed(const Duration(milliseconds: 100));

              // Verify profile setup flow initiated
              expect(states.length, greaterThanOrEqualTo(1));
              expect(states[0], isA<AuthProfileSetupRequired>());

              // Verify treated as new account (uses new user data)
              final profileSetupState = states[0] as AuthProfileSetupRequired;
              expect(profileSetupState.user.id, equals(newUserId));
              expect(profileSetupState.user.email, equals(sharedEmail));
              expect(profileSetupState.provider, equals(provider));
              expect(profileSetupState.displayName, equals('New User $i'));

              await subscription.cancel();
            } finally {
              unawaited(testBloc.close());
            }
          }
        }
      },
    );

    test(
      'Property 18: Successful Linking Uses Existing Profile',
      () async {
        // Feature: social-login, Property 18: Successful Linking Uses Existing
        // Profile
        // Validates: Requirements 5.5
        // Test with 100+ iterations
        // Verify authenticated session uses existing profile
        // Verify correct user data loaded

        const iterations = 100;

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
            final sharedEmail = 'success$i@example.com';
            final existingUserId = 'existing-success-$i';

            final existingProfile = UserProfile(
              id: existingUserId,
              email: sharedEmail,
              displayName: 'Existing Success User $i',
              preferredCurrency: 'EUR',
              languageCode: 'es',
              createdAt: DateTime.now().subtract(const Duration(days: 60)),
              updatedAt: DateTime.now(),
            );

            // Setup successful linking
            when(
              mockSocialAuthRepository.linkSocialProvider(
                userId: existingUserId,
                provider: SocialAuthProvider.google,
              ),
            ).thenAnswer((_) async => const Right(null));
            when(
              mockUserRepository.getUserProfile(existingUserId),
            ).thenAnswer((_) async => Right(existingProfile));
            when(mockAuthRepository.currentUser).thenReturn(
              User(
                id: existingUserId,
                email: sharedEmail,
                createdAt: DateTime.now(),
              ),
            );
            when(mockAuthRepository.currentSession).thenReturn(
              supabase.Session(
                accessToken: 'success-token-$i',
                tokenType: 'bearer',
                user: supabase.User(
                  id: existingUserId,
                  appMetadata: {},
                  userMetadata: {},
                  aud: 'authenticated',
                  createdAt: DateTime.now().toIso8601String(),
                  email: sharedEmail,
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

            // Setup linking state
            final linkingState = AuthAccountLinkingRequired(
              newUser: User(
                id: 'new-temp-$i',
                email: sharedEmail,
                createdAt: DateTime.now(),
                appMetadata: const {
                  'providers': ['google'],
                },
              ),
              existingProfile: existingProfile,
              provider: SocialAuthProvider.google,
            );

            testBloc.emit(linkingState);

            final states = <AuthState>[];
            final subscription = testBloc.stream.listen(states.add);

            testBloc.add(AuthAccountLinkingConfirmed(existingUserId));
            await Future<void>.delayed(const Duration(milliseconds: 100));

            // Verify authenticated session uses existing profile
            expect(states.length, greaterThanOrEqualTo(2));
            expect(states[1], isA<AuthAuthenticated>());

            final authenticatedState = states[1] as AuthAuthenticated;
            expect(authenticatedState.user.id, equals(existingUserId));
            expect(authenticatedState.profile?.id, equals(existingUserId));
            expect(
              authenticatedState.profile?.displayName,
              equals('Existing Success User $i'),
            );
            expect(
              authenticatedState.profile?.preferredCurrency,
              equals('EUR'),
            );
            expect(authenticatedState.profile?.languageCode, equals('es'));

            // Verify session started with correct data
            verify(
              mockSessionManager.startSession(
                accessToken: anyNamed('accessToken'),
                refreshToken: anyNamed('refreshToken'),
                user: anyNamed('user'),
                userProfile: anyNamed('userProfile'),
              ),
            ).called(1);

            await subscription.cancel();
          } finally {
            unawaited(testBloc.close());
          }
        }
      },
    );
  });
}
