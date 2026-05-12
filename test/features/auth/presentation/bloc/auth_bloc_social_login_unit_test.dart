import 'dart:async';

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
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'auth_bloc_social_login_unit_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
  SocialAuthRepository,
  SessionManager,
  AuthDeepLinkHandler,
  SocialLoginAnalytics,
])
void main() {
  group('AuthBloc Social Login Unit Tests', () {
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

    tearDown(() {
      unawaited(authBloc.close());
    });

    group('Google Social Login', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthSocialLoginInProgress, AuthAuthenticated] when Google '
        'login succeeds for existing user',
        build: () {
          final testUser = User(
            id: 'test-user',
            email: 'test@example.com',
            createdAt: DateTime.now(),
            appMetadata: const {
              'providers': ['google'],
            },
          );

          final testProfile = UserProfile(
            id: 'test-user',
            email: 'test@example.com',
            displayName: 'Test User',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          when(mockSocialAuthRepository.signInWithGoogle()).thenAnswer(
            (_) async => Right(testUser),
          );
          when(mockUserRepository.getUserProfile('test-user')).thenAnswer(
            (_) async => Right(testProfile),
          );
          when(mockAuthRepository.currentSession).thenReturn(
            supabase.Session(
              accessToken: 'test-token',
              tokenType: 'bearer',
              user: supabase.User(
                id: 'test-user',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
                email: 'test@example.com',
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

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('google')),
        expect: () => [
          const AuthSocialLoginInProgress(SocialAuthProvider.google),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthSocialLoginInProgress, AuthProfileSetupRequired] when '
        'Google login succeeds for new user',
        build: () {
          final testUser = User(
            id: 'new-user',
            email: 'new@example.com',
            createdAt: DateTime.now(),
            appMetadata: const {
              'providers': ['google'],
            },
            userMetadata: const {'full_name': 'New User'},
          );

          when(mockSocialAuthRepository.signInWithGoogle()).thenAnswer(
            (_) async => Right(testUser),
          );
          when(mockUserRepository.getUserProfile('new-user')).thenAnswer(
            (_) async => const Left(UserNotFoundFailure()),
          );
          when(
            mockUserRepository.getUserProfileByEmail('new@example.com'),
          ).thenAnswer(
            (_) async => const Right(null),
          );

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('google')),
        expect: () => [
          const AuthSocialLoginInProgress(SocialAuthProvider.google),
          isA<AuthProfileSetupRequired>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthSocialLoginInProgress, AuthUnauthenticated] when Google '
        'login is cancelled',
        build: () {
          when(mockSocialAuthRepository.signInWithGoogle()).thenAnswer(
            (_) async => const Left(SocialAuthCancelledFailure()),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('google')),
        expect: () => [
          const AuthSocialLoginInProgress(SocialAuthProvider.google),
          const AuthUnauthenticated(),
        ],
      );
    });

    group('Apple Social Login', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthSocialLoginInProgress, AuthAuthenticated] when Apple '
        'login succeeds for existing user',
        build: () {
          final testUser = User(
            id: 'apple-user',
            email: 'apple@example.com',
            createdAt: DateTime.now(),
            appMetadata: const {
              'providers': ['apple'],
            },
          );

          final testProfile = UserProfile(
            id: 'apple-user',
            email: 'apple@example.com',
            displayName: 'Apple User',
            preferredCurrency: 'USD',
            languageCode: 'en',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          when(mockSocialAuthRepository.signInWithApple()).thenAnswer(
            (_) async => Right(testUser),
          );
          when(mockUserRepository.getUserProfile('apple-user')).thenAnswer(
            (_) async => Right(testProfile),
          );
          when(mockAuthRepository.currentSession).thenReturn(
            supabase.Session(
              accessToken: 'apple-token',
              tokenType: 'bearer',
              user: supabase.User(
                id: 'apple-user',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
                email: 'apple@example.com',
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

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('apple')),
        expect: () => [
          const AuthSocialLoginInProgress(SocialAuthProvider.apple),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthSocialLoginInProgress, AuthAccountLinkingRequired] when '
        'Apple login email matches existing profile',
        build: () {
          final testUser = User(
            id: 'apple-new-user',
            email: 'existing@example.com',
            createdAt: DateTime.now(),
            appMetadata: const {
              'providers': ['apple'],
            },
          );

          final existingProfile = UserProfile(
            id: 'existing-user',
            email: 'existing@example.com',
            displayName: 'Existing User',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          when(mockSocialAuthRepository.signInWithApple()).thenAnswer(
            (_) async => Right(testUser),
          );
          when(mockUserRepository.getUserProfile('apple-new-user')).thenAnswer(
            (_) async => const Left(UserNotFoundFailure()),
          );
          when(
            mockUserRepository.getUserProfileByEmail('existing@example.com'),
          ).thenAnswer(
            (_) async => Right(existingProfile),
          );

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('apple')),
        expect: () => [
          const AuthSocialLoginInProgress(SocialAuthProvider.apple),
          isA<AuthAccountLinkingRequired>(),
        ],
      );
    });

    group('Profile Setup Flow', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when profile setup is '
        'completed successfully',
        build: () {
          final testUser = User(
            id: 'setup-user',
            email: 'setup@example.com',
            createdAt: DateTime.now(),
            appMetadata: const {
              'providers': ['google'],
            },
          );

          final createdProfile = UserProfile(
            id: 'setup-user',
            email: 'setup@example.com',
            displayName: 'Setup User',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          when(mockAuthRepository.currentUser).thenReturn(testUser);
          when(
            mockSocialAuthRepository.createUserProfile(
              'setup-user',
              any,
            ),
          ).thenAnswer((_) async => Right(createdProfile));
          when(mockUserRepository.getUserProfile('setup-user')).thenAnswer(
            (_) async => Right(createdProfile),
          );
          when(mockAuthRepository.currentSession).thenReturn(
            supabase.Session(
              accessToken: 'setup-token',
              tokenType: 'bearer',
              user: supabase.User(
                id: 'setup-user',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
                email: 'setup@example.com',
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

          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthProfileSetupCompleted(
            displayName: 'Setup User',
            preferredCurrency: 'VND',
            languageCode: 'vi',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when profile setup is '
        'cancelled',
        build: () {
          when(
            mockSessionManager.endSession(),
          ).thenAnswer((_) async => const Right(null));
          when(mockAuthRepository.signOut()).thenAnswer(
            (_) async => const Right(null),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthProfileSetupCancelled()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );
    });

    group('Account Linking Flow', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when account linking is '
        'confirmed',
        build: () {
          final linkingState = AuthAccountLinkingRequired(
            newUser: User(
              id: 'new-user',
              email: 'link@example.com',
              createdAt: DateTime.now(),
              appMetadata: const {
                'providers': ['google'],
              },
            ),
            existingProfile: UserProfile(
              id: 'existing-user',
              email: 'link@example.com',
              displayName: 'Existing User',
              preferredCurrency: 'VND',
              languageCode: 'vi',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            provider: SocialAuthProvider.google,
          );

          // Set initial state
          authBloc.emit(linkingState);

          when(
            mockSocialAuthRepository.linkSocialProvider(
              userId: 'existing-user',
              provider: SocialAuthProvider.google,
            ),
          ).thenAnswer(
            (_) async => const Right(null),
          );
          when(mockUserRepository.getUserProfile('existing-user')).thenAnswer(
            (_) async => Right(linkingState.existingProfile),
          );
          when(mockAuthRepository.currentUser).thenReturn(linkingState.newUser);
          when(mockAuthRepository.currentSession).thenReturn(
            supabase.Session(
              accessToken: 'linked-token',
              tokenType: 'bearer',
              user: supabase.User(
                id: 'existing-user',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
                email: 'link@example.com',
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

          return authBloc;
        },
        act: (bloc) =>
            bloc.add(const AuthAccountLinkingConfirmed('existing-user')),
        expect: () => [
          const AuthLoading(),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthProfileSetupRequired] when account linking is '
        'declined',
        build: () {
          final linkingState = AuthAccountLinkingRequired(
            newUser: User(
              id: 'new-user',
              email: 'decline@example.com',
              createdAt: DateTime.now(),
              appMetadata: const {
                'providers': ['apple'],
              },
              userMetadata: const {'full_name': 'New User'},
            ),
            existingProfile: UserProfile(
              id: 'existing-user',
              email: 'decline@example.com',
              displayName: 'Existing User',
              preferredCurrency: 'USD',
              languageCode: 'en',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            provider: SocialAuthProvider.apple,
          );

          // Set initial state
          authBloc.emit(linkingState);

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthAccountLinkingDeclined()),
        expect: () => [
          isA<AuthProfileSetupRequired>(),
        ],
      );
    });

    group('Error Handling', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthSocialLoginInProgress, AuthError] when invalid provider '
        'is used',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('invalid')),
        expect: () => [
          isA<AuthError>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthSocialLoginInProgress, AuthError] when network error '
        'occurs',
        build: () {
          when(mockSocialAuthRepository.signInWithGoogle()).thenAnswer(
            (_) async => const Left(SocialAuthNetworkFailure()),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('google')),
        expect: () => [
          const AuthSocialLoginInProgress(SocialAuthProvider.google),
          isA<AuthError>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when profile setup fails',
        build: () {
          final testUser = User(
            id: 'fail-user',
            email: 'fail@example.com',
            createdAt: DateTime.now(),
          );

          when(mockAuthRepository.currentUser).thenReturn(testUser);
          when(
            mockSocialAuthRepository.createUserProfile(
              'fail-user',
              any,
            ),
          ).thenAnswer(
            (_) async =>
                const Left(GenericAuthFailure('Profile creation failed')),
          );

          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthProfileSetupCompleted(
            displayName: 'Fail User',
            preferredCurrency: 'VND',
            languageCode: 'vi',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>(),
        ],
      );
    });
  });
}
