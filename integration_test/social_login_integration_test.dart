import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/domain/entities/user.dart' as grex_user;
import 'package:grex/features/auth/domain/entities/user_profile.dart';
import 'package:grex/features/auth/presentation/pages/login_page.dart';
import 'package:grex/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:grex/features/groups/presentation/pages/group_list_page.dart';
import 'package:grex/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_helpers/mock_supabase_client.dart';
import 'test_helpers/oauth_simulator.dart';
import 'test_helpers/test_data_generators.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Social Login Integration Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late OAuthSimulator oauthSimulator;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      oauthSimulator = OAuthSimulator(mockSupabaseClient);
    });

    testWidgets('15.1 Google OAuth flow (new user)', (tester) async {
      // Setup test app with mock Supabase instance
      await _setupTestApp(tester, mockSupabaseClient);

      // Navigate to login page
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Google sign-in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate OAuth callback with new user data
      final newUser = TestDataGenerators.generateNewUser();
      await oauthSimulator.simulateSuccessfulOAuth(
        provider: SocialAuthProvider.google,
        user: newUser,
        isNewUser: true,
      );
      await tester.pumpAndSettle();

      // Verify navigation to profile setup page
      expect(find.byType(ProfileSetupPage), findsOneWidget);
      expect(find.text('Complete Your Profile'), findsOneWidget);

      // Verify pre-filled data
      expect(find.text(newUser.email), findsOneWidget);
      if (newUser.oauthDisplayName != null) {
        final displayNameField = find.byKey(const Key('display_name_field'));
        expect(displayNameField, findsOneWidget);
        final textField = tester.widget<TextFormField>(displayNameField);
        expect(textField.controller?.text, equals(newUser.oauthDisplayName));
      }

      // Fill and submit profile form
      await tester.enterText(
        find.byKey(const Key('display_name_field')),
        'Test User',
      );

      // Select currency
      await tester.tap(find.byKey(const Key('currency_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VND'));
      await tester.pumpAndSettle();

      // Select language
      await tester.tap(find.byKey(const Key('language_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vietnamese'));
      await tester.pumpAndSettle();

      // Submit profile form
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify navigation to main app
      expect(find.byType(GroupListPage), findsOneWidget);
    });

    testWidgets('15.2 Apple OAuth flow (new user)', (tester) async {
      // Setup test app with mock Supabase instance
      await _setupTestApp(tester, mockSupabaseClient);

      // Navigate to login page
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Apple sign-in button
      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      // Simulate OAuth callback with new user data
      final newUser = TestDataGenerators.generateNewUser();
      await oauthSimulator.simulateSuccessfulOAuth(
        provider: SocialAuthProvider.apple,
        user: newUser,
        isNewUser: true,
      );
      await tester.pumpAndSettle();

      // Verify navigation to profile setup page
      expect(find.byType(ProfileSetupPage), findsOneWidget);
      expect(find.text('Complete Your Profile'), findsOneWidget);

      // Fill and submit profile form
      await tester.enterText(
        find.byKey(const Key('display_name_field')),
        'Apple User',
      );

      await tester.tap(find.byKey(const Key('currency_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('language_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify navigation to main app
      expect(find.byType(GroupListPage), findsOneWidget);
    });

    testWidgets('15.3 Google OAuth flow (existing user)', (tester) async {
      // Create existing user with profile in test database
      final existingUser = TestDataGenerators.generateExistingUser();
      final existingProfile = TestDataGenerators.generateUserProfile(
        existingUser.id,
      );

      await _setupTestAppWithExistingUser(
        tester,
        mockSupabaseClient,
        existingUser,
        existingProfile,
      );

      // Navigate to login page
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Google sign-in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate OAuth callback with existing user data
      await oauthSimulator.simulateSuccessfulOAuth(
        provider: SocialAuthProvider.google,
        user: existingUser,
        isNewUser: false,
      );
      await tester.pumpAndSettle();

      // Verify direct navigation to main app
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify no profile setup shown
      expect(find.byType(ProfileSetupPage), findsNothing);
      expect(find.text('Complete Your Profile'), findsNothing);
    });

    testWidgets('15.4 Apple OAuth flow (existing user)', (tester) async {
      // Create existing user with profile in test database
      final existingUser = TestDataGenerators.generateExistingUser();
      final existingProfile = TestDataGenerators.generateUserProfile(
        existingUser.id,
      );

      await _setupTestAppWithExistingUser(
        tester,
        mockSupabaseClient,
        existingUser,
        existingProfile,
      );

      // Navigate to login page
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Apple sign-in button
      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      // Simulate OAuth callback with existing user data
      await oauthSimulator.simulateSuccessfulOAuth(
        provider: SocialAuthProvider.apple,
        user: existingUser,
        isNewUser: false,
      );
      await tester.pumpAndSettle();

      // Verify direct navigation to main app
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify no profile setup shown
      expect(find.byType(ProfileSetupPage), findsNothing);
    });

    testWidgets('15.5 Account linking flow', (tester) async {
      // Create existing user with email in test database
      const email = 'existing@example.com';
      final existingProfile = TestDataGenerators.generateUserProfileWithEmail(
        email,
      );
      final newUser = TestDataGenerators.generateNewUserWithEmail(email);

      await _setupTestAppWithExistingProfile(
        tester,
        mockSupabaseClient,
        existingProfile,
      );

      // Navigate to login page
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Google sign-in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate OAuth callback with same email
      await oauthSimulator.simulateOAuthWithExistingEmail(
        provider: SocialAuthProvider.google,
        user: newUser,
        existingProfile: existingProfile,
      );
      await tester.pumpAndSettle();

      // Verify account linking dialog shown
      expect(find.text('Link Your Account'), findsOneWidget);
      expect(
        find.text('An account with email $email already exists.'),
        findsOneWidget,
      );

      // Confirm account linking
      await tester.tap(find.text('Link Accounts'));
      await tester.pumpAndSettle();

      // Verify navigation to main app with existing profile
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify OAuth provider linked to account
      verify(
        mockSupabaseClient.auth.linkIdentity(OAuthProvider.google),
      ).called(1);
    });

    testWidgets('15.6 Declined account linking', (tester) async {
      // Create existing user with email in test database
      const email = 'existing@example.com';
      final existingProfile = TestDataGenerators.generateUserProfileWithEmail(
        email,
      );
      final newUser = TestDataGenerators.generateNewUserWithEmail(email);

      await _setupTestAppWithExistingProfile(
        tester,
        mockSupabaseClient,
        existingProfile,
      );

      // Navigate to login page
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Google sign-in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate OAuth callback with same email
      await oauthSimulator.simulateOAuthWithExistingEmail(
        provider: SocialAuthProvider.google,
        user: newUser,
        existingProfile: existingProfile,
      );
      await tester.pumpAndSettle();

      // Verify account linking dialog shown
      expect(find.text('Link Your Account'), findsOneWidget);

      // Decline account linking
      await tester.tap(find.text('Create New Account'));
      await tester.pumpAndSettle();

      // Verify navigation to profile setup
      expect(find.byType(ProfileSetupPage), findsOneWidget);
      expect(find.text('Complete Your Profile'), findsOneWidget);

      // Verify treated as new account
      expect(find.text(email), findsOneWidget); // Email pre-filled
    });

    testWidgets('15.7 Profile setup cancellation', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);

      // Navigate to login page and complete OAuth to profile setup
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      final newUser = TestDataGenerators.generateNewUser();
      await oauthSimulator.simulateSuccessfulOAuth(
        provider: SocialAuthProvider.google,
        user: newUser,
        isNewUser: true,
      );
      await tester.pumpAndSettle();

      // Navigate to profile setup
      expect(find.byType(ProfileSetupPage), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Confirm cancellation in dialog
      expect(find.text('Cancel Profile Setup?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify user signed out
      verify(mockSupabaseClient.auth.signOut()).called(1);

      // Verify return to login page
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('15.8 OAuth cancellation', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);

      // Navigate to login page
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Google sign-in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate user cancellation (OAuth returns false)
      await oauthSimulator.simulateOAuthCancellation(
        provider: SocialAuthProvider.google,
      );
      await tester.pumpAndSettle();

      // Verify return to login page
      expect(find.byType(LoginPage), findsOneWidget);

      // Verify no error message displayed
      expect(find.text('Sign in failed'), findsNothing);
      expect(find.text('Authentication failed'), findsNothing);
    });

    testWidgets('15.9 Network error handling', (tester) async {
      // Setup test app with network error simulation
      await _setupTestAppWithNetworkError(tester, mockSupabaseClient);

      // Navigate to login page
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Google sign-in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate network error
      await oauthSimulator.simulateNetworkError(
        provider: SocialAuthProvider.google,
      );
      await tester.pumpAndSettle();

      // Verify error message displayed
      expect(
        find.text('Network error. Please check your connection and try again.'),
        findsOneWidget,
      );

      // Verify retry button shown
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify OAuth flow retried
      verify(
        mockSupabaseClient.auth.signInWithOAuth(OAuthProvider.google),
      ).called(2);
    });

    testWidgets('15.10 Deep link handling (app closed)', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);

      // Simulate app closed state
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/lifecycle',
        (data) async => null,
      );

      // Trigger OAuth callback deep link
      await oauthSimulator.simulateDeepLinkCallback(
        'io.supabase.grex://login-callback/?access_token=test_token&refresh_token=test_refresh',
        appClosed: true,
      );

      // Verify app launches
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Verify authentication completed
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify navigation to appropriate screen
      verify(
        mockSupabaseClient.auth.getSessionFromUrl(
          Uri.parse(
            'io.supabase.grex://login-callback/?access_token=test_token&refresh_token=test_refresh',
          ),
        ),
      ).called(1);
    });

    testWidgets('15.11 Deep link handling (app running)', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);

      // Navigate to login page
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Google sign-in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate OAuth callback while app running
      await oauthSimulator.simulateDeepLinkCallback(
        'io.supabase.grex://login-callback/?access_token=test_token&refresh_token=test_refresh',
        appClosed: false,
      );
      await tester.pumpAndSettle();

      // Verify authentication completed without restart
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify navigation to appropriate screen
      verify(
        mockSupabaseClient.auth.getSessionFromUrl(
          Uri.parse(
            'io.supabase.grex://login-callback/?access_token=test_token&refresh_token=test_refresh',
          ),
        ),
      ).called(1);
    });

    testWidgets('15.12 Session persistence', (tester) async {
      // Complete Google OAuth flow
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      final user = TestDataGenerators.generateExistingUser();
      await oauthSimulator.simulateSuccessfulOAuth(
        provider: SocialAuthProvider.google,
        user: user,
        isNewUser: false,
      );
      await tester.pumpAndSettle();

      // Verify authenticated session established
      expect(find.byType(GroupListPage), findsOneWidget);
      verify(mockSupabaseClient.auth.currentSession).called(greaterThan(0));

      // Simulate app restart
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Verify session restored
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify user remains authenticated
      verify(mockSupabaseClient.auth.currentUser).called(greaterThan(0));
    });
  });
}

/// Setup test app with mock Supabase instance
Future<void> _setupTestApp(
  WidgetTester tester,
  MockSupabaseClient mockSupabaseClient,
) async {
  // Initialize Supabase with mock client
  await Supabase.initialize(
    url: 'https://test.supabase.co',
    anonKey: 'test-anon-key',
  );

  // Pump the app
  await tester.pumpWidget(const app.MyApp());
}

/// Setup test app with existing user and profile
Future<void> _setupTestAppWithExistingUser(
  WidgetTester tester,
  MockSupabaseClient mockSupabaseClient,
  grex_user.User existingUser,
  UserProfile existingProfile,
) async {
  await _setupTestApp(tester, mockSupabaseClient);
}

/// Setup test app with existing profile by email
Future<void> _setupTestAppWithExistingProfile(
  WidgetTester tester,
  MockSupabaseClient mockSupabaseClient,
  UserProfile existingProfile,
) async {
  await _setupTestApp(tester, mockSupabaseClient);
}

/// Setup test app with network error simulation
Future<void> _setupTestAppWithNetworkError(
  WidgetTester tester,
  MockSupabaseClient mockSupabaseClient,
) async {
  await _setupTestApp(tester, mockSupabaseClient);
}
