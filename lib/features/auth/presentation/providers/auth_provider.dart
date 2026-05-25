import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/core/di/providers.dart';
import 'package:grex/core/utils/result.dart';
import 'package:grex/features/auth/domain/entities/user.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';

part 'auth_provider.freezed.dart';

/// Authentication state for routing and session management
///
/// This state is used by GoRouter's redirect logic and main() session
/// restore. It is NOT used by auth UI pages (which use AuthBloc instead).
@freezed
abstract class AuthState with _$AuthState {
  /// Creates an [AuthState].
  const factory AuthState({
    /// Currently authenticated user, null if not logged in
    User? user,

    /// Whether an authentication operation is in progress
    @Default(false) bool isLoading,

    /// Error message if authentication failed, null otherwise
    String? error,

    /// Tri-state profile existence flag. `null` = not checked yet (or no
    /// user); `true` = a row exists in `public.users` for this user;
    /// `false` = no profile row yet (social-login users who haven't
    /// completed setup). GoRouter uses this to redirect orphan sessions
    /// to /profile-setup instead of the home screen, where RLS-guarded
    /// queries would otherwise surface as "something went wrong".
    bool? hasProfile,
  }) = _AuthState;
}

/// Authentication bridge between repository and GoRouter.
///
/// **Architecture note:** This notifier acts as a **bridge only** — it
/// syncs the repository's `authStateChanges` stream into Riverpod state
/// so that GoRouter's `refreshListenable` triggers route redirects.
///
/// **It does NOT contain business logic.** All auth operations (login,
/// register, logout, email verification, OTP, etc.) are handled by
/// AuthBloc in the presentation layer. This separation avoids
/// duplicating business logic across two state management systems.
///
/// Responsibilities:
/// - Listen to `authStateChanges` from the repository (auto-sync)
/// - Provide `getCurrentUser()` for session restore in `main()`
/// - Provide `isAuthenticated()` for routing guards
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);

    // Listen to repository's auth state changes to keep this notifier in sync
    // with any auth operations (e.g. from BLoC or direct repo calls)
    final subscription = repository.authStateChanges.listen((user) {
      if (state.user != user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          error: null,
          hasProfile: user == null ? null : state.hasProfile,
        );
        if (user != null) {
          // Fire-and-forget: state update happens inside the async helper.
          // ignore: discarded_futures
          _refreshProfileExistence(user.id);
        }
      }
    });

    // Clean up subscription when the provider is disposed
    ref.onDispose(subscription.cancel);

    return const AuthState();
  }

  /// Gets the current authenticated user for session restore.
  ///
  /// Called from `main()` at app startup to restore the previous session.
  Future<void> getCurrentUser() async {
    state = state.copyWith(isLoading: true, error: null);

    final getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
    final result = await getCurrentUserUseCase();

    await result.when(
      success: (user) async {
        state = state.copyWith(
          user: user,
          isLoading: false,
          error: null,
        );
        if (user != null) {
          await _refreshProfileExistence(user.id);
        }
      },
      failureCallback: (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Checks whether the authenticated user has a `public.users` row and
  /// reflects the result in [AuthState.hasProfile] for the router to read.
  Future<void> _refreshProfileExistence(String userId) async {
    final userRepository = GetIt.instance<UserRepository>();
    final result = await userRepository.getUserProfile(userId);
    if (state.user?.id != userId) return;
    state = state.copyWith(hasProfile: result.isRight());
  }

  /// Re-runs the profile existence check for the current user.
  ///
  /// Call after creating the user's profile (e.g. from ProfileSetupPage
  /// success) so the router can stop redirecting them to /profile-setup.
  Future<void> refreshProfileExistence() async {
    final user = state.user;
    if (user == null) return;
    await _refreshProfileExistence(user.id);
  }

  /// Checks if the user is authenticated.
  ///
  /// Used by routing guards. Does not update state.
  Future<bool> isAuthenticated() async {
    final isAuthenticatedUseCase = ref.read(isAuthenticatedUseCaseProvider);
    final result = await isAuthenticatedUseCase();

    return result.when(
      success: (isAuth) => isAuth,
      failureCallback: (_) => false,
    );
  }
}

/// Provider for AuthNotifier (Riverpod 3.0 - using NotifierProvider)
///
/// Used by:
/// - GoRouter redirect logic (routing guards)
/// - `main()` for session restore
///
/// NOT used by auth UI pages (which use AuthBloc).
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
