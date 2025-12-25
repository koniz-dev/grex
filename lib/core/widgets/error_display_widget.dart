import 'package:flutter/material.dart';
import 'package:grex/core/errors/failures.dart';

/// Widget for displaying different types of errors with appropriate styling
/// and actions.
///
/// This widget provides consistent error display across the app with
/// user-friendly messages, retry mechanisms, and appropriate visual styling.
class ErrorDisplayWidget extends StatelessWidget {
  /// Creates an [ErrorDisplayWidget] with the provided configuration.
  ///
  /// The [error] is required and represents the error to display.
  /// The [onRetry] and [onDismiss] callbacks are optional.
  /// The [showRetry] and [showDismiss] flags control button visibility.
  /// The [customMessage] allows overriding the default error message.
  const ErrorDisplayWidget({
    required this.error,
    super.key,
    this.onRetry,
    this.onDismiss,
    this.showRetry = true,
    this.showDismiss = false,
    this.customMessage,
  });

  /// The error to display
  final dynamic error;

  /// Optional callback for retry action
  final VoidCallback? onRetry;

  /// Optional callback for dismiss action
  final VoidCallback? onDismiss;

  /// Whether to show the retry button
  final bool showRetry;

  /// Whether to show the dismiss button
  final bool showDismiss;

  /// Custom error message override
  final String? customMessage;

  @override
  Widget build(BuildContext context) {
    final errorInfo = _getErrorInfo(error);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorInfo.backgroundColor,
        border: Border.all(color: errorInfo.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error header with icon
          Row(
            children: [
              Icon(
                errorInfo.icon,
                color: errorInfo.iconColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorInfo.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: errorInfo.textColor,
                    fontSize: 16,
                  ),
                ),
              ),
              if (showDismiss && onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: errorInfo.textColor,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Error message
          Text(
            customMessage ?? errorInfo.message,
            style: TextStyle(
              color: errorInfo.textColor,
              fontSize: 14,
            ),
          ),

          // Action buttons
          if (showRetry && onRetry != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onRetry,
                  icon: Icon(
                    Icons.refresh,
                    color: errorInfo.actionColor,
                    size: 18,
                  ),
                  label: Text(
                    'Thử lại',
                    style: TextStyle(color: errorInfo.actionColor),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Gets error information based on error type
  _ErrorInfo _getErrorInfo(dynamic error) {
    if (error is AuthFailure) {
      return _getAuthErrorInfo(error);
    } else if (error is ValidationFailure) {
      return _ErrorInfo(
        title: 'Dữ liệu không hợp lệ',
        message: error.message,
        icon: Icons.warning_outlined,
        backgroundColor: Colors.orange[50]!,
        borderColor: Colors.orange[300]!,
        iconColor: Colors.orange[700]!,
        textColor: Colors.orange[800]!,
        actionColor: Colors.orange[700]!,
      );
    } else if (error is NetworkFailure) {
      return _ErrorInfo(
        title: 'Lỗi kết nối',
        message:
            'Không thể kết nối đến máy chủ. '
            'Vui lòng kiểm tra kết nối mạng và thử lại.',
        icon: Icons.wifi_off,
        backgroundColor: Colors.orange[50]!,
        borderColor: Colors.orange[300]!,
        iconColor: Colors.orange[700]!,
        textColor: Colors.orange[800]!,
        actionColor: Colors.orange[700]!,
      );
    } else if (error is NotFoundFailure) {
      return _ErrorInfo(
        title: 'Không tìm thấy',
        message: error.message,
        icon: Icons.search_off,
        backgroundColor: Colors.grey[50]!,
        borderColor: Colors.grey[300]!,
        iconColor: Colors.grey[700]!,
        textColor: Colors.grey[800]!,
        actionColor: Colors.grey[700]!,
      );
    } else if (error is PermissionFailure) {
      return _ErrorInfo(
        title: 'Không có quyền',
        message: error.message,
        icon: Icons.lock_outline,
        backgroundColor: Colors.red[50]!,
        borderColor: Colors.red[300]!,
        iconColor: Colors.red[700]!,
        textColor: Colors.red[800]!,
        actionColor: Colors.red[700]!,
      );
    } else if (error is ServerFailure) {
      return _ErrorInfo(
        title: 'Lỗi máy chủ',
        message: error.message,
        icon: Icons.error_outline,
        backgroundColor: Colors.red[50]!,
        borderColor: Colors.red[300]!,
        iconColor: Colors.red[700]!,
        textColor: Colors.red[800]!,
        actionColor: Colors.red[700]!,
      );
    } else if (error is CacheFailure) {
      return _ErrorInfo(
        title: 'Lỗi lưu trữ',
        message: error.message,
        icon: Icons.storage,
        backgroundColor: Colors.amber[50]!,
        borderColor: Colors.amber[300]!,
        iconColor: Colors.amber[700]!,
        textColor: Colors.amber[800]!,
        actionColor: Colors.amber[700]!,
      );
    } else {
      return _ErrorInfo(
        title: 'Đã xảy ra lỗi',
        message: error?.toString() ?? 'Lỗi không xác định',
        icon: Icons.error_outline,
        backgroundColor: Colors.red[50]!,
        borderColor: Colors.red[300]!,
        iconColor: Colors.red[700]!,
        textColor: Colors.red[800]!,
        actionColor: Colors.red[700]!,
      );
    }
  }

  /// Gets error info for authentication failures
  /// Uses message and code to determine specific error type
  _ErrorInfo _getAuthErrorInfo(AuthFailure failure) {
    final message = failure.message.toLowerCase();
    final code = failure.code?.toLowerCase() ?? '';

    // Check for specific error patterns in message or code
    if (message.contains('invalid') ||
        message.contains('credentials') ||
        message.contains('email or password') ||
        code.contains('invalid_credentials')) {
      return _ErrorInfo(
        title: 'Thông tin đăng nhập không đúng',
        message: 'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.',
        icon: Icons.lock_outline,
        backgroundColor: Colors.red[50]!,
        borderColor: Colors.red[300]!,
        iconColor: Colors.red[700]!,
        textColor: Colors.red[800]!,
        actionColor: Colors.red[700]!,
      );
    } else if (message.contains('already in use') ||
        message.contains('email already') ||
        code.contains('email_already_in_use')) {
      return _ErrorInfo(
        title: 'Email đã được sử dụng',
        message:
            'Email này đã được đăng ký. '
            'Vui lòng sử dụng email khác hoặc đăng nhập.',
        icon: Icons.email_outlined,
        backgroundColor: Colors.orange[50]!,
        borderColor: Colors.orange[300]!,
        iconColor: Colors.orange[700]!,
        textColor: Colors.orange[800]!,
        actionColor: Colors.orange[700]!,
      );
    } else if (message.contains('weak password') ||
        message.contains('password is too weak') ||
        code.contains('weak_password')) {
      return _ErrorInfo(
        title: 'Mật khẩu không đủ mạnh',
        message:
            'Mật khẩu phải có ít nhất 8 ký tự, '
            'bao gồm chữ hoa, chữ thường và số.',
        icon: Icons.security,
        backgroundColor: Colors.amber[50]!,
        borderColor: Colors.amber[300]!,
        iconColor: Colors.amber[700]!,
        textColor: Colors.amber[800]!,
        actionColor: Colors.amber[700]!,
      );
    } else if (message.contains('unverified') ||
        message.contains('verify your email') ||
        code.contains('unverified_email')) {
      return _ErrorInfo(
        title: 'Email chưa được xác thực',
        message:
            'Vui lòng xác thực email trước khi đăng nhập. '
            'Kiểm tra hộp thư của bạn.',
        icon: Icons.mark_email_unread,
        backgroundColor: Colors.blue[50]!,
        borderColor: Colors.blue[300]!,
        iconColor: Colors.blue[700]!,
        textColor: Colors.blue[800]!,
        actionColor: Colors.blue[700]!,
      );
    } else {
      return _ErrorInfo(
        title: 'Lỗi xác thực',
        message: failure.message,
        icon: Icons.error_outline,
        backgroundColor: Colors.red[50]!,
        borderColor: Colors.red[300]!,
        iconColor: Colors.red[700]!,
        textColor: Colors.red[800]!,
        actionColor: Colors.red[700]!,
      );
    }
  }
}

/// Information about how to display an error
class _ErrorInfo {
  const _ErrorInfo({
    required this.title,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.actionColor,
  });
  final String title;
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Color actionColor;
}
