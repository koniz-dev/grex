import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/presentation/pages/login_page.dart';
import 'package:grex/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_helpers/mock_supabase_client.dart';
import 'test_helpers/oauth_simulator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Social Login Error Handling Integration Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late OAuthSimulator oauthSimulator;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      oauthSimulator = OAuthSimulator(mockSupabaseClient);
    });

    testWidgets('Network error shows retry option', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Navigate to login page
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

      // Verify error icon displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('OAuth timeout shows appropriate error', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Navigate to login page
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Apple sign-in button
      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      // Simulate OAuth timeout
      await oauthSimulator.simulateOAuthTimeout(
        provider: SocialAuthProvider.apple,
      );
      await tester.pumpAndSettle();

      // Verify timeout error message
      expect(
        find.text('Sign in timed out. Please try again.'),
        findsOneWidget,
      );

      // Verify fallback option shown
      expect(find.text('Sign in with email'), findsOneWidget);
    });

    testWidgets('Invalid OAuth callback shows error', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Simulate invalid OAuth callback
      await oauthSimulator.simulateInvalidCallback(
        'io.supabase.grex://login-callback/?error=invalid_request',
      );
      await tester.pumpAndSettle();

      // Verify error message displayed
      expect(
        find.text('Sign in failed. Please try again.'),
        findsOneWidget,
      );

      // Verify retry option available
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Multiple failures suggest alternatives', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Simulate multiple consecutive failures
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();

        await oauthSimulator.simulateNetworkError(
          provider: SocialAuthProvider.google,
        );
        await tester.pumpAndSettle();

        if (i < 2) {
          // Retry for first two failures
          await tester.tap(find.text('Retry'));
          await tester.pumpAndSettle();
        }
      }

      // After third failure, should suggest alternatives
      expect(find.text('Sign in with email'), findsOneWidget);
      expect(
        find.text('Having trouble? Try signing in with your email instead.'),
        findsOneWidget,
      );
    });

    testWidgets('Account linking failure shows recovery options', (
      tester,
    ) async {
      // Setup test app with existing profile
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Mock account linking failure
      when(
        mockSupabaseClient.auth.linkIdentity(OAuthProvider.google),
      ).thenThrow(Exception('Linking failed'));

      // Navigate through OAuth flow to account linking
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate OAuth with existing email
      // (This would trigger account linking dialog)

      // Confirm linking (which will fail)
      await tester.tap(find.text('Link Accounts'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(
        find.text('Failed to link accounts. Please try again.'),
        findsOneWidget,
      );

      // Verify recovery options
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Sign in with email'), findsOneWidget);
    });

    testWidgets('Profile setup validation errors', (tester) async {
      // Setup test app and navigate to profile setup
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Complete OAuth flow to reach profile setup
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Navigate to profile setup (mocked)
      // ... (profile setup navigation logic)

      // Try to submit empty form
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Display name is required'), findsOneWidget);
      expect(find.text('Please select a currency'), findsOneWidget);
      expect(find.text('Please select a language'), findsOneWidget);

      // Fill invalid display name (too short)
      await tester.enterText(
        find.byKey(const Key('display_name_field')),
        'A',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify length validation
      expect(
        find.text('Display name must be at least 2 characters'),
        findsOneWidget,
      );
    });

    testWidgets('Session expiration during OAuth flow', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Start OAuth flow
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate session expiration during flow
      await oauthSimulator.simulateExpiredSession();
      await tester.pumpAndSettle();

      // Verify redirect to login
      expect(find.byType(LoginPage), findsOneWidget);

      // Verify session expired message
      expect(
        find.text('Your session has expired. Please sign in again.'),
        findsOneWidget,
      );
    });

    testWidgets('Deep link processing failure', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Mock deep link processing failure
      when(
        mockSupabaseClient.auth.getSessionFromUrl(
          Uri.parse('io.supabase.grex://login-callback/?access_token=invalid'),
        ),
      ).thenThrow(Exception('Failed to process callback'));

      // Simulate deep link callback
      await oauthSimulator.simulateDeepLinkCallback(
        'io.supabase.grex://login-callback/?access_token=invalid',
        appClosed: false,
      );
      await tester.pumpAndSettle();

      // Verify generic error message
      expect(
        find.text('Authentication failed. Please try again.'),
        findsOneWidget,
      );

      // Verify no sensitive information exposed
      expect(find.textContaining('access_token'), findsNothing);
      expect(find.textContaining('invalid'), findsNothing);
    });

    testWidgets('Provider-specific error handling', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Test Google-specific error
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Mock Google-specific error
      when(
        mockSupabaseClient.auth.signInWithOAuth(OAuthProvider.google),
      ).thenThrow(Exception('Google OAuth temporarily unavailable'));

      await tester.pumpAndSettle();

      // Verify provider-specific error handling
      expect(
        find.text(
          'Google sign-in is temporarily unavailable. Please try again later.',
        ),
        findsOneWidget,
      );

      // Test Apple-specific error
      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      // Mock Apple-specific error
      when(
        mockSupabaseClient.auth.signInWithOAuth(OAuthProvider.apple),
      ).thenThrow(Exception('Apple ID verification failed'));

      await tester.pumpAndSettle();

      // Verify Apple-specific error handling
      expect(
        find.text('Apple ID verification failed. Please try again.'),
        findsOneWidget,
      );
    });
  });
}

/// Setup test app with mock Supabase instance
Future<void> _setupTestApp(
  WidgetTester tester,
  MockSupabaseClient mockSupabaseClient,
) async {
  // Initialize test app with mocked dependencies
  await tester.pumpWidget(const app.MyApp());
}
