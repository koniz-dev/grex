import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/failures.dart';
import 'package:grex/features/auth/presentation/widgets/social_auth_error_widget.dart';
import 'package:grex/l10n/app_localizations.dart';

/// Unit tests for SocialAuthErrorWidget
///
/// Tests error display components and error recovery flows.
///
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
void main() {
  group('SocialAuthErrorWidget', () {
    late bool retryPressed;
    late bool fallbackPressed;
    late bool dismissPressed;
    late int retryCount;
    Widget createTestWidget({
      required AuthFailure failure,
      VoidCallback? onRetry,
      VoidCallback? onFallback,
      VoidCallback? onDismiss,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SocialAuthErrorWidget(
            failure: failure,
            onRetry: onRetry,
            onFallback: onFallback,
            onDismiss: onDismiss,
          ),
        ),
      );
    }

    group('error display', () {
      testWidgets('should not display anything for cancellation failures', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthCancelledFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.byType(SocialAuthErrorWidget), findsOneWidget);
        // Widget should be present but not display any error content
        expect(find.text('Sign in was cancelled'), findsNothing);
      });

      testWidgets('should display network error message', (tester) async {
        // Arrange
        const failure = SocialAuthNetworkFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.byType(SocialAuthErrorWidget), findsOneWidget);
        expect(find.textContaining('Network'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      });

      testWidgets('should display timeout error message', (tester) async {
        // Arrange
        const failure = SocialAuthTimeoutFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.byType(SocialAuthErrorWidget), findsOneWidget);
        expect(find.textContaining('Authentication timed out'), findsOneWidget);
        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });

      testWidgets('should display account linking error message', (
        tester,
      ) async {
        // Arrange
        const failure = AccountLinkingFailure('Failed to link accounts');

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.byType(SocialAuthErrorWidget), findsOneWidget);
        expect(find.textContaining('link'), findsOneWidget);
        expect(find.byIcon(Icons.link_off), findsOneWidget);
      });

      testWidgets('should display generic social auth error message', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthFailure('Authentication failed');

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.byType(SocialAuthErrorWidget), findsOneWidget);
        expect(find.textContaining('Authentication'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should use theme error colors', (tester) async {
        // Arrange
        const failure = SocialAuthNetworkFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        final errorContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(SocialAuthErrorWidget),
                matching: find.byType(Container),
              )
              .first,
        );

        // Verify error styling is applied
        expect(errorContainer.decoration, isNotNull);
      });
    });

    group('retry button', () {
      testWidgets('should show retry button for network failures', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthNetworkFailure();
        retryPressed = false;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            failure: failure,
            onRetry: () => retryPressed = true,
          ),
        );

        // Assert
        expect(find.textContaining('Retry'), findsOneWidget);

        // Test retry callback
        await tester.tap(find.textContaining('Retry'));
        expect(retryPressed, isTrue);
      });

      testWidgets('should show retry button for timeout failures', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthTimeoutFailure();
        retryPressed = false;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            failure: failure,
            onRetry: () => retryPressed = true,
          ),
        );

        // Assert
        expect(find.textContaining('Retry'), findsOneWidget);

        // Test retry callback
        await tester.tap(find.textContaining('Retry'));
        expect(retryPressed, isTrue);
      });

      testWidgets('should not show retry button for cancellation failures', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthCancelledFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.textContaining('Retry'), findsNothing);
      });

      testWidgets('should not show retry button for generic failures', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthFailure('Generic error');

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.textContaining('Retry'), findsNothing);
      });
    });

    group('fallback button', () {
      testWidgets('should show fallback button for generic failures', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthFailure('Generic error');
        fallbackPressed = false;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            failure: failure,
            onFallback: () => fallbackPressed = true,
          ),
        );

        // Assert
        expect(find.textContaining('Sign in with email'), findsOneWidget);

        // Test fallback callback
        await tester.tap(find.textContaining('Sign in with email'));
        expect(fallbackPressed, isTrue);
      });

      testWidgets('should show fallback button for account linking failures', (
        tester,
      ) async {
        // Arrange
        const failure = AccountLinkingFailure('Linking failed');
        fallbackPressed = false;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            failure: failure,
            onFallback: () => fallbackPressed = true,
          ),
        );

        // Assert
        expect(find.textContaining('Sign in with email'), findsOneWidget);

        // Test fallback callback
        await tester.tap(find.textContaining('Sign in with email'));
        expect(fallbackPressed, isTrue);
      });

      testWidgets('should not show fallback button for network failures', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthNetworkFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.textContaining('Sign in with email'), findsNothing);
      });

      testWidgets('should not show fallback button for cancellation failures', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthCancelledFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.textContaining('Sign in with email'), findsNothing);
      });
    });

    group('dismiss button', () {
      testWidgets('should always show dismiss button', (tester) async {
        // Arrange
        const failures = [
          SocialAuthNetworkFailure(),
          SocialAuthTimeoutFailure(),
          SocialAuthFailure('Generic error'),
          AccountLinkingFailure('Linking failed'),
        ];

        for (final failure in failures) {
          dismissPressed = false;

          // Act
          await tester.pumpWidget(
            createTestWidget(
              failure: failure,
              onDismiss: () => dismissPressed = true,
            ),
          );

          // Assert
          expect(find.textContaining('Dismiss'), findsOneWidget);

          // Test dismiss callback
          await tester.tap(find.textContaining('Dismiss'));
          expect(dismissPressed, isTrue);
        }
      });

      testWidgets('should not show dismiss button for cancellation failures', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthCancelledFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.textContaining('Dismiss'), findsNothing);
      });
    });

    group('accessibility', () {
      testWidgets('should have proper semantics for screen readers', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthNetworkFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        expect(find.bySemanticsLabel('Network error'), findsOneWidget);
        expect(find.bySemanticsLabel('Retry authentication'), findsOneWidget);
        expect(find.bySemanticsLabel('Dismiss error'), findsOneWidget);
      });

      testWidgets('should announce error messages to screen readers', (
        tester,
      ) async {
        // Arrange
        const failure = SocialAuthTimeoutFailure();

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert
        // Find the text widget that contains the error message
        final textWidget = find.textContaining('Authentication timed out');
        expect(textWidget, findsOneWidget);

        // Check semantics on the text widget
        final semantics = tester.getSemantics(textWidget);
        expect(semantics.label, contains('Authentication timed out'));
      });
    });

    group('error recovery flows', () {
      testWidgets('should handle retry flow correctly', (tester) async {
        // Arrange
        const failure = SocialAuthNetworkFailure();
        retryCount = 0;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            failure: failure,
            onRetry: () => retryCount++,
          ),
        );

        // Test multiple retries
        await tester.tap(find.textContaining('Retry'));
        await tester.tap(find.textContaining('Retry'));
        await tester.tap(find.textContaining('Retry'));

        // Assert
        expect(retryCount, equals(3));
      });

      testWidgets('should handle fallback flow correctly', (tester) async {
        // Arrange
        const failure = SocialAuthFailure('Generic error');
        fallbackPressed = false;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            failure: failure,
            onFallback: () => fallbackPressed = true,
          ),
        );

        await tester.tap(find.textContaining('Sign in with email'));

        // Assert
        expect(fallbackPressed, isTrue);
      });

      testWidgets('should handle dismiss flow correctly', (tester) async {
        // Arrange
        const failure = SocialAuthNetworkFailure();
        dismissPressed = false;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            failure: failure,
            onDismiss: () => dismissPressed = true,
          ),
        );

        await tester.tap(find.textContaining('Dismiss'));

        // Assert
        expect(dismissPressed, isTrue);
      });
    });

    group('edge cases', () {
      testWidgets('should handle null callbacks gracefully', (tester) async {
        // Arrange
        const failure = SocialAuthNetworkFailure();

        // Act & Assert - Should not throw
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Buttons should still be present but not functional
        expect(find.textContaining('Retry'), findsOneWidget);
        expect(find.textContaining('Dismiss'), findsOneWidget);
      });

      testWidgets('should handle very long error messages', (tester) async {
        // Arrange
        final longMessage = 'Very long error message ' * 20;
        final failure = SocialAuthFailure(longMessage);

        // Act
        await tester.pumpWidget(createTestWidget(failure: failure));

        // Assert - Should not overflow
        expect(tester.takeException(), isNull);
        expect(find.byType(SocialAuthErrorWidget), findsOneWidget);
      });

      testWidgets('should handle rapid button taps', (tester) async {
        // Arrange
        const failure = SocialAuthNetworkFailure();
        retryCount = 0;

        // Act
        await tester.pumpWidget(
          createTestWidget(
            failure: failure,
            onRetry: () => retryCount++,
          ),
        );

        // Rapid taps
        for (var i = 0; i < 10; i++) {
          await tester.tap(find.textContaining('Retry'));
        }

        // Assert - Should handle all taps
        expect(retryCount, equals(10));
      });
    });
  });
}
