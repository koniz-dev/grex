import 'package:grex/features/auth/domain/entities/entities.dart';

/// Utility class for converting technical errors into user-friendly
/// Vietnamese messages.
///
/// This class provides consistent, localized error messages that are
/// appropriate for end users while maintaining technical accuracy.
class ErrorMessages {
  /// Gets a user-friendly error message for any type of error
  static String getErrorMessage(dynamic error) {
    if (error is AuthFailure) {
      return _getAuthErrorMessage(error);
    } else if (error is UserFailure) {
      return _getUserErrorMessage(error);
    } else if (error is NetworkFailure) {
      return _getNetworkErrorMessage(error);
    } else if (error is String) {
      return _getStringErrorMessage(error);
    } else {
      return _getGenericErrorMessage(error);
    }
  }

  /// Gets user-friendly message for authentication errors
  static String _getAuthErrorMessage(AuthFailure failure) {
    if (failure is InvalidCredentialsFailure) {
      return 'Email hoặc mật khẩu không chính xác. '
          'Vui lòng kiểm tra lại thông tin đăng nhập.';
    } else if (failure is EmailAlreadyInUseFailure) {
      return 'Email này đã được đăng ký. '
          'Vui lòng sử dụng email khác hoặc đăng nhập với tài khoản hiện có.';
    } else if (failure is WeakPasswordFailure) {
      return 'Mật khẩu không đủ mạnh. '
          'Vui lòng sử dụng mật khẩu có ít nhất 8 ký tự, '
          'bao gồm chữ hoa, chữ thường và số.';
    } else if (failure is UnverifiedEmailFailure) {
      return 'Email chưa được xác thực. '
          'Vui lòng kiểm tra hộp thư và nhấp vào link xác thực.';
    } else if (failure is NetworkFailure) {
      return 'Không thể kết nối đến máy chủ. '
          'Vui lòng kiểm tra kết nối mạng và thử lại.';
    } else {
      return failure.message.isNotEmpty
          ? _humanizeErrorMessage(failure.message)
          : 'Đã xảy ra lỗi xác thực. Vui lòng thử lại sau.';
    }
  }

  /// Gets user-friendly message for user-related errors
  static String _getUserErrorMessage(UserFailure failure) {
    if (failure is UserNotFoundFailure) {
      return 'Không tìm thấy thông tin người dùng. '
          'Vui lòng đăng nhập lại hoặc liên hệ hỗ trợ.';
    } else if (failure is ValidationFailure) {
      return 'Thông tin nhập vào không hợp lệ. Vui lòng kiểm tra và nhập lại.';
    } else if (failure is NetworkFailure) {
      return 'Không thể tải thông tin người dùng. '
          'Vui lòng kiểm tra kết nối mạng.';
    } else {
      return failure.message.isNotEmpty
          ? _humanizeErrorMessage(failure.message)
          : 'Đã xảy ra lỗi với thông tin người dùng. Vui lòng thử lại.';
    }
  }

  /// Gets user-friendly message for network errors
  static String _getNetworkErrorMessage(NetworkFailure failure) {
    final message = failure.message.toLowerCase();

    if (message.contains('timeout')) {
      return 'Kết nối bị timeout. Vui lòng kiểm tra mạng và thử lại.';
    } else if (message.contains('connection')) {
      return 'Không thể kết nối đến máy chủ. '
          'Vui lòng kiểm tra kết nối internet.';
    } else if (message.contains('dns')) {
      return 'Không thể tìm thấy máy chủ. Vui lòng kiểm tra kết nối mạng.';
    } else if (message.contains('ssl') || message.contains('certificate')) {
      return 'Lỗi bảo mật kết nối. Vui lòng thử lại sau.';
    } else {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
    }
  }

  /// Gets user-friendly message for string errors
  static String _getStringErrorMessage(String error) {
    final lowerError = error.toLowerCase();

    // Common error patterns
    if (lowerError.contains('network') || lowerError.contains('internet')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
    } else if (lowerError.contains('timeout')) {
      return 'Thao tác bị timeout. Vui lòng thử lại.';
    } else if (lowerError.contains('permission')) {
      return 'Không có quyền thực hiện thao tác này.';
    } else if (lowerError.contains('not found')) {
      return 'Không tìm thấy dữ liệu yêu cầu.';
    } else if (lowerError.contains('invalid')) {
      return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
    } else if (lowerError.contains('expired')) {
      return 'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.';
    } else {
      return _humanizeErrorMessage(error);
    }
  }

  /// Gets generic error message for unknown error types
  static String _getGenericErrorMessage(dynamic error) {
    if (error == null) {
      return 'Đã xảy ra lỗi không xác định.';
    }

    final errorString = error.toString();
    if (errorString.isEmpty || errorString == 'null') {
      return 'Đã xảy ra lỗi không xác định.';
    }

    return _humanizeErrorMessage(errorString);
  }

  /// Converts technical error messages to more human-readable format
  static String _humanizeErrorMessage(String message) {
    // Remove common technical prefixes
    var humanized = message
        .replaceAll(RegExp(r'^Exception:\s*'), '')
        .replaceAll(RegExp(r'^Error:\s*'), '')
        .replaceAll(RegExp(r'^Failure:\s*'), '')
        .replaceAll(RegExp(r'^\w+Exception:\s*'), '');

    // Capitalize first letter
    if (humanized.isNotEmpty) {
      humanized = humanized[0].toUpperCase() + humanized.substring(1);
    }

    // Add period if missing
    if (humanized.isNotEmpty && !humanized.endsWith('.')) {
      humanized += '.';
    }

    // Fallback for very technical messages
    if (humanized.length > 200 || _isTooTechnical(humanized)) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại sau hoặc liên hệ hỗ trợ.';
    }

    return humanized.isNotEmpty ? humanized : 'Đã xảy ra lỗi không xác định.';
  }

  /// Checks if an error message is too technical for end users
  static bool _isTooTechnical(String message) {
    final technicalTerms = [
      'stack trace',
      'null pointer',
      'segmentation fault',
      'assertion failed',
      'index out of bounds',
      'class cast',
      'no such method',
      'illegal argument',
      'concurrent modification',
    ];

    final lowerMessage = message.toLowerCase();
    return technicalTerms.any(lowerMessage.contains);
  }

  /// Gets specific error messages for form validation
  static String getValidationMessage(String field, String? error) {
    if (error == null || error.isEmpty) {
      return '';
    }

    switch (field.toLowerCase()) {
      case 'email':
        if (error.contains('format') || error.contains('invalid')) {
          return 'Định dạng email không hợp lệ.';
        } else if (error.contains('required')) {
          return 'Email là bắt buộc.';
        } else if (error.contains('exists') || error.contains('taken')) {
          return 'Email này đã được sử dụng.';
        }

      case 'password':
        if (error.contains('length') || error.contains('short')) {
          return 'Mật khẩu phải có ít nhất 8 ký tự.';
        } else if (error.contains('weak') || error.contains('strength')) {
          return 'Mật khẩu phải bao gồm chữ hoa, chữ thường và số.';
        } else if (error.contains('required')) {
          return 'Mật khẩu là bắt buộc.';
        }

      case 'displayname':
      case 'display_name':
        if (error.contains('required')) {
          return 'Tên hiển thị là bắt buộc.';
        } else if (error.contains('length')) {
          return 'Tên hiển thị quá dài.';
        }

      case 'currency':
        if (error.contains('invalid')) {
          return 'Mã tiền tệ không hợp lệ.';
        }

      case 'language':
        if (error.contains('invalid')) {
          return 'Mã ngôn ngữ không hợp lệ.';
        }
    }

    return _humanizeErrorMessage(error);
  }

  /// Gets error messages for specific operations
  static String getOperationErrorMessage(String operation, dynamic error) {
    final baseMessage = getErrorMessage(error);

    switch (operation.toLowerCase()) {
      case 'login':
      case 'signin':
        return 'Đăng nhập thất bại: $baseMessage';

      case 'register':
      case 'signup':
        return 'Đăng ký thất bại: $baseMessage';

      case 'logout':
      case 'signout':
        return 'Đăng xuất thất bại: $baseMessage';

      case 'reset_password':
        return 'Đặt lại mật khẩu thất bại: $baseMessage';

      case 'verify_email':
        return 'Xác thực email thất bại: $baseMessage';

      case 'update_profile':
        return 'Cập nhật thông tin thất bại: $baseMessage';

      case 'load_profile':
        return 'Tải thông tin thất bại: $baseMessage';

      default:
        return baseMessage;
    }
  }
}
