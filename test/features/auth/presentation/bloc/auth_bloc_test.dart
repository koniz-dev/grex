import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../helpers/test_helpers.mocks.dart';

class _FakeSession extends Fake implements supabase.Session {
  @override
  String get accessToken => 'test-access-token';

  @override
  String get refreshToken => 'test-refresh-token';
}

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
    when(mockAuthRepository.currentSession).thenReturn(null);
    when(mockAuthRepository.currentUser).thenReturn(null);

    final mockSessionManager = MockSessionManager();
    when(
      mockSessionManager.endSession(),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockSessionManager.startSession(
        accessToken: anyNamed('accessToken'),
        refreshToken: anyNamed('refreshToken'),
        user: anyNamed('user'),
        userProfile: anyNamed('userProfile'),
      ),
    ).thenAnswer((_) async => const Right(null));
    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      userRepository: mockUserRepository,
      sessionManager: mockSessionManager,
      analytics: MockSocialLoginAnalytics(),
      deepLinkHandler: MockAuthDeepLinkHandler(),
      socialAuthRepository: MockSocialAuthRepository(),
    );
  });

  tearDown(() async {
    await authBloc.close();
  });

  group('AuthBloc', () {
    final testUser = User(
      id: 'test-user-id',
      email: 'test@example.com',
      createdAt: DateTime.now(),
    );

    final testProfile = UserProfile(
      id: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
      preferredCurrency: 'VND',
      languageCode: 'vi',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    group('AuthLoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login succeeds',
        build: () {
          when(
            mockAuthRepository.signInWithEmail(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenAnswer((_) async => Right(testUser));

          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));

          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthLoginRequested(
            email: 'test@example.com',
            password: 'StrongPassword1!',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: testUser, profile: testProfile),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails',
        build: () {
          when(
            mockAuthRepository.signInWithEmail(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenAnswer(
            (_) async => const Left(
              InvalidCredentialsFailure(),
            ),
          );

          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthLoginRequested(
            email: 'test@example.com',
            password: 'WrongPassword1!',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            message: 'Invalid email or password. Please try again.',
            failure: InvalidCredentialsFailure(),
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthError] when email is invalid',
        build: () => authBloc,
        act: (bloc) => bloc.add(
          const AuthLoginRequested(
            email: 'invalid-email',
            password: 'StrongPassword1!',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Please enter a valid email address'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthError] when password is invalid',
        build: () => authBloc,
        act: (bloc) => bloc.add(
          const AuthLoginRequested(
            email: 'test@example.com',
            password: 'weak',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            message: 'Password must be at least 8 characters long',
          ),
        ],
      );
    });

    group('AuthRegisterRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when registration succeeds',
        build: () {
          when(
            mockAuthRepository.signUpWithEmail(
              email: anyNamed('email'),
              password: anyNamed('password'),
              displayName: anyNamed('displayName'),
              preferredCurrency: anyNamed('preferredCurrency'),
              languageCode: anyNamed('languageCode'),
            ),
          ).thenAnswer((_) async => Right(testUser));

          // Registration handler requires a session to emit AuthAuthenticated.
          when(mockAuthRepository.currentSession).thenReturn(_FakeSession());

          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));

          when(
            mockUserRepository.createUserProfile(any),
          ).thenAnswer((_) async => Right(testProfile));

          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthRegisterRequested(
            email: 'test@example.com',
            password: 'StrongPassword1!',
            displayName: 'Test User',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: testUser, profile: testProfile),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when registration fails',
        build: () {
          when(
            mockAuthRepository.signUpWithEmail(
              email: anyNamed('email'),
              password: anyNamed('password'),
              displayName: anyNamed('displayName'),
              preferredCurrency: anyNamed('preferredCurrency'),
              languageCode: anyNamed('languageCode'),
            ),
          ).thenAnswer(
            (_) async => const Left(
              EmailAlreadyInUseFailure(),
            ),
          );

          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthRegisterRequested(
            email: 'existing@example.com',
            password: 'StrongPassword1!',
            displayName: 'Test User',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            message:
                'This email is already registered. Please use a '
                'different email or try logging in.',
            failure: EmailAlreadyInUseFailure(),
          ),
        ],
      );
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when logout succeeds',
        build: () {
          when(
            mockAuthRepository.signOut(),
          ).thenAnswer((_) async => const Right(null));

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );
    });

    group('AuthSessionChecked', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is authenticated',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(testUser);
          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSessionChecked()),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(user: testUser, profile: testProfile),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when no user is '
        'authenticated',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(null);

          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSessionChecked()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );
    });

    group('AuthPasswordResetRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthPasswordResetSent] when password reset '
        'succeeds',
        build: () {
          when(
            mockAuthRepository.resetPassword(email: anyNamed('email')),
          ).thenAnswer((_) async => const Right(null));

          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthPasswordResetRequested(
            email: 'test@example.com',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthPasswordResetSent(email: 'test@example.com'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when password reset fails',
        build: () {
          when(
            mockAuthRepository.resetPassword(email: anyNamed('email')),
          ).thenAnswer(
            (_) async => const Left(
              NetworkFailure(),
            ),
          );

          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthPasswordResetRequested(
            email: 'test@example.com',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            message:
                'Network error. Please check your connection and try again.',
            failure: NetworkFailure(),
          ),
        ],
      );
    });
  });
}
