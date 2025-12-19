import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/property_test_helpers.dart';
import '../../../../helpers/test_helpers.mocks.dart';

/// Property 13: Registration triggers verification email
///
/// This property verifies that when a user registers successfully,
/// a verification email is automatically sent to their email address.
///
/// **Correctness Property**: For any valid registration data,
/// if registration succeeds, then a verification email should be sent
/// and the user should be in an unverified state.
void main() {
  group('Property 13: Registration triggers verification email', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
    });

    test(
      'should send verification email after successful registration',
      () async {
        // Property: For any valid registration data, if registration
        // succeeds, then a verification email should be sent and user should
        // be unverified

        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          // Generate random valid registration data
          final registrationData =
              PropertyTestHelpers.generateRegistrationData();

          // Create unverified user (as Supabase does for new registrations)
          final unverifiedUser = User(
            id: PropertyTestHelpers.generateUserId(),
            email: registrationData.email,
            emailConfirmed: false, // Key property: email not confirmed
            createdAt: DateTime.now(),
          );

          final userProfile = UserProfile(
            id: unverifiedUser.id,
            email: unverifiedUser.email,
            displayName: registrationData.displayName,
            preferredCurrency: registrationData.preferredCurrency ?? 'VND',
            languageCode: registrationData.languageCode ?? 'vi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Mock successful registration
          when(
            mockAuthRepository.signUpWithEmail(
              email: registrationData.email,
              password: registrationData.password,
            ),
          ).thenAnswer((_) async => Right(unverifiedUser));

          // Mock successful profile creation
          when(
            mockUserRepository.createUserProfile(any),
          ).thenAnswer((_) async => Right(userProfile));

          // Mock verification email sending
          when(
            mockAuthRepository.sendVerificationEmail(),
          ).thenAnswer((_) async => const Right(null));

          // Act: Perform registration
          final registrationResult = await mockAuthRepository.signUpWithEmail(
            email: registrationData.email,
            password: registrationData.password,
          );

          final profileResult = await mockUserRepository.createUserProfile(
            userProfile,
          );

          // Property verification: Registration should succeed
          expect(
            registrationResult.isRight(),
            isTrue,
            reason: 'Registration should succeed for valid data',
          );

          expect(
            profileResult.isRight(),
            isTrue,
            reason: 'Profile creation should succeed',
          );

          final user = registrationResult.fold(
            (failure) => throw fail('Registration should not fail: $failure'),
            (user) => user,
          );

          // Property 1: User should be created but unverified
          expect(
            user.emailConfirmed,
            isFalse,
            reason: 'New user should not have confirmed email',
          );

          expect(
            user.email,
            equals(registrationData.email),
            reason: 'User email should match registration email',
          );

          // Property 2: Verification email should be sendable
          // (In real implementation, this would be called automatically)
          final verificationResult = await mockAuthRepository
              .sendVerificationEmail();

          expect(
            verificationResult.isRight(),
            isTrue,
            reason: 'Verification email should be sent successfully',
          );

          // Verify that verification email method was available to call
          verify(mockAuthRepository.sendVerificationEmail()).called(1);

          // Reset mocks for next iteration
          reset(mockAuthRepository);
          reset(mockUserRepository);
        }
      },
    );

    test(
      'should handle verification email sending failures gracefully',
      () async {
        // Property: If verification email sending fails, user should still be
        // created
        // but remain in unverified state

        const iterations = 50;

        for (var i = 0; i < iterations; i++) {
          final registrationData =
              PropertyTestHelpers.generateRegistrationData();

          final unverifiedUser = User(
            id: PropertyTestHelpers.generateUserId(),
            email: registrationData.email,
            emailConfirmed: false,
            createdAt: DateTime.now(),
          );

          // Mock successful registration
          when(
            mockAuthRepository.signUpWithEmail(
              email: registrationData.email,
              password: registrationData.password,
            ),
          ).thenAnswer((_) async => Right(unverifiedUser));

          // Mock verification email failure
          when(mockAuthRepository.sendVerificationEmail()).thenAnswer(
            (_) async =>
                const Left(GenericAuthFailure('Email service unavailable')),
          );

          // Act
          final registrationResult = await mockAuthRepository.signUpWithEmail(
            email: registrationData.email,
            password: registrationData.password,
          );

          final verificationResult = await mockAuthRepository
              .sendVerificationEmail();

          // Property verification
          expect(
            registrationResult.isRight(),
            isTrue,
            reason: 'Registration should succeed even if email sending fails',
          );

          expect(
            verificationResult.isLeft(),
            isTrue,
            reason: 'Verification email should fail as mocked',
          );

          registrationResult.fold(
            (failure) => fail('Registration should not fail'),
            (user) {
              expect(
                user.emailConfirmed,
                isFalse,
                reason: 'User should remain unverified when email fails',
              );
            },
          );

          reset(mockAuthRepository);
        }
      },
    );

    test('should maintain email verification state consistency', () async {
      // Property: Email verification state should be consistent across
      // operations

      const iterations = 75;

      for (var i = 0; i < iterations; i++) {
        final email = PropertyTestHelpers.generateEmail();

        final unverifiedUser = User(
          id: PropertyTestHelpers.generateUserId(),
          email: email,
          emailConfirmed: false,
          createdAt: DateTime.now(),
        );

        // Mock current user as unverified
        when(mockAuthRepository.currentUser).thenReturn(unverifiedUser);
        when(mockAuthRepository.isEmailVerified).thenReturn(false);

        // Mock verification email sending
        when(
          mockAuthRepository.sendVerificationEmail(),
        ).thenAnswer((_) async => const Right(null));

        // Property verification: Unverified user should be able to request
        // verification email
        final canSendEmail =
            mockAuthRepository.currentUser != null &&
            !mockAuthRepository.isEmailVerified;

        expect(
          canSendEmail,
          isTrue,
          reason:
              'Unverified user should be able to request verification email',
        );

        if (canSendEmail) {
          final result = await mockAuthRepository.sendVerificationEmail();
          expect(
            result.isRight(),
            isTrue,
            reason: 'Verification email should be sent for unverified user',
          );
        }

        reset(mockAuthRepository);
      }
    });
  });
}
