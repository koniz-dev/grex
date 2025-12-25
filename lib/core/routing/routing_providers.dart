import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/app_router.dart';
import 'package:grex/core/routing/app_routes.dart';
import 'package:grex/features/auth/presentation/providers/auth_provider.dart';

/// Provider for GoRouter instance
///
/// This provider creates a singleton instance of GoRouter that handles
/// all navigation throughout the application.
final goRouterProvider = Provider<GoRouter>((ref) {
  // Create a refresh notifier to trigger redirection when auth state changes
  final refreshNotifier = ValueNotifier<bool>(false);

  // Use ref.listen to update the refresh notifier when auth state changes
  ref.listen(authNotifierProvider, (previous, next) {
    // Only refresh if the user status or loading status actually changes
    // the logic
    if (previous?.user != next.user || previous?.isLoading != next.isLoading) {
      refreshNotifier.value = !refreshNotifier.value;
    }
  });

  return GoRouter(
    initialLocation: AppRoutes.groups,
    debugLogDiagnostics: true,
    routes: AppRouter.routes,
    errorBuilder: AppRouter.errorBuilder,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      final isAuthenticated = authState.user != null;
      final isEmailVerified = authState.user?.emailConfirmed ?? false;

      final isLoggingIn = state.uri.path == AppRoutes.login;
      final isRegistering = state.uri.path == AppRoutes.register;
      final isForgotPassword = state.uri.path == AppRoutes.forgotPassword;
      final isEmailVerification = state.uri.path == AppRoutes.emailVerification;

      final isAuthRoute =
          isLoggingIn ||
          isRegistering ||
          isForgotPassword ||
          isEmailVerification;

      // 1. If not authenticated and not on an auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // 2. If authenticated but NOT verified, they must be on the
      // verification page or a non-auth page that will redirect them there.
      if (isAuthenticated && !isEmailVerified) {
        // If they are on a main app route, send them to verification
        if (!isAuthRoute) {
          return AppRoutes.emailVerification;
        }
        // If they are on Login/Register/ForgotPw, keep them on verification
        // if they are already logged in (even if unverified)
        if (isLoggingIn || isRegistering || isForgotPassword) {
          return AppRoutes.emailVerification;
        }
        return null;
      }

      // 3. If authenticated AND verified, and on an auth route,
      // redirect to home
      if (isAuthenticated && isEmailVerified && isAuthRoute) {
        return AppRoutes.groups;
      }

      return null;
    },
  );
});

/// Provider for current route information
///
/// This provider watches the current route and provides route information
/// that can be used by other providers or widgets.
final currentRouteProvider = Provider<String>((ref) {
  // This would need to be implemented with a state notifier
  // to properly track route changes
  return '/';
});

/// Provider for navigation state
///
/// This provider can be used to track navigation state and provide
/// navigation-related functionality throughout the app.
final navigationStateProvider =
    NotifierProvider<NavigationStateNotifier, NavigationState>(
      NavigationStateNotifier.new,
    );

/// Navigation state class
class NavigationState {
  /// Creates a [NavigationState].
  const NavigationState({
    required this.currentRoute,
    required this.pathParameters,
    required this.queryParameters,
    required this.canPop,
  });

  /// The current route path.
  final String currentRoute;

  /// The path parameters of the current route.
  final Map<String, String> pathParameters;

  /// The query parameters of the current route.
  final Map<String, String> queryParameters;

  /// Whether the navigation stack can be popped.
  final bool canPop;

  /// Creates a copy of this state with the given fields replaced.
  NavigationState copyWith({
    String? currentRoute,
    Map<String, String>? pathParameters,
    Map<String, String>? queryParameters,
    bool? canPop,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      pathParameters: pathParameters ?? this.pathParameters,
      queryParameters: queryParameters ?? this.queryParameters,
      canPop: canPop ?? this.canPop,
    );
  }
}

/// Navigation state notifier
class NavigationStateNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return const NavigationState(
      currentRoute: '/',
      pathParameters: {},
      queryParameters: {},
      canPop: false,
    );
  }

  /// Updates the current route and its parameters.
  void updateRoute({
    required String route,
    Map<String, String>? pathParameters,
    Map<String, String>? queryParameters,
    bool? canPop,
  }) {
    state = state.copyWith(
      currentRoute: route,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      canPop: canPop,
    );
  }

  /// Updates the [canPop] state.
  void updateCanPop({required bool canPop}) {
    state = state.copyWith(canPop: canPop);
  }
}
