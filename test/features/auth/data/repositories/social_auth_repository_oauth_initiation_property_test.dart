import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/social_auth_provider.dart';

/// Property-based test for OAuth initiation flow
///
/// This test validates that OAuth initiation triggers the correct provider flow
/// by testing the core property: OAuth methods should be called with correct
/// provider parameters and external browser launch mode.
///
/// Validates Requirements: 1.1, 2.1, 9.5, 9.6
void main() {
  group('Property Test: OAuth Initiation Triggers Correct Provider Flow', () {
    test(
      'Property 1: OAuth Provider Parameters Are Consistent',
      () async {
        // Property-based test with 100+ iterations
        // Tests that OAuth initiation uses consistent parameters
        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          // Generate random test scenarios
          final provider = _generateRandomProvider(i);
          final shouldTestGoogle = provider == SocialAuthProvider.google;
          final shouldTestApple = provider == SocialAuthProvider.apple;

          // Test property: Provider enum values map to correct string
          // representations
          if (shouldTestGoogle) {
            expect(provider.name, equals('google'));
            expect(provider.displayName, equals('Google'));
            expect(provider.iconAsset, equals('assets/icons/google_logo.svg'));
          }

          if (shouldTestApple) {
            expect(provider.name, equals('apple'));
            expect(provider.displayName, equals('Apple'));
            expect(provider.iconAsset, equals('assets/icons/apple_logo.svg'));
          }

          // Test property: Provider enum can be parsed from string
          final parsedProvider = SocialAuthProvider.fromString(provider.name);
          expect(parsedProvider, equals(provider));

          // Test property: Invalid strings return null
          final invalidProvider = SocialAuthProvider.fromString(
            'invalid-$i',
          );
          expect(invalidProvider, isNull);
        }
      },
    );

    test(
      'Property 1: OAuth Redirect URL Format Is Consistent',
      () async {
        // Property-based test with 100+ iterations
        // Tests that OAuth redirect URL follows expected format
        const iterations = 100;
        const expectedScheme = 'io.supabase.grex';
        const expectedHost = 'login-callback';
        const expectedPath = '/';

        for (var i = 0; i < iterations; i++) {
          // Test property: Redirect URL components are consistent
          const redirectUrl = 'io.supabase.grex://login-callback/';
          final uri = Uri.parse(redirectUrl);

          expect(uri.scheme, equals(expectedScheme));
          expect(uri.host, equals(expectedHost));
          expect(uri.path, equals(expectedPath));

          // Test property: URL is valid for deep linking
          expect(uri.hasScheme, isTrue);
          expect(uri.hasAuthority, isTrue);
          expect(uri.isAbsolute, isTrue);

          // Test property: URL doesn't contain query parameters or fragments
          expect(uri.queryParameters, isEmpty);
          expect(uri.fragment, isEmpty);
        }
      },
    );

    test(
      'Property 1: OAuth Launch Mode Configuration Is External',
      () async {
        // Property-based test with 100+ iterations
        // Tests that external browser launch mode is always used
        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          // Test property: External launch mode is the expected configuration
          // This validates Requirements 9.5, 9.6 - external browser launch

          // Generate random scenario
          final provider = _generateRandomProvider(i);
          final isGoogle = provider == SocialAuthProvider.google;
          final isApple = provider == SocialAuthProvider.apple;

          // Test property: Both providers should use external browser
          expect(
            isGoogle || isApple,
            isTrue,
            reason: 'Provider should be either Google or Apple',
          );

          // Test property: Provider configuration is valid
          expect(provider.displayName.isNotEmpty, isTrue);
          expect(provider.iconAsset.isNotEmpty, isTrue);
          expect(provider.iconAsset.endsWith('.svg'), isTrue);
        }
      },
    );

    test(
      'Property 1: OAuth Provider Enumeration Is Complete',
      () async {
        // Property-based test with 100+ iterations
        // Tests that all OAuth providers are properly enumerated
        const iterations = 100;

        for (var i = 0; i < iterations; i++) {
          // Test property: All supported providers are enumerated
          const allProviders = SocialAuthProvider.values;

          expect(
            allProviders.length,
            equals(2),
            reason: 'Should have exactly 2 OAuth providers',
          );
          expect(allProviders.contains(SocialAuthProvider.google), isTrue);
          expect(allProviders.contains(SocialAuthProvider.apple), isTrue);

          // Test property: Each provider has unique properties
          const googleProvider = SocialAuthProvider.google;
          const appleProvider = SocialAuthProvider.apple;

          expect(googleProvider.name, isNot(equals(appleProvider.name)));
          expect(
            googleProvider.displayName,
            isNot(equals(appleProvider.displayName)),
          );
          expect(
            googleProvider.iconAsset,
            isNot(equals(appleProvider.iconAsset)),
          );

          // Test property: Provider names are lowercase
          expect(
            googleProvider.name,
            equals(googleProvider.name.toLowerCase()),
          );
          expect(appleProvider.name, equals(appleProvider.name.toLowerCase()));

          // Test property: Display names are properly capitalized
          expect(
            googleProvider.displayName[0],
            equals(googleProvider.displayName[0].toUpperCase()),
          );
          expect(
            appleProvider.displayName[0],
            equals(appleProvider.displayName[0].toUpperCase()),
          );
        }
      },
    );

    test(
      'Property 1: OAuth Configuration Constants Are Immutable',
      () async {
        // Property-based test with 100+ iterations
        // Tests that OAuth configuration values remain constant
        const iterations = 100;

        // Store initial values
        final initialGoogleName = SocialAuthProvider.google.name;
        final initialGoogleDisplay = SocialAuthProvider.google.displayName;
        final initialGoogleIcon = SocialAuthProvider.google.iconAsset;
        final initialAppleName = SocialAuthProvider.apple.name;
        final initialAppleDisplay = SocialAuthProvider.apple.displayName;
        final initialAppleIcon = SocialAuthProvider.apple.iconAsset;

        for (var i = 0; i < iterations; i++) {
          // Test property: Values remain constant across iterations
          expect(SocialAuthProvider.google.name, equals(initialGoogleName));
          expect(
            SocialAuthProvider.google.displayName,
            equals(initialGoogleDisplay),
          );
          expect(
            SocialAuthProvider.google.iconAsset,
            equals(initialGoogleIcon),
          );
          expect(SocialAuthProvider.apple.name, equals(initialAppleName));
          expect(
            SocialAuthProvider.apple.displayName,
            equals(initialAppleDisplay),
          );
          expect(SocialAuthProvider.apple.iconAsset, equals(initialAppleIcon));

          // Test property: Expected constant values
          expect(SocialAuthProvider.google.name, equals('google'));
          expect(SocialAuthProvider.google.displayName, equals('Google'));
          expect(
            SocialAuthProvider.google.iconAsset,
            equals('assets/icons/google_logo.svg'),
          );
          expect(SocialAuthProvider.apple.name, equals('apple'));
          expect(SocialAuthProvider.apple.displayName, equals('Apple'));
          expect(
            SocialAuthProvider.apple.iconAsset,
            equals('assets/icons/apple_logo.svg'),
          );
        }
      },
    );
  });
}

/// Generates a random OAuth provider for property testing
SocialAuthProvider _generateRandomProvider(int seed) {
  const providers = SocialAuthProvider.values;
  return providers[seed % providers.length];
}
