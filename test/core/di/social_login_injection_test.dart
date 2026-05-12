import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/core/performance/performance_service.dart';
import 'package:grex/features/auth/data/handlers/auth_deep_link_handler.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/social_auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/services/social_login_analytics.dart';
import 'package:grex/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock classes — must `implements <T>` for the constructor's typed
// parameters to accept the mock instance.
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSocialLoginAnalytics extends Mock implements SocialLoginAnalytics {}

class MockSocialAuthRepository extends Mock implements SocialAuthRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockSessionManager extends Mock implements SessionManager {}

class MockPerformanceService extends Mock implements PerformanceService {}

void main() {
  group('Social Login Dependency Injection', () {
    late GetIt getIt;

    setUp(() async {
      getIt = GetIt.instance;
      await getIt.reset();
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('SocialAuthRepository Registration', () {
      test('should register SocialAuthRepository as lazy singleton', () async {
        // Arrange
        final mockSupabaseClient = MockSupabaseClient();
        getIt
          ..registerLazySingleton<SupabaseClient>(() => mockSupabaseClient)
          ..registerLazySingleton<UserRepository>(MockUserRepository.new)
          ..registerLazySingleton<SocialAuthRepository>(
            MockSocialAuthRepository.new,
          );

        // Act
        final repository1 = getIt<SocialAuthRepository>();
        final repository2 = getIt<SocialAuthRepository>();

        // Assert
        expect(repository1, isA<SocialAuthRepository>());
        expect(repository1, same(repository2)); // Should be singleton
      });

      test('should resolve SocialAuthRepository with correct dependencies', () {
        // Arrange
        final mockSupabaseClient = MockSupabaseClient();
        getIt
          ..registerLazySingleton<SupabaseClient>(() => mockSupabaseClient)
          ..registerLazySingleton<UserRepository>(MockUserRepository.new)
          ..registerLazySingleton<SocialAuthRepository>(
            MockSocialAuthRepository.new,
          );

        // Act
        final repository = getIt<SocialAuthRepository>();

        // Assert
        expect(repository, isA<MockSocialAuthRepository>());
      });
    });

    group('AuthDeepLinkHandler Registration', () {
      test('should register AuthDeepLinkHandler as lazy singleton', () {
        // Arrange
        final mockPerformanceService = MockPerformanceService();
        getIt.registerLazySingleton<AuthDeepLinkHandler>(
          () => AuthDeepLinkHandler(
            onDeepLink: (uri) {
              // Mock callback
            },
            performanceService: mockPerformanceService,
          ),
        );

        // Act
        final handler1 = getIt<AuthDeepLinkHandler>();
        final handler2 = getIt<AuthDeepLinkHandler>();

        // Assert
        expect(handler1, isA<AuthDeepLinkHandler>());
        expect(handler1, same(handler2)); // Should be singleton
      });

      test('should configure onDeepLink callback correctly', () {
        // Arrange
        var callbackTriggered = false;
        final mockPerformanceService = MockPerformanceService();
        getIt.registerLazySingleton<AuthDeepLinkHandler>(
          () => AuthDeepLinkHandler(
            onDeepLink: (uri) {
              callbackTriggered = true;
            },
            performanceService: mockPerformanceService,
          ),
        );

        // Act
        final handler = getIt<AuthDeepLinkHandler>();
        // Simulate deep link callback (would normally be called by the handler)
        handler.onDeepLink(Uri.parse('io.supabase.grex://login-callback/'));

        // Assert
        expect(callbackTriggered, isTrue);
      });
    });

    group('SocialLoginAnalytics Registration', () {
      test('should register SocialLoginAnalytics as lazy singleton', () {
        // Arrange
        getIt.registerLazySingleton<SocialLoginAnalytics>(
          MockSocialLoginAnalytics.new,
        );

        // Act
        final analytics1 = getIt<SocialLoginAnalytics>();
        final analytics2 = getIt<SocialLoginAnalytics>();

        // Assert
        expect(analytics1, isA<SocialLoginAnalytics>());
        expect(analytics1, same(analytics2)); // Should be singleton
      });
    });

    group('AuthBloc Registration', () {
      test('should register AuthBloc with all required dependencies', () {
        // Arrange - Register all dependencies
        final mockSupabaseClient = MockSupabaseClient();
        final mockPerformanceService = MockPerformanceService();
        getIt
          ..registerLazySingleton<SupabaseClient>(() => mockSupabaseClient)
          ..registerLazySingleton<AuthRepository>(MockAuthRepository.new)
          ..registerLazySingleton<UserRepository>(MockUserRepository.new)
          ..registerLazySingleton<SessionManager>(MockSessionManager.new)
          ..registerLazySingleton<SocialAuthRepository>(
            MockSocialAuthRepository.new,
          )
          ..registerLazySingleton<AuthDeepLinkHandler>(
            () => AuthDeepLinkHandler(
              onDeepLink: (uri) {},
              performanceService: mockPerformanceService,
            ),
          )
          ..registerLazySingleton<SocialLoginAnalytics>(
            MockSocialLoginAnalytics.new,
          )
          ..registerLazySingleton<AuthBloc>(
            () => AuthBloc(
              authRepository: getIt<AuthRepository>(),
              userRepository: getIt<UserRepository>(),
              sessionManager: getIt<SessionManager>(),
              socialAuthRepository: getIt<SocialAuthRepository>(),
              deepLinkHandler: getIt<AuthDeepLinkHandler>(),
              analytics: getIt<SocialLoginAnalytics>(),
            ),
          );

        // Act
        final authBloc = getIt<AuthBloc>();

        // Assert
        expect(authBloc, isA<AuthBloc>());
      });

      test('should register AuthBloc as singleton', () {
        // Arrange - Register minimal dependencies
        final mockSupabaseClient = MockSupabaseClient();
        final mockPerformanceService = MockPerformanceService();
        getIt
          ..registerLazySingleton<SupabaseClient>(() => mockSupabaseClient)
          ..registerLazySingleton<AuthRepository>(MockAuthRepository.new)
          ..registerLazySingleton<UserRepository>(MockUserRepository.new)
          ..registerLazySingleton<SessionManager>(MockSessionManager.new)
          ..registerLazySingleton<SocialAuthRepository>(
            MockSocialAuthRepository.new,
          )
          ..registerLazySingleton<AuthDeepLinkHandler>(
            () => AuthDeepLinkHandler(
              onDeepLink: (uri) {},
              performanceService: mockPerformanceService,
            ),
          )
          ..registerLazySingleton<SocialLoginAnalytics>(
            MockSocialLoginAnalytics.new,
          )
          ..registerLazySingleton<AuthBloc>(
            () => AuthBloc(
              authRepository: getIt<AuthRepository>(),
              userRepository: getIt<UserRepository>(),
              sessionManager: getIt<SessionManager>(),
              socialAuthRepository: getIt<SocialAuthRepository>(),
              deepLinkHandler: getIt<AuthDeepLinkHandler>(),
              analytics: getIt<SocialLoginAnalytics>(),
            ),
          );

        // Act
        final authBloc1 = getIt<AuthBloc>();
        final authBloc2 = getIt<AuthBloc>();

        // Assert
        expect(authBloc1, same(authBloc2)); // Should be singleton
      });
    });

    group('Dependency Graph Validation', () {
      test('should have valid dependency graph for social login', () {
        // Arrange - Register all dependencies in correct order
        final mockSupabaseClient = MockSupabaseClient();
        final mockPerformanceService = MockPerformanceService();

        getIt
          // External dependencies
          ..registerLazySingleton<SupabaseClient>(() => mockSupabaseClient)
          // Core repositories
          ..registerLazySingleton<AuthRepository>(MockAuthRepository.new)
          ..registerLazySingleton<UserRepository>(MockUserRepository.new)
          ..registerLazySingleton<SessionManager>(MockSessionManager.new)
          // Social login dependencies
          ..registerLazySingleton<SocialAuthRepository>(
            MockSocialAuthRepository.new,
          )
          ..registerLazySingleton<SocialLoginAnalytics>(
            MockSocialLoginAnalytics.new,
          )
          ..registerLazySingleton<AuthDeepLinkHandler>(
            () => AuthDeepLinkHandler(
              onDeepLink: (uri) {},
              performanceService: mockPerformanceService,
            ),
          )
          // AuthBloc with all dependencies
          ..registerLazySingleton<AuthBloc>(
            () => AuthBloc(
              authRepository: getIt<AuthRepository>(),
              userRepository: getIt<UserRepository>(),
              sessionManager: getIt<SessionManager>(),
              socialAuthRepository: getIt<SocialAuthRepository>(),
              deepLinkHandler: getIt<AuthDeepLinkHandler>(),
              analytics: getIt<SocialLoginAnalytics>(),
            ),
          );

        // Act & Assert - Should not throw any exceptions
        expect(() => getIt<SocialAuthRepository>(), returnsNormally);
        expect(() => getIt<AuthDeepLinkHandler>(), returnsNormally);
        expect(() => getIt<SocialLoginAnalytics>(), returnsNormally);
        expect(() => getIt<AuthBloc>(), returnsNormally);
      });

      test('should fail gracefully when dependencies are missing', () {
        // Arrange - Register AuthBloc without dependencies
        getIt.registerLazySingleton<AuthBloc>(
          () => AuthBloc(
            authRepository: getIt<AuthRepository>(), // This will fail
            userRepository: getIt<UserRepository>(),
            sessionManager: getIt<SessionManager>(),
            socialAuthRepository: getIt<SocialAuthRepository>(),
            deepLinkHandler: getIt<AuthDeepLinkHandler>(),
            analytics: getIt<SocialLoginAnalytics>(),
          ),
        );

        // Act & Assert — GetIt throws StateError ("Object/factory with type X
        // is not registered") which is an Error, not an Exception.
        expect(
          () => getIt<AuthBloc>(),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
