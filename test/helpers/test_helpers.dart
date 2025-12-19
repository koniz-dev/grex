import 'package:grex/features/auth/domain/repositories/auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/features/auth/domain/services/email_verification_service.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:mockito/annotations.dart';

import 'test_helpers.mocks.dart';

/// Generate mocks for testing
@GenerateMocks([
  AuthRepository,
  UserRepository,
  SessionService,
  SessionManager,
  EmailVerificationService,
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
    ..mockSessionService = MockSessionService();

  // Create session manager with mocked dependencies
  deps.sessionManager = SessionManager(
    sessionService: deps.mockSessionService,
  );

  // Create mock session manager
  final mockSessionManager = MockSessionManager();

  // Create BLoCs with mocked dependencies
  deps
    ..authBloc = AuthBloc(
      authRepository: deps.mockAuthRepository,
      userRepository: deps.mockUserRepository,
      sessionManager: mockSessionManager,
    )
    ..profileBloc = ProfileBloc(
      userRepository: deps.mockUserRepository,
      authRepository: deps.mockAuthRepository,
    );

  return deps;
}
