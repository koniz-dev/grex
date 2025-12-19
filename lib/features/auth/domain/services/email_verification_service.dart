import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

/// Service interface for handling email verification operations.
///
/// This service provides methods for processing email verification
/// links, extracting tokens, and handling deep link navigation.
abstract class EmailVerificationService {
  /// Processes an email verification deep link.
  ///
  /// Extracts the verification token and email from the deep link
  /// and returns them for verification processing.
  ///
  /// Returns [Right<EmailVerificationData>] if link is valid.
  /// Returns [Left<AuthFailure>] if link is invalid or malformed.
  Either<AuthFailure, EmailVerificationData> processVerificationLink(
    String link,
  );

  /// Checks if a URL is a valid email verification link.
  ///
  /// Returns `true` if the URL contains the expected verification
  /// parameters and format, `false` otherwise.
  bool isVerificationLink(String url);

  /// Extracts verification token from a verification link.
  ///
  /// Returns the token if found, null if the link doesn't contain
  /// a valid token parameter.
  String? extractToken(String link);

  /// Extracts email address from a verification link.
  ///
  /// Returns the email if found, null if the link doesn't contain
  /// a valid email parameter.
  String? extractEmail(String link);
}

/// Data class containing email verification information extracted from links.
@immutable
class EmailVerificationData {
  /// Creates an [EmailVerificationData] with the provided verification data.
  ///
  /// Both [token] and [email] are required for email verification.
  const EmailVerificationData({
    required this.token,
    required this.email,
  });

  /// The verification token from the email link
  final String token;

  /// The email address being verified
  final String email;

  @override
  String toString() => 'EmailVerificationData(email: $email)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailVerificationData &&
        other.token == token &&
        other.email == email;
  }

  @override
  int get hashCode => token.hashCode ^ email.hashCode;
}
