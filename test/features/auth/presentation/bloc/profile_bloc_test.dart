import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/repositories.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:mockito/mockito.dart';

// Manual mocks for now
class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('ProfileBloc', () {
    late MockUserRepository mockUserRepository;
    late MockAuthRepository mockAuthRepository;
    late ProfileBloc profileBloc;

    // Test data
    final testUser = User(
      id: 'test-user-id',
      email: 'test@example.com',
      createdAt: DateTime.now(),
      lastSignInAt: DateTime.now(),
    );

    final testProfile = UserProfile(
      id: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
      preferredCurrency: 'VND',
      languageCode: 'vi',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockUserRepository = MockUserRepository();
      mockAuthRepository = MockAuthRepository();
      profileBloc = ProfileBloc(
        userRepository: mockUserRepository,
        authRepository: mockAuthRepository,
      );
    });

    tearDown(() async {
      await profileBloc.close();
    });

    test('initial state is ProfileInitial', () {
      expect(profileBloc.state, equals(const ProfileInitial()));
    });

    group('ProfileLoadRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileLoaded] when profile is loaded '
        'successfully',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(testUser);
          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested()),
        expect: () => [
          const ProfileLoading(),
          ProfileLoaded(profile: testProfile),
        ],
        verify: (_) {
          verify(mockAuthRepository.currentUser).called(1);
          verify(mockUserRepository.getUserProfile(testUser.id)).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when no authenticated user',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(null);
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested()),
        expect: () => [
          const ProfileLoading(),
          const ProfileError(message: 'No authenticated user found'),
        ],
        verify: (_) {
          verify(mockAuthRepository.currentUser).called(1);
          verifyNever(mockUserRepository.getUserProfile(''));
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when profile loading fails',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(testUser);
          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => const Left(UserNotFoundFailure()));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested()),
        expect: () => [
          const ProfileLoading(),
          const ProfileError(
            message: 'User profile not found. Please try refreshing.',
            failure: UserNotFoundFailure(),
          ),
        ],
      );
    });

    group('ProfileUpdateRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdating, ProfileUpdateSuccess] when update succeeds',
        build: () {
          final updatedProfile = testProfile.copyWith(
            displayName: 'Updated Name',
          );
          when(
            mockUserRepository.updateUserProfile(testProfile),
          ).thenAnswer((_) async => Right(updatedProfile));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            displayName: 'Updated Name',
          ),
        ),
        expect: () => [
          ProfileUpdating(
            profile: testProfile,
            updatedProfile: testProfile.copyWith(displayName: 'Updated Name'),
          ),
          ProfileUpdateSuccess(
            profile: testProfile.copyWith(displayName: 'Updated Name'),
          ),
        ],
        verify: (_) {
          verify(
            mockUserRepository.updateUserProfile(testProfile),
          ).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileError when no profile data available',
        build: () => profileBloc,
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            displayName: 'Updated Name',
          ),
        ),
        expect: () => [
          const ProfileError(message: 'No profile data available for update'),
        ],
        verify: (_) {
          verifyNever(
            mockUserRepository.updateUserProfile(testProfile),
          );
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileError when validation fails',
        build: () => profileBloc,
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            displayName: '', // Invalid empty display name
          ),
        ),
        expect: () => [
          ProfileError(
            message: 'Display name is required',
            profile: testProfile,
          ),
        ],
        verify: (_) {
          verifyNever(
            mockUserRepository.updateUserProfile(testProfile),
          );
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileError when no changes provided',
        build: () => profileBloc,
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(const ProfileUpdateRequested()),
        expect: () => [
          ProfileError(
            message: 'No changes to update',
            profile: testProfile,
          ),
        ],
        verify: (_) {
          verifyNever(
            mockUserRepository.updateUserProfile(testProfile),
          );
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileError when update fails',
        build: () {
          when(
            mockUserRepository.updateUserProfile(testProfile),
          ).thenAnswer(
            (_) async => const Left(UserDatabaseFailure('Update failed')),
          );
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            displayName: 'Updated Name',
          ),
        ),
        expect: () => [
          ProfileUpdating(
            profile: testProfile,
            updatedProfile: testProfile.copyWith(displayName: 'Updated Name'),
          ),
          ProfileError(
            message: 'Update failed',
            profile: testProfile,
            failure: const UserDatabaseFailure('Update failed'),
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'validates currency code correctly',
        build: () => profileBloc,
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            preferredCurrency: 'INVALID', // Invalid currency code
          ),
        ),
        expect: () => [
          ProfileError(
            message: 'Currency code must be exactly 3 characters',
            profile: testProfile,
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'validates language code correctly',
        build: () => profileBloc,
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            languageCode: 'invalid', // Invalid language code
          ),
        ),
        expect: () => [
          ProfileError(
            message: 'Language code is not supported',
            profile: testProfile,
          ),
        ],
      );
    });

    group('ProfileRefreshRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileLoaded] when refresh succeeds',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(testUser);
          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(const ProfileRefreshRequested()),
        expect: () => [
          const ProfileLoading(),
          ProfileLoaded(profile: testProfile),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'preserves profile data when refresh fails',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(testUser);
          when(mockUserRepository.getUserProfile(testUser.id)).thenAnswer(
            (_) async => const Left(UserDatabaseFailure('Network error')),
          );
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(const ProfileRefreshRequested()),
        expect: () => [
          const ProfileLoading(),
          ProfileError(
            message: 'Database error occurred. Please try again later.',
            profile: testProfile,
            failure: const UserDatabaseFailure('Network error'),
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'handles refresh from error state',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(testUser);
          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));
          return profileBloc;
        },
        seed: () => ProfileError(
          message: 'Previous error',
          profile: testProfile,
        ),
        act: (bloc) => bloc.add(const ProfileRefreshRequested()),
        expect: () => [
          const ProfileLoading(),
          ProfileLoaded(profile: testProfile),
        ],
      );
    });

    group('Error Message Mapping', () {
      test('maps UserNotFoundFailure correctly', () {
        const failure = UserNotFoundFailure();
        expect(failure.message, equals('User profile not found'));
      });

      test('maps InvalidUserDataFailure correctly', () {
        const failure = InvalidUserDataFailure('Custom error message');
        expect(failure.message, equals('Custom error message'));
      });

      test('maps UserDatabaseFailure correctly', () {
        const failure = UserDatabaseFailure('Database error');
        expect(failure.message, equals('Database error'));
      });
    });

    group('Optimistic Updates', () {
      blocTest<ProfileBloc, ProfileState>(
        'shows optimistic update before actual update',
        build: () {
          // Delay the repository response to test optimistic update
          when(
            mockUserRepository.updateUserProfile(testProfile),
          ).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return Right(testProfile.copyWith(displayName: 'Updated Name'));
          });
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            displayName: 'Updated Name',
          ),
        ),
        expect: () => [
          ProfileUpdating(
            profile: testProfile,
            updatedProfile: testProfile.copyWith(displayName: 'Updated Name'),
          ),
          ProfileUpdateSuccess(
            profile: testProfile.copyWith(displayName: 'Updated Name'),
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'reverts optimistic update on failure',
        build: () {
          when(
            mockUserRepository.updateUserProfile(testProfile),
          ).thenAnswer(
            (_) async => const Left(UserDatabaseFailure('Network error')),
          );
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            displayName: 'Updated Name',
          ),
        ),
        expect: () => [
          ProfileUpdating(
            profile: testProfile,
            updatedProfile: testProfile.copyWith(displayName: 'Updated Name'),
          ),
          ProfileError(
            message: 'Database error occurred. Please try again later.',
            profile: testProfile,
            failure: const UserDatabaseFailure('Network error'),
          ),
        ],
      );
    });
  });
}
