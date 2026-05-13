import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:grex/core/di/providers.dart';
import 'package:grex/core/utils/result.dart';
import 'package:grex/features/auth/domain/entities/user.dart';

part 'auth_provider.freezed.dart';

/// Authentication state for routing and session management
///
/// This state is used by GoRouter's redirect logic and main() session
/// restore. It is NOT used by auth UI pages (which use AuthBloc instead).
@freezed
abstract class AuthState with _$AuthState {
  /// Creates an [AuthState] with the given [user], [isLoading], and [error]
  const factory AuthState({
    /// Currently authenticated user, null if not logged in
    User? user,

    /// Whether an authentication operation is in progress
    @Default(false) bool isLoading,

    /// Error message if authentication failed, null otherwise
    String? error,
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
        state = state.copyWith(user: user, isLoading: false, error: null);
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

    result.when(
      success: (user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          error: null,
        );
      },
      failureCallback: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
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
