import 'package:dartz/dartz.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/email_verification_service.dart';

/// Supabase implementation of [EmailVerificationService].
///
/// This service handles email verification links from Supabase Auth
/// and extracts the necessary parameters for verification processing.
class SupabaseEmailVerificationService implements EmailVerificationService {
  /// Creates a [SupabaseEmailVerificationService].
  const SupabaseEmailVerificationService();

  /// The expected base URL for Supabase email verification links
  static const String _verificationPath = '/auth/confirm';

  /// Query parameter names used by Supabase for email verification
  static const String _tokenParam = 'token';
  static const String _typeParam = 'type';
  static const String _emailParam = 'email';
  static const String _expectedType = 'signup';

  @override
  Either<AuthFailure, EmailVerificationData> processVerificationLink(
    String link,
  ) {
    try {
      final uri = Uri.parse(link);

      // Only require the path here so we can produce field-specific errors
      // below. Use isVerificationLink for the strict "is this a full
      // verification link" check elsewhere.
      if (!uri.path.contains(_verificationPath)) {
        return const Left(
          GenericAuthFailure('Failed to process verification link'),
        );
      }

      // Extract token and email
      final token = uri.queryParameters[_tokenParam];
      final email = uri.queryParameters[_emailParam];
      final type = uri.queryParameters[_typeParam];

      // Validate required parameters
      if (token == null || token.isEmpty) {
        return const Left(
          GenericAuthFailure('Verification token not found in link'),
        );
      }

      if (email == null || email.isEmpty) {
        return const Left(
          GenericAuthFailure('email address not found in link'),
        );
      }

      if (type != _expectedType) {
        return const Left(GenericAuthFailure('Invalid verification link type'));
      }

      // Validate email format
      if (!_isValidEmail(email)) {
        return const Left(
          GenericAuthFailure('Invalid email format in verification link'),
        );
      }

      return Right(
        EmailVerificationData(
          token: token,
          email: email,
        ),
      );
    } on Object catch (e) {
      return Left(
        GenericAuthFailure('Failed to process verification link: $e'),
      );
    }
  }

  @override
  bool isVerificationLink(String url) {
    try {
      final uri = Uri.parse(url);

      // Check if URL contains the verification path
      if (!uri.path.contains(_verificationPath)) {
        return false;
      }

      // Strict check — all required params must be present
      final hasToken = uri.queryParameters.containsKey(_tokenParam);
      final hasEmail = uri.queryParameters.containsKey(_emailParam);
      final hasType = uri.queryParameters.containsKey(_typeParam);

      return hasToken && hasEmail && hasType;
    } on Object catch (_) {
      return false;
    }
  }

  @override
  String? extractToken(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.queryParameters[_tokenParam];
    } on Object catch (_) {
      return null;
    }
  }

  @override
  String? extractEmail(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.queryParameters[_emailParam];
    } on Object catch (_) {
      return null;
    }
  }

  /// Validates email format using a simple regex pattern.
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
