// UNUSED SCAFFOLDING: nothing in this app consumes this file.
//
// Every repository talks to SupabaseClient directly, and `apiClientProvider`
// has no consumer outside its own definition. The Dio layer is kept
// deliberately -- as a starting point for a future non-Supabase API -- not
// because it is in the request path today. See issue #7.
//
// test/core/network/network_scaffolding_test.dart fails if this notice is
// missing, and fails if `apiClientProvider` ever gains a consumer. When that
// happens, this notice is what needs deleting.

import 'package:grex/core/config/app_config.dart';

/// API endpoints constants
///
/// Contains only endpoint path constants.
/// For base URL configuration, use [AppConfig.baseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  /// API version prefix for all endpoints
  static const String apiVersion = '/v1';

  /// Authentication endpoint for user login
  static const String login = '/auth/login';

  /// Authentication endpoint for user registration
  static const String register = '/auth/register';

  /// Authentication endpoint for user logout
  static const String logout = '/auth/logout';

  /// Authentication endpoint for refreshing access token
  static const String refreshToken = '/auth/refresh';

  /// User endpoint for retrieving user profile
  static const String userProfile = '/user/profile';

  /// User endpoint for updating user profile
  static const String updateProfile = '/user/profile';
}
