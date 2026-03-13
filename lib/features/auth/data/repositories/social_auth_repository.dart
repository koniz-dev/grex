import 'package:dartz/dartz.dart';
import 'package:grex/features/auth/data/utils/social_auth_error_mapper.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/features/auth/domain/services/oauth_scope_validator.dart';
import 'package:grex/features/auth/domain/services/secure_token_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Repository interface for social authentication operations
abstract class SocialAuthRepository {
  /// Initiates Google OAuth flow
  /// Returns User on success, or AuthFailure on error
  Future<Either<AuthFailure, User>> signInWithGoogle();

  /// Initiates Apple OAuth flow
  /// Returns User on success, or AuthFailure on error
  Future<Either<AuthFailure, User>> signInWithApple();

  /// Checks if a user profile exists for the given user ID
  Future<bool> hasUserProfile(String userId);

  /// Links a social provider to an existing user account
  Future<Either<AuthFailure, void>> linkSocialProvider({
    required String userId,
    required SocialAuthProvider provider,
  });

  /// Creates a user profile for social login users
  Future<Either<AuthFailure, UserProfile>> createUserProfile(
    String userId,
    ProfileSetupData profileData,
  );
}

/// Implementation of social authentication repository using Supabase
class SocialAuthRepositoryImpl implements SocialAuthRepository {
  /// Creates a [SocialAuthRepositoryImpl] with required dependencies
  const SocialAuthRepositoryImpl({
    required this.supabase,
    required this.userRepository,
  });

  /// Supabase client for authentication operations
  final sb.SupabaseClient supabase;

  /// User repository for profile operations
  final UserRepository userRepository;

  @override
  Future<Either<AuthFailure, User>> signInWithGoogle() async {
    try {
      // Validate HTTPS transmission
      if (!SecureTokenHandler.validateHttpsTransmission()) {
        return Left(
          SocialAuthErrorMapper.mapError(
            'Insecure connection detected',
          ),
        );
      }

      // Validate OAuth scopes
      final scopes = OAuthScopeValidator.getRequiredScopes(
        SocialAuthProvider.google,
      );
      if (!OAuthScopeValidator.validateScopes(
        SocialAuthProvider.google,
        scopes,
      )) {
        return Left(SocialAuthErrorMapper.mapError('Invalid OAuth scopes'));
      }

      final response = await supabase.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: 'io.supabase.grex://login-callback/',
        authScreenLaunchMode: sb.LaunchMode.externalApplication,
      );

      if (!response) {
        return Left(SocialAuthErrorMapper.mapCancellationError());
      }

      // Wait for auth state change with timeout
      final user = await _waitForAuthUser();

      if (user == null) {
        return Left(
          SocialAuthErrorMapper.mapTimeoutError(
            'Authentication timeout',
          ),
        );
      }

      // Validate secure token storage
      if (!SecureTokenHandler.validateSecureStorage()) {
        SecureTokenHandler.secureLog(
          'Token storage validation failed',
        );
      }

      return Right(User.fromSupabaseUser(user));
    } on sb.AuthException catch (e) {
      final sanitizedMessage = SecureTokenHandler.sanitizeErrorMessage(
        e.message,
      );
      return Left(SocialAuthErrorMapper.mapError(sanitizedMessage));
    } on Exception catch (e) {
      final sanitizedMessage = SecureTokenHandler.sanitizeErrorMessage(
        e.toString(),
      );
      return Left(SocialAuthErrorMapper.mapError(sanitizedMessage));
    }
  }

  @override
  Future<Either<AuthFailure, User>> signInWithApple() async {
    try {
      // Validate HTTPS transmission
      if (!SecureTokenHandler.validateHttpsTransmission()) {
        return Left(
          SocialAuthErrorMapper.mapError(
            'Insecure connection detected',
          ),
        );
      }

      // Validate OAuth scopes
      final scopes = OAuthScopeValidator.getRequiredScopes(
        SocialAuthProvider.apple,
      );
      if (!OAuthScopeValidator.validateScopes(
        SocialAuthProvider.apple,
        scopes,
      )) {
        return Left(SocialAuthErrorMapper.mapError('Invalid OAuth scopes'));
      }

      final response = await supabase.auth.signInWithOAuth(
        sb.OAuthProvider.apple,
        redirectTo: 'io.supabase.grex://login-callback/',
        authScreenLaunchMode: sb.LaunchMode.externalApplication,
      );

      if (!response) {
        return Left(SocialAuthErrorMapper.mapCancellationError());
      }

      final user = await _waitForAuthUser();

      if (user == null) {
        return Left(
          SocialAuthErrorMapper.mapTimeoutError(
            'Authentication timeout',
          ),
        );
      }

      // Validate secure token storage
      if (!SecureTokenHandler.validateSecureStorage()) {
        SecureTokenHandler.secureLog(
          'Token storage validation failed',
        );
      }

      return Right(User.fromSupabaseUser(user));
    } on sb.AuthException catch (e) {
      final sanitizedMessage = SecureTokenHandler.sanitizeErrorMessage(
        e.message,
      );
      return Left(SocialAuthErrorMapper.mapError(sanitizedMessage));
    } on Exception catch (e) {
      final sanitizedMessage = SecureTokenHandler.sanitizeErrorMessage(
        e.toString(),
      );
      return Left(SocialAuthErrorMapper.mapError(sanitizedMessage));
    }
  }

  @override
  Future<bool> hasUserProfile(String userId) async {
    final result = await userRepository.getUserProfile(userId);
    return result.isRight();
  }

  @override
  Future<Either<AuthFailure, void>> linkSocialProvider({
    required String userId,
    required SocialAuthProvider provider,
  }) async {
    try {
      // Supabase automatically links providers when same email is used
      // This method is for explicit linking scenarios
      return const Right(null);
    } on Exception catch (e) {
      final sanitizedMessage = SecureTokenHandler.sanitizeErrorMessage(
        e.toString(),
      );
      return Left(
        SocialAuthErrorMapper.mapAccountLinkingError(
          sanitizedMessage,
        ),
      );
    }
  }

  @override
  Future<Either<AuthFailure, UserProfile>> createUserProfile(
    String userId,
    ProfileSetupData profileData,
  ) async {
    try {
      final result = await userRepository.createSocialUserProfile(
        userId: userId,
        email: supabase.auth.currentUser?.email ?? '',
        displayName: profileData.displayName,
        preferredCurrency: profileData.preferredCurrency,
        languageCode: profileData.languageCode,
        provider: profileData.socialProvider?.name ?? '',
      );

      return result.fold(
        (failure) => Left(SocialAuthErrorMapper.mapError(failure)),
        Right.new,
      );
    } on Exception catch (e) {
      final sanitizedMessage = SecureTokenHandler.sanitizeErrorMessage(
        e.toString(),
      );
      return Left(SocialAuthErrorMapper.mapError(sanitizedMessage));
    }
  }

  /// Wait up to 10 seconds for auth state to update
  Future<sb.User?> _waitForAuthUser() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final user = supabase.auth.currentUser;
      if (user != null) return user;
    }
    return null;
  }
}

/// Social authentication failure types

/// Base failure for social authentication errors
class SocialAuthFailure extends AuthFailure {
  /// Creates a [SocialAuthFailure] with the given message
  const SocialAuthFailure(super.message);
}

/// Failure when user cancels social authentication
class SocialAuthCancelledFailure extends AuthFailure {
  /// Creates a [SocialAuthCancelledFailure]
  const SocialAuthCancelledFailure() : super('Sign in was cancelled');
}

/// Failure when network error occurs during social authentication
class SocialAuthNetworkFailure extends AuthFailure {
  /// Creates a [SocialAuthNetworkFailure]
  const SocialAuthNetworkFailure() : super('Network error during sign in');
}

/// Failure when social authentication times out
class SocialAuthTimeoutFailure extends AuthFailure {
  /// Creates a [SocialAuthTimeoutFailure]
  const SocialAuthTimeoutFailure() : super('Sign in timed out');
}

/// Failure when account linking fails
class AccountLinkingFailure extends AuthFailure {
  /// Creates an [AccountLinkingFailure] with the given message
  const AccountLinkingFailure(super.message);
}

/// Failure when profile setup is required
class ProfileSetupRequiredFailure extends AuthFailure {
  /// Creates a [ProfileSetupRequiredFailure]
  const ProfileSetupRequiredFailure() : super('Profile setup required');
}
