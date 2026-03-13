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

import 'auth_bloc_new_user_navigation_property_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
  SocialAuthRepository,
  SessionManager,
  AuthDeepLinkHandler,
  SocialLoginAnalytics,
])
void main() {
  group('AuthBloc New User Navigation Property Tests', () {
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
      'Property 6: New Users Navigate to Profile Setup',
      () async {
        // Feature: social-login, Property 6: New Users Navigate to Profile
        // Setup
        // Validates: Requirements 1.6, 2.6, 4.2
        // Test with 100+ iterations for both providers
        // Verify navigation to profile setup
        // Verify profile setup state emitted

        const providers = [
          SocialAuthProvider.google,
          SocialAuthProvider.apple,
        ];
        const iterations = 100;

        for (final provider in providers) {
          for (var i = 0; i < iterations; i++) {
            // Create a new AuthBloc for each iteration to ensure clean state
            final testBloc = AuthBloc(
              authRepository: mockAuthRepository,
              userRepository: mockUserRepository,
              socialAuthRepository: mockSocialAuthRepository,
              sessionManager: mockSessionManager,
              deepLinkHandler: mockDeepLinkHandler,
              analytics: mockAnalytics,
            );

            try {
              // Generate test data for new user
              final newUser = User(
                id: 'new-user-$i',
                email: 'newuser$i@example.com',
                createdAt: DateTime.now(),
                appMetadata: const {
                  'providers': ['google'],
                },
                userMetadata: {'full_name': 'New User $i'},
              );

              // Setup mocks for new user scenario
              when(
                provider == SocialAuthProvider.google
                    ? mockSocialAuthRepository.signInWithGoogle()
                    : mockSocialAuthRepository.signInWithApple(),
              ).thenAnswer((_) async => Right(newUser));

              // User profile doesn't exist (new user)
              when(
                mockUserRepository.getUserProfile('new-user-$i'),
              ).thenAnswer((_) async => const Left(UserNotFoundFailure()));

              // Email doesn't exist (no account linking needed)
              when(
                mockUserRepository.getUserProfileByEmail(
                  'newuser$i@example.com',
                ),
              ).thenAnswer((_) async => const Right(null));

              // Test the social login flow
              final states = <AuthState>[];
              final subscription = testBloc.stream.listen(states.add);

              testBloc.add(AuthSocialLoginRequested(provider.name));

              // Wait for state changes
              await Future<void>.delayed(const Duration(milliseconds: 100));

              // Verify states
              expect(states.length, greaterThanOrEqualTo(2));
              expect(states[0], isA<AuthSocialLoginInProgress>());
              expect(states[1], isA<AuthProfileSetupRequired>());

              // Verify profile setup state contains correct data
              final profileSetupState = states[1] as AuthProfileSetupRequired;
              expect(profileSetupState.user.id, equals('new-user-$i'));
              expect(
                profileSetupState.user.email,
                equals('newuser$i@example.com'),
              );
              expect(profileSetupState.provider, equals(provider));
              expect(profileSetupState.displayName, equals('New User $i'));
              expect(profileSetupState.email, equals('newuser$i@example.com'));

              await subscription.cancel();
            } finally {
              await testBloc.close();
            }
          }
        }
      },
    );

    test(
      'Property 6 Extended: Profile Setup State Contains OAuth Data',
      () async {
        // Extended property test to verify OAuth data is properly passed to
        // profile setup
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
            // Generate varied OAuth data
            final displayNames = [
              'John Doe',
              'Jane Smith',
              'Test User',
              null, // Some OAuth providers don't provide display name
            ];
            final displayName = displayNames[i % displayNames.length];

            final newUser = User(
              id: 'oauth-user-$i',
              email: 'oauth$i@example.com',
              createdAt: DateTime.now(),
              appMetadata: const {
                'providers': ['google'],
              },
              userMetadata: displayName != null
                  ? {'full_name': displayName}
                  : {},
            );

            when(
              mockSocialAuthRepository.signInWithGoogle(),
            ).thenAnswer((_) async => Right(newUser));
            when(
              mockUserRepository.getUserProfile('oauth-user-$i'),
            ).thenAnswer((_) async => const Left(UserNotFoundFailure()));
            when(
              mockUserRepository.getUserProfileByEmail('oauth$i@example.com'),
            ).thenAnswer((_) async => const Right(null));

            final states = <AuthState>[];
            final subscription = testBloc.stream.listen(states.add);

            testBloc.add(const AuthSocialLoginRequested('google'));
            await Future<void>.delayed(const Duration(milliseconds: 100));

            expect(states.length, greaterThanOrEqualTo(2));
            expect(states[1], isA<AuthProfileSetupRequired>());

            final profileSetupState = states[1] as AuthProfileSetupRequired;
            expect(profileSetupState.email, equals('oauth$i@example.com'));
            expect(profileSetupState.displayName, equals(displayName));

            await subscription.cancel();
          } finally {
            await testBloc.close();
          }
        }
      },
    );

    test(
      'Property 6 Provider Consistency: Both Providers Navigate New Users to '
      'Setup',
      () async {
        // Test that both Google and Apple providers consistently navigate new
        // users to profile setup
        const iterations = 50;
        const providers = [
          SocialAuthProvider.google,
          SocialAuthProvider.apple,
        ];

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
              final newUser = User(
                id: 'provider-user-$i',
                email: 'provider$i@example.com',
                createdAt: DateTime.now(),
                appMetadata: {
                  'providers': [provider.name],
                },
                userMetadata: {'full_name': 'Provider User $i'},
              );

              when(
                provider == SocialAuthProvider.google
                    ? mockSocialAuthRepository.signInWithGoogle()
                    : mockSocialAuthRepository.signInWithApple(),
              ).thenAnswer((_) async => Right(newUser));
              when(
                mockUserRepository.getUserProfile('provider-user-$i'),
              ).thenAnswer((_) async => const Left(UserNotFoundFailure()));
              when(
                mockUserRepository.getUserProfileByEmail(
                  'provider$i@example.com',
                ),
              ).thenAnswer((_) async => const Right(null));

              final states = <AuthState>[];
              final subscription = testBloc.stream.listen(states.add);

              testBloc.add(AuthSocialLoginRequested(provider.name));
              await Future<void>.delayed(const Duration(milliseconds: 100));

              // Verify consistent behavior across providers
              expect(states.length, greaterThanOrEqualTo(2));
              expect(states[0], isA<AuthSocialLoginInProgress>());
              expect(
                (states[0] as AuthSocialLoginInProgress).provider,
                equals(provider),
              );
              expect(states[1], isA<AuthProfileSetupRequired>());
              expect(
                (states[1] as AuthProfileSetupRequired).provider,
                equals(provider),
              );

              await subscription.cancel();
            } finally {
              await testBloc.close();
            }
          }
        }
      },
    );
  });
}
