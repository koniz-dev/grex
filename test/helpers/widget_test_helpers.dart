import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/app_routes.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/screens/auth_screen_wrappers.dart';

import 'test_helpers.dart';
import 'test_helpers.mocks.dart';

/// Creates a test router for widget testing
GoRouter createTestRouter(TestDependencies deps) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => BlocProvider.value(
          value: deps.authBloc,
          child: const LoginScreenWrapper(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => BlocProvider.value(
          value: deps.authBloc,
          child: const RegisterScreenWrapper(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: (context, state) => BlocProvider.value(
          value: deps.authBloc,
          child: const ForgotPasswordScreenWrapper(),
        ),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        name: AppRoutes.emailVerificationName,
        builder: (context, state) => BlocProvider.value(
          value: deps.authBloc,
          child: const EmailVerificationScreenWrapper(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profileName,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: deps.authBloc),
            BlocProvider.value(value: deps.profileBloc),
          ],
          child: const ProfileScreenWrapper(),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            name: AppRoutes.editProfileName,
            builder: (context, state) => BlocProvider.value(
              value: deps.profileBloc,
              child: const EditProfileScreenWrapper(),
            ),
          ),
        ],
      ),
      // Home route (mock)
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (context, state) => const MockHomePage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = deps.mockAuthRepository.currentUser != null;
      final isAuthRoute = _isAuthRoute(state.matchedLocation);
      final isProtectedRoute = _isProtectedRoute(state.matchedLocation);

      // Redirect to login if not authenticated and trying to access protected
      // route
      if (!isAuthenticated && isProtectedRoute) {
        return AppRoutes.login;
      }

      // Redirect to home if authenticated and trying to access auth routes
      // (except email verification which might be needed even when
      // authenticated)
      if (isAuthenticated &&
          isAuthRoute &&
          state.matchedLocation != AppRoutes.emailVerification) {
        return AppRoutes.home;
      }

      return null;
    },
  );
}

/// Creates a test app widget with the given router
Widget createTestApp({
  required GoRouter router,
  String? initialLocation,
}) {
  if (initialLocation != null) {
    router.go(initialLocation);
  }

  return MaterialApp.router(
    routerConfig: router,
    title: 'Grex Test',
  );
}

/// Mock home page for testing
class MockHomePage extends StatelessWidget {
  const MockHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Page'),
      ),
    );
  }
}

/// Helper function to check if a route is an authentication route
bool _isAuthRoute(String location) {
  return location == AppRoutes.login ||
      location == AppRoutes.register ||
      location == AppRoutes.forgotPassword ||
      location == AppRoutes.emailVerification;
}

/// Helper function to check if a route requires authentication
bool _isProtectedRoute(String location) {
  return !_isAuthRoute(location);
}

/// Extension to help with widget testing
extension WidgetTesterExtensions on WidgetTester {
  /// Pumps an auth widget with proper BLoC providers and MaterialApp wrapper
  Future<void> pumpAuthWidget(
    Widget widget, {
    required MockAuthRepository mockAuthRepository,
    required MockUserRepository mockUserRepository,
    required MockSessionService mockSessionService,
    AuthState? initialState,
  }) async {
    // Create session manager with mocked dependencies
    final sessionManager = SessionManager(
      sessionService: mockSessionService,
    );

    // Create AuthBloc with mocked dependencies
    final authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      userRepository: mockUserRepository,
      sessionManager: sessionManager,
    );

    // Create ProfileBloc with mocked dependencies
    final profileBloc = ProfileBloc(
      userRepository: mockUserRepository,
      authRepository: mockAuthRepository,
    );

    // If initial state is provided, emit it
    if (initialState != null) {
      authBloc.emit(initialState);
    }

    await pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ProfileBloc>.value(value: profileBloc),
          ],
          child: widget,
        ),
      ),
    );

    // Clean up
    addTearDown(() async {
      await authBloc.close();
      await profileBloc.close();
      sessionManager.dispose();
    });
  }
}
