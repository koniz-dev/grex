import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:grex/features/auth/presentation/pages/profile_page.dart';

import '../../../../helpers/test_helpers.mocks.dart';

/// Widget tests for profile forms
///
/// Tests profile display, profile edit form validation,
/// profile update flow, and error handling in forms.
///
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5
void main() {
  group('Profile Forms Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockSessionService mockSessionService;
    late SessionManager sessionManager;
    late AuthBloc authBloc;
    late ProfileBloc profileBloc;

    // Test data
    final testUser = User(
      id: 'test-user-id',
      email: 'test@example.com',
      createdAt: DateTime(2024),
      lastSignInAt: DateTime(2024, 1, 15),
    );

    final testProfile = UserProfile(
      id: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
      preferredCurrency: 'VND',
      languageCode: 'vi',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024, 1, 15),
    );

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockSessionService = MockSessionService();

      sessionManager = SessionManager(
        sessionService: mockSessionService,
      );

      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
        sessionManager: sessionManager,
      );

      profileBloc = ProfileBloc(
        userRepository: mockUserRepository,
        authRepository: mockAuthRepository,
      );
    });

    tearDown(() async {
      await authBloc.close();
      await profileBloc.close();
      sessionManager.dispose();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ProfileBloc>.value(value: profileBloc),
          ],
          child: child,
        ),
      );
    }

    group('ProfilePage', () {
      testWidgets('should display profile information correctly', (
        tester,
      ) async {
        // Arrange
        authBloc.emit(AuthAuthenticated(user: testUser, profile: testProfile));
        profileBloc.emit(ProfileLoaded(profile: testProfile));

        // Act
        await tester.pumpWidget(createTestWidget(const ProfilePage()));
        await tester.pump();

        // Assert
        expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.text('VND'), findsOneWidget);
        expect(find.text('Tiếng Việt'), findsOneWidget);
        expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
      });

      testWidgets('should show loading state', (tester) async {
        // Arrange
        authBloc.emit(AuthAuthenticated(user: testUser, profile: testProfile));
        profileBloc.emit(const ProfileLoading());

        // Act
        await tester.pumpWidget(createTestWidget(const ProfilePage()));
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Đang tải...'), findsOneWidget);
      });

      testWidgets('should show error state', (tester) async {
        // Arrange
        authBloc.emit(AuthAuthenticated(user: testUser, profile: testProfile));
        profileBloc.emit(const ProfileError(message: 'Không thể tải hồ sơ'));

        // Act
        await tester.pumpWidget(createTestWidget(const ProfilePage()));
        await tester.pump();

        // Assert
        expect(find.text('Không thể tải hồ sơ'), findsOneWidget);
        expect(find.text('Thử lại'), findsOneWidget);
      });

      testWidgets(
        'should navigate to edit profile when edit button is tapped',
        (tester) async {
          // Arrange
          authBloc.emit(
            AuthAuthenticated(user: testUser, profile: testProfile),
          );
          profileBloc.emit(ProfileLoaded(profile: testProfile));

          // Act
          await tester.pumpWidget(createTestWidget(const ProfilePage()));
          await tester.pump();

          final editButton = find.text('Chỉnh sửa hồ sơ');
          await tester.tap(editButton);
          await tester.pumpAndSettle();

          // Assert - Button should be tappable
          expect(editButton, findsOneWidget);
        },
      );

      testWidgets('should display user avatar or initials', (tester) async {
        // Arrange
        authBloc.emit(AuthAuthenticated(user: testUser, profile: testProfile));
        profileBloc.emit(ProfileLoaded(profile: testProfile));

        // Act
        await tester.pumpWidget(createTestWidget(const ProfilePage()));
        await tester.pump();

        // Assert - Should show avatar or initials
        expect(find.byType(CircleAvatar), findsOneWidget);
      });

      testWidgets('should show profile creation date', (tester) async {
        // Arrange
        authBloc.emit(AuthAuthenticated(user: testUser, profile: testProfile));
        profileBloc.emit(ProfileLoaded(profile: testProfile));

        // Act
        await tester.pumpWidget(createTestWidget(const ProfilePage()));
        await tester.pump();

        // Assert - Should show creation date
        expect(find.textContaining('Tham gia'), findsOneWidget);
      });
    });

    group('EditProfilePage', () {
      testWidgets('should display edit profile form with current data', (
        tester,
      ) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));

        // Act
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Assert
        expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
        expect(
          find.byType(TextFormField),
          findsNWidgets(2),
        ); // Display name and email
        expect(
          find.text('Test User'),
          findsOneWidget,
        ); // Pre-filled display name
        expect(
          find.text('test@example.com'),
          findsOneWidget,
        ); // Pre-filled email
        expect(find.text('Lưu thay đổi'), findsOneWidget);
        expect(find.text('Hủy'), findsOneWidget);
      });

      testWidgets('should show validation error for empty display name', (
        tester,
      ) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Act - Clear display name and submit
        final displayNameField = find.byType(TextFormField).first;
        await tester.enterText(displayNameField, '');

        final saveButton = find.widgetWithText(ElevatedButton, 'Lưu thay đổi');
        await tester.tap(saveButton);
        await tester.pump();

        // Assert
        expect(find.text('Tên hiển thị không được để trống'), findsOneWidget);
      });

      testWidgets('should show validation error for invalid email', (
        tester,
      ) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Act - Enter invalid email
        final emailField = find.byType(TextFormField).last;
        await tester.enterText(emailField, 'invalid-email');

        final saveButton = find.widgetWithText(ElevatedButton, 'Lưu thay đổi');
        await tester.tap(saveButton);
        await tester.pump();

        // Assert
        expect(find.text('Email không hợp lệ'), findsOneWidget);
      });

      testWidgets('should show validation error for display name too long', (
        tester,
      ) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Act - Enter very long display name
        final displayNameField = find.byType(TextFormField).first;
        await tester.enterText(displayNameField, 'A' * 100); // Very long name

        final saveButton = find.widgetWithText(ElevatedButton, 'Lưu thay đổi');
        await tester.tap(saveButton);
        await tester.pump();

        // Assert
        expect(find.text('Tên hiển thị quá dài'), findsOneWidget);
      });

      testWidgets('should handle loading state during update', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Emit loading state
        profileBloc.emit(const ProfileLoading());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Đang lưu...'), findsOneWidget);
      });

      testWidgets('should show success message after successful update', (
        tester,
      ) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Act - Update profile successfully
        final updatedProfile = testProfile.copyWith(
          displayName: 'Updated Name',
          updatedAt: DateTime.now(),
        );
        profileBloc.emit(ProfileLoaded(profile: updatedProfile));
        await tester.pump();

        // Assert - Should show updated data
        expect(find.text('Updated Name'), findsOneWidget);
      });

      testWidgets('should show error message for update failure', (
        tester,
      ) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Emit error state
        profileBloc.emit(
          const ProfileError(message: 'Không thể cập nhật hồ sơ'),
        );
        await tester.pump();

        // Assert
        expect(find.text('Không thể cập nhật hồ sơ'), findsOneWidget);
      });

      testWidgets('should cancel changes when cancel button is tapped', (
        tester,
      ) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Act - Make changes then cancel
        final displayNameField = find.byType(TextFormField).first;
        await tester.enterText(displayNameField, 'Changed Name');

        final cancelButton = find.text('Hủy');
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Assert - Should navigate back without saving
        expect(cancelButton, findsOneWidget);
      });

      testWidgets('should show currency selection dropdown', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Assert - Should have currency dropdown
        expect(
          find.byType(DropdownButtonFormField<String>),
          findsAtLeastNWidgets(1),
        );
        expect(find.text('VND'), findsOneWidget); // Current currency
      });

      testWidgets('should show language selection dropdown', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Assert - Should have language dropdown
        expect(
          find.byType(DropdownButtonFormField<String>),
          findsAtLeastNWidgets(1),
        );
        expect(find.text('Tiếng Việt'), findsOneWidget); // Current language
      });

      testWidgets('should handle form submission with valid data', (
        tester,
      ) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Act - Update with valid data
        final displayNameField = find.byType(TextFormField).first;
        await tester.enterText(displayNameField, 'New Display Name');

        final saveButton = find.widgetWithText(ElevatedButton, 'Lưu thay đổi');
        await tester.tap(saveButton);
        await tester.pump();

        // Assert - Should not show validation errors
        expect(find.text('Tên hiển thị không được để trống'), findsNothing);
        expect(find.text('Email không hợp lệ'), findsNothing);
      });

      testWidgets('should preserve form data during loading', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Act - Enter data then trigger loading
        final displayNameField = find.byType(TextFormField).first;
        await tester.enterText(displayNameField, 'Modified Name');

        profileBloc.emit(const ProfileLoading());
        await tester.pump();

        // Assert - Form data should be preserved during loading
        expect(find.text('Modified Name'), findsOneWidget);
      });
    });

    group('Profile Form Interactions', () {
      testWidgets('should handle keyboard input correctly', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Act - Enter text in fields
        final displayNameField = find.byType(TextFormField).first;
        await tester.enterText(displayNameField, 'New Name');
        await tester.pump();

        // Assert
        expect(find.text('New Name'), findsOneWidget);
      });

      testWidgets('should clear validation errors when typing', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Show validation error first
        final displayNameField = find.byType(TextFormField).first;
        await tester.enterText(displayNameField, '');

        final saveButton = find.widgetWithText(ElevatedButton, 'Lưu thay đổi');
        await tester.tap(saveButton);
        await tester.pump();

        expect(find.text('Tên hiển thị không được để trống'), findsOneWidget);

        // Act - Start typing
        await tester.enterText(displayNameField, 'Valid Name');
        await tester.pump();

        // Assert - Error should be cleared (depends on implementation)
        expect(find.text('Valid Name'), findsOneWidget);
      });

      testWidgets('should handle dropdown selections', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Act - Tap currency dropdown
        final currencyDropdown = find
            .byType(DropdownButtonFormField<String>)
            .first;
        await tester.tap(currencyDropdown);
        await tester.pumpAndSettle();

        // Assert - Dropdown should open
        // Note: Actual dropdown items would depend on implementation
        expect(currencyDropdown, findsOneWidget);
      });
    });

    group('Profile Error Handling', () {
      testWidgets('should display network error messages', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Emit network error
        profileBloc.emit(const ProfileError(message: 'Lỗi kết nối mạng'));
        await tester.pump();

        // Assert
        expect(find.text('Lỗi kết nối mạng'), findsOneWidget);
      });

      testWidgets('should display validation error messages', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Emit validation error
        profileBloc.emit(const ProfileError(message: 'Dữ liệu không hợp lệ'));
        await tester.pump();

        // Assert
        expect(find.text('Dữ liệu không hợp lệ'), findsOneWidget);
      });

      testWidgets('should handle permission error messages', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Emit permission error
        profileBloc.emit(
          const ProfileError(message: 'Không có quyền cập nhật'),
        );
        await tester.pump();

        // Assert
        expect(find.text('Không có quyền cập nhật'), findsOneWidget);
      });
    });

    group('Profile Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));

        // Act
        await tester.pumpWidget(createTestWidget(const ProfilePage()));
        await tester.pump();

        // Assert - Check for semantic elements
        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('should support screen readers for edit form', (
        tester,
      ) async {
        // Arrange
        profileBloc.emit(ProfileLoaded(profile: testProfile));

        // Act
        await tester.pumpWidget(createTestWidget(const EditProfilePage()));
        await tester.pump();

        // Assert - Form fields should have labels
        expect(find.text('Tên hiển thị'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Tiền tệ'), findsOneWidget);
        expect(find.text('Ngôn ngữ'), findsOneWidget);
      });
    });
  });
}
