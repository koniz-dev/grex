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
    // Refresh on user changes (login/logout/register) and on hasProfile
    // transitions so the orphan-session redirect kicks in once the
    // async profile-existence check resolves.
    if (previous?.user != next.user ||
        previous?.hasProfile != next.hasProfile) {
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
      // `hasProfile` is `null` while the existence check is still in flight,
      // `true` if a public.users row exists, `false` if the user is an
      // orphan (e.g. social-login user who never finished setup).
      final needsProfileSetup =
          isAuthenticated && authState.hasProfile == false;

      final isLoggingIn = state.uri.path == AppRoutes.login;
      final isRegistering = state.uri.path == AppRoutes.register;
      final isForgotPassword = state.uri.path == AppRoutes.forgotPassword;
      final isEmailVerification = state.uri.path == AppRoutes.emailVerification;
      final isProfileSetup = state.uri.path == AppRoutes.profileSetup;

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

      // 3. Authenticated + verified but no profile row yet: park them on
      // the profile-setup page until they complete it. Skip this redirect
      // while on auth routes (login flow already routes via BlocListener
      // with the right `extra` payload).
      if (needsProfileSetup && !isProfileSetup && !isAuthRoute) {
        return AppRoutes.profileSetup;
      }

      // 4. If authenticated AND verified, and on an auth route,
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
