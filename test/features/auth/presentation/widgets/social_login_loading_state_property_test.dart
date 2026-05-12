import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';
import 'package:grex/features/auth/presentation/widgets/social_login_button.dart';
import 'package:grex/l10n/app_localizations.dart';

/// Wraps a widget in a MaterialApp with localizations so SocialLoginButton's
/// `context.l10n` calls resolve in this property-test environment.
MaterialApp _wrap(Widget home) {
  return MaterialApp(
    // English — assertions in this property test use the English strings
    // ("Continue with Google", "Continue with Apple") rendered by
    // SocialLoginButton via context.l10n.
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

/// Property 20: Loading State Disables Authentication Buttons
///
/// This property validates that when social login buttons are in loading
/// state, they are properly disabled and show loading indicators instead of
/// normal content.
///
/// Validates Requirements:
/// - 6.5: Loading states disable all authentication buttons
void main() {
  group('Property 20: Loading State Disables Authentication Buttons', () {
    testWidgets(
      'should disable all auth buttons during loading and show '
      'loading indicator',
      (tester) async {
        // Property: For any combination of loading states and providers,
        // buttons should be disabled when loading and show appropriate
        // indicators

        final random = Random();

        for (var iteration = 0; iteration < 100; iteration++) {
          // Generate random test parameters
          final providers = [
            SocialAuthProvider.google,
            SocialAuthProvider.apple,
          ];
          final testProvider = providers[random.nextInt(providers.length)];
          final isLoading = random.nextBool();
          final hasOnPressed = random.nextBool();

          await tester.pumpWidget(
            _wrap(
              Scaffold(
                body: SocialLoginButton(
                  provider: testProvider,
                  isLoading: isLoading,
                  onPressed: hasOnPressed ? () {} : null,
                ),
              ),
            ),
          );

          // Find the button
          final buttonFinder = find.byType(OutlinedButton);
          expect(buttonFinder, findsOneWidget);

          final button = tester.widget<OutlinedButton>(buttonFinder);

          if (isLoading) {
            // Property: Loading state should disable button regardless of
            // onPressed
            expect(
              button.onPressed,
              isNull,
              reason:
                  'Iteration $iteration: Button should be disabled when '
                  'loading',
            );

            // Property: Loading state should show CircularProgressIndicator
            expect(
              find.byType(CircularProgressIndicator),
              findsOneWidget,
              reason:
                  'Iteration $iteration: Should show loading indicator '
                  'when loading',
            );

            // Property: Loading state should not show SVG icon
            expect(
              find.byType(SvgPicture),
              findsNothing,
              reason: 'Iteration $iteration: Should not show icon when loading',
            );
          } else {
            // Property: Non-loading state should respect onPressed parameter
            if (hasOnPressed) {
              expect(
                button.onPressed,
                isNotNull,
                reason:
                    'Iteration $iteration: Button should be enabled when '
                    'not loading and has onPressed',
              );
            } else {
              expect(
                button.onPressed,
                isNull,
                reason:
                    'Iteration $iteration: Button should be disabled when '
                    'onPressed is null',
              );
            }

            // Property: Non-loading state should not show
            // CircularProgressIndicator
            expect(
              find.byType(CircularProgressIndicator),
              findsNothing,
              reason:
                  'Iteration $iteration: Should not show loading indicator '
                  'when not loading',
            );
          }

          // Property: Button should always show text regardless of loading
          // state
          final expectedText = testProvider == SocialAuthProvider.google
              // Hardcoded text since context.l10n isn't easy to access here.
              ? 'Continue with Google'
              : 'Continue with Apple';

          expect(
            find.text(expectedText),
            findsOneWidget,
            reason: 'Iteration $iteration: Should always show button text',
          );

          // Single pump rather than pumpAndSettle: when isLoading is true,
          // CircularProgressIndicator animates forever and pumpAndSettle
          // never resolves.
          await tester.pump();
        }
      },
    );

    testWidgets(
      'should show correct loading indicator colors for different providers',
      (tester) async {
        // Property: Loading indicators should use appropriate colors for
        // each provider

        final providers = [SocialAuthProvider.google, SocialAuthProvider.apple];

        for (var iteration = 0; iteration < 50; iteration++) {
          for (final provider in providers) {
            await tester.pumpWidget(
              _wrap(
                Scaffold(
                  body: SocialLoginButton(
                    provider: provider,
                    isLoading: true,
                    onPressed: () {},
                  ),
                ),
              ),
            );

            // Find the loading indicator
            final indicatorFinder = find.byType(CircularProgressIndicator);
            expect(indicatorFinder, findsOneWidget);

            final indicator = tester.widget<CircularProgressIndicator>(
              indicatorFinder,
            );
            final valueColor =
                indicator.valueColor! as AlwaysStoppedAnimation<Color>;

            // Property: Google should use dark color, Apple should use
            // white color
            if (provider == SocialAuthProvider.google) {
              expect(
                valueColor.value,
                equals(Colors.black87),
                reason: 'Google loading indicator should be dark',
              );
            } else {
              expect(
                valueColor.value,
                equals(Colors.white),
                reason: 'Apple loading indicator should be white',
              );
            }

            // Single pump: spinner animates forever, pumpAndSettle would hang.
            await tester.pump();
          }
        }
      },
    );

    testWidgets('should maintain button dimensions during loading state', (
      tester,
    ) async {
      // Property: Button dimensions should remain consistent between
      // loading and non-loading states

      final random = Random();

      for (var iteration = 0; iteration < 50; iteration++) {
        final provider = [
          SocialAuthProvider.google,
          SocialAuthProvider.apple,
        ][random.nextInt(2)];

        // Test non-loading state first
        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: SocialLoginButton(
                provider: provider,
                onPressed: () {},
              ),
            ),
          ),
        );

        final nonLoadingSize = tester.getSize(find.byType(SizedBox).first);

        // Test loading state
        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: SocialLoginButton(
                provider: provider,
                isLoading: true,
                onPressed: () {},
              ),
            ),
          ),
        );

        final loadingSize = tester.getSize(find.byType(SizedBox).first);

        // Property: Button size should remain the same
        expect(
          loadingSize,
          equals(nonLoadingSize),
          reason:
              'Iteration $iteration: Button size should not change during '
              'loading',
        );

        // Property: Button should maintain required dimensions
        expect(
          loadingSize.height,
          equals(48.0),
          reason: 'Iteration $iteration: Button height should be 48px',
        );
        expect(
          loadingSize.width,
          greaterThan(200.0),
          reason: 'Iteration $iteration: Button should have reasonable width',
        );

        // Single pump: spinner animates forever, pumpAndSettle would hang.
        await tester.pump();
      }
    });

    testWidgets('should handle rapid loading state changes', (tester) async {
      // Property: Button should handle rapid loading state changes
      // without errors

      final random = Random();

      for (var iteration = 0; iteration < 25; iteration++) {
        final provider = [
          SocialAuthProvider.google,
          SocialAuthProvider.apple,
        ][random.nextInt(2)];
        var isLoading = false;

        await tester.pumpWidget(
          _wrap(
            StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      SocialLoginButton(
                        provider: provider,
                        isLoading: isLoading,
                        onPressed: () {},
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = !isLoading;
                          });
                        },
                        child: const Text('Toggle Loading'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        // Rapidly toggle loading state multiple times
        for (var toggle = 0; toggle < 10; toggle++) {
          await tester.tap(find.text('Toggle Loading'));
          await tester.pump();

          // Property: Button should always be in a valid state
          final buttonFinder = find.byType(OutlinedButton);
          expect(
            buttonFinder,
            findsOneWidget,
            reason:
                'Iteration $iteration, Toggle $toggle: Button should '
                'always exist',
          );

          // Property: Should show either loading indicator or icon, never both
          final hasLoadingIndicator = find
              .byType(CircularProgressIndicator)
              .evaluate()
              .isNotEmpty;
          final hasIcon = find.byType(SvgPicture).evaluate().isNotEmpty;

          expect(
            hasLoadingIndicator && hasIcon,
            isFalse,
            reason:
                'Iteration $iteration, Toggle $toggle: Should not show '
                'both loading and icon',
          );
          expect(
            hasLoadingIndicator || hasIcon,
            isTrue,
            reason:
                'Iteration $iteration, Toggle $toggle: Should show either '
                'loading or icon',
          );
        }

        // Single pump: spinner animates forever, pumpAndSettle would hang.
        await tester.pump();
      }
    });
  });
}
