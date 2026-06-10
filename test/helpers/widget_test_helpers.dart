import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/app_routes.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:grex/features/auth/domain/entities/user.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/screens/auth_screen_wrappers.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:mockito/mockito.dart';

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
    redirect: (context, state) {
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
    // Force Vietnamese — widget tests assert Vietnamese copy. Without this,
    // tests on machines with non-Vietnamese system locale fail.
    locale: const Locale('vi'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
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
    // Default stubs so AuthBloc construction doesn't throw on unstubbed
    // getters (authStateChanges, currentUser, currentSession). Individual
    // tests can override these afterwards if they need different values.
    when(mockAuthRepository.authStateChanges).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(mockAuthRepository.currentUser).thenReturn(null);
    when(mockAuthRepository.currentSession).thenReturn(null);

    // Default stubs for the auth methods that tests may dispatch through the
    // form (signInWithEmail, signUpWithEmail, resetPassword). Returning a
    // pending Completer-future lets the in-flight loading UI render without
    // the test having to resolve real authentication.
    //
    // Completers are tracked so we can resolve them in addTearDown — otherwise
    // `bloc.close()` would block forever waiting on the in-flight handler that
    // is awaiting an unresolved future, hanging the test runner.
    final pendingCompleters = <Completer<dynamic>>[];
    Future<Either<AuthFailure, User>> pendingUserResult() {
      final c = Completer<Either<AuthFailure, User>>();
      pendingCompleters.add(c);
      return c.future;
    }

    Future<Either<AuthFailure, void>> pendingVoidResult() {
      final c = Completer<Either<AuthFailure, void>>();
      pendingCompleters.add(c);
      return c.future;
    }

    when(
      mockAuthRepository.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    ).thenAnswer((_) => pendingUserResult());
    when(
      mockAuthRepository.signUpWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
        displayName: anyNamed('displayName'),
        preferredCurrency: anyNamed('preferredCurrency'),
        languageCode: anyNamed('languageCode'),
      ),
    ).thenAnswer((_) => pendingUserResult());
    when(
      mockAuthRepository.resetPassword(email: anyNamed('email')),
    ).thenAnswer((_) => pendingVoidResult());

    // Create session manager with mocked dependencies
    final sessionManager = SessionManager(
      sessionService: mockSessionService,
    );

    // Create mock dependencies for social login
    final mockSocialAuthRepository = MockSocialAuthRepository();
    when(
      mockSocialAuthRepository.signInWithGoogle(),
    ).thenAnswer((_) => pendingUserResult());
    when(
      mockSocialAuthRepository.signInWithApple(),
    ).thenAnswer((_) => pendingUserResult());

    final mockAuthDeepLinkHandler = MockAuthDeepLinkHandler();
    final mockSocialLoginAnalytics = MockSocialLoginAnalytics();
    when(
      mockAuthDeepLinkHandler.initialize(),
    ).thenAnswer((_) async {});

    // Create AuthBloc with mocked dependencies
    final authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      userRepository: mockUserRepository,
      sessionManager: sessionManager,
      socialAuthRepository: mockSocialAuthRepository,
      deepLinkHandler: mockAuthDeepLinkHandler,
      analytics: mockSocialLoginAnalytics,
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

    // Wrap in a GoRouter so navigation extensions (`context.go(...)`) used
    // inside pages don't throw "No GoRouter found in context". To keep the
    // test scope on the widget under test, every route — including ones a
    // tapped link would navigate to — renders the same widget. This lets
    // navigation tests verify "tap didn't throw" without losing the widget
    // under test from the tree after `pumpAndSettle()`.
    Widget rootBuilder(BuildContext context, GoRouterState state) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<ProfileBloc>.value(value: profileBloc),
        ],
        child: widget,
      );
    }

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: rootBuilder),
        GoRoute(path: AppRoutes.login, builder: rootBuilder),
        GoRoute(path: AppRoutes.register, builder: rootBuilder),
        GoRoute(path: AppRoutes.forgotPassword, builder: rootBuilder),
        GoRoute(path: AppRoutes.emailVerification, builder: rootBuilder),
        GoRoute(path: AppRoutes.home, builder: rootBuilder),
      ],
    );

    await pumpWidget(
      MaterialApp.router(
        // Force Vietnamese — existing widget tests assert against Vietnamese
        // copy. Without forcing, Flutter test env falls back to the device's
        // locale which is typically en and breaks every test.
        locale: const Locale('vi'),
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    // Clean up. We don't await `bloc.close()` here: if a test left an event
    // handler awaiting a pending mock future (e.g., the loading-state tests),
    // close() blocks the runner. Firing close() without awaiting lets the
    // test runner move on; outstanding microtasks will be discarded once the
    // test zone tears down.
    addTearDown(() {
      for (final c in pendingCompleters) {
        if (!c.isCompleted) {
          c.completeError(StateError('test teardown'));
        }
      }
      unawaited(authBloc.close());
      unawaited(profileBloc.close());
      sessionManager.dispose();
    });
  }
}
