import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:grex/features/auth/presentation/bloc/profile_event.dart';
import 'package:grex/features/auth/presentation/bloc/profile_state.dart';
import 'package:grex/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:grex/features/auth/presentation/pages/profile_page.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_helpers.mocks.dart';

/// Integration tests for profile management flows
///
/// Tests complete profile operations from UI through BLoC to repository
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
void main() {
  group('Profile Management Flow Integration Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late ProfileBloc profileBloc;
    late UserProfile testProfile;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      profileBloc = ProfileBloc(
        userRepository: mockUserRepository,
        authRepository: mockAuthRepository,
      );

      testProfile = UserProfile(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        preferredCurrency: 'VND',
        languageCode: 'vi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    tearDown(() async {
      await profileBloc.close();
    });

    testWidgets('Profile display flow - load and show data', (tester) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile('test-user-id'),
      ).thenAnswer((_) async => Right(testProfile));

      // Act - Build profile page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const ProfilePage(),
          ),
        ),
      );

      // Trigger profile load
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Assert - Verify profile data is displayed
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('VND'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);

      // Verify repository was called
      verify(mockUserRepository.getUserProfile('test-user-id')).called(1);
    });

    testWidgets('Profile edit flow - update and persist changes', (
      tester,
    ) async {
      // Arrange
      const updatedDisplayName = 'Updated User Name';
      const updatedCurrency = 'USD';
      const updatedLanguage = 'en';

      final updatedProfile = testProfile.copyWith(
        displayName: updatedDisplayName,
        preferredCurrency: updatedCurrency,
        languageCode: updatedLanguage,
        updatedAt: DateTime.now(),
      );

      // Mock initial profile load
      when(
        mockUserRepository.getUserProfile('test-user-id'),
      ).thenAnswer((_) async => Right(testProfile));

      // Mock successful profile update
      when(
        mockUserRepository.updateUserProfile(any),
      ).thenAnswer((_) async => Right(updatedProfile));

      // Act - Build edit profile page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const EditProfilePage(),
          ),
        ),
      );

      // Load initial profile
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Update profile fields
      await tester.enterText(
        find.byKey(const Key('edit_display_name_field')),
        updatedDisplayName,
      );

      // Select USD currency
      await tester.tap(find.byKey(const Key('currency_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD').last);
      await tester.pumpAndSettle();

      // Select English language
      await tester.tap(find.byKey(const Key('language_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      // Assert - Verify update was called with correct data
      final captured =
          verify(
                mockUserRepository.updateUserProfile(captureAny),
              ).captured.single
              as UserProfile;

      expect(captured.displayName, equals(updatedDisplayName));
      expect(captured.preferredCurrency, equals(updatedCurrency));
      expect(captured.languageCode, equals(updatedLanguage));

      // Verify BLoC state shows updated profile
      expect(profileBloc.state, isA<ProfileLoaded>());
      final loadedState = profileBloc.state as ProfileLoaded;
      expect(loadedState.profile.displayName, equals(updatedDisplayName));
    });

    testWidgets('Profile validation flow - prevent invalid updates', (
      tester,
    ) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile('test-user-id'),
      ).thenAnswer((_) async => Right(testProfile));

      // Act - Build edit profile page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const EditProfilePage(),
          ),
        ),
      );

      // Load initial profile
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Clear display name (invalid)
      await tester.enterText(
        find.byKey(const Key('edit_display_name_field')),
        '',
      );

      // Try to save
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      // Assert - Verify validation error is shown
      expect(find.text('Tên hiển thị không được để trống'), findsOneWidget);

      // Verify repository was not called due to validation
      verifyNever(mockUserRepository.updateUserProfile(any));
    });

    testWidgets('Profile error handling flow - network failure', (
      tester,
    ) async {
      // Arrange - Mock profile loading failure
      when(
        mockUserRepository.getUserProfile('test-user-id'),
      ).thenAnswer((_) async => const Left(UserNotFoundFailure()));

      // Act - Build profile page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const ProfilePage(),
          ),
        ),
      );

      // Trigger profile load
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Assert - Verify error message is displayed
      expect(find.text('Không tìm thấy thông tin người dùng'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);

      // Verify BLoC is in error state
      expect(profileBloc.state, isA<ProfileError>());
    });

    testWidgets('Profile retry flow - recover from error', (tester) async {
      // Arrange - Mock initial failure then success
      var callCount = 0;
      when(mockUserRepository.getUserProfile('test-user-id')).thenAnswer((
        _,
      ) async {
        callCount++;
        if (callCount == 1) {
          return const Left(GenericUserFailure('Network connection failed'));
        }
        return Right(testProfile);
      });

      // Act - Build profile page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const ProfilePage(),
          ),
        ),
      );

      // Trigger initial profile load (fails)
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Verify error state
      expect(find.text('Lỗi kết nối mạng'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);

      // Retry loading
      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pumpAndSettle();

      // Assert - Verify profile loads successfully after retry
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      // Verify repository was called twice (initial + retry)
      verify(mockUserRepository.getUserProfile('test-user-id')).called(2);
    });

    testWidgets('Profile update error flow - handle update failure', (
      tester,
    ) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile('test-user-id'),
      ).thenAnswer((_) async => Right(testProfile));

      // Mock network error on update
      when(
        mockUserRepository.updateUserProfile(any),
      ).thenAnswer(
        (_) async =>
            const Left(GenericUserFailure('Network connection failed')),
      );

      // Act - Build edit profile page with BLoC
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const EditProfilePage(),
          ),
        ),
      );

      // Load initial profile
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Update display name
      await tester.enterText(
        find.byKey(const Key('edit_display_name_field')),
        'New Name',
      );

      // Try to save (fails)
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      // Assert - Verify error message is shown
      expect(find.text('Lỗi kết nối mạng'), findsOneWidget);
      expect(find.byKey(const Key('retry_update_button')), findsOneWidget);

      // Verify BLoC is in error state
      expect(profileBloc.state, isA<ProfileError>());
    });

    testWidgets('Profile optimistic update flow - rollback on failure', (
      tester,
    ) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile('test-user-id'),
      ).thenAnswer((_) async => Right(testProfile));

      // Mock update failure after delay (to test optimistic update)
      when(mockUserRepository.updateUserProfile(any)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return const Left(GenericUserFailure('Network connection failed'));
      });

      // Act - Load initial profile
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(profileBloc.state, isA<ProfileLoaded>());
      final initialState = profileBloc.state as ProfileLoaded;
      expect(initialState.profile.displayName, equals('Test User'));

      // Update profile (will fail)
      const newName = 'Optimistic Update Name';
      testProfile.copyWith(
        displayName: newName,
        updatedAt: DateTime.now(),
      );

      profileBloc.add(
        const ProfileUpdateRequested(
          displayName: newName,
        ),
      );

      // Pump a few frames to see optimistic update
      await tester.pump(const Duration(milliseconds: 50));

      // Should show loading state initially
      expect(profileBloc.state, isA<ProfileLoading>());

      // Wait for update to complete (and fail)
      await tester.pumpAndSettle();

      // Assert - Verify error state and original data is preserved
      expect(profileBloc.state, isA<ProfileError>());

      // Reload to verify original data is still there
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      final reloadedState = profileBloc.state as ProfileLoaded;
      expect(reloadedState.profile.displayName, equals('Test User'));
    });

    testWidgets('Profile data consistency flow - multiple operations', (
      tester,
    ) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile('test-user-id'),
      ).thenAnswer((_) async => Right(testProfile));

      // Act - Load profile multiple times
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Verify profile data
      expect(profileBloc.state, isA<ProfileLoaded>());
      var loadedState = profileBloc.state as ProfileLoaded;
      expect(loadedState.profile.displayName, equals('Test User'));

      // Load again
      profileBloc.add(const ProfileLoadRequested());
      await tester.pumpAndSettle();

      // Assert - Verify data is still consistent
      expect(profileBloc.state, isA<ProfileLoaded>());
      loadedState = profileBloc.state as ProfileLoaded;
      expect(loadedState.profile.displayName, equals('Test User'));
      expect(loadedState.profile.email, equals('test@example.com'));

      // Verify repository was called multiple times
      verify(mockUserRepository.getUserProfile('test-user-id')).called(2);
    });
  });
}
