import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/presentation/widgets/social_login_button.dart';
import 'package:grex/l10n/app_localizations.dart';

void main() {
  group('SocialLoginButton', () {
    /// Helper function to create a test app with proper localization
    Widget createTestApp(Widget child) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
    }

    testWidgets('should display Google button with correct styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.google,
            onPressed: () {},
          ),
        ),
      );

      // Should find the button
      expect(find.byType(OutlinedButton), findsOneWidget);

      // Should display correct text
      expect(find.text('Continue with Google'), findsOneWidget);

      // Should have correct styling for Google
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final style = button.style!;

      // Google button should have white background
      expect(
        style.backgroundColor?.resolve(<WidgetState>{}),
        equals(Colors.white),
      );
      expect(
        style.foregroundColor?.resolve(<WidgetState>{}),
        equals(Colors.black87),
      );
    });

    testWidgets('should display Apple button with correct styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.apple,
            onPressed: () {},
          ),
        ),
      );

      // Should find the button
      expect(find.byType(OutlinedButton), findsOneWidget);

      // Should display correct text
      expect(find.text('Continue with Apple'), findsOneWidget);

      // Should have correct styling for Apple
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final style = button.style!;

      // Apple button should have black background
      expect(
        style.backgroundColor?.resolve(<WidgetState>{}),
        equals(Colors.black),
      );
      expect(
        style.foregroundColor?.resolve(<WidgetState>{}),
        equals(Colors.white),
      );
    });

    testWidgets('should be disabled when loading is true', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.google,
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

      // Button should be disabled when loading
      expect(button.onPressed, isNull);
    });

    testWidgets('should show loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.google,
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Should not show icon when loading
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('should show correct loading indicator color for Google', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.google,
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      final valueColor = indicator.valueColor! as AlwaysStoppedAnimation<Color>;
      expect(valueColor.value, equals(Colors.black87));
    });

    testWidgets('should show correct loading indicator color for Apple', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.apple,
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      final valueColor = indicator.valueColor! as AlwaysStoppedAnimation<Color>;
      expect(valueColor.value, equals(Colors.white));
    });

    testWidgets('should call onPressed callback when tapped', (tester) async {
      var wasPressed = false;

      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.google,
            onPressed: () {
              wasPressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));

      expect(wasPressed, isTrue);
    });

    testWidgets('should be disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SocialLoginButton(
            provider: SocialAuthProvider.google,
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

      // Button should be disabled when onPressed is null
      expect(button.onPressed, isNull);
    });

    testWidgets('should have correct dimensions', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.google,
            onPressed: () {},
          ),
        ),
      );

      // Find the SizedBox that wraps the button (should be the first one)
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final buttonSizedBox = sizedBoxes.first;

      // Should have correct height and full width
      expect(buttonSizedBox.height, equals(48.0));
      expect(buttonSizedBox.width, equals(double.infinity));
    });

    testWidgets('should show disabled styling when disabled', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SocialLoginButton(
            provider: SocialAuthProvider.google,
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final style = button.style!;

      // Should have disabled styling
      final disabledStates = <WidgetState>{WidgetState.disabled};
      expect(
        style.backgroundColor?.resolve(disabledStates),
        isNotNull,
      );
      expect(
        style.foregroundColor?.resolve(disabledStates),
        isNotNull,
      );
    });

    testWidgets('should show disabled styling when loading', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.apple,
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

      // Button should be disabled when loading
      expect(button.onPressed, isNull);
    });

    testWidgets('should maintain consistent styling across providers', (
      tester,
    ) async {
      // Test Google button
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.google,
            onPressed: () {},
          ),
        ),
      );

      final googleButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      final googleStyle = googleButton.style!;

      // Test Apple button
      await tester.pumpWidget(
        createTestApp(
          SocialLoginButton(
            provider: SocialAuthProvider.apple,
            onPressed: () {},
          ),
        ),
      );

      final appleButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      final appleStyle = appleButton.style!;

      // Both should have same shape and elevation
      expect(
        googleStyle.shape?.resolve(<WidgetState>{}),
        equals(appleStyle.shape?.resolve(<WidgetState>{})),
      );
      expect(
        googleStyle.elevation?.resolve(<WidgetState>{}),
        equals(appleStyle.elevation?.resolve(<WidgetState>{})),
      );
    });

    testWidgets('should handle rapid state changes without errors', (
      tester,
    ) async {
      var isLoading = false;

      await tester.pumpWidget(
        createTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  SocialLoginButton(
                    provider: SocialAuthProvider.google,
                    isLoading: isLoading,
                    onPressed: () {},
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = !isLoading;
                      });
                    },
                    child: const Text('Toggle'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Rapidly toggle loading state
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('Toggle'));
        await tester.pump();

        // Should always find the button
        expect(find.byType(OutlinedButton), findsOneWidget);
      }
    });
  });
}
