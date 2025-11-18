/// Base exception for application-specific failures.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException(message: $message, cause: $cause)';
}

/// Thrown when a network request fails or returns an invalid response.
class NetworkException extends AppException {
  const NetworkException(String message, {this.statusCode, Object? cause})
      : super(message, cause: cause);

  final int? statusCode;
}

/// Thrown when required data cannot be found or is malformed.
class DataException extends AppException {
  const DataException(String message, {Object? cause})
      : super(message, cause: cause);
}
