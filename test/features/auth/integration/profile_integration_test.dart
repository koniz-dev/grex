import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/main.dart' as app;
import 'package:mockito/mockito.dart';

import '../../../helpers/test_helpers.mocks.dart';

/// Integration tests for profile management flows
///
/// Tests complete profile operations from UI to database persistence
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
void main() {
  group('Profile Management Integration Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late User testUser;
    late UserProfile testProfile;

    setUp(() async {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();

      testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastSignInAt: DateTime.now(),
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

      // Reset dependency injection
      await configureDependencies();

      // Override with mocks for testing
      getIt
        ..unregister<AuthRepository>()
        ..unregister<UserRepository>()
        ..registerSingleton<AuthRepository>(mockAuthRepository)
        ..registerSingleton<UserRepository>(mockUserRepository);

      // Setup authenticated user
      when(mockAuthRepository.currentUser).thenReturn(testUser);
      when(
        mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => Stream.value(testUser));
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('Profile loading from database', (tester) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => Right(testProfile));

      // Act - Launch app (should navigate to profile since user is
      // authenticated)
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to profile page
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Assert - Verify profile data is loaded and displayed
      verify(mockUserRepository.getUserProfile(testUser.id)).called(1);

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('VND'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
    });

    testWidgets('Profile updates with database persistence', (tester) async {
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
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => Right(testProfile));

      // Mock successful profile update
      when(
        mockUserRepository.updateUserProfile(any),
      ).thenAnswer((_) async => Right(updatedProfile));

      // Act - Launch app and navigate to profile
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Navigate to edit profile
      await tester.tap(find.byKey(const Key('edit_profile_button')));
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

      // Verify navigation back to profile page
      expect(find.text('Chỉnh sửa hồ sơ'), findsNothing);
      expect(find.text('Hồ sơ'), findsOneWidget);

      // Verify updated data is displayed
      expect(find.text(updatedDisplayName), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('Profile error scenarios', (tester) async {
      // Arrange - Mock profile loading failure
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => const Left(UserNotFoundFailure()));

      // Act - Launch app and navigate to profile
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Assert - Verify error message is displayed
      expect(find.text('Không tìm thấy thông tin người dùng'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);

      // Test retry functionality
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => Right(testProfile));

      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pumpAndSettle();

      // Verify profile loads after retry
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('Profile update validation errors', (tester) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => Right(testProfile));

      // Act - Launch app and navigate to edit profile
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_profile_button')));
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

    testWidgets('Profile update network error handling', (tester) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => Right(testProfile));

      // Mock network error on update
      when(
        mockUserRepository.updateUserProfile(any),
      ).thenAnswer(
        (_) async =>
            const Left(GenericUserFailure('Network connection failed')),
      );

      // Act - Launch app and navigate to edit profile
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_profile_button')));
      await tester.pumpAndSettle();

      // Update display name
      await tester.enterText(
        find.byKey(const Key('edit_display_name_field')),
        'New Name',
      );

      // Try to save
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      // Assert - Verify error message is shown
      expect(find.text('Lỗi kết nối mạng'), findsOneWidget);
      expect(find.byKey(const Key('retry_update_button')), findsOneWidget);

      // Test retry functionality
      final updatedProfile = testProfile.copyWith(
        displayName: 'New Name',
        updatedAt: DateTime.now(),
      );

      when(
        mockUserRepository.updateUserProfile(any),
      ).thenAnswer((_) async => Right(updatedProfile));

      await tester.tap(find.byKey(const Key('retry_update_button')));
      await tester.pumpAndSettle();

      // Verify update succeeds after retry
      expect(find.text('Lỗi kết nối mạng'), findsNothing);
      expect(find.text('New Name'), findsOneWidget);
    });

    testWidgets('Profile update optimistic updates and rollback', (
      tester,
    ) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => Right(testProfile));

      // Mock update failure after delay (to test optimistic update)
      when(mockUserRepository.updateUserProfile(any)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return const Left(GenericUserFailure('Network connection failed'));
      });

      // Act - Launch app and navigate to edit profile
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_profile_button')));
      await tester.pumpAndSettle();

      // Update display name
      const newName = 'Optimistic Update Name';
      await tester.enterText(
        find.byKey(const Key('edit_display_name_field')),
        newName,
      );

      // Save changes
      await tester.tap(find.byKey(const Key('save_profile_button')));

      // Pump a few frames to see optimistic update
      await tester.pump(const Duration(milliseconds: 100));

      // Should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for update to complete (and fail)
      await tester.pumpAndSettle();

      // Assert - Verify error is shown and original data is restored
      expect(find.text('Lỗi kết nối mạng'), findsOneWidget);

      // Navigate back to profile to check rollback
      await tester.tap(find.byKey(const Key('cancel_edit_button')));
      await tester.pumpAndSettle();

      // Verify original name is restored
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text(newName), findsNothing);
    });

    testWidgets('Profile data consistency across navigation', (tester) async {
      // Arrange
      when(
        mockUserRepository.getUserProfile(testUser.id),
      ).thenAnswer((_) async => Right(testProfile));

      // Act - Launch app and navigate to profile multiple times
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Verify profile data
      expect(find.text('Test User'), findsOneWidget);

      // Navigate away and back
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Assert - Verify data is still consistent
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      // Verify repository was called only once (cached)
      verify(mockUserRepository.getUserProfile(testUser.id)).called(1);
    });
  });
}
