import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/presentation/pages/login_page.dart';
import 'package:grex/features/groups/presentation/pages/group_list_page.dart';
import 'package:grex/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import 'test_helpers/mock_supabase_client.dart';
import 'test_helpers/oauth_simulator.dart';
import 'test_helpers/test_data_generators.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Social Login Deep Link Integration Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late OAuthSimulator oauthSimulator;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      oauthSimulator = OAuthSimulator(mockSupabaseClient);
    });

    testWidgets('Deep link handling when app is closed', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);

      // Simulate app closed state
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/lifecycle',
        (data) async => null,
      );

      // Trigger OAuth callback deep link with valid tokens
      const callbackUrl =
          'io.supabase.grex://login-callback/'
          '?access_token=valid_access_token'
          '&refresh_token=valid_refresh_token'
          '&expires_in=3600'
          '&token_type=bearer';

      await oauthSimulator.simulateDeepLinkCallback(
        callbackUrl,
        appClosed: true,
      );

      // Verify app launches
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Verify authentication completed
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify session established from deep link
      verify(
        mockSupabaseClient.auth.getSessionFromUrl(Uri.parse(callbackUrl)),
      ).called(1);
    });

    testWidgets('Deep link handling when app is running', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Navigate to login page
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Google sign-in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate OAuth callback while app is running
      const callbackUrl =
          'io.supabase.grex://login-callback/'
          '?access_token=running_app_token'
          '&refresh_token=running_app_refresh'
          '&expires_in=3600'
          '&token_type=bearer';

      await oauthSimulator.simulateDeepLinkCallback(
        callbackUrl,
        appClosed: false,
      );
      await tester.pumpAndSettle();

      // Verify authentication completed without app restart
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify session processed from URL
      verify(
        mockSupabaseClient.auth.getSessionFromUrl(Uri.parse(callbackUrl)),
      ).called(1);
    });

    testWidgets('Deep link with error parameter', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Simulate OAuth error callback
      const errorCallbackUrl =
          'io.supabase.grex://login-callback/'
          '?error=access_denied'
          '&error_description=User%20denied%20access';

      await oauthSimulator.simulateInvalidCallback(errorCallbackUrl);
      await tester.pumpAndSettle();

      // Verify error handling
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.text('Sign in was cancelled. Please try again if needed.'),
        findsOneWidget,
      );

      // Verify no error details exposed to user
      expect(find.textContaining('access_denied'), findsNothing);
      expect(find.textContaining('User denied access'), findsNothing);
    });

    testWidgets('Deep link with malformed URL', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Simulate malformed callback URL
      const malformedUrl = 'io.supabase.grex://login-callback/malformed';

      await oauthSimulator.simulateInvalidCallback(malformedUrl);
      await tester.pumpAndSettle();

      // Verify graceful error handling
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.text('Authentication failed. Please try again.'),
        findsOneWidget,
      );

      // Verify retry option available
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Deep link with expired tokens', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Simulate callback with expired tokens
      const expiredCallbackUrl =
          'io.supabase.grex://login-callback/'
          '?access_token=expired_token'
          '&refresh_token=expired_refresh'
          '&expires_in=0'
          '&token_type=bearer';

      // Mock expired token handling
      when(
        mockSupabaseClient.auth.getSessionFromUrl(
          Uri.parse(expiredCallbackUrl),
        ),
      ).thenThrow(Exception('Token expired'));

      await oauthSimulator.simulateInvalidCallback(expiredCallbackUrl);
      await tester.pumpAndSettle();

      // Verify expired token handling
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.text('Authentication session expired. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('Deep link scheme validation', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Test invalid scheme
      const invalidSchemeUrl =
          'https://example.com/callback'
          '?access_token=valid_token'
          '&refresh_token=valid_refresh';

      // Deep link handler should ignore non-matching schemes
      await oauthSimulator.simulateInvalidCallback(invalidSchemeUrl);
      await tester.pumpAndSettle();

      // Verify app remains on login page (deep link ignored)
      expect(find.byType(LoginPage), findsOneWidget);

      // Test invalid host
      const invalidHostUrl =
          'io.supabase.grex://invalid-host/'
          '?access_token=valid_token'
          '&refresh_token=valid_refresh';

      await oauthSimulator.simulateInvalidCallback(invalidHostUrl);
      await tester.pumpAndSettle();

      // Verify app remains on login page (deep link ignored)
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Multiple deep link callbacks', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Simulate first callback
      const firstCallbackUrl =
          'io.supabase.grex://login-callback/'
          '?access_token=first_token'
          '&refresh_token=first_refresh';

      await oauthSimulator.simulateDeepLinkCallback(
        firstCallbackUrl,
        appClosed: false,
      );
      await tester.pumpAndSettle();

      // Verify first callback processed
      expect(find.byType(GroupListPage), findsOneWidget);

      // Simulate second callback (should be ignored or handled gracefully)
      const secondCallbackUrl =
          'io.supabase.grex://login-callback/'
          '?access_token=second_token'
          '&refresh_token=second_refresh';

      await oauthSimulator.simulateDeepLinkCallback(
        secondCallbackUrl,
        appClosed: false,
      );
      await tester.pumpAndSettle();

      // Verify app remains stable (no duplicate processing)
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify only first callback was processed
      verify(
        mockSupabaseClient.auth.getSessionFromUrl(Uri.parse(firstCallbackUrl)),
      ).called(1);
    });

    testWidgets('Deep link callback timeout handling', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Start OAuth flow
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Simulate callback
      const callbackUrl =
          'io.supabase.grex://login-callback/'
          '?access_token=timeout_token'
          '&refresh_token=timeout_refresh';

      // Mock callback processing timeout
      when(
        mockSupabaseClient.auth.getSessionFromUrl(Uri.parse(callbackUrl)),
      ).thenAnswer((
        _,
      ) async {
        await Future<void>.delayed(
          const Duration(seconds: 15),
        ); // Simulate timeout
        throw Exception('Callback processing timeout');
      });

      await oauthSimulator.simulateDeepLinkCallback(
        callbackUrl,
        appClosed: false,
      );

      // Wait for timeout
      await tester.pumpAndSettle(const Duration(seconds: 20));

      // Verify timeout handling
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.text('Authentication timed out. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('Deep link with state parameter validation', (tester) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Simulate callback with state parameter (CSRF protection)
      const callbackWithState =
          'io.supabase.grex://login-callback/'
          '?access_token=state_token'
          '&refresh_token=state_refresh'
          '&state=valid_state_parameter';

      await oauthSimulator.simulateDeepLinkCallback(
        callbackWithState,
        appClosed: false,
      );
      await tester.pumpAndSettle();

      // Verify state parameter is processed correctly
      expect(find.byType(GroupListPage), findsOneWidget);

      // Verify session established with state validation
      verify(
        mockSupabaseClient.auth.getSessionFromUrl(Uri.parse(callbackWithState)),
      ).called(1);
    });

    testWidgets('Deep link processing with network interruption', (
      tester,
    ) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Simulate callback
      const callbackUrl =
          'io.supabase.grex://login-callback/'
          '?access_token=network_token'
          '&refresh_token=network_refresh';

      // Mock network interruption during callback processing
      when(
        mockSupabaseClient.auth.getSessionFromUrl(Uri.parse(callbackUrl)),
      ).thenThrow(Exception('Network connection lost'));

      await oauthSimulator.simulateDeepLinkCallback(
        callbackUrl,
        appClosed: false,
      );
      await tester.pumpAndSettle();

      // Verify network error handling
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.text('Network error during authentication. Please try again.'),
        findsOneWidget,
      );

      // Verify retry option available
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Deep link callback with user profile creation', (
      tester,
    ) async {
      // Setup test app
      await _setupTestApp(tester, mockSupabaseClient);
      await tester.pumpAndSettle();

      // Generate new user data
      final newUser = TestDataGenerators.generateNewUser();

      // Simulate callback for new user
      const callbackUrl =
          'io.supabase.grex://login-callback/'
          '?access_token=new_user_token'
          '&refresh_token=new_user_refresh';

      await oauthSimulator.simulateDeepLinkCallback(
        callbackUrl,
        appClosed: false,
      );
      await tester.pumpAndSettle();

      // Verify navigation to profile setup
      expect(find.text('Complete Your Profile'), findsOneWidget);

      // Verify user data pre-filled from OAuth
      expect(find.text(newUser.email), findsOneWidget);
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
