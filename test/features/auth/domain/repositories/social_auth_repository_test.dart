import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/entities/profile_setup_data.dart';
import 'package:grex/features/auth/domain/repositories/social_auth_repository.dart';

/// Mock implementation of SocialAuthRepository for testing
class MockSocialAuthRepository implements SocialAuthRepository {
  bool shouldSucceed = true;
  bool hasProfile = false;
  AuthFailure? failureToReturn;

  @override
  Future<Either<AuthFailure, User>> signInWithGoogle() async {
    if (!shouldSucceed) {
      return Left(
        failureToReturn ?? const SocialAuthFailure('Google sign in failed'),
      );
    }
    return Right(_createMockUser('google-user-id', 'google@example.com'));
  }

  @override
  Future<Either<AuthFailure, User>> signInWithApple({
    bool useNativeFlow = true,
  }) async {
    if (!shouldSucceed) {
      return Left(
        failureToReturn ?? const SocialAuthFailure('Apple sign in failed'),
      );
    }
    return Right(_createMockUser('apple-user-id', 'apple@example.com'));
  }

  @override
  Future<bool> hasUserProfile(String userId) async {
    if (!shouldSucceed) {
      // In a real implementation, this would throw or handle the error
      // differently
      // For testing, we'll return false on failure
      return false;
    }
    return hasProfile;
  }

  @override
  Future<Either<AuthFailure, void>> linkSocialProvider({
    required String userId,
    required SocialAuthProvider provider,
  }) async {
    if (!shouldSucceed) {
      return Left(
        failureToReturn ?? const AccountLinkingFailure('Linking failed'),
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<AuthFailure, UserProfile>> createUserProfile(
    String userId,
    ProfileSetupData profileData,
  ) async {
    if (!shouldSucceed) {
      return Left(
        failureToReturn ?? const GenericAuthFailure('Profile creation failed'),
      );
    }
    return Right(_createMockUserProfile(userId, profileData));
  }

  UserProfile _createMockUserProfile(String userId, ProfileSetupData data) {
    return UserProfile(
      id: userId,
      email: 'test@example.com',
      displayName: data.displayName,
      preferredCurrency: data.preferredCurrency,
      languageCode: data.languageCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  User _createMockUser(String id, String email) {
    return User(
      id: id,
      email: email,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  group('SocialAuthRepository Interface', () {
    late MockSocialAuthRepository repository;

    setUp(() {
      repository = MockSocialAuthRepository();
    });

    group('signInWithGoogle', () {
      test('should return User on successful Google sign in', () async {
        // Arrange
        repository.shouldSucceed = true;

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (user) {
            expect(user.id, 'google-user-id');
            expect(user.email, 'google@example.com');
          },
        );
      });

      test(
        'should return SocialAuthFailure on Google sign in failure',
        () async {
          // Arrange
          repository.shouldSucceed = false;

          // Act
          final result = await repository.signInWithGoogle();

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<SocialAuthFailure>()),
            (user) => fail('Should not return user'),
          );
        },
      );

      test(
        'should return SocialAuthCancelledFailure when user cancels',
        () async {
          // Arrange
          repository
            ..shouldSucceed = false
            ..failureToReturn = const SocialAuthCancelledFailure();

          // Act
          final result = await repository.signInWithGoogle();

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<SocialAuthCancelledFailure>()),
            (user) => fail('Should not return user'),
          );
        },
      );

      test('should return SocialAuthNetworkFailure on network error', () async {
        // Arrange
        repository
          ..shouldSucceed = false
          ..failureToReturn = const SocialAuthNetworkFailure();

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<SocialAuthNetworkFailure>()),
          (user) => fail('Should not return user'),
        );
      });

      test('should return ProfileSetupRequiredFailure for new users', () async {
        // Arrange
        repository
          ..shouldSucceed = false
          ..failureToReturn = const ProfileSetupRequiredFailure();

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ProfileSetupRequiredFailure>()),
          (user) => fail('Should not return user'),
        );
      });
    });

    group('signInWithApple', () {
      test('should return User on successful Apple sign in', () async {
        // Arrange
        repository.shouldSucceed = true;

        // Act
        final result = await repository.signInWithApple();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (user) {
            expect(user.id, 'apple-user-id');
            expect(user.email, 'apple@example.com');
          },
        );
      });

      test(
        'should return SocialAuthFailure on Apple sign in failure',
        () async {
          // Arrange
          repository.shouldSucceed = false;

          // Act
          final result = await repository.signInWithApple();

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<SocialAuthFailure>()),
            (user) => fail('Should not return user'),
          );
        },
      );

      test(
        'should return SocialAuthCancelledFailure when user cancels',
        () async {
          // Arrange
          repository
            ..shouldSucceed = false
            ..failureToReturn = const SocialAuthCancelledFailure();

          // Act
          final result = await repository.signInWithApple();

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<SocialAuthCancelledFailure>()),
            (user) => fail('Should not return user'),
          );
        },
      );
    });

    group('hasUserProfile', () {
      test('should return true when user profile exists', () async {
        // Arrange
        repository
          ..shouldSucceed = true
          ..hasProfile = true;

        // Act
        final result = await repository.hasUserProfile('test-user-id');

        // Assert
        expect(result, true);
      });

      test('should return false when user profile does not exist', () async {
        // Arrange
        repository
          ..shouldSucceed = true
          ..hasProfile = false;

        // Act
        final result = await repository.hasUserProfile('test-user-id');

        // Assert
        expect(result, false);
      });

      test('should return false on database error', () async {
        // Arrange
        repository.shouldSucceed = false;

        // Act
        final result = await repository.hasUserProfile('test-user-id');

        // Assert
        expect(result, false);
      });
    });

    group('linkSocialProvider', () {
      test('should return success on successful linking', () async {
        // Arrange
        repository.shouldSucceed = true;

        // Act
        final result = await repository.linkSocialProvider(
          userId: 'test-user-id',
          provider: SocialAuthProvider.google,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (_) => <String, dynamic>{}, // Success - void return
        );
      });

      test(
        'should return AccountLinkingFailure when provider already linked',
        () async {
          // Arrange
          repository
            ..shouldSucceed = false
            ..failureToReturn = const AccountLinkingFailure(
              'Provider already linked to another account',
            );

          // Act
          final result = await repository.linkSocialProvider(
            userId: 'test-user-id',
            provider: SocialAuthProvider.google,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<AccountLinkingFailure>()),
            (_) => fail('Should not return success'),
          );
        },
      );

      test(
        'should return SocialAuthCancelledFailure when user cancels',
        () async {
          // Arrange
          repository
            ..shouldSucceed = false
            ..failureToReturn = const SocialAuthCancelledFailure();

          // Act
          final result = await repository.linkSocialProvider(
            userId: 'test-user-id',
            provider: SocialAuthProvider.apple,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<SocialAuthCancelledFailure>()),
            (_) => fail('Should not return success'),
          );
        },
      );
    });

    group('createUserProfile', () {
      test(
        'should return UserProfile on successful profile creation',
        () async {
          // Arrange
          repository.shouldSucceed = true;
          const profileData = ProfileSetupData(
            displayName: 'Test User',
            preferredCurrency: 'VND',
            languageCode: 'vi',
            socialProvider: SocialAuthProvider.google,
          );

          // Act
          final result = await repository.createUserProfile(
            'test-user-id',
            profileData,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should not return failure'),
            (profile) {
              expect(profile.id, 'test-user-id');
              expect(profile.displayName, 'Test User');
              expect(profile.preferredCurrency, 'VND');
              expect(profile.languageCode, 'vi');
            },
          );
        },
      );

      test('should return AuthFailure on profile creation failure', () async {
        // Arrange
        repository.shouldSucceed = false;
        const profileData = ProfileSetupData(
          displayName: 'Test User',
          preferredCurrency: 'VND',
          languageCode: 'vi',
        );

        // Act
        final result = await repository.createUserProfile(
          'test-user-id',
          profileData,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Should not return success'),
        );
      });
    });
  });
}
