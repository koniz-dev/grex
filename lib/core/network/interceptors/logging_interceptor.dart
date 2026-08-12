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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor for logging HTTP requests and responses
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
      debugPrint('Headers: ${options.headers}');
      if (options.data != null) {
        debugPrint('Data: ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        debugPrint('QueryParams: ${options.queryParameters}');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint(
        'RESPONSE[${response.statusCode}] => '
        'PATH: ${response.requestOptions.path}',
      );
      debugPrint('Data: ${response.data}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        'ERROR[${err.response?.statusCode}] => '
        'PATH: ${err.requestOptions.path}',
      );
      debugPrint('Message: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('Error Data: ${err.response?.data}');
      }
    }
    super.onError(err, handler);
  }
}
