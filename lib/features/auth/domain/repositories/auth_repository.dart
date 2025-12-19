import 'package:dartz/dartz.dart';
import 'package:grex/core/utils/result.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

/// Repository interface for authentication operations.
///
/// This interface defines the contract for authentication-related operations
/// including sign in, sign up, sign out, password reset, and session
/// management.
/// All methods return `Either<Failure, Success>` for proper error handling.
abstract class AuthRepository {
  /// Signs in a user with email and password.
  ///
  /// Returns [Right<User>] on successful authentication.
  /// Returns [Left<AuthFailure>] on authentication failure.
  ///
  /// Possible failures:
  /// - [InvalidCredentialsFailure] for wrong email/password
  /// - [UnverifiedEmailFailure] for unverified email addresses
  /// - [NetworkFailure] for connection issues
  Future<Either<AuthFailure, User>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs up a new user with email and password.
  ///
  /// Returns [Right<User>] on successful registration.
  /// Returns [Left<AuthFailure>] on registration failure.
  ///
  /// Possible failures:
  /// - [EmailAlreadyInUseFailure] for existing email addresses
  /// - [WeakPasswordFailure] for passwords not meeting requirements
  /// - [NetworkFailure] for connection issues
  Future<Either<AuthFailure, User>> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs out the current user.
  ///
  /// Returns [Right<void>] on successful sign out.
  /// Returns [Left<AuthFailure>] on sign out failure.
  ///
  /// Clears all session data and authentication tokens.
  Future<Either<AuthFailure, void>> signOut();

  /// Sends a password reset email to the specified email address.
  ///
  /// Returns [Right<void>] on successful email sending.
  /// Returns [Left<AuthFailure>] on failure.
  ///
  /// Possible failures:
  /// - [NetworkFailure] for connection issues
  /// - [AuthFailure] for invalid email addresses
  Future<Either<AuthFailure, void>> resetPassword({
    required String email,
  });

  /// Stream of authentication state changes.
  ///
  /// Emits a [User] when user is authenticated.
  /// Emits `null` when user is not authenticated.
  ///
  /// This stream should be listened to for real-time authentication
  /// state updates throughout the app lifecycle.
  Stream<User?> get authStateChanges;

  /// Gets the currently authenticated user.
  ///
  /// Returns a [User] if user is currently authenticated.
  /// Returns `null` if no user is authenticated.
  ///
  /// This is a synchronous getter that returns the current
  /// authentication state without making network calls.
  User? get currentUser;

  /// Gets the currently authenticated user asynchronously.
  ///
  /// Returns [Result<User?>] with the user if authenticated, null otherwise.
  /// Returns [ResultFailure] on failure.
  ///
  /// This method retrieves the user from local storage/cache.
  Future<Result<User?>> getCurrentUser();

  /// Checks if the user is currently authenticated.
  ///
  /// Returns [Result<bool>] with true if authenticated, false otherwise.
  /// Returns [ResultFailure] on failure.
  ///
  /// This method checks if there is a valid authenticated user.
  Future<Result<bool>> isAuthenticated();

  /// Gets the current authentication session.
  ///
  /// Returns the current session with tokens if authenticated, null otherwise.
  /// This is used for session management and token refresh.
  dynamic get currentSession;

  /// Sends a verification email to the current user.
  ///
  /// Returns [Right<void>] on successful email sending.
  /// Returns [Left<AuthFailure>] on failure.
  ///
  /// This method can be used to resend verification emails
  /// for users who haven't verified their email address yet.
  Future<Either<AuthFailure, void>> sendVerificationEmail();

  /// Verifies an email using the verification token.
  ///
  /// Returns [Right<void>] on successful verification.
  /// Returns [Left<AuthFailure>] on verification failure.
  ///
  /// This method processes email verification tokens received
  /// through email links or deep links in the app.
  Future<Either<AuthFailure, void>> verifyEmail({
    required String token,
    required String email,
  });

  /// Checks if the current user's email is verified.
  ///
  /// Returns `true` if email is verified, `false` otherwise.
  /// Returns `false` if no user is currently authenticated.
  bool get isEmailVerified;

  /// Refreshes the authentication token.
  ///
  /// Returns [Result<String>] with the new token on success.
  /// Returns [ResultFailure] on failure.
  ///
  /// This method is used to refresh expired access tokens using
  /// a refresh token stored securely.
  Future<Result<String>> refreshToken();
}
