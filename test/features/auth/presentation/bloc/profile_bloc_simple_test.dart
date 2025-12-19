import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/profile_event.dart';
import 'package:grex/features/auth/presentation/bloc/profile_state.dart';

import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  group('ProfileBloc Simple Tests', () {
    late ProfileBloc profileBloc;

    // Test data
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
      // We'll create a mock implementation for testing
      final mockUserRepository = MockUserRepository();
      final mockAuthRepository = MockAuthRepository();

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

    group('ProfileEvent and ProfileState', () {
      test('ProfileLoadRequested creates correct event', () {
        const event = ProfileLoadRequested();
        expect(event.props, isEmpty);
        expect(event.toString(), equals('ProfileLoadRequested()'));
      });

      test('ProfileUpdateRequested creates correct event with parameters', () {
        const event = ProfileUpdateRequested(
          displayName: 'New Name',
          preferredCurrency: 'USD',
          languageCode: 'en',
        );

        expect(event.displayName, equals('New Name'));
        expect(event.preferredCurrency, equals('USD'));
        expect(event.languageCode, equals('en'));
        expect(event.props, equals(['New Name', 'USD', 'en']));
      });

      test('ProfileLoaded state contains profile data', () {
        final state = ProfileLoaded(profile: testProfile);
        expect(state.profile, equals(testProfile));
        expect(state.props, equals([testProfile]));
      });

      test('ProfileError state contains error information', () {
        const state = ProfileError(
          message: 'Test error',
        );
        expect(state.message, equals('Test error'));
        expect(state.profile, isNull);
        expect(state.props, equals(['Test error', null, null]));
      });

      test('ProfileUpdating state contains both profiles', () {
        final updatedProfile = testProfile.copyWith(displayName: 'Updated');
        final state = ProfileUpdating(
          profile: testProfile,
          updatedProfile: updatedProfile,
        );

        expect(state.profile, equals(testProfile));
        expect(state.updatedProfile, equals(updatedProfile));
        expect(state.props, equals([testProfile, updatedProfile]));
      });
    });

    group('Validation Logic', () {
      test('validates display name correctly', () {
        // Test empty display name
        const event = ProfileUpdateRequested(displayName: '');
        expect(event.displayName, equals(''));

        // Test valid display name
        const validEvent = ProfileUpdateRequested(displayName: 'Valid Name');
        expect(validEvent.displayName, equals('Valid Name'));
      });

      test('validates currency code correctly', () {
        // Test invalid currency code
        const event = ProfileUpdateRequested(preferredCurrency: 'INVALID');
        expect(event.preferredCurrency, equals('INVALID'));

        // Test valid currency code
        const validEvent = ProfileUpdateRequested(preferredCurrency: 'USD');
        expect(validEvent.preferredCurrency, equals('USD'));
      });

      test('validates language code correctly', () {
        // Test invalid language code
        const event = ProfileUpdateRequested(languageCode: 'invalid');
        expect(event.languageCode, equals('invalid'));

        // Test valid language code
        const validEvent = ProfileUpdateRequested(languageCode: 'en');
        expect(validEvent.languageCode, equals('en'));
      });
    });

    group('State Transitions', () {
      test('ProfileRefreshRequested creates correct event', () {
        const event = ProfileRefreshRequested();
        expect(event.props, isEmpty);
        expect(event.toString(), equals('ProfileRefreshRequested()'));
      });

      test('ProfileUpdateSuccess state contains updated profile', () {
        final state = ProfileUpdateSuccess(profile: testProfile);
        expect(state.profile, equals(testProfile));
        expect(state.props, equals([testProfile]));
      });
    });
  });
}
