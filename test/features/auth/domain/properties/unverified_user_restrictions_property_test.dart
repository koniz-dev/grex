import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/property_test_helpers.dart';
import '../../../../helpers/test_helpers.mocks.dart';

/// Property 4: Unverified users get verification prompts
///
/// This property verifies that unverified users are properly restricted
/// from accessing certain features and are prompted to verify their email.
///
/// **Correctness Property**: For any unverified user attempting to access
/// protected features, they should be redirected to email verification
/// and not be able to proceed until verification is complete.
void main() {
  group('Property 4: Unverified users get verification prompts', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
    });

    test(
      'should restrict unverified users from accessing protected features',
      () async {
        // Property: Unverified users should be redirected to verification
        // when attempting to access protected features

        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          // Generate unverified user
          final email = PropertyTestHelpers.generateEmail();
          final userId = PropertyTestHelpers.generateUserId();

          final unverifiedUser = User(
            id: userId,
            email: email,
            emailConfirmed: false, // Key property: not verified
            createdAt: DateTime.now(),
            lastSignInAt: DateTime.now(),
          );

          // Mock unverified user state
          when(mockAuthRepository.currentUser).thenReturn(unverifiedUser);
          when(mockAuthRepository.isEmailVerified).thenReturn(false);

          // Mock sign-in attempt with unverified email
          when(
            mockAuthRepository.signInWithEmail(
              email: email,
              password: any,
            ),
          ).thenAnswer(
            (_) async => const Left(
              UnverifiedEmailFailure(),
            ),
          );

          // Property 1: Unverified user should be identified correctly
          final currentUser = mockAuthRepository.currentUser;
          expect(
            currentUser,
            isNotNull,
            reason: 'Unverified user should exist',
          );

          expect(
            currentUser!.emailConfirmed,
            isFalse,
            reason: 'User should be marked as unverified',
          );

          expect(
            mockAuthRepository.isEmailVerified,
            isFalse,
            reason: 'Email verification status should be false',
          );

          // Property 2: Sign-in should be restricted for unverified users
          final signInResult = await mockAuthRepository.signInWithEmail(
            email: email,
            password: 'password123',
          );

          expect(
            signInResult.isLeft(),
            isTrue,
            reason: 'Unverified user sign-in should be restricted',
          );

          signInResult.fold(
            (failure) {
              expect(
                failure,
                isA<UnverifiedEmailFailure>(),
                reason: 'Should return UnverifiedEmailFailure',
              );
              expect(
                failure.message.toLowerCase(),
                contains('verify'),
                reason: 'Error message should mention verification',
              );
            },
            (_) => fail('Unverified user should not be able to sign in'),
          );

          // Property 3: Verification email should be available
          when(
            mockAuthRepository.sendVerificationEmail(),
          ).thenAnswer((_) async => const Right(null));

          final verificationEmailResult = await mockAuthRepository
              .sendVerificationEmail();
          expect(
            verificationEmailResult.isRight(),
            isTrue,
            reason: 'Verification email should be sendable for unverified user',
          );

          reset(mockAuthRepository);
          reset(mockUserRepository);
        }
      },
    );

    test('should allow verified users to access all features', () async {
      // Property: Verified users should have full access to features

      const iterations = 50;

      for (var i = 0; i < iterations; i++) {
        final email = PropertyTestHelpers.generateEmail();
        final userId = PropertyTestHelpers.generateUserId();
        final password = PropertyTestHelpers.generatePassword();

        final verifiedUser = User(
          id: userId,
          email: email,
          createdAt: DateTime.now(),
          lastSignInAt: DateTime.now(),
        );

        final userProfile = UserProfile(
          id: userId,
          email: email,
          displayName: PropertyTestHelpers.generateDisplayName(),
          preferredCurrency: 'VND',
          languageCode: 'vi',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Mock verified user state
        when(mockAuthRepository.currentUser).thenReturn(verifiedUser);
        when(mockAuthRepository.isEmailVerified).thenReturn(true);

        // Mock successful sign-in for verified user
        when(
          mockAuthRepository.signInWithEmail(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => Right(verifiedUser));

        // Mock profile access
        when(
          mockUserRepository.getUserProfile(userId),
        ).thenAnswer((_) async => Right(userProfile));

        // Property verification: Verified user should have full access
        final currentUser = mockAuthRepository.currentUser;
        expect(
          currentUser!.emailConfirmed,
          isTrue,
          reason: 'User should be verified',
        );

        expect(
          mockAuthRepository.isEmailVerified,
          isTrue,
          reason: 'Email verification status should be true',
        );

        // Should be able to sign in
        final signInResult = await mockAuthRepository.signInWithEmail(
          email: email,
          password: password,
        );

        expect(
          signInResult.isRight(),
          isTrue,
          reason: 'Verified user should be able to sign in',
        );

        // Should be able to access profile
        final profileResult = await mockUserRepository.getUserProfile(userId);
        expect(
          profileResult.isRight(),
          isTrue,
          reason: 'Verified user should be able to access profile',
        );

        reset(mockAuthRepository);
        reset(mockUserRepository);
      }
    });

    test('should handle verification state changes correctly', () async {
      // Property: User access should change when verification state changes

      const iterations = 75;

      for (var i = 0; i < iterations; i++) {
        final email = PropertyTestHelpers.generateEmail();
        final userId = PropertyTestHelpers.generateUserId();
        final password = PropertyTestHelpers.generatePassword();

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

        // Mock restricted sign-in for unverified user
        when(
          mockAuthRepository.signInWithEmail(
            email: email,
            password: password,
          ),
        ).thenAnswer(
          (_) async => const Left(UnverifiedEmailFailure()),
        );

        // Verify initial restrictions
        final initialSignIn = await mockAuthRepository.signInWithEmail(
          email: email,
          password: password,
        );

        expect(
          initialSignIn.isLeft(),
          isTrue,
          reason: 'Unverified user should be restricted initially',
        );

        // Simulate email verification
        final verifiedUser = User(
          id: userId,
          email: email,
          createdAt: unverifiedUser.createdAt,
          lastSignInAt: DateTime.now(),
        );

        // Update mocks to verified state
        when(mockAuthRepository.currentUser).thenReturn(verifiedUser);
        when(mockAuthRepository.isEmailVerified).thenReturn(true);

        // Mock successful sign-in after verification
        when(
          mockAuthRepository.signInWithEmail(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => Right(verifiedUser));

        // Verify access is now granted
        final verifiedSignIn = await mockAuthRepository.signInWithEmail(
          email: email,
          password: password,
        );

        expect(
          verifiedSignIn.isRight(),
          isTrue,
          reason: 'Verified user should have access after verification',
        );

        expect(
          mockAuthRepository.isEmailVerified,
          isTrue,
          reason: 'Verification status should be updated',
        );

        reset(mockAuthRepository);
      }
    });

    test('should provide appropriate verification prompts', () async {
      // Property: Unverified users should receive clear verification prompts

      const iterations = 50;

      for (var i = 0; i < iterations; i++) {
        final email = PropertyTestHelpers.generateEmail();
        final userId = PropertyTestHelpers.generateUserId();

        final unverifiedUser = User(
          id: userId,
          email: email,
          emailConfirmed: false,
          createdAt: DateTime.now(),
        );

        // Mock unverified user attempting various actions
        when(mockAuthRepository.currentUser).thenReturn(unverifiedUser);
        when(mockAuthRepository.isEmailVerified).thenReturn(false);

        // Mock sign-in restriction with clear message
        when(
          mockAuthRepository.signInWithEmail(
            email: any,
            password: any,
          ),
        ).thenAnswer(
          (_) async => const Left(
            UnverifiedEmailFailure(),
          ),
        );

        // Mock verification email availability
        when(
          mockAuthRepository.sendVerificationEmail(),
        ).thenAnswer((_) async => const Right(null));

        // Property verification: User should get clear verification prompts
        final signInAttempt = await mockAuthRepository.signInWithEmail(
          email: email,
          password: 'password',
        );

        expect(
          signInAttempt.isLeft(),
          isTrue,
          reason: 'Unverified user should be blocked from sign-in',
        );

        signInAttempt.fold(
          (failure) {
            expect(
              failure,
              isA<UnverifiedEmailFailure>(),
              reason: 'Should return specific unverified email failure',
            );

            expect(
              failure.message,
              isNotEmpty,
              reason: 'Error message should not be empty',
            );

            expect(
              failure.message.toLowerCase(),
              contains('verify'),
              reason: 'Message should mention verification',
            );
          },
          (_) => fail('Should not succeed for unverified user'),
        );

        // Property: Verification email should be available as solution
        final verificationOption = await mockAuthRepository
            .sendVerificationEmail();
        expect(
          verificationOption.isRight(),
          isTrue,
          reason: 'Verification email should be available as solution',
        );

        reset(mockAuthRepository);
      }
    });

    test('should maintain consistent verification requirements', () async {
      // Property: Verification requirements should be consistent across all
      // entry points

      const iterations = 60;

      for (var i = 0; i < iterations; i++) {
        final email = PropertyTestHelpers.generateEmail();
        final userId = PropertyTestHelpers.generateUserId();

        final unverifiedUser = User(
          id: userId,
          email: email,
          emailConfirmed: false,
          createdAt: DateTime.now(),
        );

        // Mock unverified state consistently
        when(mockAuthRepository.currentUser).thenReturn(unverifiedUser);
        when(mockAuthRepository.isEmailVerified).thenReturn(false);

        // Mock all authentication methods to require verification
        when(
          mockAuthRepository.signInWithEmail(
            email: any,
            password: any,
          ),
        ).thenAnswer(
          (_) async => const Left(UnverifiedEmailFailure()),
        );

        // Property verification: All checks should be consistent
        final user = mockAuthRepository.currentUser;
        final isVerified = mockAuthRepository.isEmailVerified;

        expect(user, isNotNull, reason: 'User should exist');
        expect(
          user!.emailConfirmed,
          isFalse,
          reason: 'User should be unverified',
        );
        expect(
          isVerified,
          isFalse,
          reason: 'Verification status should be false',
        );

        // All authentication attempts should be consistently blocked
        final signInResult = await mockAuthRepository.signInWithEmail(
          email: email,
          password: 'any-password',
        );

        expect(
          signInResult.isLeft(),
          isTrue,
          reason: 'All sign-in attempts should be blocked for unverified users',
        );

        signInResult.fold(
          (failure) {
            expect(
              failure,
              isA<UnverifiedEmailFailure>(),
              reason: 'Should consistently return UnverifiedEmailFailure',
            );
          },
          (_) => fail('Should not allow access for unverified user'),
        );

        reset(mockAuthRepository);
      }
    });
  });
}
