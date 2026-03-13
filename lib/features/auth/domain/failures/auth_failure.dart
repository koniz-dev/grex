/// Base class for authentication failures
abstract class AuthFailure {
  /// Creates an [AuthFailure] with the specified error message.
  ///
  /// The [message] parameter provides a human-readable description
  /// of the authentication failure that occurred.
  const AuthFailure(this.message);

  /// Human-readable error message describing the authentication failure.
  ///
  /// This message should be user-friendly and suitable for display
  /// in the UI or for logging purposes.
  final String message;

  @override
  String toString() => message;
}
