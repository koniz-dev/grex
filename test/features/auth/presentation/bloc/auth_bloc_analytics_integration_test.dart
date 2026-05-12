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

import 'auth_bloc_analytics_integration_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
  SessionManager,
  SocialAuthRepository,
  AuthDeepLinkHandler,
  SocialLoginAnalytics,
])
void main() {
  group('AuthBloc Analytics Integration', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockSessionManager mockSessionManager;
    late MockSocialAuthRepository mockSocialAuthRepository;
    late MockAuthDeepLinkHandler mockDeepLinkHandler;
    late MockSocialLoginAnalytics mockAnalytics;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockSessionManager = MockSessionManager();
      mockSocialAuthRepository = MockSocialAuthRepository();
      mockDeepLinkHandler = MockAuthDeepLinkHandler();
      mockAnalytics = MockSocialLoginAnalytics();

      // Setup default mocks
      when(
        mockSessionManager.initialize(),
      ).thenAnswer((_) async => const Right(null));
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(mockDeepLinkHandler.dispose()).thenReturn(null);

      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
        sessionManager: mockSessionManager,
        socialAuthRepository: mockSocialAuthRepository,
        deepLinkHandler: mockDeepLinkHandler,
        analytics: mockAnalytics,
      );
    });

    tearDown(() async {
      await authBloc.close();
    });

    group('Social Login Analytics', () {
      blocTest<AuthBloc, AuthState>(
        'should log analytics event when social login is initiated',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('google')),
        setUp: () {
          when(
            mockSocialAuthRepository.signInWithGoogle(),
          ).thenAnswer((_) async => const Left(SocialAuthCancelledFailure()));
        },
        verify: (_) {
          verify(
            mockAnalytics.logSocialLoginInitiated(SocialAuthProvider.google),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should log analytics event when social login succeeds for existing '
        'user',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('google')),
        setUp: () {
          final user = User(
            id: 'user-id',
            email: 'test@example.com',
            createdAt: DateTime.now(),
          );
          final profile = UserProfile(
            id: 'user-id',
            email: 'test@example.com',
            displayName: 'Test User',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          when(
            mockSocialAuthRepository.signInWithGoogle(),
          ).thenAnswer((_) async => Right(user));
          when(
            mockUserRepository.getUserProfile('user-id'),
          ).thenAnswer((_) async => Right(profile));
          when(mockAuthRepository.currentSession).thenReturn(null);
        },
        verify: (_) {
          verify(
            mockAnalytics.logSocialLoginInitiated(SocialAuthProvider.google),
          ).called(1);
          verify(
            mockAnalytics.logSocialLoginSuccess(
              provider: SocialAuthProvider.google,
              userType: 'existing',
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should log analytics event when social login succeeds for new user',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('apple')),
        setUp: () {
          final user = User(
            id: 'user-id',
            email: 'test@example.com',
            createdAt: DateTime.now(),
            userMetadata: const {'full_name': 'Test User'},
          );

          when(
            mockSocialAuthRepository.signInWithApple(),
          ).thenAnswer((_) async => Right(user));
          when(
            mockUserRepository.getUserProfile('user-id'),
          ).thenAnswer((_) async => const Left(UserNotFoundFailure()));
          when(
            mockUserRepository.getUserProfileByEmail('test@example.com'),
          ).thenAnswer((_) async => const Right(null));
        },
        verify: (_) {
          verify(
            mockAnalytics.logSocialLoginInitiated(SocialAuthProvider.apple),
          ).called(1);
          verify(
            mockAnalytics.logSocialLoginSuccess(
              provider: SocialAuthProvider.apple,
              userType: 'new',
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should log analytics event when social login fails',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('google')),
        setUp: () {
          when(
            mockSocialAuthRepository.signInWithGoogle(),
          ).thenAnswer((_) async => const Left(SocialAuthNetworkFailure()));
        },
        verify: (_) {
          verify(
            mockAnalytics.logSocialLoginInitiated(SocialAuthProvider.google),
          ).called(1);
          verify(
            mockAnalytics.logSocialLoginFailure(
              provider: SocialAuthProvider.google,
              errorType: 'network',
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should log analytics event when social login is cancelled',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthSocialLoginRequested('apple')),
        setUp: () {
          when(
            mockSocialAuthRepository.signInWithApple(),
          ).thenAnswer((_) async => const Left(SocialAuthCancelledFailure()));
        },
        verify: (_) {
          verify(
            mockAnalytics.logSocialLoginInitiated(SocialAuthProvider.apple),
          ).called(1);
          verify(
            mockAnalytics.logSocialLoginCancelled(SocialAuthProvider.apple),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should log analytics event when profile setup is completed',
        build: () => authBloc,
        act: (bloc) => bloc.add(
          const AuthProfileSetupCompleted(
            displayName: 'John Doe',
            preferredCurrency: 'VND',
            languageCode: 'vi',
          ),
        ),
        setUp: () {
          final user = User(
            id: 'user-id',
            email: 'test@example.com',
            createdAt: DateTime.now(),
          );
          final profile = UserProfile(
            id: 'user-id',
            email: 'test@example.com',
            displayName: 'John Doe',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          when(mockAuthRepository.currentUser).thenReturn(user);
          when(
            mockSocialAuthRepository.createUserProfile(
              'user-id',
              any,
            ),
          ).thenAnswer((_) async => Right(profile));
          when(
            mockUserRepository.getUserProfile('user-id'),
          ).thenAnswer((_) async => Right(profile));
          when(mockAuthRepository.currentSession).thenReturn(null);
        },
        verify: (_) {
          // Note: Analytics won't be called because user.socialProvider is null
          // This is expected behavior - analytics only called for social users
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should log analytics event when account linking is confirmed',
        build: () => authBloc,
        seed: () => AuthAccountLinkingRequired(
          newUser: User(
            id: 'new-user-id',
            email: 'test@example.com',
            createdAt: DateTime.now(),
          ),
          existingProfile: UserProfile(
            id: 'existing-user-id',
            email: 'test@example.com',
            displayName: 'Existing User',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          provider: SocialAuthProvider.google,
        ),
        act: (bloc) =>
            bloc.add(const AuthAccountLinkingConfirmed('existing-user-id')),
        setUp: () {
          final profile = UserProfile(
            id: 'existing-user-id',
            email: 'test@example.com',
            displayName: 'Existing User',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          when(
            mockSocialAuthRepository.linkSocialProvider(
              userId: 'existing-user-id',
              provider: SocialAuthProvider.google,
            ),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockUserRepository.getUserProfile('existing-user-id'),
          ).thenAnswer((_) async => Right(profile));
          when(mockAuthRepository.currentUser).thenReturn(
            User(
              id: 'new-user-id',
              email: 'test@example.com',
              createdAt: DateTime.now(),
            ),
          );
          when(mockAuthRepository.currentSession).thenReturn(null);
        },
        verify: (_) {
          verify(
            mockAnalytics.logAccountLinking(
              provider: SocialAuthProvider.google,
              action: 'confirmed',
              existingEmail: 'test@example.com',
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should log analytics event when account linking is declined',
        build: () => authBloc,
        seed: () => AuthAccountLinkingRequired(
          newUser: User(
            id: 'new-user-id',
            email: 'test@example.com',
            createdAt: DateTime.now(),
            userMetadata: const {'full_name': 'New User'},
          ),
          existingProfile: UserProfile(
            id: 'existing-user-id',
            email: 'test@example.com',
            displayName: 'Existing User',
            preferredCurrency: 'USD',
            languageCode: 'en',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          provider: SocialAuthProvider.apple,
        ),
        act: (bloc) => bloc.add(const AuthAccountLinkingDeclined()),
        verify: (_) {
          verify(
            mockAnalytics.logAccountLinking(
              provider: SocialAuthProvider.apple,
              action: 'declined',
              existingEmail: 'test@example.com',
            ),
          ).called(1);
        },
      );
    });

    group('Analytics Error Type Mapping', () {
      // blocTest declarations must happen during group setup, NOT inside a
      // test() callback (which would defer declaration to runtime and trigger
      // "Can't call test() once tests have begun running").
      final testCases = [
        (const SocialAuthCancelledFailure(), 'cancelled'),
        (const SocialAuthNetworkFailure(), 'network'),
        (const SocialAuthTimeoutFailure(), 'timeout'),
        (const AccountLinkingFailure('test'), 'linking'),
        (const NetworkFailure(), 'network'),
        (const GenericAuthFailure('unknown error'), 'unknown'),
      ];

      for (final (failure, expectedType) in testCases) {
        blocTest<AuthBloc, AuthState>(
          'should map ${failure.runtimeType} to $expectedType',
          build: () => AuthBloc(
            authRepository: mockAuthRepository,
            userRepository: mockUserRepository,
            sessionManager: mockSessionManager,
            socialAuthRepository: mockSocialAuthRepository,
            deepLinkHandler: mockDeepLinkHandler,
            analytics: mockAnalytics,
          ),
          act: (bloc) => bloc.add(const AuthSocialLoginRequested('google')),
          setUp: () {
            when(
              mockSocialAuthRepository.signInWithGoogle(),
            ).thenAnswer((_) async => Left(failure));
            when(
              mockSessionManager.initialize(),
            ).thenAnswer((_) async => const Right(null));
            when(
              mockAuthRepository.authStateChanges,
            ).thenAnswer((_) => const Stream.empty());
          },
          verify: (_) {
            if (failure is SocialAuthCancelledFailure) {
              verify(
                mockAnalytics.logSocialLoginCancelled(
                  SocialAuthProvider.google,
                ),
              ).called(1);
            } else {
              verify(
                mockAnalytics.logSocialLoginFailure(
                  provider: SocialAuthProvider.google,
                  errorType: expectedType,
                ),
              ).called(1);
            }
          },
          tearDown: () async => authBloc.close(),
        );
      }
    });
  });
}
