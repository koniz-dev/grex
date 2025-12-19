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
  group('Profile Display Property Tests', () {
    late MockUserRepository mockUserRepository;
    late MockAuthRepository mockAuthRepository;
    late ProfileBloc profileBloc;

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

    /// **Feature: 2-authentication, Property 5: Profile display shows current
    /// data**
    /// **Validates: Requirements 3.1**
    ///
    /// Property: For any authenticated user viewing their profile,
    /// the displayed information should match the current data in the users
    /// table
    group('Property 5: Profile display shows current data', () {
      test(
        'should display current profile data for any valid user profile',
        () async {
          // Property-based test with 100 iterations
          for (var i = 0; i < 100; i++) {
            // Generate random but valid profile data
            final testProfile = _generateRandomProfile(i);
            final testUser = _generateRandomUser(i);

            // Setup mocks
            when(mockAuthRepository.currentUser).thenReturn(testUser);
            when(
              mockUserRepository.getUserProfile(testUser.id),
            ).thenAnswer((_) async => Right(testProfile));

            // Create fresh bloc for each iteration
            final bloc = ProfileBloc(
              userRepository: mockUserRepository,
              authRepository: mockAuthRepository,
            );

            // Test the property
            await _testProfileDisplayProperty(bloc, testProfile);

            await bloc.close();
          }
        },
      );

      test(
        'should handle profile data consistency across multiple loads',
        () async {
          // Test that multiple loads of the same profile return consistent data
          for (var i = 0; i < 50; i++) {
            final testProfile = _generateRandomProfile(i);
            final testUser = _generateRandomUser(i);

            when(mockAuthRepository.currentUser).thenReturn(testUser);
            when(
              mockUserRepository.getUserProfile(testUser.id),
            ).thenAnswer((_) async => Right(testProfile));

            final bloc = ProfileBloc(
              userRepository: mockUserRepository,
              authRepository: mockAuthRepository,
            );

            // Load profile multiple times
            final stream = bloc.stream;
            bloc.add(const ProfileLoadRequested());
            await expectLater(
              stream,
              emitsInOrder([
                const ProfileLoading(),
                ProfileLoaded(profile: testProfile),
              ]),
            );

            // Load again - should return same data
            bloc.add(const ProfileRefreshRequested());
            await expectLater(
              bloc.stream,
              emitsInOrder([
                const ProfileLoading(),
                ProfileLoaded(profile: testProfile),
              ]),
            );

            await bloc.close();
          }
        },
      );

      test('should maintain data integrity for edge case profiles', () async {
        // Test with edge case profile data
        final edgeCaseProfiles = _generateEdgeCaseProfiles();

        for (final testProfile in edgeCaseProfiles) {
          final testUser = User(
            id: testProfile.id,
            email: testProfile.email,
            createdAt: DateTime.now(),
          );

          when(mockAuthRepository.currentUser).thenReturn(testUser);
          when(
            mockUserRepository.getUserProfile(testUser.id),
          ).thenAnswer((_) async => Right(testProfile));

          final bloc = ProfileBloc(
            userRepository: mockUserRepository,
            authRepository: mockAuthRepository,
          );

          await _testProfileDisplayProperty(bloc, testProfile);

          await bloc.close();
        }
      });
    });
  });
}

/// Tests the core property: displayed profile data matches repository data
Future<void> _testProfileDisplayProperty(
  ProfileBloc bloc,
  UserProfile expectedProfile,
) async {
  bloc.add(const ProfileLoadRequested());

  await expectLater(
    bloc.stream,
    emitsInOrder([
      const ProfileLoading(),
      ProfileLoaded(profile: expectedProfile),
    ]),
  );

  // Verify the loaded profile matches exactly
  final currentState = bloc.state;
  expect(currentState, isA<ProfileLoaded>());

  final loadedProfile = (currentState as ProfileLoaded).profile;

  // Property: All profile fields must match exactly
  expect(loadedProfile.id, equals(expectedProfile.id));
  expect(loadedProfile.email, equals(expectedProfile.email));
  expect(loadedProfile.displayName, equals(expectedProfile.displayName));
  expect(
    loadedProfile.preferredCurrency,
    equals(expectedProfile.preferredCurrency),
  );
  expect(loadedProfile.languageCode, equals(expectedProfile.languageCode));
  expect(loadedProfile.createdAt, equals(expectedProfile.createdAt));
  expect(loadedProfile.updatedAt, equals(expectedProfile.updatedAt));
}

/// Generates random but valid user profiles for property testing
UserProfile _generateRandomProfile(int seed) {
  final random = _SeededRandom(seed);

  final currencies = ['VND', 'USD', 'EUR', 'GBP', 'JPY'];
  final languages = ['vi', 'en', 'zh', 'ja', 'ko'];
  final domains = ['test.com', 'example.org', 'demo.net'];

  final userId = 'user-${random.nextInt(10000)}';
  final email =
      'user${random.nextInt(1000)}@${domains[random.nextInt(domains.length)]}';
  final displayName = 'User ${random.nextInt(1000)}';
  final currency = currencies[random.nextInt(currencies.length)];
  final language = languages[random.nextInt(languages.length)];

  final createdAt = DateTime.now().subtract(
    Duration(days: random.nextInt(365)),
  );
  final updatedAt = createdAt.add(Duration(hours: random.nextInt(24 * 30)));

  return UserProfile(
    id: userId,
    email: email,
    displayName: displayName,
    preferredCurrency: currency,
    languageCode: language,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Generates random but valid users for property testing
User _generateRandomUser(int seed) {
  final random = _SeededRandom(seed);
  final domains = ['test.com', 'example.org', 'demo.net'];

  final userId = 'user-${random.nextInt(10000)}';
  final email =
      'user${random.nextInt(1000)}@${domains[random.nextInt(domains.length)]}';
  final emailConfirmed = random.nextBool();
  final createdAt = DateTime.now().subtract(
    Duration(days: random.nextInt(365)),
  );
  final lastSignInAt = random.nextBool()
      ? createdAt.add(Duration(hours: random.nextInt(24 * 30)))
      : null;

  return User(
    id: userId,
    email: email,
    emailConfirmed: emailConfirmed,
    createdAt: createdAt,
    lastSignInAt: lastSignInAt,
  );
}

/// Generates edge case profiles for comprehensive testing
List<UserProfile> _generateEdgeCaseProfiles() {
  final now = DateTime.now();

  return [
    // Minimum length display name
    UserProfile(
      id: 'edge-1',
      email: 'min@test.com',
      displayName: 'AB',
      preferredCurrency: 'VND',
      languageCode: 'vi',
      createdAt: now,
      updatedAt: now,
    ),

    // Maximum length display name
    UserProfile(
      id: 'edge-2',
      email: 'max@test.com',
      displayName: 'A' * 50,
      preferredCurrency: 'USD',
      languageCode: 'en',
      createdAt: now,
      updatedAt: now,
    ),

    // Special characters in display name
    UserProfile(
      id: 'edge-3',
      email: 'special@test.com',
      displayName: 'User-Name_123',
      preferredCurrency: 'EUR',
      languageCode: 'zh',
      createdAt: now,
      updatedAt: now,
    ),

    // Very old profile
    UserProfile(
      id: 'edge-4',
      email: 'old@test.com',
      displayName: 'Old User',
      preferredCurrency: 'JPY',
      languageCode: 'ja',
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020, 1, 2),
    ),

    // Recently created profile
    UserProfile(
      id: 'edge-5',
      email: 'new@test.com',
      displayName: 'New User',
      preferredCurrency: 'GBP',
      languageCode: 'ko',
      createdAt: now.subtract(const Duration(minutes: 1)),
      updatedAt: now,
    ),
  ];
}

/// Simple seeded random number generator for reproducible tests
class _SeededRandom {
  _SeededRandom(this._seed);
  int _seed;

  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }

  bool nextBool() => nextInt(2) == 1;
}
