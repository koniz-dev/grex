import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:grex/core/performance/performance_service.dart';

/// Handler for OAuth deep link callbacks
///
/// This class manages deep link handling for OAuth authentication flows,
/// processing callbacks from OAuth providers with performance optimizations
/// and handling various failure scenarios with appropriate error logging.
///
/// Requirements: 3.1, 3.2, 3.3, 3.4, 8.5
class AuthDeepLinkHandler {
  /// Creates an [AuthDeepLinkHandler] with the specified callback.
  ///
  /// The [onDeepLink] callback will be invoked when a valid OAuth deep link
  /// is processed. This callback should handle the URI and extract any
  /// authentication tokens or session information.
  AuthDeepLinkHandler({
    required this.onDeepLink,
    required PerformanceService performanceService,
  }) : _performanceService = performanceService;

  /// Callback function to handle deep link URIs
  ///
  /// This function is called when a valid OAuth callback URI is received.
  /// It should process the URI and handle authentication token extraction.
  final void Function(Uri) onDeepLink;

  final PerformanceService _performanceService;

  /// Initialize deep link handling
  ///
  /// Sets up the deep link handler to process OAuth callbacks.
  /// This method is called during AuthBloc initialization.
  Future<void> initialize() async {
    // In a full implementation, this would set up app_links listener
    // For now, we just ensure the handler is ready
    debugPrint('AuthDeepLinkHandler initialized');
  }

  /// Handles a deep link URI with performance optimization
  ///
  /// This method processes OAuth callback URIs with:
  /// - Fast validation and processing (< 1 second target)
  /// - Minimal UI blocking operations
  /// - Performance monitoring
  /// - Proper error handling and logging
  Future<void> handleDeepLink(Uri uri) async {
    return _performanceService.measureOperation(
      name: 'oauth_deeplink_processing',
      attributes: {
        'scheme': uri.scheme,
        'host': uri.host,
        'has_fragment': uri.fragment.isNotEmpty.toString(),
        'has_query': uri.query.isNotEmpty.toString(),
      },
      operation: () => _processDeepLinkOptimized(uri),
    );
  }

  /// Optimized deep link processing with performance monitoring
  Future<void> _processDeepLinkOptimized(Uri uri) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Fast validation - should complete in microseconds
      if (!_isAuthCallback(uri)) {
        debugPrint('Deep link is not an OAuth callback: $uri');
        return;
      }

      // Process the callback immediately - no async operations here
      // to minimize UI blocking
      onDeepLink(uri);

      stopwatch.stop();
      debugPrint('Deep link processed in ${stopwatch.elapsedMicroseconds}μs');
    } catch (e) {
      stopwatch.stop();
      // Log detailed error for debugging
      debugPrint('Error handling deep link: $uri');
      debugPrint('Error details: $e');
      debugPrint('Processing failed after ${stopwatch.elapsedMicroseconds}μs');

      // Re-throw for upper layers to handle with generic user message
      rethrow;
    }
  }

  /// Checks if a URI is an OAuth callback with optimized validation
  ///
  /// Fast validation that should complete in microseconds
  bool _isAuthCallback(Uri uri) {
    // Use direct string comparison for fastest validation
    return uri.scheme == 'io.supabase.grex' && uri.host == 'login-callback';
  }

  /// Disposes resources
  void dispose() {
    // Clean up any resources if needed
  }
}
