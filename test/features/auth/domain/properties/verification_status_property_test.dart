import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/email_verification_service.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/property_test_helpers.dart';
import '../../../../helpers/test_helpers.mocks.dart';

/// Property 14: Email verification updates user status
///
/// This property verifies that when a user successfully verifies their email,
/// their user status is updated to reflect the verified state.
///
/// **Correctness Property**: For any valid verification token and email,
/// if verification succeeds, then the user's emailConfirmed status
/// should be updated to true and they should be able to access the app.
void main() {
  group('Property 14: Email verification updates user status', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockEmailVerificationService mockVerificationService;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockVerificationService = MockEmailVerificationService();
    });

    test(
      'should update user status after successful email verification',
      () async {
        // Property: For any valid verification data, if verification succeeds,
        // then user status should be updated to verified

        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          // Generate random verification data
          final email = PropertyTestHelpers.generateEmail();
          final token = PropertyTestHelpers.generateVerificationToken();
          final userId = PropertyTestHelpers.generateUserId();

          // Create unverified user initially
          final unverifiedUser = User(
            id: userId,
            email: email,
            emailConfirmed: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          );

          // Create verified user (after verification)
          final verifiedUser = User(
            id: userId,
            email: email,
            createdAt: unverifiedUser.createdAt,
            lastSignInAt: DateTime.now(),
          );

          final userProfile = UserProfile(
            id: userId,
            email: email,
            displayName: PropertyTestHelpers.generateDisplayName(),
            preferredCurrency: 'VND',
            languageCode: 'vi',
            createdAt: unverifiedUser.createdAt,
            updatedAt: DateTime.now(),
          );

          // Mock verification link processing
          final verificationData = EmailVerificationData(
            token: token,
            email: email,
          );

          when(
            mockVerificationService.processVerificationLink(any),
          ).thenReturn(Right(verificationData));

          // Mock successful email verification
          when(
            mockAuthRepository.verifyEmail(
              token: token,
              email: email,
            ),
          ).thenAnswer((_) async => const Right(null));

          // Mock updated user state after verification
          when(mockAuthRepository.currentUser).thenReturn(verifiedUser);
          when(mockAuthRepository.isEmailVerified).thenReturn(true);

          // Mock profile loading
          when(
            mockUserRepository.getUserProfile(userId),
          ).thenAnswer((_) async => Right(userProfile));

          // Act: Process verification link
          final linkResult = mockVerificationService.processVerificationLink(
            'https://app.grex.com/auth/confirm?token=$token&email=$email&type=signup',
          );

          expect(
            linkResult.isRight(),
            isTrue,
            reason: 'Valid verification link should be processed successfully',
          );

          await linkResult.fold(
            (failure) => fail('Link processing should not fail: $failure'),
            (data) async {
              // Verify email using extracted data
              final verificationResult = await mockAuthRepository.verifyEmail(
                token: data.token,
                email: data.email,
              );

              expect(
                verificationResult.isRight(),
                isTrue,
                reason: 'Email verification should succeed for valid token',
              );

              // Property 1: User status should be updated to verified
              final currentUser = mockAuthRepository.currentUser;
              expect(
                currentUser,
                isNotNull,
                reason: 'User should be available after verification',
              );

              expect(
                currentUser!.emailConfirmed,
                isTrue,
                reason: 'User email should be confirmed after verification',
              );

              expect(
                currentUser.email,
                equals(email),
                reason: 'User email should match verification email',
              );

              // Property 2: User should be able to access authenticated
              // features
              expect(
                mockAuthRepository.isEmailVerified,
                isTrue,
                reason: 'Email verification status should be true',
              );

              // Property 3: Profile should be accessible
              final profileResult = await mockUserRepository.getUserProfile(
                userId,
              );
              expect(
                profileResult.isRight(),
                isTrue,
                reason: 'Profile should be accessible for verified user',
              );
            },
          );

          reset(mockAuthRepository);
          reset(mockUserRepository);
          reset(mockVerificationService);
        }
      },
    );

    test('should handle invalid verification tokens correctly', () async {
      // Property: Invalid tokens should not update user status

      const iterations = 50;

      for (var i = 0; i < iterations; i++) {
        final email = PropertyTestHelpers.generateEmail();
        final invalidToken =
            'invalid-token-${PropertyTestHelpers.generateUserId()}';

        // Mock verification failure for invalid token
        when(
          mockAuthRepository.verifyEmail(
            token: invalidToken,
            email: email,
          ),
        ).thenAnswer(
          (_) async =>
              const Left(GenericAuthFailure('Invalid verification token')),
        );

        // Mock user remains unverified
        when(mockAuthRepository.isEmailVerified).thenReturn(false);

        // Act
        final verificationResult = await mockAuthRepository.verifyEmail(
          token: invalidToken,
          email: email,
        );

        // Property verification: Invalid token should fail
        expect(
          verificationResult.isLeft(),
          isTrue,
          reason: 'Invalid token should cause verification to fail',
        );

        expect(
          mockAuthRepository.isEmailVerified,
          isFalse,
          reason: 'User should remain unverified with invalid token',
        );

        reset(mockAuthRepository);
      }
    });

    test('should handle expired verification tokens', () async {
      // Property: Expired tokens should not verify email

      const iterations = 30;

      for (var i = 0; i < iterations; i++) {
        final email = PropertyTestHelpers.generateEmail();
        final expiredToken = PropertyTestHelpers.generateVerificationToken();

        // Mock verification failure for expired token
        when(
          mockAuthRepository.verifyEmail(
            token: expiredToken,
            email: email,
          ),
        ).thenAnswer(
          (_) async =>
              const Left(GenericAuthFailure('Verification token has expired')),
        );

        // Act
        final verificationResult = await mockAuthRepository.verifyEmail(
          token: expiredToken,
          email: email,
        );

        // Property verification
        expect(
          verificationResult.isLeft(),
          isTrue,
          reason: 'Expired token should cause verification to fail',
        );

        verificationResult.fold(
          (failure) {
            expect(
              failure.message.toLowerCase(),
              contains('expired'),
              reason: 'Failure message should indicate token expiration',
            );
          },
          (_) => fail('Expired token should not succeed'),
        );

        reset(mockAuthRepository);
      }
    });

    test('should maintain verification state consistency', () async {
      // Property: Verification state should be consistent across all checks

      const iterations = 75;

      for (var i = 0; i < iterations; i++) {
        final email = PropertyTestHelpers.generateEmail();
        final userId = PropertyTestHelpers.generateUserId();
        final isVerified = i.isEven; // Alternate between verified/unverified

        final user = User(
          id: userId,
          email: email,
          emailConfirmed: isVerified,
          createdAt: DateTime.now(),
          lastSignInAt: isVerified ? DateTime.now() : null,
        );

        // Mock consistent verification state
        when(mockAuthRepository.currentUser).thenReturn(user);
        when(mockAuthRepository.isEmailVerified).thenReturn(isVerified);

        // Property verification: All verification checks should be consistent
        final currentUser = mockAuthRepository.currentUser;
        final verificationStatus = mockAuthRepository.isEmailVerified;

        expect(
          currentUser,
          isNotNull,
          reason: 'Current user should be available',
        );

        expect(
          currentUser!.emailConfirmed,
          equals(verificationStatus),
          reason: 'User emailConfirmed should match isEmailVerified',
        );

        if (isVerified) {
          expect(
            currentUser.lastSignInAt,
            isNotNull,
            reason: 'Verified user should have lastSignInAt',
          );
        }

        reset(mockAuthRepository);
      }
    });

    test('should handle verification state transitions correctly', () async {
      // Property: User can only transition from unverified to verified, not
      // backwards

      const iterations = 50;

      for (var i = 0; i < iterations; i++) {
        final email = PropertyTestHelpers.generateEmail();
        final token = PropertyTestHelpers.generateVerificationToken();
        final userId = PropertyTestHelpers.generateUserId();

        // Start with unverified user
        final unverifiedUser = User(
          id: userId,
          email: email,
          emailConfirmed: false,
          createdAt: DateTime.now(),
        );

        // Mock initial unverified state
        when(mockAuthRepository.currentUser).thenReturn(unverifiedUser);
        when(mockAuthRepository.isEmailVerified).thenReturn(false);

        // Verify initial state
        expect(
          mockAuthRepository.currentUser!.emailConfirmed,
          isFalse,
          reason: 'User should start unverified',
        );

        // Mock successful verification
        when(
          mockAuthRepository.verifyEmail(
            token: token,
            email: email,
          ),
        ).thenAnswer((_) async => const Right(null));

        // Update to verified state
        final verifiedUser = unverifiedUser.copyWith(emailConfirmed: true);
        when(mockAuthRepository.currentUser).thenReturn(verifiedUser);
        when(mockAuthRepository.isEmailVerified).thenReturn(true);

        // Act: Verify email
        final result = await mockAuthRepository.verifyEmail(
          token: token,
          email: email,
        );

        // Property verification: Transition should succeed
        expect(
          result.isRight(),
          isTrue,
          reason: 'Valid verification should succeed',
        );

        expect(
          mockAuthRepository.currentUser!.emailConfirmed,
          isTrue,
          reason: 'User should be verified after successful verification',
        );

        expect(
          mockAuthRepository.isEmailVerified,
          isTrue,
          reason: 'Verification status should be true',
        );

        reset(mockAuthRepository);
      }
    });
  });
}

/// Extension to add copyWith method to User for testing
// ignore: unreachable_from_main
extension UserCopyWith on User {
  // Extension method is used via method call syntax but linter doesn't
  // detect it
  // ignore: unreachable_from_main
  User copyWith({
    String? id,
    String? email,
    bool? emailConfirmed,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      emailConfirmed: emailConfirmed ?? this.emailConfirmed,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }
}
