import 'package:dartz/dartz.dart';
import 'package:grex/features/auth/data/handlers/auth_deep_link_handler.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/social_auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/features/auth/domain/services/email_verification_service.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:grex/features/auth/domain/services/social_login_analytics.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'test_helpers.mocks.dart';

/// Generate mocks for testing
@GenerateMocks([
  AuthRepository,
  UserRepository,
  SessionService,
  SessionManager,
  EmailVerificationService,
  SocialAuthRepository,
  AuthDeepLinkHandler,
  SocialLoginAnalytics,
])
void main() {}

/// Test dependencies container
/// This class is used by setupTestDependencies() and exported for use in test
/// files
// ignore: unreachable_from_main
class TestDependencies {
  TestDependencies._();
  // Fields are initialized and used by setupTestDependencies() function
  // Field is assigned in setupTestDependencies() but linter doesn't detect it
  // ignore: unreachable_from_main
  late MockAuthRepository mockAuthRepository;
  // Field is assigned in setupTestDependencies() but linter doesn't detect it
  // ignore: unreachable_from_main
  late MockUserRepository mockUserRepository;
  // Field is assigned in setupTestDependencies() but linter doesn't detect it
  // ignore: unreachable_from_main
  late MockSessionService mockSessionService;
  // Field is assigned in setupTestDependencies() but linter doesn't detect it
  // ignore: unreachable_from_main
  late MockSocialAuthRepository mockSocialAuthRepository;
  // Field is assigned in setupTestDependencies() but linter doesn't detect it
  // ignore: unreachable_from_main
  late MockAuthDeepLinkHandler mockAuthDeepLinkHandler;
  // Field is assigned in setupTestDependencies() but linter doesn't detect it
  // ignore: unreachable_from_main
  late MockSocialLoginAnalytics mockSocialLoginAnalytics;
  // Field is assigned in setupTestDependencies() but linter doesn't detect it
  // ignore: unreachable_from_main
  late SessionManager sessionManager;
  // Field is assigned in setupTestDependencies() but linter doesn't detect it
  // ignore: unreachable_from_main
  late AuthBloc authBloc;
  // Field is assigned in setupTestDependencies() but linter doesn't detect it
  // ignore: unreachable_from_main
  late ProfileBloc profileBloc;

  // Method is called by test files in tearDown but linter doesn't detect it
  // ignore: unreachable_from_main
  Future<void> dispose() async {
    await authBloc.close();
    await profileBloc.close();
    sessionManager.dispose();
  }
}

/// Setup test dependencies with mocks
/// Function is called by test files but linter doesn't detect it
// ignore: unreachable_from_main
TestDependencies setupTestDependencies() {
  final deps = TestDependencies._()
    // Create mocks
    ..mockAuthRepository = MockAuthRepository()
    ..mockUserRepository = MockUserRepository()
    ..mockSessionService = MockSessionService()
    ..mockSocialAuthRepository = MockSocialAuthRepository()
    ..mockAuthDeepLinkHandler = MockAuthDeepLinkHandler()
    ..mockSocialLoginAnalytics = MockSocialLoginAnalytics();

  // Default stubs so unstubbed calls during bloc construction don't throw
  // MissingStubError. Tests override these as needed.
  when(deps.mockAuthRepository.authStateChanges).thenAnswer(
    (_) => const Stream.empty(),
  );
  when(deps.mockAuthRepository.currentUser).thenReturn(null);
  when(deps.mockAuthRepository.currentSession).thenReturn(null);
  when(
    deps.mockAuthRepository.signOut(),
  ).thenAnswer((_) async => const Right(null));
  when(deps.mockAuthDeepLinkHandler.initialize()).thenAnswer((_) async {});
  when(
    deps.mockSessionService.clearSession(),
  ).thenAnswer((_) async => const Right(null));
  when(
    deps.mockSessionService.validateSession(),
  ).thenAnswer((_) async => const Right(true));

  // Create session manager with mocked dependencies
  deps.sessionManager = SessionManager(
    sessionService: deps.mockSessionService,
  );

  // Create mock session manager
  final mockSessionManager = MockSessionManager();

  // Default stubs for mock session manager so AuthBloc handlers that call
  // sessionManager.endSession / startSession don't throw MissingStubError.
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

  // Create BLoCs with mocked dependencies
  deps
    ..authBloc = AuthBloc(
      authRepository: deps.mockAuthRepository,
      userRepository: deps.mockUserRepository,
      sessionManager: mockSessionManager,
      socialAuthRepository: deps.mockSocialAuthRepository,
      deepLinkHandler: deps.mockAuthDeepLinkHandler,
      analytics: deps.mockSocialLoginAnalytics,
    )
    ..profileBloc = ProfileBloc(
      userRepository: deps.mockUserRepository,
      authRepository: deps.mockAuthRepository,
    );

  return deps;
}
