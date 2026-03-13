import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// Simple session service for managing authentication sessions
///
/// This service provides basic session management that works for both
/// email/password and social login authentication methods. It delegates
/// to Supabase Auth for session handling.
class SimpleSessionService {
  /// Creates a [SimpleSessionService] with the provided Supabase client.
  const SimpleSessionService(this.supabase);

  /// Supabase client for authentication operations
  final SupabaseClient supabase;

  /// Check if user has valid session (works for both email and social login)
  ///
  /// Returns true if there is a current authenticated user with a valid
  /// session. This method works for both email/password and OAuth
  /// authentication.
  Future<bool> hasValidSession() async {
    final session = supabase.auth.currentSession;
    if (session == null) return false;

    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;

    return DateTime.now().isBefore(
      DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
    );
  }

  /// Get current user (works for both email and social login)
  ///
  /// Returns the currently authenticated user or null if not authenticated.
  /// This method works for both email/password and OAuth authentication.
  User? getCurrentUser() {
    final supabaseUser = supabase.auth.currentUser;
    if (supabaseUser == null) return null;

    return User.fromSupabaseUser(supabaseUser);
  }

  /// Sign out (works for both email and social login)
  ///
  /// Signs out the current user and clears all session data.
  /// This method works for both email/password and OAuth authentication.
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Detect authentication method from user metadata
  ///
  /// Returns the authentication method used by the current user.
  /// Returns 'email' for email/password authentication.
  /// Returns 'google' or 'apple' for OAuth authentication.
  /// Returns null if no user is authenticated.
  String? getAuthenticationMethod() {
    final user = getCurrentUser();
    if (user == null) return null;

    // Check if user has social provider
    final socialProvider = user.socialProvider;
    if (socialProvider != null) {
      return socialProvider.name;
    }

    // Default to email authentication
    return 'email';
  }

  /// Check if current user is authenticated via social login
  ///
  /// Returns true if the current user authenticated using OAuth
  /// (Google/Apple). Returns false if authenticated via email/password
  /// or not authenticated.
  bool isSocialLoginUser() {
    final user = getCurrentUser();
    return user?.socialProvider != null;
  }

  /// Get current session information
  ///
  /// Returns the current Supabase session or null if not authenticated.
  Session? getCurrentSession() {
    return supabase.auth.currentSession;
  }

  /// Refresh the current session
  ///
  /// Attempts to refresh the current session using the refresh token.
  /// Returns true if refresh was successful, false otherwise.
  Future<bool> refreshSession() async {
    try {
      final response = await supabase.auth.refreshSession();
      return response.session != null;
    } on AuthException catch (_) {
      return false;
    } on Exception catch (_) {
      return false;
    }
  }
}
