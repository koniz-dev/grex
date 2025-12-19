import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grex/core/services/error_logging_service.dart';
import 'package:grex/core/widgets/error_display_widget.dart';

/// Global error handler widget that wraps the app and catches unhandled errors.
///
/// This widget provides a fallback UI for unhandled errors and ensures
/// that the app doesn't crash completely when unexpected errors occur.
class GlobalErrorHandler extends StatefulWidget {
  /// Creates a [GlobalErrorHandler] with the provided configuration.
  ///
  /// The [child] is required and represents the widget tree to wrap.
  /// The [onError] callback is optional and will be called when errors occur.
  const GlobalErrorHandler({
    required this.child,
    super.key,
    this.onError,
  });

  /// The child widget to wrap
  final Widget child;

  /// Optional callback when an error occurs
  final void Function(FlutterErrorDetails details)? onError;

  @override
  State<GlobalErrorHandler> createState() => _GlobalErrorHandlerState();
}

class _GlobalErrorHandlerState extends State<GlobalErrorHandler> {
  FlutterErrorDetails? _lastError;

  @override
  void initState() {
    super.initState();

    // Set up global error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error
      ErrorLoggingService.logError(
        details.exception,
        stackTrace: details.stack,
        context: {
          'library': details.library,
          'context': details.context?.toString(),
        },
        severity: ErrorSeverity.critical,
      );

      // Call custom error handler if provided
      widget.onError?.call(details);

      // Update UI to show error
      if (mounted) {
        setState(() {
          _lastError = details;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    // Show error UI if there's an unhandled error
    if (_lastError != null) {
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: ErrorRecoveryScreen(
              error: _lastError!,
              onRestart: _handleRestart,
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  /// Handles app restart after error recovery
  void _handleRestart() {
    setState(() {
      _lastError = null;
    });
  }
}

/// Screen displayed when a critical error occurs
class ErrorRecoveryScreen extends StatelessWidget {
  /// Creates an [ErrorRecoveryScreen] with the provided error and restart
  /// callback.
  ///
  /// The [error] and [onRestart] are required.
  const ErrorRecoveryScreen({
    required this.error,
    required this.onRestart,
    super.key,
  });

  /// The error details
  final FlutterErrorDetails error;

  /// Callback to restart the app
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error icon
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 24),

          // Error title
          const Text(
            'Đã xảy ra lỗi không mong muốn',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Error description
          const Text(
            'Ứng dụng đã gặp phải một lỗi không thể xử lý. '
            'Chúng tôi đã ghi nhận lỗi này và sẽ khắc phục '
            'trong phiên bản tiếp theo.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Error details (in debug mode)
          if (error.exception.toString().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi tiết lỗi:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.exception.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyErrorToClipboard(context),
                  icon: const Icon(Icons.copy),
                  label: const Text('Sao chép lỗi'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Khởi động lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Help text
          Text(
            'Nếu lỗi tiếp tục xảy ra, vui lòng liên hệ hỗ trợ kỹ thuật.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Copies error details to clipboard
  void _copyErrorToClipboard(BuildContext context) {
    final errorText =
        '''
Grex Error Report
================
Time: ${DateTime.now().toIso8601String()}
Library: ${error.library}
Context: ${error.context}

Exception:
${error.exception}

Stack Trace:
${error.stack}
''';

    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      Clipboard.setData(ClipboardData(text: errorText)).then((_) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Chi tiết lỗi đã được sao chép'),
            backgroundColor: Colors.green,
          ),
        );
      }),
    );
  }
}

/// Mixin for widgets that need error handling capabilities
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  /// Handles errors with consistent logging and user feedback
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool showSnackBar = true,
    VoidCallback? onRetry,
  }) {
    // Log the error
    ErrorLoggingService.logError(
      error,
      stackTrace: stackTrace,
      context: context != null ? {'context': context} : null,
    );

    // Show user feedback if requested
    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: ErrorDisplayWidget(
            error: error,
            onRetry: onRetry,
            showRetry: onRetry != null,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Shows an error dialog with retry option
  void showErrorDialog(
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) {
    if (!mounted) return;

    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title ?? 'Đã xảy ra lỗi'),
          content: ErrorDisplayWidget(
            error: error,
            showRetry: false,
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('Thử lại'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }
}
