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
import 'package:grex/core/errors/dio_exception_mapper.dart';

/// Interceptor for converting DioException to domain exceptions
///
/// This interceptor should be added FIRST in the interceptor chain
/// (before auth and logging interceptors) to ensure all DioExceptions
/// are converted to domain exceptions before other interceptors process them.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Convert DioException to domain exception
    final domainException = DioExceptionMapper.map(err);

    // Reject with a DioException that contains the domain exception
    // This allows the domain exception to be extracted later in catch blocks
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: domainException,
        type: err.type,
        response: err.response,
        message: domainException.message,
      ),
    );
  }
}
