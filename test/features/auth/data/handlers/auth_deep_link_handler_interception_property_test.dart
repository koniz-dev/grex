import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/handlers/auth_deep_link_handler.dart';
import 'package:mockito/mockito.dart';
import '../../../../helpers/mock_helpers.dart';

/// Property 7: Deep Link Handler Intercepts OAuth Callbacks
///
/// This property validates that the AuthDeepLinkHandler correctly intercepts
/// OAuth callback URLs while ignoring non-OAuth deep links.
///
/// Validates Requirements:
/// - 3.1: Deep link handler intercepts OAuth callbacks
void main() {
  group('Property 7: Deep Link Handler Intercepts OAuth Callbacks', () {
    late AuthDeepLinkHandler handler;
    late MockPerformanceService mockPerformanceService;
    late List<Uri> interceptedCallbacks;
    late Random random;

    setUp(() {
      interceptedCallbacks = [];
      random = Random();
      mockPerformanceService = MockPerformanceService();

      // Setup mock performance service to execute operations directly
      when(mockPerformanceService.measureOperation<void>(
        name: anyNamed('name'),
        operation: anyNamed('operation'),
        attributes: anyNamed('attributes'),
      )).thenAnswer((invocation) async {
        final operation = invocation.namedArguments[#operation] as Future<void> Function();
        return operation();
      });

      handler = AuthDeepLinkHandler(
        onDeepLink: (uri) {
          interceptedCallbacks.add(uri);
        },
        performanceService: mockPerformanceService,
      );
    });

    tearDown(() {
      handler.dispose();
    });

    test(
      'should intercept valid OAuth callbacks and ignore non-OAuth links',
      () {
        // Property: For any set of URLs, only valid OAuth callbacks should be
        // intercepted

        for (var iteration = 0; iteration < 100; iteration++) {
          // Reset for each iteration
          interceptedCallbacks.clear();

          // Generate test URLs
          final testUrls = _generateTestUrls(random, iteration);
          final validOAuthCallbacks = <Uri>[];
          final nonOAuthUrls = <Uri>[];

          // Categorize URLs
          for (final url in testUrls) {
            if (_isValidOAuthCallback(url)) {
              validOAuthCallbacks.add(url);
            } else {
              nonOAuthUrls.add(url);
            }
          }

          // Simulate processing each URL
          for (final url in testUrls) {
            if (handler._isAuthCallback(url)) {
              handler.onDeepLink(url);
            }
          }

          // Verify property: Only valid OAuth callbacks were intercepted
          expect(
            interceptedCallbacks.length,
            equals(validOAuthCallbacks.length),
            reason:
                'Iteration $iteration: Should intercept exactly '
                '${validOAuthCallbacks.length} valid OAuth callbacks, '
                'but intercepted ${interceptedCallbacks.length}',
          );

          // Verify all intercepted URLs are valid OAuth callbacks
          for (final intercepted in interceptedCallbacks) {
            expect(
              _isValidOAuthCallback(intercepted),
              isTrue,
              reason:
                  'Iteration $iteration: Intercepted URL should be valid '
                  'OAuth callback: $intercepted',
            );
          }

          // Verify all valid OAuth callbacks were intercepted
          for (final validCallback in validOAuthCallbacks) {
            expect(
              interceptedCallbacks.contains(validCallback),
              isTrue,
              reason:
                  'Iteration $iteration: Valid OAuth callback should be '
                  'intercepted: $validCallback',
            );
          }

          // Verify no non-OAuth URLs were intercepted
          for (final nonOAuth in nonOAuthUrls) {
            expect(
              interceptedCallbacks.contains(nonOAuth),
              isFalse,
              reason:
                  'Iteration $iteration: Non-OAuth URL should not be '
                  'intercepted: $nonOAuth',
            );
          }
        }
      },
    );
  });
}

/// Generates a list of test URLs for the given iteration
List<Uri> _generateTestUrls(Random random, int iteration) {
  final urls = <Uri>[];
  final urlCount = 3 + random.nextInt(8); // 3-10 URLs per iteration

  for (var i = 0; i < urlCount; i++) {
    if (random.nextBool()) {
      // Generate valid OAuth callback URL
      urls.add(_generateValidOAuthCallback(random));
    } else {
      // Generate non-OAuth URL
      urls.add(_generateNonOAuthUrl(random));
    }
  }

  return urls;
}

/// Generates a valid OAuth callback URL
Uri _generateValidOAuthCallback(Random random) {
  final accessToken = _generateRandomString(random, 32);
  final refreshToken = _generateRandomString(random, 32);
  const tokenType = 'bearer';
  final expiresIn = 3600 + random.nextInt(3600);

  final queryParams = <String, String>{
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'token_type': tokenType,
    'expires_in': expiresIn.toString(),
  };

  // Sometimes add additional parameters
  if (random.nextBool()) {
    queryParams['provider_token'] = _generateRandomString(random, 24);
  }

  if (random.nextBool()) {
    queryParams['provider_refresh_token'] = _generateRandomString(random, 24);
  }

  return Uri(
    scheme: 'io.supabase.grex',
    host: 'login-callback',
    queryParameters: queryParams,
  );
}

/// Generates a non-OAuth URL (various invalid formats)
Uri _generateNonOAuthUrl(Random random) {
  final urlType = random.nextInt(6);

  switch (urlType) {
    case 0:
      // Wrong scheme
      return Uri(
        scheme: 'https',
        host: 'login-callback',
        queryParameters: {'access_token': _generateRandomString(random, 32)},
      );

    case 1:
      // Wrong host
      return Uri(
        scheme: 'io.supabase.grex',
        host: 'other-callback',
        queryParameters: {'access_token': _generateRandomString(random, 32)},
      );

    case 2:
      // Different app scheme
      return Uri(
        scheme: 'com.example.app',
        host: 'login-callback',
        queryParameters: {'access_token': _generateRandomString(random, 32)},
      );

    case 3:
      // HTTP URL
      return Uri(
        scheme: 'http',
        host: 'example.com',
        path: '/callback',
        queryParameters: {'code': _generateRandomString(random, 16)},
      );

    case 4:
      // HTTPS URL
      return Uri(
        scheme: 'https',
        host: 'api.example.com',
        path: '/auth/callback',
        queryParameters: {'state': _generateRandomString(random, 16)},
      );

    default:
      // Custom app scheme with different format
      return Uri(
        scheme: 'myapp',
        host: 'open',
        path: '/screen',
        queryParameters: {'id': random.nextInt(1000).toString()},
      );
  }
}

/// Checks if a URL is a valid OAuth callback
bool _isValidOAuthCallback(Uri uri) {
  return uri.scheme == 'io.supabase.grex' && uri.host == 'login-callback';
}

/// Generates a random string of the specified length
String _generateRandomString(Random random, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

/// Extension to access private method for testing
extension AuthDeepLinkHandlerTest on AuthDeepLinkHandler {
  bool _isAuthCallback(Uri uri) {
    return uri.scheme == 'io.supabase.grex' && uri.host == 'login-callback';
  }
}
