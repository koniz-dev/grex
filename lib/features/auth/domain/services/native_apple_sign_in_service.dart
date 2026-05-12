import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';

/// Service for native Apple Sign In on iOS/macOS platforms.
///
/// This service provides platform-native Apple authentication using
/// Apple Authentication Services framework on iOS 13+ and macOS 10.15+.
/// It offers a seamless, system-integrated sign-in experience with
/// Face ID/Touch ID support.
///
/// ## Platform Support
///
/// - **iOS 13+**: Native Apple Sign In with biometric authentication
/// - **macOS 10.15+**: Native Apple Sign In with system integration
/// - **Other platforms**: Returns unavailable, falls back to web OAuth
///
/// ## Features
///
/// - Native system UI for Apple Sign In
/// - Biometric authentication (Face ID/Touch ID)
/// - Email and name scope requests
/// - Relay email address support (@privaterelay.appleid.com)
/// - Nonce-based security for replay attack prevention
/// - Graceful cancellation handling
///
/// ## Usage Example
///
/// ```dart
/// final service = getIt<NativeAppleSignInService>();
///
/// // Check platform availability
/// if (service.isAvailable()) {
///   // Perform native sign-in
///   final result = await service.signIn(nonce: hashedNonce);
///   result.fold(
///     (failure) => handleError(failure),
///     (appleResult) => handleSuccess(appleResult),
///   );
/// } else {
///   // Fall back to web OAuth flow
///   await performWebOAuth();
/// }
/// ```
///
/// ## Security
///
/// - Uses cryptographically secure nonces
/// - Validates nonces with Supabase backend
/// - Stores tokens securely using platform keychain
/// - Handles relay emails appropriately
///
/// **Requirements:** 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8
abstract class NativeAppleSignInService {
  /// Checks if native Apple Sign In is available on this platform.
  ///
  /// Returns `true` if running on iOS 13+ or macOS 10.15+ where
  /// Apple Authentication Services framework is available.
  ///
  /// Returns `false` on Android, web, or older iOS/macOS versions.
  /// When unavailable, callers should fall back to web OAuth flow.
  ///
  /// **Returns:**
  /// - `true` if native Apple Sign In is supported
  /// - `false` if not supported (use web OAuth instead)
  ///
  /// **Example:**
  /// ```dart
  /// if (service.isAvailable()) {
  ///   // Use native flow
  ///   await service.signIn(nonce: nonce);
  /// } else {
  ///   // Use web OAuth flow
  ///   await webOAuthFlow();
  /// }
  /// ```
  ///
  /// **Requirements:** 3.1
  bool isAvailable();

  /// Performs native Apple Sign In with the provided nonce.
  ///
  /// Initiates the native Apple Sign In flow using Apple Authentication
  /// Services. Shows the system sign-in sheet with Face ID/Touch ID
  /// authentication. Requests email and fullName scopes from Apple.
  ///
  /// The [nonce] parameter should be the **hashed** nonce (SHA-256)
  /// that will be sent to Apple for validation. The plain nonce is
  /// sent separately to Supabase.
  ///
  /// **Parameters:**
  /// - [nonce]: Hashed nonce (SHA-256) for replay attack prevention
  ///
  /// **Returns:**
  /// - `Right(AppleSignInResult)` on successful authentication
  /// - `Left(AuthFailure)` on error or cancellation
  ///
  /// **Possible Failures:**
  /// - `SocialAuthCancelledFailure`: User cancelled sign-in
  /// - `SocialAuthFailure`: Platform error or network issue
  /// - `NativeSignInFailure`: Platform-specific error with details
  ///
  /// **Example:**
  /// ```dart
  /// final result = await service.signIn(nonce: hashedNonce);
  /// result.fold(
  ///   (failure) {
  ///     if (failure is SocialAuthCancelledFailure) {
  ///       // User cancelled - no error message needed
  ///     } else {
  ///       // Show error to user
  ///       showError(failure.message);
  ///     }
  ///   },
  ///   (appleResult) {
  ///     // Process Apple credential
  ///     await handleAppleCredential(
  ///       credential: appleResult,
  ///       plainNonce: plainNonce,
  ///     );
  ///   },
  /// );
  /// ```
  ///
  /// **Requirements:** 3.1, 3.2, 3.3, 3.8
  Future<Either<AuthFailure, AppleSignInResult>> signIn({
    required String nonce,
  });

  /// Handles Apple credential response and completes authentication.
  ///
  /// Processes the Apple ID credential received from native sign-in,
  /// validates it with Supabase, and creates/updates the user account.
  /// Handles name metadata storage for first-time sign-ins and relay
  /// email addresses.
  ///
  /// **Parameters:**
  /// - [idToken]: Apple ID token from credential
  /// - [authorizationCode]: Apple authorization code (optional)
  /// - [email]: User's email (may be relay address)
  /// - [fullName]: User's name components (only on first sign-in)
  /// - [plainNonce]: Plain (unhashed) nonce for Supabase validation
  ///
  /// **Returns:**
  /// - `Right(User)` on successful authentication
  /// - `Left(AuthFailure)` on validation or network error
  ///
  /// **Possible Failures:**
  /// - `NonceMismatchFailure`: Nonce validation failed
  /// - `SocialAuthFailure`: Supabase authentication failed
  /// - `TokenStorageFailure`: Failed to store provider tokens
  ///
  /// **Name Handling:**
  /// - First sign-in: Name provided by Apple, saved to metadata
  /// - Subsequent sign-ins: Name not provided, retrieved from metadata
  ///
  /// **Relay Email Handling:**
  /// - Detects @privaterelay.appleid.com addresses
  /// - Marks as relay email in metadata
  /// - Handles appropriately in UI
  ///
  /// **Example:**
  /// ```dart
  /// final result = await service.handleAppleCredential(
  ///   idToken: credential.identityToken,
  ///   authorizationCode: credential.authorizationCode,
  ///   email: credential.email,
  ///   fullName: credential.fullName,
  ///   plainNonce: plainNonce,
  /// );
  /// ```
  ///
  /// **Requirements:** 3.4, 3.5, 3.6, 3.7, 3.8
  Future<Either<AuthFailure, User>> handleAppleCredential({
    required String idToken,
    required String plainNonce,
    String? authorizationCode,
    String? email,
    PersonNameComponents? fullName,
  });
}

/// Result of Apple Sign In containing credential and user information.
///
/// Contains the Apple ID token and optional user information returned
/// from native Apple Sign In. The name and email are only provided on
/// the first sign-in; subsequent sign-ins return null for these fields.
///
/// ## First Sign-In vs Subsequent Sign-Ins
///
/// **First Sign-In:**
/// - `email`: User's email (or relay address)
/// - `fullName`: User's name components
/// - Store name in metadata for future use
///
/// **Subsequent Sign-Ins:**
/// - `email`: null (retrieve from stored metadata)
/// - `fullName`: null (retrieve from stored metadata)
///
/// ## Relay Email Addresses
///
/// Apple provides relay email addresses (@privaterelay.appleid.com)
/// when users choose to hide their email. These should be:
/// - Accepted as valid email addresses
/// - Marked as relay emails in metadata
/// - Displayed with appropriate privacy notice
///
/// **Requirements:** 3.4, 3.5, 3.6
class AppleSignInResult extends Equatable {
  /// Creates an [AppleSignInResult] with the provided credential data.
  ///
  /// **Parameters:**
  /// - [idToken]: Apple ID token (JWT) for Supabase authentication
  /// - [authorizationCode]: Apple authorization code (optional)
  /// - [email]: User's email or relay address (only on first sign-in)
  /// - [fullName]: User's name components (only on first sign-in)
  const AppleSignInResult({
    required this.idToken,
    this.authorizationCode,
    this.email,
    this.fullName,
  });

  /// Apple ID token (JWT) for authentication.
  ///
  /// This token is sent to Supabase signInWithIdToken along with
  /// the plain nonce for validation. Contains user identity claims.
  final String idToken;

  /// Apple authorization code for token exchange.
  ///
  /// Optional code that can be used to obtain refresh tokens from
  /// Apple's token endpoint. May be null in some flows.
  final String? authorizationCode;

  /// User's email address or relay address.
  ///
  /// Only provided on first sign-in. May be a relay address
  /// (@privaterelay.appleid.com) if user chose to hide email.
  /// Null on subsequent sign-ins.
  final String? email;

  /// User's name components from Apple.
  ///
  /// Only provided on first sign-in. Contains given name and
  /// family name. Null on subsequent sign-ins - retrieve from
  /// stored metadata instead.
  final PersonNameComponents? fullName;

  /// Checks if the email is an Apple relay address.
  ///
  /// Returns `true` if email ends with @privaterelay.appleid.com,
  /// indicating the user chose to hide their real email address.
  bool get isRelayEmail =>
      email?.endsWith('@privaterelay.appleid.com') ?? false;

  @override
  List<Object?> get props => [idToken, authorizationCode, email, fullName];

  @override
  String toString() {
    return 'AppleSignInResult('
        'idToken: ${idToken.substring(0, 20)}..., '
        'authorizationCode: ${authorizationCode != null ? '***' : 'null'}, '
        'email: $email, '
        'fullName: $fullName, '
        'isRelayEmail: $isRelayEmail'
        ')';
  }
}

/// Person name components from Apple Sign In.
///
/// Contains the user's given name (first name) and family name (last name)
/// as provided by Apple. Only available on first sign-in; subsequent
/// sign-ins return null and the name should be retrieved from metadata.
///
/// ## Name Handling
///
/// - **First Sign-In**: Apple provides name, save to metadata
/// - **Subsequent Sign-Ins**: Apple returns null, retrieve from metadata
/// - **Display**: Use fullName getter for complete name
///
/// ## Privacy Considerations
///
/// Users can choose not to share their name with the app. In this case,
/// both givenName and familyName will be null. Handle gracefully by
/// using email or a default display name.
///
/// **Requirements:** 3.5, 3.7
class PersonNameComponents extends Equatable {
  /// Creates [PersonNameComponents] with the provided name parts.
  ///
  /// **Parameters:**
  /// - [givenName]: User's first name (optional)
  /// - [familyName]: User's last name (optional)
  const PersonNameComponents({
    this.givenName,
    this.familyName,
  });

  /// User's given name (first name).
  ///
  /// May be null if user chose not to share name or if this is
  /// a subsequent sign-in (retrieve from metadata instead).
  final String? givenName;

  /// User's family name (last name).
  ///
  /// May be null if user chose not to share name or if this is
  /// a subsequent sign-in (retrieve from metadata instead).
  final String? familyName;

  /// Constructs full name from given and family names.
  ///
  /// Combines givenName and familyName with a space separator,
  /// filtering out null values. Returns empty string if both are null.
  ///
  /// **Returns:**
  /// - Full name string (e.g., "John Doe")
  /// - Empty string if both names are null
  ///
  /// **Example:**
  /// ```dart
  /// final name = PersonNameComponents(
  ///   givenName: 'John',
  ///   familyName: 'Doe',
  /// );
  /// print(name.fullName); // "John Doe"
  /// ```
  String get fullName {
    final parts = [
      givenName,
      familyName,
    ].where((p) => p != null && p.isNotEmpty);
    return parts.join(' ').trim();
  }

  /// Checks if any name component is provided.
  ///
  /// Returns `true` if either givenName or familyName is non-null
  /// and non-empty. Useful for determining if name was shared.
  bool get hasName => fullName.isNotEmpty;

  @override
  List<Object?> get props => [givenName, familyName];

  @override
  String toString() {
    return 'PersonNameComponents('
        'givenName: $givenName, '
        'familyName: $familyName, '
        'fullName: $fullName'
        ')';
  }
}
